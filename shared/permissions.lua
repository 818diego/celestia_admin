Config.Permissions = {
    ['god'] = {'admin'},
    ['godarea'] = {'admin'},
    ['ban'] = {'admin'},
    ['unban'] = {'admin'},
    ['kick'] = {'admin', 'moderador'},
    ['adv'] = {'admin', 'moderador'},
    ['mute'] = {'admin', 'moderador'},
    ['mutearea'] = {'admin', 'moderador'},
    ['noclip'] = {'admin', 'moderador', 'soporte'},
    ['wall'] = {'admin', 'moderador', 'soporte'},
    ['tptome'] = {'admin', 'moderador', 'soporte'},
    ['tpdv'] = {'admin', 'moderador', 'soporte'},
    ['tpcoords'] = {'admin', 'moderador', 'soporte'},
    ['dvarea'] = {'admin', 'moderador', 'soporte'},
    ['tuning'] = {'admin', 'moderador', 'soporte'},
}

function CheckPermission(source, commandName)
    if source == 0 then return true end
    local requiredRoles = Config.Permissions[commandName]
    if not requiredRoles then
        print(("^1[celestia_admin] ERROR: El comando '%s' no está registrado en permissions.lua^7"):format(commandName))
        return false 
    end
    if type(requiredRoles) == "string" then
        requiredRoles = {requiredRoles}
    end
    for _, roleKey in ipairs(requiredRoles) do
        if HasDiscordRole(source, roleKey) then
            return true
        end
    end
    TriggerClientEvent('QBCore:Notify', source, "No tienes permisos suficientes para usar este comando.", "error")
    return false
end