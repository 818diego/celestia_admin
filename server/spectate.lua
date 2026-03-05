local QBCore = exports['qb-core']:GetCoreObject()

local function notify(source, message, msgType)
    TriggerClientEvent('QBCore:Notify', source, message, msgType or 'primary')
end

QBCore.Commands.Add('spectar', 'Espectear a un jugador (Staff)', {
    { name = 'id', help = 'ID del jugador. Ejemplo: /spectar 12 (Dejar vacío para salir)' }
}, false, function(source, args)
    if not CheckPermission(source, 'spectate') then return end
    local src = source
    local targetId = tonumber(args[1])
    
    if not targetId then
        TriggerClientEvent('celestia_admin:client:ToggleSpectate', src, false)
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(src, 'Jugador no encontrado', 'error')
        return
    end

    if targetId == src then
        notify(src, 'No puedes espectearte a ti mismo', 'error')
        return
    end

    local targetPed = GetPlayerPed(targetId)
    local targetCoords = GetEntityCoords(targetPed)
    
    TriggerClientEvent('celestia_admin:client:ToggleSpectate', src, true, targetId, targetCoords)
end)
