local QBCore = exports['qb-core']:GetCoreObject()

local function notify(source, message, msgType)
    TriggerClientEvent('QBCore:Notify', source, message, msgType or 'primary')
end

local function reviveOrHealPlayer(targetId)
    local targetPed = GetPlayerPed(targetId)
    if targetPed == 0 or not DoesEntityExist(targetPed) then
        return false, 'No se pudo obtener el ped del jugador objetivo.'
    end

    local maxHealth = Config.AdminCommands and Config.AdminCommands.God and Config.AdminCommands.God.MaxHealth or 200
    local armorOnRevive = Config.AdminCommands and Config.AdminCommands.God and Config.AdminCommands.God.ArmorOnRevive or 0

    TriggerClientEvent('hospital:client:Revive', targetId)
    TriggerClientEvent('qb-ambulancejob:client:Revive', targetId)
    TriggerClientEvent('celestia_admin:client:applyGodState', targetId, maxHealth, armorOnRevive)

    SetTimeout(500, function()
        TriggerClientEvent('celestia_admin:client:applyGodState', targetId, maxHealth, armorOnRevive)
    end)

    return true
end

local function getRadiusLimits()
    local minRadius = 1.0
    local maxRadius = 9999999.0

    if Config.AdminCommands and Config.AdminCommands.GodArea then
        minRadius = Config.AdminCommands.GodArea.MinRadius or minRadius
        maxRadius = Config.AdminCommands.GodArea.MaxRadius or maxRadius
    end

    return minRadius, maxRadius
end

QBCore.Commands.Add('god', 'Curar o revivir a un jugador por ID (Solo Admin Discord)', {{name = 'id', help = 'ID del jugador'}}, true, function(source, args)
    if not CheckPermission(source, 'god') then return end
    local src = source

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, 'Debes indicar un ID valido. Ejemplo: /god 12', 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(src, 'Jugador no encontrado', 'error')
        return
    end

    local ok, err = reviveOrHealPlayer(targetId)
    if not ok then
        notify(src, err or 'No se pudo aplicar /god al jugador', 'error')
        return
    end

    notify(src, ('Has curado/revivido al jugador ID %s'):format(targetId), 'success')
    notify(targetId, ('Has sido curado/revivido por un administrador (%s)'):format(src), 'success')
end)

QBCore.Commands.Add('godarea', 'Revivir jugadores en un radio en metros (Solo Admin Discord)', {{name = 'radio', help = 'Radio en metros'}}, true, function(source, args)
    if not CheckPermission(source, 'godarea') then return end
    local src = source

    local radius = tonumber(args[1])
    local minRadius, maxRadius = getRadiusLimits()

    if not radius then
        notify(src, 'Debes indicar un radio valido. Ejemplo: /godarea 25', 'error')
        return
    end

    if radius < minRadius or radius > maxRadius then
        notify(src, ('El radio debe estar entre %.1f y %.1f metros'):format(minRadius, maxRadius), 'error')
        return
    end

    local adminPed = GetPlayerPed(src)
    if adminPed == 0 or not DoesEntityExist(adminPed) then
        notify(src, 'No se pudo obtener tu posicion actual', 'error')
        return
    end

    local adminCoords = GetEntityCoords(adminPed)
    local revivedCount = 0

    for _, playerSrc in ipairs(QBCore.Functions.GetPlayers()) do
        local targetPed = GetPlayerPed(playerSrc)
        if targetPed ~= 0 and DoesEntityExist(targetPed) then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(adminCoords - targetCoords)
            if distance <= radius then
                local ok = reviveOrHealPlayer(playerSrc)
                if ok then
                    revivedCount = revivedCount + 1
                    if playerSrc ~= src then
                        notify(playerSrc, ('Has sido curado/revivido por un administrador en un area de %.1fm'):format(radius), 'success')
                    end
                end
            end
        end
    end

    if revivedCount == 0 then
        notify(src, ('No se encontraron jugadores dentro de %.1f metros'):format(radius), 'error')
        return
    end

    notify(src, ('/godarea aplicado: %s jugador(es) curados/revividos en %.1fm'):format(revivedCount, radius), 'success')
end)
