function love.conf(t)
	t.identity = "ImgurLua"
	t.version = "0.9.1"
	t.console = true
	
	t.window.title = t.identity
	t.window.width = 1200
	t.window.height = 672
	
	t.modules.physics = false
end