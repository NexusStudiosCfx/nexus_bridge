--[[
    cd_easytime (Codesign, free) adapter (server). Written against cd_easytime 2.0.5 and the
    vendor's documentation; docs/adapters.md lists the lines.

    GetAllData answers one table with `weather`, `hours` and `mins`. SetTime wants numbers
    (0 to 23, 0 to 59) and SetWeather a type from the resource's own list; both answer true
    or false.
]]

local easytime = exports['cd_easytime']

return {
    caps = { read = true, time = true, set = true },

    get = function()
        local data = easytime:GetAllData()
        return type(data) == 'table' and data.weather or nil
    end,

    time = function()
        local data = easytime:GetAllData()
        if type(data) ~= 'table' then return nil end
        return data.hours, data.mins
    end,

    set = function(kind) return easytime:SetWeather(kind) == true end,
    setTime = function(hour, minute) return easytime:SetTime(hour, minute) == true end,
}
