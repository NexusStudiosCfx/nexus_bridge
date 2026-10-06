--[[
    The key prompt: what serves Bridge.target on a server without a target resource.

    The prompt itself runs once, inside nexus_bridge (client/prompt.lua), for every resource
    together: one loop that sleeps while nobody is near anything, one key in the game's key
    bindings, and never two prompts on screen at once. This adapter only hands the targets
    over. The callbacks cross to the script that owns them when they are needed.
]]

local bridge = exports.nexus_bridge

local target = {
    caps = { boxes = true, entities = true, models = true, globals = true },
}

local function hand(entry)
    local options = {}
    for index, option in ipairs(entry.options) do
        options[index] = { label = option.label, distance = option.distance, can = option.can, select = option.select }
    end
    return bridge:PromptAdd({
        kind = entry.kind,
        coords = entry.coords,
        radius = entry.radius,
        size = entry.size,
        heading = entry.heading,
        entity = entry.entity,
        models = entry.models,
        type = entry.type,
        options = options,
    })
end

target.addSphere = hand
target.addBox = hand
target.addEntity = hand
target.addModel = hand
target.addGlobal = hand

function target.remove(_, handle)
    bridge:PromptRemove(handle)
end

function target.disable(state)
    bridge:PromptDisable(state)
end

return target
