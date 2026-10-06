-- qbx_medical (client): the player state `isDead` is true for dead and for last stand.

return {
    isDown = function()
        return LocalPlayer.state.isDead == true
    end,
}
