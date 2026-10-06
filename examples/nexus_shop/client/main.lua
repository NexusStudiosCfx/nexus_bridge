local resource = GetCurrentResourceName()

local function loadLocale(name)
    local text = LoadResourceFile(resource, ('locales/%s.json'):format(name))
    if not text then
        print(("There is no locales/%s.json, falling back to English."):format(name))
        text = LoadResourceFile(resource, 'locales/en.json')
    end
    return json.decode(text)
end

-- The page gets its strings from the same file Lua reads, so there is one place to translate.
local strings = loadLocale(Config.locale)
Nexus.locale(strings)

-- The inventory decides where an item's picture is, and only its client side knows. So the
-- pictures are looked up here and handed to the page when the shop opens. An inventory
-- without pictures leaves an item out, and the page shows its name alone.
local function imagesOf(shop)
    local images = {}
    for _, sold in ipairs(shop.items) do
        images[sold.name] = Bridge.inventory.image(sold.name)
    end
    return images
end

-- One clerk per shop, there only while the player is near. The clerk is local to this client:
-- every player has their own, so there is nothing to sync and nothing for the server to own.
local clerks, targets = {}, {}

local function removeClerk(id)
    local ped = clerks[id]
    if not ped then return end
    Bridge.target.remove(targets[id])
    targets[id] = nil
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
    clerks[id] = nil
end

local function spawnClerk(shop)
    local model = GetHashKey(shop.ped)
    if not IsModelInCdimage(model) then
        print(("The ped model '%s' of the shop '%s' does not exist."):format(shop.ped, shop.id))
        return
    end

    RequestModel(model)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(model) do
        if GetGameTimer() > deadline then return end
        Wait(0)
    end

    local coords = shop.coords
    -- CreatePed places the ped by its centre, a metre above the ground it should stand on.
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
    SetModelAsNoLongerNeeded(model)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    clerks[shop.id] = ped

    -- An eye option on ox_target or qb-target, a key prompt on a server without either.
    targets[shop.id] = Bridge.target.addEntity(ped, {
        label = strings['target.browse'],
        icon = 'fa-basket-shopping',
        distance = 2.5,
        onSelect = function()
            Nexus.open('shop', { shop = shop.id, images = imagesOf(shop) })
        end,
    })
end

for _, shop in ipairs(Config.shops) do
    if shop.blip then
        local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
        SetBlipSprite(blip, shop.blip.sprite)
        SetBlipColour(blip, shop.blip.colour)
        SetBlipScale(blip, shop.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(shop.label)
        EndTextCommandSetBlipName(blip)
    end
end

-- A slow loop is enough to decide which clerks should exist. It is the only loop this resource
-- runs, and the shop screen itself costs nothing while it is closed.
CreateThread(function()
    while true do
        local position = GetEntityCoords(PlayerPedId())
        for _, shop in ipairs(Config.shops) do
            local distance = #(position - vec3(shop.coords.x, shop.coords.y, shop.coords.z))
            if not clerks[shop.id] and distance < Config.spawnDistance then
                spawnClerk(shop)
            elseif clerks[shop.id] and distance > Config.spawnDistance + 20.0 then
                removeClerk(shop.id)
            end
        end
        Wait(1500)
    end
end)

-- /shoppos prints where you stand as a line for config.lua.
RegisterCommand('shoppos', function()
    local ped = PlayerPedId()
    local position = GetEntityCoords(ped)
    print(('coords = vec4(%.2f, %.2f, %.2f, %.2f),'):format(position.x, position.y, position.z, GetEntityHeading(ped)))
end, false)

AddEventHandler('onResourceStop', function(stopped)
    if stopped ~= resource then return end
    for id in pairs(clerks) do
        removeClerk(id)
    end
end)
