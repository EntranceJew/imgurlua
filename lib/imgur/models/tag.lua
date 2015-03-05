Tag = class("Tag")

function Tag:init(name, followers, total_items, following, items)
	self.name = name
	self.followers = followers
	self.total_items = total_items
	self.following = following
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