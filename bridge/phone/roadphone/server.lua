--[[
    RoadPhone adapter (server), for RoadPhone and RoadPhone Pro, which share the resource
    name. Written against the vendor's documentation (the resources are escrowed); see
    docs/adapters.md. Only calls that both of them document are used.

    What to know about RoadPhone:
      - numbers and e-mails go by the character's identifier, not by the player id, and
        both work for a character that is not online;
      - a notification is a client event sent to the player. `apptitle` is the line above
        the title, where the phone shows which app it is from.
]]

local phone = exports['roadphone']

return {
    caps = { mail = true, offline = true },

    number = function(who)
        if not who.id then return nil end
        return phone:getNumberFromIdentifier(who.id)
    end,

    notify = function(who, note)
        TriggerClientEvent('roadphone:sendNotification', who.src, {
            apptitle = note.app or note.title,
            title = note.title,
            message = note.message,
        })
        return true
    end,

    mail = function(who, mail)
        if not who.id then return false end
        phone:sendMailOffline(who.id, {
            senderMail = mail.sender,
            subject = mail.subject,
            message = mail.message,
        })
        return true
    end,
}
