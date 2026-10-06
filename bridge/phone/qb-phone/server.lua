--[[
    qb-phone adapter (server). Written against qb-phone 1.5.0 and the Renewed fork, which
    keeps the resource name and the two calls used here; docs/adapters.md lists the lines.

    What to know about qb-phone:
      - it has no function for the phone number: the number is a field of the QBCore
        character (charinfo.phone), so it is read from the player the framework holds, and
        only for somebody who is online;
      - a notification is a client event with a row of arguments: title, text, an icon as a
        Font Awesome class, a colour and the milliseconds it stays;
      - sendNewMailToOffline takes the citizenid and works for a character that is online
        as well: it then also shows the "new mail" pop-up.
]]

local h = ...

return {
    caps = { mail = true, offline = true },

    number = function(who)
        local player = who.src and h.bridge.framework.getPlayer(who.src) or nil
        local data = type(player) == 'table' and player.PlayerData or nil
        local info = type(data) == 'table' and data.charinfo or nil
        return type(info) == 'table' and info.phone or nil
    end,

    notify = function(who, note)
        TriggerClientEvent('qb-phone:client:CustomNotification', who.src, note.title, note.message, 'fas fa-bell', '#2f7dd1', 5000)
        return true
    end,

    mail = function(who, mail)
        if not who.id then return false end
        exports['qb-phone']:sendNewMailToOffline(who.id, {
            sender = mail.sender,
            subject = mail.subject,
            message = mail.message,
        })
        return true
    end,
}
