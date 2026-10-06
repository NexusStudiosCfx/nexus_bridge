--[[
    ps-dispatch has no way to raise an alert for a whole job from the server, so there is no
    `send` here: the module hands the alert to a client, and the client half of this adapter
    raises it there.
]]

return {
    caps = { blip = true, priority = true, code = true },
}
