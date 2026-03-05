local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('playerDropped', function(reason)
    local src = source
    local playerPed = GetPlayerPed(src)
    if not playerPed or playerPed == 0 then return end
    local coords = GetEntityCoords(playerPed)
    local name = GetPlayerName(src)
    TriggerClientEvent('celestia_admin:client:AddDisconnectLog', -1, name, src, coords, reason)
end)
