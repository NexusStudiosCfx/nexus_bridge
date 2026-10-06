--[[
    Bridge.phone (server): the phone a player carries, whichever phone resource it is.

      getNumber(who)                 the phone number as text, or nil without a phone
      notify(src, note)              a notification on the phone: true when it was handed over
          note = { title = 'Lottery', message = 'Your ticket won $500', app = nil }
      mail(who, mail)                an e-mail in the inbox: true when it was sent
          mail = { sender = 'Lottery Office', subject = 'You won', message = '...' }

    `who` is a player id, or the id of a character (a citizenid, an identifier). A character
    that is not online is reached only where the phone resource can: supports('offline').
    A phone without e-mail (supports('mail') is false) answers false to mail.

    `app` names the app a notification belongs to, in the phone resource's own words; left
    out, each adapter uses a neutral one. Text is plain text.

    With no phone resource running the module is not available: no number, nothing sent.
    A resource that must reach the player either way falls back to Bridge.notify.
]]

local h = ...

local function text(value, limit)
    if type(value) ~= 'string' or value == '' then return nil end
    return #value > limit and value:sub(1, limit) or value
end

--- Letters and digits of a name, for the part of an address in front of the @.
local function slug(name)
    local out = name:lower():gsub('[^%w]+', '.'):gsub('^%.+', ''):gsub('%.+$', '')
    return out ~= '' and out or 'system'
end

return {
    adapters = true,
    caps = { 'mail', 'offline' },

    build = function(adapter)
        local phone = {}

        if not adapter then
            phone.getNumber = h.unavailable('getNumber', function() return nil end)
            phone.notify = h.unavailable('notify', function() return false end)
            phone.mail = h.unavailable('mail', function() return false end)
            return phone
        end

        local caps = adapter.caps or {}
        local settings = h.settings()
        local framework = h.bridge.framework

        --- Both ways to name somebody, as far as they are known: adapters need one or the other.
        local function resolve(who)
            if math.type(who) == 'integer' and who > 0 then
                return { src = who, id = framework.getIdentifier(who) }
            end
            if type(who) == 'string' and who ~= '' then
                return { id = who, src = framework.getSource(who) }
            end
            return nil
        end

        local function guarded(what, fn, ...)
            local ok, result = pcall(fn, ...)
            if ok then return result end
            h.once(what, ('the %s adapter could not %s: %s'):format(tostring(h.adapter), what, tostring(result)))
            return nil
        end

        function phone.getNumber(who)
            who = resolve(who)
            if not who or not adapter.number then return nil end
            if not who.src and not caps.offline then return nil end
            local number = guarded('read a number', adapter.number, who)
            if type(number) == 'number' then number = tostring(math.floor(number)) end
            return type(number) == 'string' and number ~= '' and number or nil
        end

        function phone.notify(src, note)
            if math.type(src) ~= 'integer' or src <= 0 or type(note) ~= 'table' then return false end
            local clean = {
                title = text(note.title, 80),
                message = text(note.message, 500),
                app = text(note.app, 40),
            }
            if not clean.title and not clean.message then return false end
            clean.title = clean.title or clean.message
            clean.message = clean.message or clean.title

            if not DoesPlayerExist(tostring(src)) then return false end

            if adapter.notify then
                return guarded('send a notification', adapter.notify, resolve(src), clean) == true
            end
            -- The phone only takes notifications on the client.
            TriggerClientEvent('nexus_bridge:phone:notify', src, clean)
            return true
        end

        function phone.mail(who, mail)
            who = resolve(who)
            if not who or type(mail) ~= 'table' or not adapter.mail then return false end
            if not who.src and not caps.offline then return false end
            local message = text(mail.message, 4000)
            if not message then return false end
            local sender = text(mail.sender, 60) or settings.sender or 'System'
            return guarded('send an e-mail', adapter.mail, who, {
                sender = sender,
                address = ('%s@%s'):format(slug(sender), settings.domain or 'city.mail'),
                subject = text(mail.subject, 120) or sender,
                message = message,
            }) == true
        end

        return phone
    end,

    selftest = function(phone, t)
        if not phone.available then
            t.skip('everything', 'no phone resource is running')
            return
        end
        t.check('nobody has no number', phone.getNumber(0) == nil and phone.getNumber(nil) == nil, phone.name)
        t.check('a notification for nobody is refused', phone.notify(0, { title = 'x' }) == false and phone.notify(1, nil) == false)
        t.check('an e-mail without a message is refused', phone.mail(1, { subject = 'x' }) == false)
        t.note('nothing is sent by the self-test: it would land on somebody\'s phone')
    end,
}
