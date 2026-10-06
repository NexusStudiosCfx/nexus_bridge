--[[
    Bridge.locale: the texts of a resource in the server's language.

      local L = Bridge.locale.load()             reads locales/<language>.json of this resource
      L('shop.paid', { amount = '$50' })         'You paid $50'
      Bridge.locale.language()                   'en'

    The language is the bridge's (Config.settings.locale), so a server sets it once. A file
    is plain JSON, flat or nested:

        { "shop": { "paid": "You paid {amount}", "closed": "We are closed" } }

    English (locales/en.json) is read as well and fills in what the other language lacks. A
    key no file has comes back as the key itself, which is easy to spot on screen.

    For the client to read them the files have to be in the resource's manifest:
        files { 'locales/*.json' }

      Bridge.locale.load({ language = 'de', folder = 'locales', fallback = 'en' })
          for a resource that keeps them elsewhere or wants another language than the server's.
]]

local h = ...

--- Nested tables become 'a.b.c' keys in one flat table.
local function flatten(into, values, prefix)
    for key, value in pairs(values) do
        local name = prefix and (prefix .. '.' .. tostring(key)) or tostring(key)
        if type(value) == 'table' then
            flatten(into, value, name)
        elseif into[name] == nil then
            into[name] = tostring(value)
        end
    end
end

local function read(resource, folder, language)
    local path = ('%s/%s.json'):format(folder, language)
    local text = LoadResourceFile(resource, path)
    if not text then return nil end
    local ok, decoded = pcall(json.decode, text)
    if not ok or type(decoded) ~= 'table' then
        h.say(('%s/%s is not valid JSON and was skipped'):format(resource, path))
        return nil
    end
    return decoded
end

return {
    build = function()
        local locale = {}

        function locale.language()
            return h.language()
        end

        function locale.load(options)
            options = type(options) == 'table' and options or {}
            local resource = h.resource
            local folder = type(options.folder) == 'string' and options.folder or 'locales'
            local language = type(options.language) == 'string' and options.language or h.language()
            local fallback = type(options.fallback) == 'string' and options.fallback or 'en'

            local texts = {}
            local own = read(resource, folder, language)
            if own then flatten(texts, own) end
            local base = fallback ~= language and read(resource, folder, fallback) or nil
            if base then flatten(texts, base) end
            if not own and not base then
                h.once('missing:' .. folder, ('%s has no %s/%s.json it can read: its texts show as keys'):format(resource, folder, language))
            end

            return function(key, values)
                local text = texts[key]
                if text == nil then return tostring(key) end
                if type(values) ~= 'table' then return text end
                return (text:gsub('{([%w_]+)}', function(name)
                    local value = values[name]
                    if value == nil then return nil end
                    return tostring(value)
                end))
            end, texts
        end

        return locale
    end,
}
