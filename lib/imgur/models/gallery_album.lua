GalleryAlbum = class("GalleryAlbum")

function GalleryAlbum:init(dictionary)
	for k,v in pairs(dictionary) do
		self[k] = v
	end
end