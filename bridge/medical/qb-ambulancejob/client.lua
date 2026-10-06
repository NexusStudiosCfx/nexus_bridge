-- qb-ambulancejob (client): death is in the character's metadata, `isdead` and `inlaststand`.

local h = ...

return {
    isDown = function()
        local framework = h.bridge.framework
        return framework.getMetadata('isdead') == true or framework.getMetadata('inlaststand') == true
    end,
}
