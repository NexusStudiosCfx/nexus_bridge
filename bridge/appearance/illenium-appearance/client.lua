--[[
    illenium-appearance adapter. Written against the source of illenium-appearance (main,
    and release 5.7.0); docs/adapters.md lists the lines.

    What to know about illenium-appearance:
      - startPlayerCustomization(cb, conf) hands the result to the callback and saves
        nothing: an appearance when the player kept it, nothing when they cancelled. Its
        own shops then send illenium-appearance:server:saveAppearance, and so does this file;
      - `conf` says which parts of the editor are there. The resource's default table is not
        exported, so one is built here;
      - reloadSkin takes one flag that skips its checks (a cooldown, being dead, being in a
        vehicle). A reload a script asked for should not be refused for a cooldown.
]]

local appearance = exports['illenium-appearance']

return {
    caps = { result = true, reload = true, snapshot = true },

    open = function(full, done)
        appearance:startPlayerCustomization(function(look)
            if look then TriggerServerEvent('illenium-appearance:server:saveAppearance', look) end
            done(look ~= nil)
        end, {
            ped = false,
            headBlend = full,
            faceFeatures = full,
            headOverlays = full,
            components = true,
            props = true,
            tattoos = full,
            enableExit = true,
        })
    end,

    reload = function()
        TriggerEvent('illenium-appearance:client:reloadSkin', true)
    end,

    get = function()
        return appearance:getPedAppearance(PlayerPedId())
    end,

    set = function(look)
        appearance:setPlayerAppearance(look)
    end,
}
