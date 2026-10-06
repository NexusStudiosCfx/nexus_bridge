--[[
    fivem-appearance adapter. Written against fivem-appearance 1.3.0; docs/adapters.md lists
    the lines.

    What to know about fivem-appearance:
      - it is an editor and nothing else: it has no server side and stores nothing. The
        result goes to the callback, and whoever opened the editor keeps it. So there is no
        saved look to reload, and a resource that opens the editor through the bridge reads
        the new look with get() when onDone says it was kept;
      - setPlayerAppearance waits until the model is loaded.
]]

local appearance = exports['fivem-appearance']

return {
    caps = { result = true, reload = false, snapshot = true },

    open = function(full, done)
        appearance:startPlayerCustomization(function(look)
            done(look ~= nil)
        end, {
            ped = false,
            headBlend = full,
            faceFeatures = full,
            headOverlays = full,
            components = true,
            props = true,
            tattoos = full,
        })
    end,

    get = function()
        return appearance:getPedAppearance(PlayerPedId())
    end,

    set = function(look)
        appearance:setPlayerAppearance(look)
    end,
}
