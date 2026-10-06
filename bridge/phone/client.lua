--[[
    Bridge.phone (client)

      isOpen()        true while the player has the phone in front of them.
                      supports('open') tells whether the phone resource can say

    A script that draws something of its own usually wants to know, to stay out of the way.
    Notifications and e-mails are sent from the server.
]]

local h = ...

return {
    adapters = true,
    caps = { 'open' },

    build = function(adapter)
        local phone = {}

        if not adapter then
            phone.isOpen = h.unavailable('isOpen', function() return false end)
            return phone
        end

        function phone.isOpen()
            if not adapter.isOpen then return false end
            local ok, open = pcall(adapter.isOpen)
            return ok and open == true
        end

        -- What Bridge.phone.notify on the server arrives as, for a phone that only takes
        -- notifications on the client. Only nexus_bridge listens to it.
        if h.hub and adapter.notify then
            h.onNet('nexus_bridge:phone:notify', function(note)
                if type(note) ~= 'table' or type(note.title) ~= 'string' or type(note.message) ~= 'string' then return end
                pcall(adapter.notify, note)
            end)
        end

        return phone
    end,
}
