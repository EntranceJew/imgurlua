package = "imgurlua"
version = "1.0-1"
source = {
	url = 'git://github.com/EntranceJew/imgurlua.git',
	tag = 'master',
}
description = {
	summary = "The Imgur API, now in lua.",
	detailed = [[
	   A Lua client for the Imgur API.
	   It can be used to interact with the Imgur API in your projects.
	]],
	homepage = "https://github.com/EntranceJew/imgurlua",
	maintainer = "EntranceJew <EntranceJew@gmail.com>",
}
dependencies = {
	"lua >= 5.1",
	"middleclass >= 3.0-1",
}
build = {
	type = 'builtin',
	modules = {
		imgurlua = 'init.lua',
	},
}