function love.load()
	require('keys')
	hamster = love.graphics.newImage("hamster.png")
	x = 50
	y = 50
	speed = 300
	
	-- imgur stuff
	imgurlua = require("lib")
	
	client = ImgurClient:new(CLIENT_ID, CLIENT_SECRET)
	
	items = client:gallery()
	for _,item in ipairs(items) do
		print(_, item.id, item.account_url, item.title)
	end
end

function love.update(dt)
	if love.keyboard.isDown("x") then
		print("\n")
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