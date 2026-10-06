--[[
    yseries (YPhone, YFlip) adapter (server). Written against the vendor's documentation
    (the resource is escrowed); see docs/adapters.md.

    What to know about yseries:
      - notifications and e-mails say who they are for with a kind and a value: 'source'
        and a player id, or 'phoneNumber' and a number;
      - an e-mail has the sender twice: an address (`sender`) and a name to show
        (`senderDisplayName`);
      - a notification without `app` takes its own icon, so the app is only handed over
        when the caller names one;
      - a character that is not online is reached through its phone number.
]]

local phone = exports.yseries

return {
    caps = { mail = true, offline = true },

    number = function(who)
        if who.src then return phone:GetPhoneNumberBySourceId(who.src) end
        return phone:GetPhoneNumberByIdentifier(who.id)
    end,

    notify = function(who, note)
        phone:SendNotification({
            app = note.app,
            title = note.title,
            text = note.message,
            timeout = 5000,
        }, 'source', who.src)
        return true
    end,

    mail = function(who, mail)
        local email = {
            title = mail.subject,
            sender = mail.address,
            senderDisplayName = mail.sender,
            content = mail.message,
        }
        local id
        if who.src then
            id = phone:SendMail(email, 'source', who.src)
        else
            local number = phone:GetPhoneNumberByIdentifier(who.id)
            if not number then return false end
            id = phone:SendMail(email, 'phoneNumber', number)
        end
        return id ~= nil and id ~= false
    end,
}
