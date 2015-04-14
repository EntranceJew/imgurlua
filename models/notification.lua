local Notification = class("Notification")

function Notification:init(notification_id, account_id, viewed, content)
	self.id = notification_id
	self.account_id = account_id
	self.viewed = viewed
	self.content = content
end

return Notification