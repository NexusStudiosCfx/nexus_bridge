-- esx_ambulancejob (client): the player state `isDead`, set by its server.

return {
    isDown = function()
        return LocalPlayer.state.isDead == true
    end,
}
