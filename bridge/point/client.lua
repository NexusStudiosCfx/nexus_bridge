--[[
    Bridge.point (client): places in the world that only cost something while the player is
    near them.

      local id = Bridge.point.add({
          coords = vector3(25.7, -1347.3, 29.5),
          distance = 30.0,                     how near "near" is; 25 when left out
          onEnter = function(point) end,       the player came within the distance
          onExit = function(point) end,        and left again (also when the point is removed)
          nearby = function(point, distance) end,   every frame while inside: draw a marker here
      })
      Bridge.point.remove(id)
      Bridge.point.inside(id)                  true while the player is within the distance

    `point` is the table that was handed in, with `id`: a place to keep what belongs to it
    (the prop that onEnter made, for onExit to delete).

    All points of a resource share one loop. It looks at the distances once a second when
    everything is far, more often as something comes closer, and every frame only while the
    player is inside a point that has `nearby`. With no points there is no loop at all.
]]

local h = ...

return {
    build = function()
        local api = {}
        -- The points outlive the module being built again (the bridge restarted): they are
        -- the resource's, and so is the loop that watches them.
        local store = h.store
        store.points = store.points or {}
        store.count = store.count or 0
        local points = store.points

        local function leave(point)
            if not point.isInside then return end
            point.isInside = false
            if point.onExit then
                local ok, problem = pcall(point.onExit, point)
                if not ok then h.once('exit', ('a point of %s raised in onExit: %s'):format(h.resource, tostring(problem))) end
            end
        end

        local function loop()
            while next(points) ~= nil do
                local position = GetEntityCoords(PlayerPedId())
                local nearest, everyFrame = math.huge, false

                for _, point in pairs(points) do
                    local distance = #(position - point.coords)
                    local gap = distance - point.distance
                    if gap < nearest then nearest = gap end

                    if distance <= point.distance then
                        if not point.isInside then
                            point.isInside = true
                            if point.onEnter then
                                local ok, problem = pcall(point.onEnter, point)
                                if not ok then h.once('enter', ('a point of %s raised in onEnter: %s'):format(h.resource, tostring(problem))) end
                            end
                        end
                        if point.nearby then
                            everyFrame = true
                            local ok, problem = pcall(point.nearby, point, distance)
                            if not ok then h.once('nearby', ('a point of %s raised in nearby: %s'):format(h.resource, tostring(problem))) end
                        end
                    else
                        leave(point)
                    end
                end

                if everyFrame then
                    Wait(0)
                elseif nearest < 15.0 then
                    Wait(200)
                elseif nearest < 60.0 then
                    Wait(500)
                else
                    Wait(1000)
                end
            end
            store.running = false
        end

        function api.add(point)
            if type(point) ~= 'table' then return nil end
            local coords = point.coords
            local kind = type(coords)
            if kind ~= 'vector3' and kind ~= 'vector4' and kind ~= 'table' then return nil end
            if not tonumber(coords.x) or not tonumber(coords.y) or not tonumber(coords.z) then return nil end

            store.count = store.count + 1
            local id = store.count
            point.id = id
            point.coords = vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
            point.distance = (tonumber(point.distance) or 25.0) + 0.0
            point.isInside = false
            points[id] = point

            if not store.running then
                store.running = true
                CreateThread(loop)
            end
            return id
        end

        function api.remove(id)
            local point = points[id]
            if not point then return false end
            points[id] = nil
            leave(point)
            return true
        end

        function api.inside(id)
            local point = points[id]
            return point ~= nil and point.isInside == true
        end

        function api.count()
            local n = 0
            for _ in pairs(points) do n = n + 1 end
            return n
        end

        -- A resource that stops leaves its points the way it would have by walking away.
        h.cleanup(function()
            if not h.stopping then return end
            for id in pairs(points) do api.remove(id) end
        end)

        return api
    end,
}
