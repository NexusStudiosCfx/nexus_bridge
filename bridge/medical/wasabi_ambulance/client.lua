-- wasabi_ambulance (client): the player state `dead` is 'dead' or 'laststand' while down.

return {
    isDown = function()
        local state = LocalPlayer.state.dead
        return state == 'dead' or state == 'laststand'
    end,
}
