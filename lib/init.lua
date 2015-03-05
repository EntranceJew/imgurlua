local path = ...
require(path .. ".vendor.strap")
lume = require(path .. ".vendor.lume")
class = require(path .. ".vendor.middleclass")
JSON = require(path .. ".vendor.JSON")
require(path .. ".vendor.ssl")
require(path .. ".vendor.https")
https = require("ssl.https")
ltn12 = require("ltn12")

API_URL = 'https://api.imgur.com/'

local imgurlua = {}

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