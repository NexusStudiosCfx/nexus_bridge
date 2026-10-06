-- Nexus EMS (client): IsDown() is true from the moment the player is on the ground.

return {
    isDown = function()
        return exports.nexus_ems:IsDown() == true
    end,
}
