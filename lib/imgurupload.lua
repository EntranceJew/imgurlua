-- WHOO BOY THANK THE LORDY FOR SSL FROM http://love2d.org/forums/viewtopic.php?f=5&t=76728
require("lib.vendor.ssl")
require("lib.vendor.https")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local JSON = require("lib.vendor.JSON")

local CLIENT_ID = "4ce94df6f78813c" --dedicated to uploading images of crashes/misbehaviors in this game

function upload_imagedata(oname, imagedata)
	local outname = oname or "temp.png"
	imagedata:encode(outname)
	local idata, isize = love.filesystem.read(outname)
	local t = {}
	local reqbody = idata
	https.request({
		url = "https://api.imgur.com/3/image",
		sink = ltn12.sink.table(t),
		source = ltn12.source.string(reqbody),
		method = "POST",
		headers = {
			["Authorization"] = "Client-ID "..CLIENT_ID,
			["content-length"] = string.len(reqbody),
			["content-type"] = "multipart/form-data",
		},
	})
	return JSON:decode(table.concat(t))
end

function get_credits()
	--local outname = oname or "temp.png"
	--imagedata:encode(outname)
	--local idata, isize = love.filesystem.read(outname)
	local t = {}
	local reqbody = ''
	local req = {
		url = "https://api.imgur.com/3/credits",
		sink = ltn12.sink.table(t),
		source = ltn12.source.string(reqbody),
		method = "GET",
		headers = {
			["Authorization"] = "Client-ID "..CLIENT_ID,
			["content-length"] = string.len(reqbody),
			["content-type"] = "multipart/form-data",
		},
	}
	for k,v in pairs(req.headers) do print(k, v) end
	for k,v in pairs(req) do
		print(k, v)
	end
	https.request(req)
	return JSON:decode(table.concat(t))
end
