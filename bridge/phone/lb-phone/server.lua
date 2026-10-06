--[[
    LB Phone adapter (server). Written against the vendor's documentation and the open files
    of lb-phone 2.8.0, whose own framework files make the same calls; see docs/adapters.md.

    What to know about lb-phone:
      - GetEquippedPhoneNumber takes a player id or a character's identifier, and answers
        nothing when no phone is equipped (servers where the phone is an item);
      - an e-mail goes to an e-mail address, not to a player: the address belongs to the
        phone number, and a player who never opened the mail app has none. Then nothing is
        sent, as in lb-phone's own code;
      - a notification needs the name of an app. 'Settings' is the neutral one lb-phone's
        own files use.
]]

local phone = exports['lb-phone']

local function numberOf(who)
    return phone:GetEquippedPhoneNumber(who.src or who.id)
end

return {
    caps = { mail = true, offline = true },

    number = numberOf,

    notify = function(who, note)
        phone:SendNotification(who.src, {
            app = note.app or 'Settings',
            title = note.title,
            content = note.message ~= note.title and note.message or nil,
        })
        return true
    end,

    mail = function(who, mail)
        local number = numberOf(who)
        local address = number and phone:GetEmailAddress(number) or nil
        if not address then return false end
        local sent = phone:SendMail({
            to = address,
            sender = mail.sender,
            subject = mail.subject,
            message = mail.message,
        })
        return sent == true
    end,
}
