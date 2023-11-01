local QBCore = exports["qb-core"]:GetCoreObject()

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBCore.Functions.GetPlayerData()

end)
        exports['qb-drawtextui']:Popup({
            coords = vector3(-263.5817, -959.7302, 31.230915), 
            radius = 1.5,
            useZ = 7.0, 
            header = 'Апартаменти', 
            text =  'Апартаменти', 
            trigger = "apartments:GetOwnedApartment", 
            triggerType = "client" 
        }) 

        exports['qb-drawtextui']:Popup({
            coords = vector3(-267.7434,-964.3996, 2.2398321), 
            radius = 1.5,
            useZ = 7.0, 
            header = 'Напусни апартамента', 
            text =  'Напусни апартамента', 
            trigger = "", 
            triggerType = "" 
        }) 

        exports['qb-drawtextui']:Popup({
            coords = vector3(-262.9041, -961.7985, 2.5454657), 
            radius = 1.5,
            useZ = 1.0, 
            header = '[ E ], за да отворите шкаф', 
            text =  'шкаф', 
            trigger = "inventory:server:OpenInventory", 
            triggerType = "server" 
        }) 

        exports['qb-drawtextui']:Popup({
            coords = vector3(-264.0024,-957.2345, 2.2355289), 
            radius = 1.5,
            useZ = 7.0, 
            header = 'Гардероп', 
            text =  'Тоалети', 
            trigger = "qb-outfits:client:openOutfits", 
            triggerType = "client" 
        }) 