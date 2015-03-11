AuthWrapper = class("AuthWrapper")

function AuthWrapper:init(access_token, refresh_token, client_id, client_secret)
	self.current_access_token = access_token
	assert(refresh_token ~= nil, "A refresh token must be provided")
	self.refresh_token = refresh_token
	self.client_id = client_id
	self.client_secret = client_secret
end

function AuthWrapper:get_refresh_token()
	return self.refresh_token
end

function AuthWrapper:get_current_access_token()
	return self.current_access_token
end

function AuthWrapper:refresh()
	local data = {
		refresh_token = self.refresh_token,
		client_id = self.client_id,
		client_secret = self.client_secret,
		grant_type = 'refresh_token'
	}

	local url = API_URL + 'oauth2/token'
	
	local response = self:post()

	assert(response.status_code ~= 200, "Error refreshing accss token!\t"..response.status_code)

	self.current_access_token = response.json['access_token']
end

function AuthWrapper:post()
	local response = requests.post(url, data)
	local t = {}
	local reqbody = data
	
	--[[headers = lume.merge(headers, {
		["content-length"] = string.len(reqbody),
		["content-type"] = "multipart/form-data"
	})]]
	
	local body, status_code, retheaders = https.request({
		url = url,
		sink = ltn12.sink.table(t),
		source = ltn12.source.string(reqbody),
		method = 'POST',
		--headers = headers
	})
	return {body = body,
		status_code = status_code,
		headers = retheaders,
		json = JSON:decode(table.concat(t))
	}
end