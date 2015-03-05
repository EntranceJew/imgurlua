function build_comment_tree(children)
	local children_objects = {}
	for child in pairs(children) do
		local to_insert = Comment(child)
		to_insert.children = build_comment_tree(to_insert.children)
		children_objects.append(to_insert)
	end

	return children_objects
end

function format_comment_tree(response)
	local result = {}
	if type(response)=='table' then
		for comment in pairs(response) do
			local formatted = Comment(comment)
			formatted.children = build_comment_tree(comment['children'])
			result.append(formatted)
		end
	else
		result = Comment(response)
		result.children = build_comment_tree(response['children'])
	end

	return result
end

function build_gallery_images_and_albums(response)
	print_r(response)
	local result = {}
	if type(response)=='table' then
		for _,item in ipairs(response) do
			if item['is_album'] then
				table.insert(result,GalleryAlbum(item))
			else
				table.insert(result,GalleryImage(item))
			end
		end
	else
		if response['is_album'] then
			result = GalleryAlbum(response)
		else
			result = GalleryImage(response)
		end
	end

	return result
end

function build_notifications(response)
	local result = {
			replies = {},
			messages = {}
	}
	for item in pairs(response['messages']) do
		table.insert(result.messages, Notification(
			item['id'],
			item['account_id'],
			item['viewed'],
			item['content']
		))
	end

	for item in pairs(response['replies']) do
		local notification = Notification(
			item['id'],
			item['account_id'],
			item['viewed'],
			item['content']
		)
		notification.content = format_comment_tree(item['content'])
		result['replies'].append(notification)
	end

	return result
end

function build_notification(item)
	local notification = Notification(
		item['id'],
		item['account_id'],
		item['viewed'],
		item['content']
	)

	if lume.find(notification.content, 'comment') then
		notification.content = format_comment_tree(item['content'])
	end

	return notification
end