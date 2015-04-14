local TagVote = class("TagVote")

function TagVote:init(ups, downs, name, author)
	self.ups = ups
	self.downs = downs
	self.name = name
	self.author = author
end

return TagVote