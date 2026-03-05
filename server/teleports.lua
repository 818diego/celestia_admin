local QBCore = exports['qb-core']:GetCoreObject()
local bringBackPositions = {}

CreateThread(function()
    while true do
        local currentTime = os.time()
        local timeoutSeconds = (Config.BringBackTimeout or 5) * 60
        for targetId, data in pairs(bringBackPositions) do
            if currentTime - data.time >= timeoutSeconds then
                local targetPlayer = QBCore.Functions.GetPlayer(targetId)
                if targetPlayer then
                    local targetPed = GetPlayerPed(targetId)
                    SetEntityCoords(targetPed, data.coords.x, data.coords.y, data.coords.z)
                    TriggerClientEvent('QBCore:Notify', targetId, "Has sido devuelto automáticamente por límite de tiempo", "primary")
                end
                bringBackPositions[targetId] = nil
            end
        end
        Citizen.Wait(10000)
    end
end)

QBCore.Commands.Add('bring', 'Traer jugador a tu posición (Staff)', {{name = 'id', help = 'ID del jugador'}}, true, function(source, args)
    local src = source
    if not IsStaff(src) and src ~= 1 then
        TriggerClientEvent('QBCore:Notify', src, "No tienes permisos de staff", "error")
        return
    end
    local targetId = tonumber(args[1])
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if targetPlayer then
        local adminPed = GetPlayerPed(src)
        local targetPed = GetPlayerPed(targetId)
        local adminCoords = GetEntityCoords(adminPed)
        bringBackPositions[targetId] = {
            coords = GetEntityCoords(targetPed),
            time = os.time()
        }
        SetEntityCoords(targetPed, adminCoords.x, adminCoords.y, adminCoords.z)
        TriggerClientEvent('QBCore:Notify', src, "Has traído a " .. targetPlayer.PlayerData.charinfo.firstname .. " (" .. targetId .. ")", "success")
        TriggerClientEvent('QBCore:Notify', targetId, "Has sido teletransportado por un administrador. Serás devuelto en " .. (Config.BringBackTimeout or 5) .. " minutos.", "primary")
    else
        TriggerClientEvent('QBCore:Notify', src, "Jugador no encontrado", "error")
    end
end)

QBCore.Commands.Add('bringback', 'Regresar jugador a su posición anterior (Staff)', {{name = 'id', help = 'ID del jugador'}}, true, function(source, args)
    local src = source
    if not IsStaff(src) and src ~= 1 then
        TriggerClientEvent('QBCore:Notify', src, "No tienes permisos de staff", "error")
        return
    end
    local targetId = tonumber(args[1])
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if targetPlayer then
        if bringBackPositions[targetId] then
            local targetPed = GetPlayerPed(targetId)
            local prevCoords = bringBackPositions[targetId].coords
            SetEntityCoords(targetPed, prevCoords.x, prevCoords.y, prevCoords.z)
            bringBackPositions[targetId] = nil
            TriggerClientEvent('QBCore:Notify', src, "Has devuelto a " .. targetPlayer.PlayerData.charinfo.firstname .. " a su posición anterior", "success")
            TriggerClientEvent('QBCore:Notify', targetId, "Has sido devuelto a tu posición anterior por un administrador", "primary")
        else
            TriggerClientEvent('QBCore:Notify', src, "No hay una posición guardada para este jugador", "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "Jugador no encontrado", "error")
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    bringBackPositions[src] = nil
end)
