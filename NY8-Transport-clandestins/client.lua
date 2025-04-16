ESX = nil
local missionInProgress = false
local pnjList = {}

CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(0)
    end

    -- Spawn du donneur de mission
    local pedData = Config.MissionGiver
    RequestModel(pedData.model)
    while not HasModelLoaded(pedData.model) do Wait(1) end

    local missionPed = CreatePed(4, pedData.model, pedData.coords.x, pedData.coords.y, pedData.coords.z - 1.0, pedData.heading, false, true)
    FreezeEntityPosition(missionPed, true)
    SetEntityInvincible(missionPed, true)
    SetBlockingOfNonTemporaryEvents(missionPed, true)

    -- ox_target
    exports.ox_target:addLocalEntity(missionPed, {
        {
            name = "start_clandestin_mission",
            icon = "fas fa-van-shuttle",
            label = "Transport de clandestins",
            onSelect = function()
                if missionInProgress then
                    ESX.ShowNotification("Tu es déjà en mission.")
                else
                    StartClandestinMission()
                end
            end
        }
    })
end)

function StartClandestinMission()
    missionInProgress = true
    ESX.ShowNotification("Va chercher les clandestins. Utilise un Burrito.")
    SetNewWaypoint(Config.PickupLocation.x, Config.PickupLocation.y)

    -- Zone de récupération
    local pickupBlip = AddBlipForCoord(Config.PickupLocation)
    SetBlipSprite(pickupBlip, 280)
    SetBlipColour(pickupBlip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Clandestins à récupérer")
    EndTextCommandSetBlipName(pickupBlip)

    CreateThread(function()
        while missionInProgress do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - Config.PickupLocation)

            if distance < 10.0 then
                ESX.ShowHelpNotification("Appuie sur ~INPUT_CONTEXT~ pour charger les clandestins.")
                if IsControlJustPressed(0, 38) then
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if vehicle ~= 0 and GetEntityModel(vehicle) == GetHashKey(Config.VanModel) then
                        -- Spawn PNJs
                        LoadModel("a_m_m_og_boss_01")
                        for i = 1, Config.NumPNJs do
                            local pnj = CreatePed(4, "a_m_m_og_boss_01", Config.PickupLocation.x + i, Config.PickupLocation.y, Config.PickupLocation.z, 0.0, true, true)
                            TaskWarpPedIntoVehicle(pnj, vehicle, i)
                            SetEntityAsMissionEntity(pnj, true, true)
                            table.insert(pnjList, pnj)
                        end
                        RemoveBlip(pickupBlip)
                        StartDeliveryPhase()
                        break
                    else
                        ESX.ShowNotification("Tu dois utiliser un ~r~Burrito~s~.")
                    end
                end
            end
            Wait(1)
        end
    end)
end

function StartDeliveryPhase()
    ESX.ShowNotification("Conduis les clandestins au point de livraison.")
    SetNewWaypoint(Config.DeliveryLocation.x, Config.DeliveryLocation.y)

    local deliveryBlip = AddBlipForCoord(Config.DeliveryLocation)
    SetBlipSprite(deliveryBlip, 514)
    SetBlipColour(deliveryBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Point de livraison")
    EndTextCommandSetBlipName(deliveryBlip)

    CreateThread(function()
        while missionInProgress do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - Config.DeliveryLocation)

            if distance < 10.0 then
                ESX.ShowHelpNotification("Appuie sur ~INPUT_CONTEXT~ pour livrer les clandestins.")
                if IsControlJustPressed(0, 38) then
                    for _, pnj in pairs(pnjList) do
                        if DoesEntityExist(pnj) then
                            DeleteEntity(pnj)
                        end
                    end
                    TriggerServerEvent("clandestin:missionComplete")
                    ESX.ShowNotification("Livraison terminée. Tu as été payé.")
                    RemoveBlip(deliveryBlip)
                    missionInProgress = false
                    break
                end
            end
            Wait(1)
        end
    end)
end

function LoadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(1) end
end

RegisterNetEvent("clandestin:cooldownActive", function(minutes)
    ESX.ShowNotification("~r~Tu dois attendre encore " .. minutes .. " minutes avant de refaire cette mission.")
end)

RegisterNetEvent("clandestin:missionRewarded", function()
    ESX.ShowNotification("~g~Mission réussie ! Tu as reçu ta récompense.")
end)
