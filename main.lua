function love.load()
	require('keys')
	hamster = love.graphics.newImage("hamster.png")
	x = 50
	y = 50
	speed = 300
	
	-- imgur stuff
	imgurlua = require("lib")
	
	pin = ""
	
	client = ImgurClient:new(CLIENT_ID, CLIENT_SECRET, ACCESS_TOKEN, REFRESH_TOKEN)
	
	print(client:get_auth_url())
end

function love.update(dt)
	if love.keyboard.isDown("x") then
		print("\n")
	end
	
	if love.keyboard.isDown("g") then
		items = client:gallery()
		for _,item in ipairs(items) do
			print(_, item.id, item.account_url, item.title)
		end
		print("GALLERY DELIVERED")
	end
	
	if love.keyboard.isDown("y") then
		debug.debug()
	end
	
	if love.keyboard.isDown("u") then
		creds = client:authorize(pin, "pin")
		client:set_user_auth(creds.access_token, creds.refresh_token)
		print("USER AUTHORIZED, PROBABLY")
	end
	
	if love.keyboard.isDown("i") then
		print("UPLOADING IMAGE")
		local con={
			name = "Horse",
			title = "Two Horses",
			description = "Seven Whole Horses"
		}
		client:upload_from_path("hamster.png", con, false)
	end
	
	if love.keyboard.isDown("right") then
		x = x + (speed * dt)
	end
	if love.keyboard.isDown("left") then
		x = x - (speed * dt)
	end

	if love.keyboard.isDown("down") then
		y = y + (speed * dt)
	end
	if love.keyboard.isDown("up") then
		y = y - (speed * dt)
	end
end

function love.draw()
	love.graphics.draw(hamster, x, y)
end