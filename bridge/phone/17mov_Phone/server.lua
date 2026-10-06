--[[
    17mov_Phone adapter (server). Written against the vendor's documentation (the resource
    is escrowed); see docs/adapters.md.

    What to know about 17mov_Phone:
      - a notification needs the identifier of an app, in capitals. 'SYSTEM' is the one for
        what belongs to no app;
      - Email_SendEmailBySrc takes the sender as a name, and its last argument says that
        the sender is not a mail account that exists, which is the case for a script;
      - a number is known for somebody who is online, by player id or by identifier.
]]

local phone = exports['17mov_Phone']

return {
    caps = { mail = true, offline = false },

    number = function(who)
        if who.src then return phone:GetNumberFromPlayer(who.src) end
        return phone:GetNumberFromIdentifier(who.id)
    end,

    notify = function(who, note)
        phone:SendNotificationToSrc(who.src, {
            app = note.app or 'SYSTEM',
            title = note.title,
            message = note.message,
        })
        return true
    end,

    mail = function(who, mail)
        if not who.src then return false end
        phone:Email_SendEmailBySrc(who.src, mail.sender, mail.subject, mail.message, nil, true)
        return true
    end,
}
