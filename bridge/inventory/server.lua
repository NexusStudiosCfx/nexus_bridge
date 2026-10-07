--[[
    Bridge.inventory (server): items, the same on every inventory.

    An item is { slot, name, label, count, metadata, weight, image }.
    `inv` is a player id, or the id of a stash where the inventory has them.

    Read
      items(inv)                         every stack held
      slot(inv, slot)                    the item in that slot, or nil
      count(inv, name)                   how many of `name`, over all stacks
      has(inv, name, count)              true with at least `count` (1 when left out)
      find(inv, name, metadata)          the stacks of `name` whose metadata holds these values

    Give and take
      canCarry(inv, name, count, metadata)   true if it fits
      add(inv, name, count, metadata)        true if all of it arrived, with exactly this metadata
      remove(inv, name, count)               from any stacks; all or nothing; true if it left
      removeSlot(inv, slot, name, count)     out of exactly that slot, and only if it holds
                                             `name`; true if it left. Does not wait: nothing
                                             can slip in between the check and the removal
      setMetadata(inv, slot, metadata)       replaces the metadata of a slot
      clear(inv, keep)                       empties it, except the item names in `keep`

    Items
      label(name), exists(name), image(name, metadata)
      weight(name)                           what one of the item weighs by itself, in the
                                             inventory's own unit; 0 for an unknown item
      missing(names)                         the names the inventory does not know
      check(names, hint)                     says in the console which are missing, once
      registerUsable(name, function(src, item) end)     item: { name, slot, count, metadata }

    Stashes: supports('stashes')
      openStash(src, id, { label, slots, weight })      true if it opened for the player
      stashItems(id), clearStash(id)

    `add` never checks the weight for you on every inventory: ask canCarry first. An inventory
    without metadata refuses an add that needs it; supports('metadata') says so beforehand.
]]

local h = ...
local Bridge = h.bridge

local function none() return nil end
local function no() return false end
local function empty() return {} end

local fallbacks = {
    items = empty,
    slot = none,
    canCarry = no,
    add = no,
    removeSlot = no,
    setMetadata = no,
    clear = no,
    label = function(name) return name end,
    exists = no,
    image = none,
    registerUsable = no,
    openStash = no,
    stashItems = empty,
    clearStash = no,
}

--- A positive whole count, or nil.
local function whole(count)
    count = tonumber(count)
    if not count or count ~= count or count == math.huge then return nil end
    count = math.floor(count)
    return count > 0 and count or nil
end

local function isInventory(inv)
    return type(inv) == 'number' or (type(inv) == 'string' and inv ~= '')
end

--- True when every key of `wanted` has the same value in `metadata`.
local function holds(metadata, wanted)
    if type(metadata) ~= 'table' then return next(wanted) == nil end
    for key, value in pairs(wanted) do
        if metadata[key] ~= value then return false end
    end
    return true
end

--- What a usable-item callback is handed differs by framework and inventory: the item table,
--- the item name, or the name and then the table. This makes one shape of them.
local function usedItem(a, b)
    local data = type(a) == 'table' and a or (type(b) == 'table' and b or nil)
    local name = type(a) == 'string' and a or (data and data.name) or nil
    local metadata = data and (data.metadata or data.info)
    return {
        name = name,
        slot = data and tonumber(data.slot) or nil,
        count = data and math.floor(tonumber(data.count or data.amount) or 1) or 1,
        metadata = type(metadata) == 'table' and metadata or {},
    }
end

return {
    adapters = true,
    caps = { 'metadata', 'slots', 'stashes', 'weight', 'images', 'usableItems' },

    build = function(adapter)
        local a = h.complete(adapter, fallbacks)
        local inventory = { label = a.label, image = a.image }

        function inventory.weight(name)
            if type(name) ~= 'string' or not adapter or not adapter.weight then return 0 end
            return tonumber(adapter.weight(name)) or 0
        end

        function inventory.exists(name)
            return type(name) == 'string' and a.exists(name) == true
        end

        function inventory.items(inv)
            if not isInventory(inv) then return {} end
            return a.items(inv) or {}
        end

        function inventory.slot(inv, slot)
            slot = tonumber(slot)
            if not isInventory(inv) or not slot then return nil end
            return a.slot(inv, slot)
        end

        function inventory.find(inv, name, metadata)
            local out = {}
            for _, item in ipairs(inventory.items(inv)) do
                if item.name == name and (metadata == nil or holds(item.metadata, metadata)) then
                    out[#out + 1] = item
                end
            end
            table.sort(out, function(x, y) return (x.slot or 0) < (y.slot or 0) end)
            return out
        end

        local countOf = adapter and adapter.count
        function inventory.count(inv, name)
            if not isInventory(inv) or type(name) ~= 'string' then return 0 end
            if countOf then return math.floor(tonumber(countOf(inv, name)) or 0) end
            local total = 0
            for _, item in ipairs(inventory.find(inv, name)) do total = total + item.count end
            return total
        end

        function inventory.has(inv, name, count)
            return inventory.count(inv, name) >= (whole(count) or 1)
        end

        function inventory.canCarry(inv, name, count, metadata)
            count = whole(count == nil and 1 or count)
            if not count or not isInventory(inv) or type(name) ~= 'string' then return false end
            return a.canCarry(inv, name, count, metadata) == true
        end

        function inventory.add(inv, name, count, metadata)
            count = whole(count == nil and 1 or count)
            if not count or not isInventory(inv) or type(name) ~= 'string' then return false end
            if metadata ~= nil and type(metadata) ~= 'table' then return false end
            return a.add(inv, name, count, metadata) == true
        end

        function inventory.removeSlot(inv, slot, name, count)
            slot, count = tonumber(slot), whole(count == nil and 1 or count)
            if not slot or not count or not isInventory(inv) or type(name) ~= 'string' then return false end
            return a.removeSlot(inv, slot, name, count) == true
        end

        --- From as many stacks as it takes. If the inventory changes between counting and
        --- taking, what was taken goes back and the answer is false.
        local function across(inv, name, count)
            local stacks = inventory.find(inv, name)
            local total = 0
            for _, item in ipairs(stacks) do total = total + item.count end
            if total < count then return false end

            local left, taken = count, {}
            for _, item in ipairs(stacks) do
                if left <= 0 then break end
                local part = math.min(left, item.count)
                if a.removeSlot(inv, item.slot, name, part) == true then
                    left = left - part
                    taken[#taken + 1] = { count = part, metadata = item.metadata }
                end
            end
            if left <= 0 then return true end
            for _, part in ipairs(taken) do
                a.add(inv, name, part.count, next(part.metadata or {}) and part.metadata or nil)
            end
            return false
        end

        local removeAny = adapter and adapter.remove
        function inventory.remove(inv, name, count)
            count = whole(count == nil and 1 or count)
            if not count or not isInventory(inv) or type(name) ~= 'string' then return false end
            if removeAny then return removeAny(inv, name, count) == true end
            return across(inv, name, count)
        end

        function inventory.setMetadata(inv, slot, metadata)
            slot = tonumber(slot)
            if not slot or not isInventory(inv) or type(metadata) ~= 'table' then return false end
            return a.setMetadata(inv, slot, metadata) == true
        end

        function inventory.clear(inv, keep)
            if not isInventory(inv) then return false end
            return a.clear(inv, keep) == true
        end

        function inventory.missing(names)
            local out = {}
            for _, name in ipairs(type(names) == 'table' and names or { names }) do
                if not inventory.exists(name) then out[#out + 1] = name end
            end
            return out
        end

        --- For a resource to call when it starts: one console line per item the server
        --- owner still has to add, instead of a failure the first time a player needs it.
        function inventory.check(names, hint)
            if not adapter then return {} end
            local missing = inventory.missing(names)
            for _, name in ipairs(missing) do
                h.once('missing:' .. name, ('%s needs the item "%s", which is not defined in %s. %s')
                    :format(h.resource, name, h.adapter, hint or 'Add it from the install folder of that resource.'))
            end
            return missing
        end

        -- Items made usable whose entry in the inventory keeps the use away from the callback:
        -- named together in one line a moment later, not one line each.
        local kept, noted, telling = {}, {}, false
        local function tellKept()
            telling = false
            if #kept == 0 then return end
            local names = table.concat(kept, ', ')
            kept = {}
            h.say(('%s made these items usable: %s. But %s'):format(h.resource, names, adapter.keepsUseNote))
        end

        local register = adapter and (adapter.registerUsable or Bridge.framework.registerUsable) or a.registerUsable
        function inventory.registerUsable(name, callback)
            if type(name) ~= 'string' or type(callback) ~= 'function' then return false end
            local ok = register(name, function(src, x, y)
                local item = usedItem(x, y)
                item.name = item.name or name
                TriggerEvent('nexus_bridge:itemUsed', src, item.name, item.slot, item.metadata)
                callback(src, item)
            end) == true
            if ok and adapter and adapter.keepsUse and not noted[name] and adapter.keepsUse(name) then
                noted[name] = true
                kept[#kept + 1] = name
                if not telling then
                    telling = true
                    SetTimeout(1000, tellKept)
                end
            end
            return ok
        end

        function inventory.registerStash(id, options)
            if type(id) ~= 'string' or id == '' or not adapter or not adapter.registerStash then return false end
            return adapter.registerStash(id, type(options) == 'table' and options or {}) == true
        end

        function inventory.openStash(src, id, options)
            if type(id) ~= 'string' or id == '' or not tonumber(src) then return false end
            return a.openStash(tonumber(src), id, type(options) == 'table' and options or {}) == true
        end

        function inventory.stashItems(id)
            if type(id) ~= 'string' or id == '' then return {} end
            return a.stashItems(id) or {}
        end

        function inventory.clearStash(id)
            if type(id) ~= 'string' or id == '' then return false end
            return a.clearStash(id) == true
        end

        -- Uses the inventory reports by itself (a consumable eaten, on ox_inventory).
        if h.hub and adapter and adapter.listen then
            adapter.listen(function(src, name, slot, metadata)
                TriggerEvent('nexus_bridge:itemUsed', src, name, slot, type(metadata) == 'table' and metadata or {})
            end)
        end

        return inventory
    end,

    selftest = function(inventory, t)
        if not inventory.available then
            t.skip('everything', 'no inventory is running')
            return
        end
        local nobody = 65534
        t.check('an item nobody defined does not exist', inventory.exists('nexus_bridge_no_such_item') == false)
        t.check('a player that is not there carries nothing', #inventory.items(nobody) == 0 and inventory.count(nobody, 'water') == 0)
        t.check('nothing can be given to them', inventory.add(nobody, 'nexus_bridge_no_such_item', 1) == false)
        t.check('or taken from them', inventory.remove(nobody, 'water', 1) == false and inventory.removeSlot(nobody, 1, 'water', 1) == false)
        t.check('a bad count is refused', inventory.add(nobody, 'water', 0) == false and inventory.add(nobody, 'water', -2) == false)

        -- An item this server has, to move through a stash.
        local item = nil
        for _, name in ipairs({ 'water', 'bread', 'sandwich', 'burger', 'bandage', 'phone', 'lockpick' }) do
            if inventory.exists(name) then item = name break end
        end
        if not item then
            t.skip('items in a stash', 'none of the usual item names exists on this server')
            return
        end
        t.check('an item that exists has a label', type(inventory.label(item)) == 'string', ('%s: %s'):format(item, inventory.label(item)))

        if not inventory.supports('stashes') then
            t.skip('items in a stash', inventory.name .. ' has no stashes')
            return
        end
        local id = 'nexus_bridge_selftest'
        if not inventory.registerStash(id, { label = 'nexus_bridge self-test', slots = 5, weight = 100000 }) then
            t.check('a stash is registered', false)
            return
        end
        inventory.clearStash(id)

        local metadata = inventory.supports('metadata') and { nexus_bridge = 'selftest' } or nil
        t.check('two items go into the stash', inventory.add(id, item, 2, metadata) == true)
        -- One stack of two, or two stacks of one when the server made the item unique.
        local held = inventory.find(id, item)
        local stack = held[1]
        t.check('they are read back', inventory.count(id, item) == 2 and stack ~= nil, ('%d in %d stacks'):format(inventory.count(id, item), #held))
        if stack then
            t.check('with the metadata they were given', metadata == nil or stack.metadata.nexus_bridge == 'selftest')
            t.check('the wrong item is not taken from the slot', inventory.removeSlot(id, stack.slot, 'nexus_bridge_no_such_item', 1) == false)
            t.check('more than the slot holds is not taken', inventory.removeSlot(id, stack.slot, item, stack.count + 1) == false and inventory.count(id, item) == 2)
            t.check('one is taken from exactly that slot', inventory.removeSlot(id, stack.slot, item, 1) == true and inventory.count(id, item) == 1)
        end
        t.check('more than there is cannot be removed', inventory.remove(id, item, 5) == false and inventory.count(id, item) == 1)
        t.check('the last one is removed', inventory.remove(id, item, 1) == true and inventory.count(id, item) == 0)
        inventory.clearStash(id)
        t.check('the stash is empty again', #inventory.stashItems(id) == 0)
    end,
}
