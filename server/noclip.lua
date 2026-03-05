local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Commands.Add('nc', 'Activar/Desactivar NoClip (Staff)', {}, false, function(source, args)
    if not CheckPermission(source, 'noclip') then return end
    TriggerClientEvent('celestia_admin:client:toggleNoClip', source)
end)

RegisterNetEvent('celestia_admin:server:noclipLog', function(isEnabled)
    local src = source
    if not IsStaff(src) then return end   
    local status = isEnabled and "Activado" or "Desactivado"
end)
