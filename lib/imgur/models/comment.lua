Comment = class("Comment")

function Comment:init(dictionary)
	for k,v in pairs(dictionary) do
		self[k] = v
	end
end