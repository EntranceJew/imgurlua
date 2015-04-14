local AuthWrapper = class("AuthWrapper")

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
		method = 'POST',
		data = {
			refresh_token = self.refresh_token,
			client_id = self.client_id,
			client_secret = self.client_secret,
			grant_type = 'refresh_token',
		}
	}

	local url = API_URL + 'oauth2/token'
	
	local response, code, desc = request.send(url, data)
	print(response)
	print(code)
	print(desc)
	
	if response then
		assert(response.code ~= 200, "Error refreshing accss token!\t"..response.code)
	elseif code then
		assert(code ~= 200, "Error refreshing accss token!\t"..code)
	end

	local json = JSON:decode(response.body)

	self.current_access_token = json['access_token']
end

return AuthWrapper