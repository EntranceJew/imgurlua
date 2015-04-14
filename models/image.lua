local Image = class("Image")

function Image:init(dictionary)
	for k,v in pairs(dictionary) do
		self[k] = v
	end
end

return Image