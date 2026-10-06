-- ars_ambulancejob (client): the player state `dead` is true while down.

return {
    isDown = function()
        return LocalPlayer.state.dead == true
    end,
}
