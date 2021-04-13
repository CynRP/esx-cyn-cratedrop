
ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

---- CALLBACKS AND SHIT, DO NOT TOUCH ----

local isCrateActive = false
local currentCrate = 0
local currentLocation = {}

local cooldown = 0

----                                  ----

function CrateCooldown()
    if cooldown >= 0 then
        cooldown = cooldown-1
    end
    SetTimeout(60000, CrateCooldown)
end
CrateCooldown()

RegisterServerEvent('jjcrates.setCurrentState')
AddEventHandler('jjcrates.setCurrentState', function(state, crateID, locationID)
    isCrateActive = state
    currentCrate = crateID
    currentLocation = locationID

    TriggerClientEvent('jjcrates.fetchInfo', -1, crateID, locationID)
end)

RegisterServerEvent('jjcrates.spawnCrate')
AddEventHandler('jjcrates.spawnCrate', function(coords)
    TriggerClientEvent('jjcrates.startFlare', -1, coords)
    crateMessage("A plane has been observed far in the sky dropping a crate in a parachute. Stay tuned for location on its whereabout!")
end)


RegisterServerEvent('jjcrates.setCooldown')
AddEventHandler('jjcrates.setCooldown', function(minutes)
    cooldown = minutes
end)
ESX.RegisterServerCallback('jjcrates.getCooldown', function(source, cb)
    cb(cooldown)
end)
ESX.RegisterServerCallback('jjcrates.enoughPlayers', function(source, cb)
    local send = false
    local players = ESX.GetPlayers()
    local totalPlayers = 0
    local totalPolice = 0
    for i=1, #players, 1 do
        totalPlayers = totalPlayers+1
        local xPlayer = ESX.GetPlayerFromId(players[i])
        if xPlayer.job.name == 'police' then
            totalPolice = totalPolice+1
        end
    end
    print("Police: "..totalPolice)
    print("Players: "..totalPlayers)
    if totalPolice >= 0 and totalPlayers >= 0 then
        send = true
    end
    cb(send)
end)


ESX.RegisterServerCallback('jjcrates.getMoney', function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local money = xPlayer.getMoney()
    cb(money)
end)
RegisterServerEvent('jjcrates.pay')
AddEventHandler('jjcrates.pay', function(price)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    xPlayer.removeMoney(price)
end)


RegisterServerEvent('jjcrates.giveLootedItems')
AddEventHandler('jjcrates.giveLootedItems', function(crateID)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    local minItemsFromCrate = Crates.CrateTypes[crateID].minItems
    local maxItemsFromCrate = Crates.CrateTypes[crateID].maxItems

    local itemsToGet = math.random(minItemsFromCrate, maxItemsFromCrate)
    local itemsInCrate = Crates.CrateTypes[crateID].items

    for i=1, itemsToGet do
        local item = math.random(1, #itemsInCrate)
        local amount = math.random(itemsInCrate[item].min, itemsInCrate[item].max)

        local name = itemsInCrate[item].name
        local type = itemsInCrate[item].type
        if type == 'item' then
            xPlayer.addInventoryItem(itemsInCrate[item].name, amount)
        else
            xPlayer.addWeapon(itemsInCrate[item].name, amount)
        end
        print("Got item: "..item.." ("..amount..")")
    end
end)

ESX.RegisterServerCallback('jjcrates.getCurrentState', function(source, cb)
    cb(isCrateActive)
end)
ESX.RegisterServerCallback('jjcrates.fetchCurrentCrate', function(source, cb)
    cb(currentLocation)
end)

function crateMessage(message) 
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div class="chat-message-ooc" style="background-color:#2bff99;"><b>Crates:</b> '..message..'</div>',
        args = { msg }
    })
end
RegisterServerEvent('jjcrates.broadcast')
AddEventHandler('jjcrates.broadcast', function(message)
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div class="chat-message-ooc" style="background-color:#2bff99;"><b>Crates:</b> '..message..'</div>',
        args = { msg }
    })
end)