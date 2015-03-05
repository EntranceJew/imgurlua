CustomGallery = class("CustomGallery")

function CustomGallery:init(custom_gallery_id, name, datetime, account_url, link, tags, item_count, items)
	item_count = item_count or nil
	items = items or nil
	self.id = custom_gallery_id
	self.name = name
	self.datetime = datetime
	self.account_url = account_url
	self.link = link
	self.tags = tags
	self.item_count = item_count
	if item.is_album then
		self.items = GalleryAlbum(item)
	elseif item ~= nil then
		self.items = {}
		for _,item in pairs(items) do
			table.insert(self.items, GalleryImage(item))
		end
	else
		self.items = nil
	end
end