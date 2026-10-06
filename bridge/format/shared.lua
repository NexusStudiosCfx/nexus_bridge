--[[
    Bridge.format: numbers and money as text, the same on the server, the client and in every
    resource. The currency sign and the separators are a server's choice (Config.settings.format
    in the bridge), so they are set once and not in every script.

      Bridge.format.number(1234567.891)        '1,234,568'
      Bridge.format.number(1234.5, 2)          '1,234.50'
      Bridge.format.money(1500)                '$1,500'
      Bridge.format.money(-20)                 '-$20'
      Bridge.format.money(9.5, { decimals = 2, symbol = 'EUR ', after = false })
      Bridge.format.compact(1300000)           '1.3M'
]]

local h = ...

local function group(digits, separator)
    local out = {}
    local first = #digits % 3
    if first > 0 then out[1] = digits:sub(1, first) end
    for i = first + 1, #digits, 3 do
        out[#out + 1] = digits:sub(i, i + 2)
    end
    return table.concat(out, separator)
end

local function style()
    local settings = h.settings()
    return {
        symbol = type(settings.symbol) == 'string' and settings.symbol or '$',
        after = settings.after == true,
        thousands = type(settings.thousands) == 'string' and settings.thousands or ',',
        decimal = type(settings.decimal) == 'string' and settings.decimal or '.',
    }
end

--- The absolute value of `amount`, rounded to `decimals` places and grouped by thousands.
local function digits(amount, decimals, look)
    local text = ('%.' .. decimals .. 'f'):format(math.abs(amount))
    local whole, fraction = text:match('^(%d+)%.?(%d*)$')
    local out = group(whole, look.thousands)
    if decimals > 0 then out = out .. look.decimal .. fraction end
    return out
end

return {
    build = function()
        local format = {}

        --- `value` with thousands separators, rounded to `decimals` places (none by default).
        function format.number(value, decimals)
            value = tonumber(value) or 0
            decimals = math.max(0, math.floor(tonumber(decimals) or 0))
            local text = digits(value, decimals, style())
            -- A value that rounds to zero carries no sign.
            if value < 0 and text:find('[1-9]') then text = '-' .. text end
            return text
        end

        --- `amount` as money. `options` may set decimals, symbol and after (sign behind the
        --- number); what it leaves out comes from the bridge's settings.
        function format.money(amount, options)
            amount = tonumber(amount) or 0
            options = type(options) == 'table' and options or {}
            local look = style()
            local decimals = math.max(0, math.floor(tonumber(options.decimals) or 0))
            local symbol = type(options.symbol) == 'string' and options.symbol or look.symbol
            local after = look.after
            if options.after ~= nil then after = options.after == true end

            local text = digits(amount, decimals, look)
            local negative = amount < 0 and text:find('[1-9]') ~= nil
            text = after and (text .. symbol) or (symbol .. text)
            return negative and ('-' .. text) or text
        end

        --- A short form for tight spaces: 950, 1.2K, 3.4M, 1.1B.
        function format.compact(value)
            value = tonumber(value) or 0
            local size = math.abs(value)
            local look = style()
            local units = { { 1e9, 'B' }, { 1e6, 'M' }, { 1e3, 'K' } }
            for _, unit in ipairs(units) do
                if size >= unit[1] then
                    local text = ('%.1f'):format(size / unit[1]):gsub('%.0$', '')
                    text = text:gsub('%.', function() return look.decimal end)
                    return (value < 0 and '-' or '') .. text .. unit[2]
                end
            end
            return format.number(value)
        end

        return format
    end,
}
