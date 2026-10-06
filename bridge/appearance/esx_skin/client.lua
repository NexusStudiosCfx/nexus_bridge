--[[
    esx_skin adapter (with skinchanger, which it comes with). Written against esx_skin and
    skinchanger 1.15.2, with the names checked back to 1.10; docs/adapters.md lists the lines.

    What to know about the two:
      - esx_skin is the menu and the saving, skinchanger the look on the ped;
      - the "saveable" menus save on submit by themselves. The restricted one takes the
        list of fields to show, which is how the editor is kept to clothes;
      - the saved skin is asked from the server with an ESX callback, and put on with
        skinchanger:loadSkin;
      - the "saveable" menus close themselves, on submit and on cancel, before they call
        back, and a cancel puts the old skin back;
      - skinchanger:getSkin answers at once, in the same call.
]]

local CLOTHES = {
    'tshirt_1', 'tshirt_2', 'torso_1', 'torso_2', 'decals_1', 'decals_2', 'arms', 'arms_2',
    'pants_1', 'pants_2', 'shoes_1', 'shoes_2', 'mask_1', 'mask_2', 'bproof_1', 'bproof_2',
    'chain_1', 'chain_2', 'helmet_1', 'helmet_2', 'glasses_1', 'glasses_2', 'watches_1',
    'watches_2', 'bracelets_1', 'bracelets_2', 'bags_1', 'bags_2', 'ears_1', 'ears_2',
}

return {
    caps = { result = true, reload = true, snapshot = true },

    open = function(full, done)
        -- Both menus are closed by esx_skin before it calls back.
        local function submitted() done(true) end
        local function cancelled() done(false) end
        if full then
            TriggerEvent('esx_skin:openSaveableMenu', submitted, cancelled)
        else
            TriggerEvent('esx_skin:openSaveableRestrictedMenu', submitted, cancelled, CLOTHES)
        end
    end,

    reload = function()
        local ESX = exports['es_extended']:getSharedObject()
        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
            if type(skin) == 'table' then TriggerEvent('skinchanger:loadSkin', skin) end
        end)
    end,

    get = function()
        local look = nil
        TriggerEvent('skinchanger:getSkin', function(skin) look = skin end)
        return look
    end,

    set = function(look)
        TriggerEvent('skinchanger:loadSkin', look)
    end,
}
