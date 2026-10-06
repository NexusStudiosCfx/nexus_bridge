-- pma-voice (client): it has no export for "is talking" and asks the game itself, which
-- answers 1 or true depending on the build.

return {
    caps = { talking = true },

    isTalking = function()
        local talking = MumbleIsPlayerTalking(PlayerId())
        return talking == true or talking == 1
    end,
}
