local GalleryImage = class("GalleryImage")

function GalleryImage:init(dictionary)
	for k,v in pairs(dictionary) do
		self[k] = v
	end
end

return GalleryImage