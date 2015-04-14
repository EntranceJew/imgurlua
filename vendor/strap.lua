local function interp(s, tab)
	return (s:gsub('%%%((%a%w*)%)([-0-9%.]*[cdeEfgGiouxXsq])',
			function(k, fmt) return tab[k] and ("%"..fmt):format(tab[k]) or
				'%('..k..')'..fmt end))
end
getmetatable("").__mod = interp
-- refer to: https://docs.python.org/2/library/stdtypes.html#string-formatting if confused

function print_r ( t )  
	local print_r_cache={}
	local function sub_print_r(t,indent)
			if (print_r_cache[tostring(t)]) then
					print(indent.."*"..tostring(t))
			else
					print_r_cache[tostring(t)]=true
					if (type(t)=="table") then
							for pos,val in pairs(t) do
									if (type(val)=="table") then
											print(indent.."["..pos.."] => "..tostring(t).." {")
											sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
											print(indent..string.rep(" ",string.len(pos)+6).."}")
									elseif (type(val)=="string") then
											print(indent.."["..pos..'] => "'..val..'"')
									else
											print(indent.."["..pos.."] => "..tostring(val))
									end
							end
					else
							print(indent..tostring(t))
					end
			end
	end
	if (type(t)=="table") then
			print(tostring(t).." {")
			sub_print_r(t,"  ")
			print("}")
	else
			sub_print_r(t,"  ")
	end
	print()
end

-- source: http://hg.prosody.im/trunk/file/0ed617f58404/net/http.lua#l31
local function _formencodepart(s)
	return s and (s:gsub("%W", function (c)
		if c ~= " " then
			return string.format("%%%02x", c:byte());
		else
			return "+";
		end
	end));
end

function formencode(form)
	local result = {};
	if form[1] then -- Array of ordered { name, value }
		for _, field in ipairs(form) do
			table.insert(result, _formencodepart(field.name).."=".._formencodepart(field.value));
		end
	else -- Unordered map of name -> value
		for name, value in pairs(form) do
			table.insert(result, _formencodepart(name).."=".._formencodepart(value));
		end
	end
	return table.concat(result, "&");
end