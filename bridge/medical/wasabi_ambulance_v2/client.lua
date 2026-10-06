-- wasabi_ambulance_v2 (client), from the vendor's documentation: isPlayerDead() without a
-- player id is about the local player, and is true in last stand as well as when dead.

return {
    isDown = function()
        return exports['wasabi_ambulance_v2']:isPlayerDead() == true
    end,
}
