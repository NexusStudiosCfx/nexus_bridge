-- RoadPhone and RoadPhone Pro (client), from the vendor's documentation: isPhoneOpen().

return {
    caps = { open = true },

    isOpen = function()
        return exports['roadphone']:isPhoneOpen() == true
    end,
}
