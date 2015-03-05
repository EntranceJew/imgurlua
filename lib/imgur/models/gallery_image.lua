GalleryImage = class("GalleryImage")

function GalleryImage:init(dictionary)
	print("hello darkness my old friend", dictionary)
	for k,v in pairs(dictionary) do
		self[k] = v
	end
end