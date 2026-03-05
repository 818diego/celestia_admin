local QBCore = exports['qb-core']:GetCoreObject()

local function notify(source, message, msgType)
    TriggerClientEvent('QBCore:Notify', source, message, msgType or 'primary')
end

QBCore.Commands.Add('frezee', 'Congelar a un jugador (Staff)', {
    { name = 'id', help = 'ID del jugador. Ejemplo: /frezee 12' }
}, true, function(source, args)
    if not CheckPermission(source, 'freeze') then return end
    local src = source
    local targetId = tonumber(args[1])
    
    if not targetId then
        notify(src, 'Debes indicar un ID valido. Ejemplo: /frezee 12', 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(src, 'Jugador no encontrado', 'error')
        return
    end

    TriggerClientEvent('celestia_admin:client:ToggleFreeze', targetId, true)
    notify(src, ('Has congelado al jugador ID %d'):format(targetId), 'success')
    notify(targetId, 'Has sido congelado por un administrador', 'primary')
end)

QBCore.Commands.Add('unfrezee', 'Descongelar a un jugador (Staff)', {
    { name = 'id', help = 'ID del jugador. Ejemplo: /unfrezee 12' }
}, true, function(source, args)
    if not CheckPermission(source, 'unfreeze') then return end
    local src = source
    local targetId = tonumber(args[1])
    
    if not targetId then
        notify(src, 'Debes indicar un ID valido. Ejemplo: /unfrezee 12', 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(src, 'Jugador no encontrado', 'error')
        return
    end

    TriggerClientEvent('celestia_admin:client:ToggleFreeze', targetId, false)
    notify(src, ('Has descongelado al jugador ID %d'):format(targetId), 'success')
    notify(targetId, 'Has sido descongelado por un administrador', 'success')
end)
