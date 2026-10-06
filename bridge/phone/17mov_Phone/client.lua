-- 17mov_Phone (client), from the vendor's documentation: IsPhoneOpen().

return {
    caps = { open = true },

    isOpen = function()
        return exports['17mov_Phone']:IsPhoneOpen() == true
    end,
}
