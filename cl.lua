
print("^1[JJGTDev-Crates] ^2Restarted and ensured all required dependencies")

ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)


local flareSmoke = nil
local currentCrate = 0
local currentLocation = {}

RegisterNetEvent('jjcrates.fetchInfo')
AddEventHandler('jjcrates.fetchInfo', function(crate, location)
    currentCrate = crate
    currentLocation = location
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        local coords = GetEntityCoords(PlayerPedId())
        for i=1, #Crates.Locations do
            if (GetDistanceBetweenCoords(coords, Crates.Locations[i].x, Crates.Locations[i].y, Crates.Locations[i].z, true) < 3.0) then
                Draw3D(Crates.Locations[i].x, Crates.Locations[i].y, Crates.Locations[i].z, "Press ~g~E ~w~to buy crate drop.")
                if IsControlJustPressed(0, 38) then
                    OpenCrateShop()
                end
            end
        end
        if currentLocation.x ~= nil then
            if (GetDistanceBetweenCoords(coords, currentLocation.x, currentLocation.y, currentLocation.z, true) < 3.0) then
                Draw3D(currentLocation.x, currentLocation.y, currentLocation.z, "Press ~g~E ~w~to loot crate.")
                if IsControlJustPressed(0, 38) then
                    local lootedCrateID = currentCrate
                    spawnAllPeds(coords, 3)
                    TriggerServerEvent('jjcrates.setCurrentState', false, 0, {})
                    RunProgBar(120000, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", "Searching crate...")
                    TriggerServerEvent('jjcrates.giveLootedItems', lootedCrateID)
                    spawnAllPeds(coords, 3)
                end
            end
        end
    end
end)

function OpenCrateShop()
    ESX.UI.Menu.CloseAll()

    local elements = {}
    for i=1, #Crates.CrateTypes do
        local price = Crates.CrateTypes[i].price
        table.insert(elements, {
            label = "<b>"..Crates.CrateTypes[i].name.." (<font color='green'>$"..price.."</font>)</b>",
            value = i
        })
    end

    ESX.UI.Menu.Open('default', 'crateShop', 'dropType', {
        title = "Crate Shop",
        align = 'center',
        elements = elements
    }, function(data, menu)
        ESX.TriggerServerCallback('jjcrates.getCurrentState', function(state)
            if state then
                RunNotify("There is already a crate dropped thats not been looted.", '#e0040f')
            else
                ESX.TriggerServerCallback('jjcrates.enoughPlayers', function(enough)
                    if enough then
                        ESX.TriggerServerCallback('jjcrates.getCooldown', function(minutes)
                            local minutesLeft = minutes
                            if (minutesLeft <= 0) then
                                ESX.TriggerServerCallback('jjcrates.getMoney', function(money)
                                    if money >= Crates.CrateTypes[data.current.value].price then
                                        TriggerServerEvent('jjcrates.pay', Crates.CrateTypes[data.current.value].price)
                                        TriggerServerEvent('jjcrates.setCooldown', 120)
                                        local prop = Crates.CrateTypes[data.current.value].prop
                                        local locationID = math.random(1, #Crates.DropLocations)
                                        local dropLocation = {x = Crates.DropLocations[locationID].x, y = Crates.DropLocations[locationID].y, z = Crates.DropLocations[locationID].z}
                                        TriggerServerEvent('jjcrates.setCurrentState', true, data.current.value, dropLocation)

                                        RunProgBar(30000, "", "", "Ordering crate drop")
                                        Citizen.Wait(2000)
                                        RunNotify("Called for crate drop!", '#2bff99')
                                        Citizen.Wait(2000)
                                        RunNotify("Pay attention for a clue on its whereabout.", '#2bff99')
                                        Citizen.Wait(60000)
                                        RunNotify("Crate has landed, go find it!", '#2bff99')
                                        Citizen.Wait(1000)
                                        RunNotify("Clue: "..Crates.DropLocations[locationID].clue, '#2bff99')
                                        Citizen.Wait(2000)
                                        RunNotify("Flare is activated for 5 minutes.", '#2bff99')

                                        SpawnCrate(dropLocation, prop)
                                        Citizen.Wait(120*1000)
                                        TriggerServerEvent('jjcrates.broadcast', "The crate has been observed by locals close to  "..Crates.DropLocations[locationID].clue.."! Go find it before anyone else to get a bunch of awesome shit!")
                                    else
                                        RunNotify("You dont have enough money for this.", '#2bff99')
                                    end
                                end)
                            else
                                RunNotify("You cant do this for another "..minutes.." minutes.", '#2bff99')
                            end
                        end)
                    else
                        RunNotify("Required 20 players and 3 cops to start this.", '#2bff99')
                    end
                end)
            end
        end)
        ESX.UI.Menu.CloseAll()
    end, function(data, menu)
        menu.close()
    end)
end

function RunNotify(Text, Color)
    TriggerEvent('mythic_notify:client:SendAlert', { type = 'inform', text = Text, style = { ['background-color'] = Color, ['color'] = '#000000' } })
end

function RunProgBar(TimeToPlay, AnimDict, Anim, Text)
    exports['mythic_progbar']:Progress({
        name = "weaponDrop",
        duration = TimeToPlay,
        label = Text,
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = AnimDict,
            anim = Anim,
            flags = 49,
        },
    }, function(cancelled)
        if not cancelled then
            -- Do Something If Action Wasn't Cancelled
        else
            -- Do Something If Action Was Cancelled
        end
    end)
    Citizen.Wait(TimeToPlay)
end

function Draw3D(x,y,z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    if onScreen then
      SetTextScale(0.35, 0.35)
      SetTextFont(4)
      SetTextProportional(1)
      SetTextColour(255, 255, 255, 215)
      SetTextEntry("STRING")
      SetTextCentre(1)
      AddTextComponentString(text)
      DrawText(_x,_y)
      local factor = (string.len(text)) / 370
      DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
      end
  end

RegisterNetEvent('jjcrates.startFlare')
AddEventHandler('jjcrates.startFlare', function(coords)
    if not HasNamedPtfxAssetLoaded("core") then
        RequestPfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do
            Citizen.Wait(1)
        end
    end
    SetPtfxAssetNextCall("core")
    flareSmoke = StartParticleFxLoopedAtCoord("exp_grd_flare", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 2.0, false, false, false, false)
    SetParticleFxLoopedAlpha(flareSmoke, 0.8)
    SetParticleFxLoopedColour(flareSmoke, 0.0, 0.0, 0.0, 0)
    Citizen.Wait(8000000)
    StopParticleFxLooped(flareSmoke, 0)
end)

function spawnPed(coords)
    ped1 = CreatePed(26, "csb_mweather", coords.x, coords.y, coords.z, 0.0, true, true)
    GiveWeaponToPed(ped1, "WEAPON_CARBINERIFLE", 1, false, true)
    SetPedArmour(ped1, 5000)
    SetPedAlertness(ped1, 3)
    SetPedHighlyPerceptive(ped1, true)
    SetPedDropsWeaponsWhenDead(ped1, false)
    SetPedCombatRange(ped1, 50)
    SetPedToInformRespectedFriends(ped1, 200, 100)
    SetPedCombatAttributes(ped1, 1, true)
    SetPedCombatAttributes(ped1, 2, true)
    SetPedCombatAttributes(ped1, 5, true)
    SetPedCombatAttributes(ped1, 16, true)
    SetPedCombatAttributes(ped1, 26, true)
    SetPedCombatAttributes(ped1, 46, true)
    SetPedCombatAttributes(ped1, 52, true)
    SetPedFleeAttributes(ped1, 0, 0)
end
function spawnAllPeds(coords, amount)
    TriggerEvent('jjcrates.startFlare', {x = coords.x, y = coords.y, z = coords.z})
    for i=1, amount do
        local geg = math.random(1, 10)
        spawnPed({x = coords.x+geg, y = coords.y, z = coords.z})
    end
    for i=1, amount do
        local geg = math.random(1, 10)
        spawnPed({x = coords.x-geg, y = coords.y, z = coords.z})
    end
    for i=1, amount do
        local geg = math.random(1, 10)
        spawnPed({x = coords.x, y = coords.y+geg, z = coords.z})
    end
    for i=1, amount do
        local geg = math.random(1, 10)
        spawnPed({x = coords.x, y = coords.y-geg, z = coords.z})
    end
end

  function SpawnCrate(coords, prop)
    local ped = PlayerPedId()
    local prop = prop
    local model = GetHashKey(prop)
    ESX.Game.SpawnObject(model, {
        x = coords.x, y = coords.y, z = coords.z
    }, function(obj)
        SetEntityHeading(obj, GetEntityHeading(ped))
        PlaceObjectOnGroundProperly(obj)
        spawnAllPeds(coords, 10)
        TriggerServerEvent('jjcrates.spawnCrate', coords)
    end)
end