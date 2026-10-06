-- gksphone (client), from the vendor's documentation: isPhoneOpen(), with a small i.

return {
    caps = { open = true },

    isOpen = function()
        return exports['gksphone']:isPhoneOpen() == true
    end,
}
