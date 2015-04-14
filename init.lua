local path = ...
local imgurlua = {}

-- internal helpers
require(path .. ".vendor.strap")

-- a class system to keep ourselves sane
class = require(path .. ".vendor.middleclass")

imgurlua.Account =          require(path .. ".models.account")
imgurlua.AccountSettings =  require(path .. ".models.account_settings")
imgurlua.Album =            require(path .. ".models.album")
imgurlua.Comment =          require(path .. ".models.comment")
imgurlua.Conversation =     require(path .. ".models.conversation")
imgurlua.CustomGallery =    require(path .. ".models.custom_gallery")
imgurlua.GalleryAlbum =     require(path .. ".models.gallery_album")
imgurlua.GalleryImage =     require(path .. ".models.gallery_image")
imgurlua.Image =            require(path .. ".models.image")
imgurlua.Message =          require(path .. ".models.message")
imgurlua.Notification =     require(path .. ".models.notification")
imgurlua.Tag =              require(path .. ".models.tag")
imgurlua.TagVote =          require(path .. ".models.tag_vote")

imgurlua.Format =           require(path .. ".helpers.format")

imgurlua.AuthWrapper = require(path .. ".authwrapper")
imgurlua.ImgurClient = require(path .. ".imgurclient")

return imgurlua