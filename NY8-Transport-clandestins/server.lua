ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local lastMissionTime = {}

RegisterServerEvent("clandestin:missionComplete")
AddEventHandler("clandestin:missionComplete", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local now = os.time()

    if lastMissionTime[source] and (now - lastMissionTime[source]) < 7200 then
        local remaining = 7200 - (now - lastMissionTime[source])
        TriggerClientEvent("clandestin:cooldownActive", source, math.floor(remaining / 60))
        return
    end

    lastMissionTime[source] = now
    xPlayer.addAccountMoney('black_money', Config.Reward)
    TriggerClientEvent("clandestin:missionRewarded", source)
end)
