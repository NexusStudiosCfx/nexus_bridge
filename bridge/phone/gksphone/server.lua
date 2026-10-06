--[[
    gksphone adapter (server), for GKSPHONE V2. Written against the vendor's documentation
    (the resource is escrowed); see docs/adapters.md. The older generation of the phone has
    other calls and is not covered.

    What to know about gksphone:
      - sendNotification starts with a small letter, the mail exports with a capital one;
      - icons are paths inside the phone's own files. The two used here are the ones in the
        vendor's examples;
      - an e-mail for a character that is not online has its own export, by citizen id.
        The phone number of such a character is not something the documentation names a
        field for, so numbers are read for players who are online.
]]

local phone = exports['gksphone']

return {
    caps = { mail = true, offline = true },

    number = function(who)
        if not who.src then return nil end
        return phone:GetPhoneBySource(who.src)
    end,

    notify = function(who, note)
        phone:sendNotification(who.src, {
            title = note.title,
            message = note.message,
            icon = '/html/img/icons/messages.png',
            duration = 5000,
            type = 'success',
            buttonactive = false,
        })
        return true
    end,

    mail = function(who, mail)
        local data = {
            sender = mail.sender,
            image = '/html/img/icons/mail.png',
            subject = mail.subject,
            message = mail.message,
        }
        if who.src then
            phone:SendNewMail(who.src, data)
        elseif who.id then
            phone:SendNewMailOffline(who.id, data)
        else
            return false
        end
        return true
    end,
}
