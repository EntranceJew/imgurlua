local path = string.sub(..., 1, string.len(...) - string.len(".conversation"))
local Message = require(path .. ".message")

local Conversation = class("Conversation")

function Conversation:init(conversation_id, last_message_preview, datetime, with_account_id, with_account,
		message_count, messages, done, page)
	self.id = conversation_id
	self.last_message_preview = last_message_preview
	self.datetime = datetime
	self.with_account_id = with_account_id
	self.with_account = with_account
	self.message_count = message_count
	messages = messages or nil
	self.done = done or nil
	self.page = page or nil
	
	if messages then
		self.messages = {}
		for _,message in ipairs(messages) do
			table.insert(self.messages, 
				Message(
					message.id,
					message.from,
					message.account_id,
					message.sender_id,
					message.body,
					message.conversation_id,
					message.datetime
				)
			)
		end
	else
		self.messages = nil
	end
end

return Conversation