--[[
    Optional. A shared.lua runs on both sides before the server.lua or client.lua of the same
    folder, and what it returns is handed to them as their second argument:

        local h, shared = ...

    Use it for what both halves need: a table of names, a small helper.
]]

return {}
