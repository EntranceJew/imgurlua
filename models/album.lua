Album = class("Album")

function Album:init(dictionary)
	for k,v in pairs(dictionary) do
		self[k] = v
	end
end