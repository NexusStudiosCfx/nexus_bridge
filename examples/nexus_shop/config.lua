Config = {}

-- The file in locales/ that the shop reads its text from.
Config.locale = 'en'

-- How far from the clerk a player may still pay, in metres. The server checks this at checkout,
-- so walking away with the shop open does not work.
Config.range = 6.0

-- The clerk appears when a player comes within this distance and is removed beyond it.
Config.spawnDistance = 60.0

-- One entry per shop. `coords` is where the clerk stands and which way they face: stand there
-- in game and run /shoppos to get the line for a new shop.
-- An item needs a name that exists in your inventory and a price. Its label and picture come
-- from the inventory, so nothing is written twice. An item the inventory does not know is
-- left out, with a line in the server console.
Config.shops = {
    {
        id = 'strawberry',
        label = '24/7 Supermarket',
        ped = 'mp_m_shopkeep_01',
        coords = vec4(24.47, -1346.62, 29.5, 271.66),
        blip = { sprite = 52, colour = 69, scale = 0.8 },
        items = {
            { name = 'water', price = 10 },
            { name = 'sprunk', price = 12 },
            { name = 'burger', price = 15 },
            { name = 'bandage', price = 45 },
            { name = 'phone', price = 850 },
            { name = 'radio', price = 250 },
            { name = 'lockpick', price = 120 },
            { name = 'parachute', price = 600 },
        },
    },
}
