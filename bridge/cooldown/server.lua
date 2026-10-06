--[[
    Bridge.cooldown: cooldowns that survive a restart, for the whole server or per character.

      Bridge.cooldown.start(key, seconds, id)      starts (or restarts) it
      Bridge.cooldown.remaining(key, id)           whole seconds left, 0 when it is over
      Bridge.cooldown.active(key, id)              true while it runs
      Bridge.cooldown.try(key, seconds, id)        true and starts it, or false and the seconds left
      Bridge.cooldown.clear(key, id)

    Leave `id` out for a cooldown everybody shares ("the vault was robbed"). Pass a character
    id (Bridge.framework.getIdentifier(src)) for one each character has on their own.

    They are kept in the calling resource's key-value store, as the time they end. Nothing
    ticks: a cooldown costs nothing until somebody asks about it, and it is still there after
    a restart of the resource or of the server. No database is involved. Because the store
    belongs to the resource, two resources can use the same key without meeting.
]]

local PREFIX = 'nexus_bridge:cooldown:'

local function kvpKey(key, id)
    return ('%s%s|%s'):format(PREFIX, tostring(key), id ~= nil and tostring(id) or '*')
end

return {
    build = function()
        local cooldown = {}

        function cooldown.remaining(key, id)
            local slot = kvpKey(key, id)
            local ends = GetResourceKvpInt(slot)
            if not ends or ends == 0 then return 0 end
            local left = ends - os.time()
            if left <= 0 then
                DeleteResourceKvp(slot)
                return 0
            end
            return left
        end

        function cooldown.active(key, id)
            return cooldown.remaining(key, id) > 0
        end

        function cooldown.start(key, seconds, id)
            seconds = math.floor(tonumber(seconds) or 0)
            if seconds <= 0 then
                DeleteResourceKvp(kvpKey(key, id))
                return 0
            end
            SetResourceKvpInt(kvpKey(key, id), os.time() + seconds)
            return seconds
        end

        --- Check and start in one step, so two requests in the same tick cannot both pass.
        function cooldown.try(key, seconds, id)
            local left = cooldown.remaining(key, id)
            if left > 0 then return false, left end
            cooldown.start(key, seconds, id)
            return true, 0
        end

        function cooldown.clear(key, id)
            DeleteResourceKvp(kvpKey(key, id))
        end

        --- Removes the cooldowns that are over. Runs once when the module is first used, so the
        --- store does not keep a line for every character that ever triggered one.
        function cooldown.sweep()
            local now, expired = os.time(), {}
            local handle = StartFindKvp(PREFIX)
            if handle == -1 then return 0 end
            while true do
                local slot = FindKvp(handle)
                if not slot then break end
                if GetResourceKvpInt(slot) <= now then expired[#expired + 1] = slot end
            end
            EndFindKvp(handle)
            for _, slot in ipairs(expired) do DeleteResourceKvp(slot) end
            return #expired
        end

        cooldown.sweep()
        return cooldown
    end,

    selftest = function(cooldown, t)
        local key = 'nexus_bridge_selftest'
        cooldown.clear(key)
        t.check('a new cooldown is not active', cooldown.active(key) == false)
        t.check('try starts it', cooldown.try(key, 60) == true)
        local again, left = cooldown.try(key, 60)
        t.check('a second try is refused with the time left', again == false and left > 0 and left <= 60, left)
        t.check('a character has its own', cooldown.active(key, 'nobody') == false)
        cooldown.clear(key)
        t.check('clear ends it', cooldown.remaining(key) == 0)
    end,
}
