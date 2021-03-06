--[[--
  color 颜色处理
  @module color
]]

local color = {}

---整形转cc.c3b类型
-- @function color.intToc3b
-- @param int intValue eg. 0x55cc12
-- @return cc.c3b
color.intToc3b = function (intValue)
    local hexStr = string.format("%06X", intValue)
    return color.hexToc3b(hexStr)
end

---整形转十六进制字符串类型
-- @function color.intToHex
-- @param int intValue
-- @return string eg. "aabbcc"
color.intToHex = function (intValue)
    return string.format("%06X", intValue)
end

color.intToc4f = function (intValue)
    return cc.c4fFromc3b(color.intToc3b(intValue))
end

color.hexToc3b = function(hex)
  hex = hex:gsub("#", "")
  local r = tonumber(string.sub(hex, 1, 2), 16)
  local g = tonumber(string.sub(hex, 3, 4), 16)
  local b = tonumber(string.sub(hex, 5, 6), 16)

  return cc.c3b(r, g, b)
end

color.decToHex = function(dec)
    local b, k, out, i, d = 16, "0123456789ABCDEF", "", 0
    while dec > 0 do
        i = i + 1
        dec, d = math.floor(dec / b), math.fmod(dec, b) + 1
        out = string.sub(k, d, d) .. out
    end

    if(string.len(out) == 0)then
            out = '00'
    elseif(string.len(out) == 1)then
            out = '0' .. out
    end
    return out
end

color.c3bToHex = function(c3b)
  return color.decToHex(c.r) .. color.decToHex(c.g) .. color.decToHex(c.b)
end

return color
