--[[
    Bridge.inventory (client): what the inventory knows about items, and what the local player
    carries. For showing things: the server is the one that decides.

      label(name), exists(name)
      image(name, metadata)        where the picture of an item is, for a page: nui://... or https://...
      items()                      the stacks the local player carries: { slot, name, label, count, metadata, image }
      count(name)                  how many of `name`
      has(name, count)             true with at least `count` (1 when left out)
]]

local h = ...

local fallbacks = {
    label = function(name) return name end,
    exists = function() return false end,
    image = function() return nil end,
    items = function() return {} end,
}

return {
    adapters = true,
    caps = { 'metadata', 'slots', 'images' },

    build = function(adapter)
        local a = h.complete(adapter, fallbacks)
        local inventory = { label = a.label, image = a.image }

        function inventory.exists(name)
            return type(name) == 'string' and a.exists(name) == true
        end

        function inventory.items()
            return a.items() or {}
        end

        local countOf = adapter and adapter.count
        function inventory.count(name)
            if type(name) ~= 'string' then return 0 end
            if countOf then return math.floor(tonumber(countOf(name)) or 0) end
            local total = 0
            for _, item in ipairs(inventory.items()) do
                if item.name == name then total = total + item.count end
            end
            return total
        end

        function inventory.has(name, count)
            count = math.floor(tonumber(count) or 1)
            return inventory.count(name) >= (count > 0 and count or 1)
        end

        return inventory
    end,

    selftest = function(inventory, t)
        if not inventory.available then
            t.skip('everything', 'no inventory is running')
            return
        end
        t.check('an item nobody defined does not exist', inventory.exists('nexus_bridge_no_such_item') == false)
        t.check('the carried items are a list', type(inventory.items()) == 'table', #inventory.items() .. ' stacks')
        for _, name in ipairs({ 'water', 'bread', 'sandwich', 'burger', 'bandage', 'phone', 'lockpick' }) do
            if inventory.exists(name) then
                t.check('an item has a label', type(inventory.label(name)) == 'string', ('%s: %s'):format(name, inventory.label(name)))
                t.check('and a picture, where the inventory has pictures', not inventory.supports('images') or type(inventory.image(name)) == 'string', inventory.image(name))
                return
            end
        end
        t.skip('label and picture of an item', 'none of the usual item names exists on this server')
    end,
}
