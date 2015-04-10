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
require(path .. ".vendor.luajit-request.luajit-curl")
request = require(path .. ".vendor.luajit-request.luajit-request")
--require(path .. ".bin.ssl")
--require(path .. ".vendor.ssl")
--require(path .. ".vendor.ssl.https")
--https = require("ssl.https")

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

require(path .. ".imgur.models.account")
require(path .. ".imgur.models.account_settings")
require(path .. ".imgur.models.album")
require(path .. ".imgur.models.comment")
require(path .. ".imgur.models.conversation")
require(path .. ".imgur.models.custom_gallery")
require(path .. ".imgur.models.gallery_album")
require(path .. ".imgur.models.gallery_image")
require(path .. ".imgur.models.image")
require(path .. ".imgur.models.message")
require(path .. ".imgur.models.notification")
require(path .. ".imgur.models.tag")
require(path .. ".imgur.models.tag_vote")

require(path .. ".imgur.helpers.format")

imgurlua.authwrapper = require(path .. ".imgur.authwrapper")
imgurlua.imgurclient = require(path .. ".imgur.imgurclient")

return imgurlua