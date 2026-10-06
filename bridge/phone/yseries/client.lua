-- yseries (client), from the vendor's documentation: IsOpen() says whether the phone is up.

return {
    caps = { open = true },

    isOpen = function()
        return exports.yseries:IsOpen() == true
    end,
}
