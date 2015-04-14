local path = ...
local imgurlua = {}

-- internal helpers
require(path .. ".vendor.strap")

-- to-be-phased-out helpers
lume = require(path .. ".vendor.lume")
class = require(path .. ".vendor.middleclass")
JSON = require(path .. ".vendor.JSON")

-- built-in requires
mime = require("mime")
ltn12 = require("ltn12")

-- ssl related things
request = require(path .. ".vendor.luajit-request.luajit-request")

-- love handler for convenience
ioreader = function(path)
	return love.filesystem.read(path)
end

--[[ pure lua implementation
ioreader = function(path)
	local fd = io.open(path, 'rb')
	local content = fd:read("*all")
	fd:close()
	return content
end
]]

API_URL = 'https://api.imgur.com/'

require(path .. ".models.account")
require(path .. ".models.account_settings")
require(path .. ".models.album")
require(path .. ".models.comment")
require(path .. ".models.conversation")
require(path .. ".models.custom_gallery")
require(path .. ".models.gallery_album")
require(path .. ".models.gallery_image")
require(path .. ".models.image")
require(path .. ".models.message")
require(path .. ".models.notification")
require(path .. ".models.tag")
require(path .. ".models.tag_vote")

require(path .. ".helpers.format")

imgurlua.authwrapper = require(path .. ".authwrapper")
imgurlua.imgurclient = require(path .. ".imgurclient")

return imgurlua