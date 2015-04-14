local path = string.sub(..., 1, string.len(...) - string.len(".imgurclient"))

local ImgurClient = class('ImgurClient')

-- helpers
local Format = require(path .. ".helpers.format")
local AuthWrapper = require(path .. ".authwrapper")

-- models
local Account = require(path .. ".models.account")
local AccountSettings = require(path .. ".models.account_settings")
local Album = require(path .. ".models.album")
local Comment = require(path .. ".models.comment")
local Conversation = require(path .. ".models.conversation")
local CustomGallery = require(path .. ".models.custom_gallery")
local Image = require(path .. ".models.image")
local Tag = require(path .. ".models.tag")
local TagVote = require(path .. ".models.tag_vote")

-- vendor/dependencies
local mime = require("mime")
local request = require(path .. ".vendor.luajit-request.luajit-request")
local JSON = require(path .. ".vendor.JSON")
local lume = require(path .. ".vendor.lume")

local API_URL = 'https://api.imgur.com/'

local ioreader = function(path)
	return love.filesystem.read(path)
end

--[[ (bad) pure lua implementation:
ioreader = function(path)
	local fd = io.open(path, 'rb')
	local content = fd:read("*all")
	fd:close()
	return content
end
]]

local function bool_to_string(i)
	if i then
		return "true"
	else
		return "false"
	end
end

function ImgurClient:init(client_id, client_secret, access_token, refresh_token)
	assert(client_id ~= nil, "Client ID cannot be nil.")
	self.client_id = client_id
	assert(client_secret ~= nil, "Client secret cannot be nil.")
	self.client_secret = client_secret

	access_token = access_token or nil
	refresh_token = refresh_token or nil

	self.allowed_album_fields = {
		'ids', 'title', 'description', 'privacy', 'layout', 'cover'
	}

	self.allowed_advanced_search_fields = {
		'q_all', 'q_any', 'q_exactly', 'q_not', 'q_type', 'q_size_px'
	}

	self.allowed_account_fields = {
		'bio', 'public_images', 'messaging_enabled', 'album_privacy', 'accepted_gallery_terms', 'username'
	}

	self.allowed_image_fields = {
		'album', 'name', 'title', 'description'
	}

	self.auth = nil

	if refresh_token then
		self.auth = AuthWrapper(access_token, refresh_token, self.client_id, self.client_secret)
	end

	self.credits = self:get_credits()
end

function ImgurClient:set_user_auth(access_token, refresh_token)
	self.auth = AuthWrapper(access_token, refresh_token, self.client_id, self.client_secret)
end

function ImgurClient:get_client_id()
	return self.client_id
end

function ImgurClient:get_credits()
	return self:make_request('GET', 'credits', nil, true)
end

function ImgurClient:get_auth_url(response_type)
	response_type = response_type or 'pin'
	return string.format('%soauth2/authorize?client_id=%s&response_type=%s', API_URL, self.client_id, response_type)
end

function ImgurClient:authorize(response, grant_type)
	assert(response ~= nil, "Response was nil, cannot authorize it.")
	grant_type = grant_type or 'pin'
	
	local body = {
		client_id = self.client_id,
		client_secret = self.client_secret,
		grant_type = grant_type
	}
	
	if grant_type == 'authorization_code' then
		body.code = response
	elseif grant_type == 'pin' then
		body.pin = response
	end
	
	return self:make_request('POST', 'oauth2/token', body, true)
end

function ImgurClient:prepare_headers(force_anon)
	force_anon = force_anon or false
	if force_anon or self.auth == nil then
		if self.client_id == nil then
			assert(false, "ImgurClientError: Client credentials not found!")
			--raise ImgurClientError('Client credentials not found!')
		else
			return {Authorization = string.format('Client-ID %s',self:get_client_id())}
		end
	else
		return {Authorization = string.format('Bearer %s',self.auth:get_current_access_token())}
	end
end

function ImgurClient:method_to_call(method, url, headers, params, data)
	print_r({method=method, url=url, headers=headers, params=params, data=data})
	--params are turned into url parameters
	--data is the post body
	--@TODO: integrate params into querystring

	local req = {
		data = data,
		method = string.upper(method),
		headers = headers
	}
	
	local response, code, desc = request.send(url, req)
	if code then
		assert(code ~= nil, "ERROR PROCESSING HTTP REQUEST? "..code.." & "..desc)
	end
	
	response.json = JSON:decode(response.body)
	
	return response
end

--[[
If things don't make sense, remember we're replacing the following:
https://github.com/kennethreitz/requests/blob/e4ddca0f8b5f61a7cc5f3c1e46174ac05f8f6920/requests/api.py#L17
]]
function ImgurClient:make_request(method, route, data, force_anon)
	assert(method ~= nil, "Method cannot be nil.")
	assert(route ~= nil, "Route cannot be nil.")
	data = data or nil
	force_anon = force_anon or false
	
	local url = API_URL
	if string.find(route, 'oauth2') then
		url = url .. route
	else
		url = url .. string.format('3/%s', route)
	end
	print(method, route, url)
	
	local header = self:prepare_headers(force_anon)
	
	local response
	if lume.find({'delete', 'get'}, method) then
		--print("DEBUG: inside meth1")
		response = self:method_to_call(method, url, header, data, data)
	else
		--print("DEBUG: inside meth2")
		response = self:method_to_call(method, url, header, nil, data) --not supposed to have params supplied
		--print_r({response=response, yukka=yukka, zukka=zukka})
	end
	
	if response.code == 403 and self.auth ~= nil then
		print("DEBUG: need to refresh")
		self.auth:refresh()
		header = self:prepare_headers(force_anon)
		if lume.find({'delete', 'get'}, method) then
			print("DEBUG: refresh inside meth1")
			response = self:method_to_call(method, url, header, data, data)
		else
			print("DEBUG: refresh inside meth2")
			response = self:method_to_call(method, url, header, data)
		end
	end

	self.credits = {
		UserLimit = response.headers['X-RateLimit-UserLimit'],
		UserRemaining = response.headers['X-RateLimit-UserRemaining'],
		UserReset = response.headers['X-RateLimit-UserReset'],
		ClientLimit = response.headers['X-RateLimit-ClientLimit'],
		ClientRemaining = response.headers['X-RateLimit-ClientRemaining']
	}

	-- Rate-limit check
	if response.code == 429 then
		assert(false, "ImgurClientRateLimitError: No more posts allowed.")
	end

	if response.json == nil then
		assert(false, "JSON decoding of response failed.")
	end

	if lume.find(response.json, 'data') and 
		type(response.json['data']) == 'table' and
		lume.find(response.json['data'], 'error')
		then
		assert(false, "ImgurClientError: "..response.json['data']['error'] .. "\t" .. response.code)
	end
	if response.json.data then
		return response.json.data
	else
		return response.json
	end
end

function ImgurClient:validate_user_context(username)
	assert(username == 'me' and self.auth == nil, "ImgurClientError: 'me' can only be used in the authenticated context.")
end

function ImgurClient:logged_in()
	assert(self.auth ~= nil, "ImgurClientError: Must be logged in to complete request.")
end

-- Account-related endpoints
function ImgurClient:get_account(username)
	self:validate_user_context(username)
	local account_data = self:make_request('GET', string.format('account/%s', username))

	return Account(
		account_data['id'],
		account_data['url'],
		account_data['bio'],
		account_data['reputation'],
		account_data['created'],
		account_data['pro_expiration']
	)
end

function ImgurClient:get_gallery_favorites(username)
	self:validate_user_context(username)
	local gallery_favorites = self:make_request('GET', string.format('account/%s/gallery_favorites', username))

	return Format.build_gallery_images_and_albums(gallery_favorites)
end

function ImgurClient:get_account_favorites(username)
	self:validate_user_context(username)
	local favorites = self:make_request('GET', string.format('account/%s/favorites', username))

	return Format.build_gallery_images_and_albums(favorites)
end

function ImgurClient:get_account_submissions(username, page)
	page = page or 0
	self:validate_user_context(username)
	local submissions = self:make_request('GET', string.format('account/%s/submissions/%d', username, page))

	return Format.build_gallery_images_and_albums(submissions)
end

function ImgurClient:get_account_settings(username)
	self:logged_in()
	local settings = self:make_request('GET', string.format('account/%s/settings', username))

	return AccountSettings(
		settings['email'],
		settings['high_quality'],
		settings['public_images'],
		settings['album_privacy'],
		settings['pro_expiration'],
		settings['accepted_gallery_terms'],
		settings['active_emails'],
		settings['messaging_enabled'],
		settings['blocked_users']
	)
end

function ImgurClient:change_account_settings(username, fields)
	local post_data = {}
	for _,setting in ipairs(self.allowed_account_fields) do
		if fields[setting] then
			post_data[setting] = fields[setting]
		end
	end
	return self:make_request('POST', string.format('account/%s/settings', username), post_data)
end

function ImgurClient:get_email_verification_status(username)
	self:logged_in()
	self:validate_user_context(username)
	return self:make_request('GET', string.format('account/%s/verifyemail', username))
end

function ImgurClient:send_verification_email(username)
	self:logged_in()
	self:validate_user_context(username)
	return self:make_request('POST', string.format('account/%s/verifyemail', username))
end

function ImgurClient:get_account_albums(username, page)
	local page = page or 0
	self:validate_user_context(username)

	local albums = self:make_request('GET', string.format('account/%s/albums/%d', username, page))
	local ret = {}
	for _,album in ipairs(albums) do
		table.insert(ret, Album(album))
	end
	return ret
end

function ImgurClient:get_account_album_ids(username, page)
	page = page or 0
	self:validate_user_context(username)
	return self:make_request('GET', string.format('account/%s/albums/ids/%d', username, page))
end

function ImgurClient:get_account_album_count(username)
	self:validate_user_context(username)
	return self:make_request('GET', string.format('account/%s/albums/count', username))
end

function ImgurClient:get_account_comments(username, sort, page)
	sort = sort or 'newest'
	page = page or 0
	self.validate_user_context(username)
	local comments = self:make_request('GET', string.format('account/%s/comments/%s/%s', username, sort, page))

	local ret = {}
	for _,comment in ipairs(comments) do
		table.insert(ret, Comment(comment))
	end
	return ret
end

function ImgurClient:get_account_comment_ids(username, sort, page)
	sort = sort or 'newest'
	page = page or 0
	self:validate_user_context(username)
	return self:make_request('GET', string.format('account/%s/comments/ids/%s/%s', username, sort, page))
end

function ImgurClient:get_account_comment_count(username)
	self:validate_user_context(username)
	return self:make_request('GET', string.format('account/%s/comments/count', username))
end

function ImgurClient:get_account_images(username, page)
	page = page or 0
	self.validate_user_context(username)
	local images = self:make_request('GET', string.format('account/%s/images/%d', username, page))
	local ret = {}
	for _,image in ipairs(images) do
		table.insert(ret, Image(image))
	end
	return ret
end

function ImgurClient:get_account_image_ids(username, page)
	page = page or 0
	self:validate_user_context(username)
	return self:make_request('GET', string.format('account/%s/images/ids/%d', username, page))
end

function ImgurClient:get_account_images_count(username)
	self:validate_user_context(username)
	return self:make_request('GET', string.format('account/%s/images/count', username))
end

-- Album-related endpoints
function ImgurClient:get_album(album_id)
	local album = self:make_request('GET', string.format('album/%s', album_id))
	return Album(album)
end

function ImgurClient:get_album_images(album_id)
	local images = self:make_request('GET', string.format('album/%s/images', album_id))
	local ret = {}
	for _,image in ipairs(images) do
		table.insert(ret, Image(image))
	end
	return ret
end

function ImgurClient:create_album(fields)
	local post_data = {}
	for _,field in ipairs(self.allowed_album_fields) do
		if fields[field] then
			post_data[field] = fields[field]
		end
	end

	if post_data['ids'] then
		self:logged_in()
	end

	return self:make_request('POST', 'album', post_data)
end

function ImgurClient:update_album(album_id, fields)
	local post_data = {}
	for _,field in ipairs(self.allowed_album_fields) do
		if fields[field] then
			post_data[field] = fields[field]
		end
	end

	if type(post_data['ids'])=="table" then
		post_data['ids'] = table.concat(post_data['ids'], ",")
	end

	return self:make_request('POST', string.format('album/%s', album_id), post_data)
end

function ImgurClient:album_delete(album_id)
	return self:make_request('DELETE', string.format('album/%s',album_id))
end

function ImgurClient:album_favorite(album_id)
	self:logged_in()
	return self:make_request('POST', string.format('album/%s/favorite', album_id))
end

function ImgurClient:album_set_images(album_id, ids)
	if type(ids)=="table" then
		ids = table.concat(ids, ",")
	end

	return self:make_request('POST', string.format('album/%s/',album_id), {ids = ids})
end

function ImgurClient:album_add_images(album_id, ids)
	if type(ids)=="table" then
		ids = table.concat(ids, ",")
	end

	return self:make_request('POST', string.format('album/%s/add', album_id), {ids = ids})
end

function ImgurClient:album_remove_images(album_id, ids)
	if type(ids)=="table" then
		ids = table.concat(ids, ",")
	end

	return self:make_request('DELETE', string.format('album/%s/remove_images', album_id), {ids = ids})
end

-- Comment-related endpoints
function ImgurClient:get_comment(comment_id)
	local comment = self:make_request('GET', string.format('comment/%d', comment_id))
	return Comment(comment)
end

function ImgurClient:delete_comment(comment_id)
	self:logged_in()
	return self:make_request('DELETE', string.format('comment/%d', comment_id))
end

function ImgurClient:get_comment_replies(comment_id)
	local replies = self:make_request('GET', string.format('comment/%d/replies', comment_id))
	return Format.format_comment_tree(replies)
end

function ImgurClient:post_comment_reply(comment_id, image_id, comment)
	self:logged_in()
	local data = {
		image_id = image_id,
		comment = comment
	}

	return self:make_request('POST', string.format('comment/%d',comment_id), data)
end

function ImgurClient:comment_vote(comment_id, vote)
	vote = vote or 'up'
	self:logged_in()
	return self:make_request('POST', string.format('comment/%d/vote/%s', comment_id, vote))
end

function ImgurClient:comment_report(comment_id)
	self:logged_in()
	return self:make_request('POST', string.format('comment/%d/report', comment_id))
end

-- Custom Gallery Endpoints
function ImgurClient:get_custom_gallery(gallery_id, sort, window, page)
	sort = sort or 'viral'
	window = window or 'week'
	page = page or 0
	
	local gallery = self:make_request('GET', string.format('g/%s/%s/%s/%s', gallery_id, sort, window, page))
	return CustomGallery(
		gallery['id'],
		gallery['name'],
		gallery['datetime'],
		gallery['account_url'],
		gallery['link'],
		gallery['tags'],
		gallery['item_count'],
		gallery['items']
	)
end

function ImgurClient:get_user_galleries()
	self:logged_in()
	local galleries = self:make_request('GET', 'g')
	local ret = {}

	for _,gallery in ipairs(galleries) do
		table.insert(ret, CustomGallery(
			gallery['id'],
			gallery['name'],
			gallery['datetime'],
			gallery['account_url'],
			gallery['link'],
			gallery['tags']
		))
	end
	return ret
end

function ImgurClient:create_custom_gallery(name, tags)
	tags = tags or nil
	self:logged_in()
	local data = {name = name}

	if tags then
		data['tags'] = table.concat(tags, ',')
	end

	local gallery = self:make_request('POST', 'g', data)

	return CustomGallery(
		gallery['id'],
		gallery['name'],
		gallery['datetime'],
		gallery['account_url'],
		gallery['link'],
		gallery['tags']
	)
end

function ImgurClient:custom_gallery_update(gallery_id, name)
	self:logged_in()
	local data = {
		id = gallery_id,
		name = name
	}

	local gallery = self.make_request('POST', string.format('g/%s', gallery_id), data)

	return CustomGallery(
		gallery['id'],
		gallery['name'],
		gallery['datetime'],
		gallery['account_url'],
		gallery['link'],
		gallery['tags']
	)
end

function ImgurClient:custom_gallery_add_tags(gallery_id, tags)
	self:logged_in()

	local data
	if tags then
		data = {tags = table.concat(tags, ',')}
	else
		assert(false, "ImgurClientError: tags must not be empty!")
	end

	return self:make_request('PUT', string.format('g/%s/add_tags', gallery_id), data)
end

function ImgurClient:custom_gallery_remove_tags(gallery_id, tags)
	self:logged_in()

	local data
	if tags then
		data = {tags = table.concat(tags, ',')}
	else
		assert(false, "ImgurClientError: tags must not be empty!")
	end

	return self:make_request('DELETE', string.format('g/%s/remove_tags', gallery_id), data)
end

function ImgurClient:custom_gallery_delete(gallery_id)
	self:logged_in()
	return self:make_request('DELETE', string.format('g/%s', gallery_id))
end

function ImgurClient:filtered_out_tags()
	self:logged_in()
	return self:make_request('GET', 'g/filtered_out')
end

function ImgurClient:block_tag(tag)
	self:logged_in()
	return self:make_request('POST', 'g/block_tag', {tag = tag})
end

function ImgurClient:unblock_tag(tag)
	self:logged_in()
	return self:make_request('POST', 'g/unblock_tag', {tag = tag})
end

-- Gallery-related endpoints
function ImgurClient:gallery(section, sort, page, window, show_viral)
	section = section or 'hot'
	sort = sort or 'viral'
	page = 0
	window = 'day'
	show_viral = show_viral or (show_viral == nil)
	local response
	if section == 'top' then
		response = self:make_request('GET', 
			string.format('gallery/%s/%s/%s/%d?showViral=%s', section, sort, window, page, bool_to_string(show_viral))
		)
	else
		response = self:make_request('GET', 
			string.format('gallery/%s/%s/%d?showViral=%s', section, sort, page, bool_to_string(show_viral))
		)
	end

	return Format.build_gallery_images_and_albums(response)
end

function ImgurClient:memes_subgallery(sort, page, window)
	sort = sort or 'viral'
	page = page or 0
	window = window or 'week'
	
	local response
	if sort == 'top' then
		response = self:make_request('GET', string.format('g/memes/%s/%s/%d', sort, window, page))
	else
		response = self:make_request('GET', string.format('g/memes/%s/%d', sort, page))
	end

	return Format.build_gallery_images_and_albums(response)
end

function ImgurClient:memes_subgallery_image(item_id)
	local item = self:make_request('GET', string.format('g/memes/%s', item_id))
	return Format.build_gallery_images_and_albums(item)
end

function ImgurClient:subreddit_gallery(subreddit, sort, window, page)
	sort = sort or 'time'
	window = window or 'week'
	page = page or 0
	
	local response
	if sort == 'top' then
		response = self:make_request('GET', string.format('gallery/r/%s/%s/%s/%d', subreddit, sort, window, page))
	else
		response = self:make_request('GET', string.format('gallery/r/%s/%s/%d', subreddit, sort, page))
	end

	return Format.build_gallery_images_and_albums(response)
end

function ImgurClient:subreddit_image(subreddit, image_id)
	local item = self:make_request('GET', string.format('gallery/r/%s/%s', subreddit, image_id))
	return Format.build_gallery_images_and_albums(item)
end

function ImgurClient:gallery_tag(tag, sort, page, window)
	sort = sort or 'viral'
	page = page or 0
	window = window or 'week'
	
	local response
	if sort == 'top' then
		response = self:make_request('GET', string.format('gallery/t/%s/%s/%s/%d', tag, sort, window, page))
	else
		response = self:make_request('GET', string.format('gallery/t/%s/%s/%d', tag, sort, page))
	end

	return Tag(
		response['name'],
		response['followers'],
		response['total_items'],
		response['following'],
		response['items']
	)
end

function ImgurClient:gallery_tag_image(tag, item_id)
	local item = self:make_request('GET', string.format('gallery/t/%s/%s', tag, item_id))
	return Format.build_gallery_images_and_albums(item)
end

function ImgurClient:gallery_item_tags(item_id)
	local response = self:make_request('GET', string.format('gallery/%s/tags', item_id))
	local ret = {}
	
	for _,item in ipairs(response['tags']) do
		table.insert(ret, TagVote(
			item['ups'],
			item['downs'],
			item['name'],
			item['author']
		))
	end
	return ret
end


function ImgurClient:gallery_tag_vote(item_id, tag, vote)
	self:logged_in()
	local response = self:make_request('POST', string.format('gallery/%s/vote/tag/%s/%s', item_id, tag, vote))
	return response
end

function ImgurClient:gallery_search(q, advanced, sort, window, page)
	advanced = advanced or nil
	sort = sort or 'time'
	window = window or 'all'
	page = page or 0
	
	local data = {}
	if advanced then
		for _,field in ipairs(self.allowed_advanced_search_fields) do
			if advanced[field] then
				data[field] = advanced[field]
			end
		end
	else
		data = {q = q}
	end

	local response = self:make_request('GET', string.format('gallery/search/%s/%s/%s', sort, window, page), data)
	return Format.build_gallery_images_and_albums(response)
end

function ImgurClient:gallery_random(page)
	page = page or 0
	local response = self.make_request('GET', string.format('gallery/random/random/%d', page))
	return Format.build_gallery_images_and_albums(response)
end

function ImgurClient:share_on_imgur(item_id, title, terms)
	terms = terms or 0
	self:logged_in()
	local data = {
		title = title,
		terms = terms
	}

	return self:make_request('POST', string.format('gallery/%s', item_id), data)
end

function ImgurClient:remove_from_gallery(item_id)
	self:logged_in()
	return self:make_request('DELETE', string.format('gallery/%s', item_id))
end

function ImgurClient:gallery_item(item_id)
	local response = self.make_request('GET', string.format('gallery/%s', item_id))
	return Format.build_gallery_images_and_albums(response)
end

function ImgurClient:report_gallery_item(item_id)
	self:logged_in()
	return self:make_request('POST', string.format('gallery/%s/report', item_id))
end

function ImgurClient:gallery_item_vote(item_id, vote)
	vote = vote or 'up'
	self:logged_in()
	return self:make_request('POST', string.format('gallery/%s/vote/%s', item_id, vote))
end

function ImgurClient:gallery_item_comments(item_id, sort)
	sort = sort or 'best'
	local response = self:make_request('GET', string.format('gallery/%s/comments/%s', item_id, sort))
	return Format.format_comment_tree(response)
end

function ImgurClient:gallery_comment(item_id, comment)
	self:logged_in()
	return self:make_request('POST', string.format('gallery/%s/comment', item_id), {comment = comment})
end

function ImgurClient:gallery_comment_ids(item_id)
	return self:make_request('GET', string.format('gallery/%s/comments/ids', item_id))
end

function ImgurClient:gallery_comment_count(item_id)
	return self:make_request('GET', string.format('gallery/%s/comments/count', item_id))
end

-- Image-related endpoints
function ImgurClient:get_image(image_id)
	local image = self:make_request('GET', string.format('image/%s', image_id))
	return Image(image)
end

function ImgurClient:upload_from_path(path, config, anon)
	config = config or nil
	anon = anon or (anon == nil)
	
	if not config then
		config = {}
	end

	local contents = ioreader(path)
	local b64 = mime.b64(contents)

	local data = {
		image = b64,
		type = 'base64',
	}
	
	for _,meta in ipairs(self.allowed_image_fields) do
		if config[meta] then
			data[meta] = config[meta]
		end
	end
	print_r({path=path, config=config, anon=anon})
	local req = self:make_request('POST', 'upload', data, anon)
	print_r(req)
	return req
end

function ImgurClient:upload_from_url(url, config, anon)
	config = config or nil
	anon = anon or (anon == nil)
	if not config then
		config = {}
	end

	local data = {
		image = url,
		type = 'url',
	}

	for _,meta in ipairs(self.allowed_image_fields) do
		if config[meta] then
			data[meta] = config[meta]
		end
	end
	
	return self:make_request('POST', 'upload', data, anon)
end

function ImgurClient:delete_image(image_id)
	return self:make_request('DELETE', string.format('image/%s', image_id))
end

function ImgurClient:favorite_image(image_id)
	self:logged_in()
	return self:make_request('POST', string.format('image/%s/favorite', image_id))
end

-- Conversation-related endpoints
function ImgurClient:conversation_list()
	self:logged_in()

	local conversations = self:make_request('GET', 'conversations')
	local ret = {}
	for _,conversation in ipairs(conversations) do
		table.insert(ret, Conversation(
			conversation['id'],
			conversation['last_message_preview'],
			conversation['datetime'],
			conversation['with_account_id'],
			conversation['with_account'],
			conversation['message_count']
		))
	end
	return ret
end

function ImgurClient:get_conversation(conversation_id, page, offset)
	page = page or 1
	offset = offset or 0
	self:logged_in()

	local conversation = self:make_request('GET', string.format('conversations/%d/%d/%d', conversation_id, page, offset))
	return Conversation(
		conversation['id'],
		conversation['last_message_preview'],
		conversation['datetime'],
		conversation['with_account_id'],
		conversation['with_account'],
		conversation['message_count'],
		conversation['messages'],
		conversation['done'],
		conversation['page']
	)
end

function ImgurClient:create_message(recipient, body)
	self:logged_in()
	return self:make_request('POST', string.format('conversations/%s', recipient), {body = body})
end

function ImgurClient:delete_conversation(conversation_id)
	self:logged_in()
	return self:make_request('DELETE', string.format('conversations/%d', conversation_id))
end

function ImgurClient:report_sender(username)
	self:logged_in()
	return self:make_request('POST', string.format('conversations/report/%s', username))
end

function ImgurClient:block_sender(username)
	self:logged_in()
	return self:make_request('POST', string.format('conversations/block/%s', username))
end

-- Notification-related endpoints
function ImgurClient:get_notifications(new)
	new = new or (new == nil)
	self:logged_in()
	local response = self:make_request('GET', 'notification', {new = string.lower(new)})
	return Format.build_notifications(response)
end

function ImgurClient:get_notification(notification_id)
	self:logged_in()
	local response = self:make_request('GET', string.format('notification/%d', notification_id))
	return Format.build_notification(response)
end

function ImgurClient:mark_notifications_as_read(notification_ids)
	self:logged_in()
	return self.make_request('POST', 'notification', table.concat(notification_ids, ','))
end

-- Memegen-related endpoints
function ImgurClient:default_memes()
	local response = self:make_request('GET', 'memegen/defaults')
	local ret = {}
	for _,meme in ipairs(response) do
		table.insert(ret, Image(meme))
	end
	return ret
end

return ImgurClient