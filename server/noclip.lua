local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Commands.Add('noclip', 'Activar/Desactivar NoClip (Staff)', {}, false, function(source, args)
    local canNoclip = HasDiscordRole(source, 'admin')
    if canNoclip then
        TriggerClientEvent('celestia_admin:client:toggleNoClip', source)
    end
end)

RegisterNetEvent('celestia_admin:server:noclipLog', function(isEnabled)
    local src = source
    if not IsStaff(src) then return end   
    local status = isEnabled and "Activado" or "Desactivado"
end)
