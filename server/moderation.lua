local QBCore = exports['qb-core']:GetCoreObject()

local warningsByIdentifier = {}
local mutesByIdentifier = {}
local jailedPlayers = {}

local function notify(source, message, msgType)
    TriggerClientEvent('QBCore:Notify', source, message, msgType or 'primary')
end

local function getSourceName(source)
    if source == 0 then
        return 'Console'
    end

    local name = GetPlayerName(source)
    if name and name ~= '' then
        return name
    end

    return ('ID %s'):format(source)
end

local function getPreferredIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    local priority = { 'license:', 'license2:', 'discord:', 'fivem:', 'xbl:', 'live:' }

    for _, prefix in ipairs(priority) do
        for _, identifier in ipairs(identifiers) do
            if identifier:sub(1, #prefix) == prefix then
                return identifier
            end
        end
    end

    return identifiers[1]
end

local function getModerationConfig()
    local defaults = {
        DefaultAdvReason = 'Conducta indebida.',
        DefaultMuteReason = 'Comportamiento inapropiado en chat/voz.',
        DefaultMuteMinutes = 10,
        MinMuteMinutes = 1,
        MaxMuteMinutes = 240,
        MuteAreaMinRadius = 1.0,
        MuteAreaMaxRadius = 100.0
    }

    local moderation = Config.AdminCommands and Config.AdminCommands.Moderation
    if not moderation then
        return defaults
    end

    defaults.DefaultAdvReason = moderation.DefaultAdvReason or defaults.DefaultAdvReason
    defaults.DefaultMuteReason = moderation.DefaultMuteReason or defaults.DefaultMuteReason
    defaults.DefaultMuteMinutes = moderation.DefaultMuteMinutes or defaults.DefaultMuteMinutes
    defaults.MinMuteMinutes = moderation.MinMuteMinutes or defaults.MinMuteMinutes
    defaults.MaxMuteMinutes = moderation.MaxMuteMinutes or defaults.MaxMuteMinutes
    defaults.MuteAreaMinRadius = moderation.MuteAreaMinRadius or defaults.MuteAreaMinRadius
    defaults.MuteAreaMaxRadius = moderation.MuteAreaMaxRadius or defaults.MuteAreaMaxRadius

    return defaults
end

local function applyVoiceMute(targetSource, muted)
    local ok = pcall(MumbleSetPlayerMuted, targetSource, muted)
    if not ok then
        print(('[celestia_admin] Aviso: no se pudo aplicar mute de voz con MumbleSetPlayerMuted a ID %s'):format(targetSource))
    end
end

local function setMuteForSource(targetSource, reason, adminName, minutes)
    local identifier = getPreferredIdentifier(targetSource)
    if not identifier then
        return false, 'No se pudo obtener un identificador del jugador objetivo.'
    end

    local expiresAt = os.time() + (minutes * 60)
    mutesByIdentifier[identifier] = {
        reason = reason,
        mutedBy = adminName,
        expiresAt = expiresAt
    }

    applyVoiceMute(targetSource, true)
    TriggerClientEvent('celestia_admin:client:SetMuteStatus', targetSource, true, expiresAt, reason)
    notify(targetSource, ('Has sido muteado por %s durante %s minuto(s). Motivo: %s'):format(adminName, minutes, reason), 'error')
    return true
end

local function isMutedBySource(playerSource)
    local identifier = getPreferredIdentifier(playerSource)
    if not identifier then
        return false
    end

    local muteData = mutesByIdentifier[identifier]
    if not muteData then
        return false
    end

    if os.time() >= muteData.expiresAt then
        mutesByIdentifier[identifier] = nil
        applyVoiceMute(playerSource, false)
        TriggerClientEvent('celestia_admin:client:SetMuteStatus', playerSource, false)
        notify(playerSource, 'Tu mute ha expirado.', 'success')
        return false
    end

    return true, muteData
end

local function parseMuteMinutesAndReason(args, startIndex)
    local cfg = getModerationConfig()
    local minutes = cfg.DefaultMuteMinutes
    local reasonStartIndex = startIndex

    local possibleMinutes = tonumber(args[startIndex])
    if possibleMinutes then
        minutes = math.floor(possibleMinutes)
        reasonStartIndex = startIndex + 1
    end

    if minutes < cfg.MinMuteMinutes or minutes > cfg.MaxMuteMinutes then
        return nil, nil, ('Los minutos deben estar entre %s y %s.'):format(cfg.MinMuteMinutes, cfg.MaxMuteMinutes)
    end

    local reason = table.concat(args, ' ', reasonStartIndex)
    if reason == '' then
        reason = cfg.DefaultMuteReason
    end

    return minutes, reason
end

CreateThread(function()
    while true do
        local now = os.time()
        for identifier, muteData in pairs(mutesByIdentifier) do
            if now >= muteData.expiresAt then
                mutesByIdentifier[identifier] = nil

                for _, playerSrc in ipairs(QBCore.Functions.GetPlayers()) do
                    if getPreferredIdentifier(playerSrc) == identifier then
                        applyVoiceMute(playerSrc, false)
                        TriggerClientEvent('celestia_admin:client:SetMuteStatus', playerSrc, false)
                        notify(playerSrc, 'Tu mute ha expirado.', 'success')
                        break
                    end
                end
            end
        end

        Wait(15000)
    end
end)

AddEventHandler('playerJoining', function()
    local src = source
    local muted, muteData = isMutedBySource(src)
    if muted then
        applyVoiceMute(src, true)
        local remaining = math.max(1, math.ceil((muteData.expiresAt - os.time()) / 60))
        TriggerClientEvent('celestia_admin:client:SetMuteStatus', src, true, muteData.expiresAt, muteData.reason)
        notify(src, ('Sigues muteado. Tiempo restante: %s minuto(s). Motivo: %s'):format(remaining, muteData.reason), 'error')
    end
end)

AddEventHandler('chatMessage', function(source)
    local muted, muteData = isMutedBySource(source)
    if not muted then
        return
    end

    CancelEvent()
    local remaining = math.max(1, math.ceil((muteData.expiresAt - os.time()) / 60))
    notify(source, ('Estas muteado. Tiempo restante: %s minuto(s). Motivo: %s'):format(remaining, muteData.reason), 'error')
end)

QBCore.Commands.Add('adv', 'Advertir y encarcelar jugador. Uso: /adv [id] [tiempo_min o 0] [motivo]', {
    { name = 'id', help = 'ID del jugador objetivo' },
    { name = 'tiempo', help = 'Minutos (0 o vacío = Permanente)' },
    { name = 'motivo', help = 'Razón de la sanción' }
}, true, function(source, args)
    if not CheckPermission(source, 'adv') then return end
    local src = source

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, 'Uso: /adv [id] [tiempo] [motivo]', 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(src, 'Jugador no encontrado', 'error')
        return
    end

    local targetIdentifier = getPreferredIdentifier(targetId)
    if not targetIdentifier then
        notify(src, 'No se pudo obtener un identificador del jugador', 'error')
        return
    end

    local minutes = tonumber(args[2]) or 0
    local reason = table.concat(args, ' ', 3)
    if reason == '' then
        local cfg = getModerationConfig()
        reason = cfg.DefaultAdvReason
    end

    local expiresAt = (minutes > 0) and (os.time() + (minutes * 60)) or 0
    
    jailedPlayers[targetIdentifier] = {
        expiresAt = expiresAt,
        reason = reason
    }

    if not warningsByIdentifier[targetIdentifier] then
        warningsByIdentifier[targetIdentifier] = { count = 0 }
    end
    warningsByIdentifier[targetIdentifier].count = warningsByIdentifier[targetIdentifier].count + 1

    local timeMsg = (minutes > 0) and (minutes .. " minutos") or "Indefinido (Permanente)"
    TriggerClientEvent('celestia_admin:client:AdminJail', targetId, true, expiresAt, reason)
    
    notify(src, ('ID %d encarcelado por %s. Motivo: %s'):format(targetId, timeMsg, reason), 'success')
end)

QBCore.Commands.Add('unadv', 'Sacar a un jugador de la prisión administrativa', {
    { name = 'id', help = 'ID del jugador' }
}, true, function(source, args)
    if not CheckPermission(source, 'adv') then return end
    local src = source
    local targetId = tonumber(args[1])
    
    if not targetId then
        notify(src, 'ID inválido', 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    local targetIdentifier = targetPlayer and getPreferredIdentifier(targetId)

    if jailedPlayers[targetIdentifier] then
        jailedPlayers[targetIdentifier] = nil
        TriggerClientEvent('celestia_admin:client:AdminJail', targetId, false)
        notify(src, ('ID %d ha sido sacado de la prisión'):format(targetId), 'success')
    else
        notify(src, 'El jugador no está en la prisión administrativa', 'error')
    end
end)

QBCore.Commands.Add('mute', 'Mutear a un jugador. Uso: /mute [id] [minutos] [motivo] (Solo Admin Discord)', {
    { name = 'id', help = 'ID del jugador objetivo. Ejemplo: /mute 12 15 Spam por voz' },
    { name = 'minutos', help = 'Duracion en minutos (opcional).' },
    { name = 'motivo', help = 'Motivo del mute (opcional).' }
}, true, function(source, args)
    if not CheckPermission(source, 'mute') then return end
    local src = source

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, 'Debes indicar un ID valido. Ejemplo: /mute 12 15 Spam por voz', 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(src, 'Jugador no encontrado', 'error')
        return
    end

    local minutes, reason, parseErr = parseMuteMinutesAndReason(args, 2)
    if not minutes then
        notify(src, parseErr or 'No se pudo procesar la duracion del mute', 'error')
        return
    end

    local adminName = getSourceName(src)
    local ok, err = setMuteForSource(targetId, reason, adminName, minutes)
    if not ok then
        notify(src, err or 'No se pudo aplicar el mute', 'error')
        return
    end

    notify(src, ('Mute aplicado a ID %s durante %s minuto(s). Motivo: %s'):format(targetId, minutes, reason), 'success')
end)

QBCore.Commands.Add('mutearea', 'Mutear jugadores dentro de un area. Uso: /mutearea [radio] [minutos] [motivo] (Solo Admin Discord)', {
    { name = 'radio', help = 'Radio en metros. Ejemplo: /mutearea 20 10 Spam masivo' },
    { name = 'minutos', help = 'Duracion en minutos (opcional).' },
    { name = 'motivo', help = 'Motivo del mute (opcional).' }
}, true, function(source, args)
    if not CheckPermission(source, 'mutearea') then return end
    local src = source

    local radius = tonumber(args[1])
    local cfg = getModerationConfig()

    if not radius then
        notify(src, 'Debes indicar un radio valido. Ejemplo: /mutearea 20 10 Spam masivo', 'error')
        return
    end

    if radius < cfg.MuteAreaMinRadius or radius > cfg.MuteAreaMaxRadius then
        notify(src, ('El radio debe estar entre %.1f y %.1f metros'):format(cfg.MuteAreaMinRadius, cfg.MuteAreaMaxRadius), 'error')
        return
    end

    local minutes, reason, parseErr = parseMuteMinutesAndReason(args, 2)
    if not minutes then
        notify(src, parseErr or 'No se pudo procesar la duracion del mute', 'error')
        return
    end

    local adminPed = GetPlayerPed(src)
    if adminPed == 0 or not DoesEntityExist(adminPed) then
        notify(src, 'No se pudo obtener tu posicion actual', 'error')
        return
    end

    local adminCoords = GetEntityCoords(adminPed)
    local adminName = getSourceName(src)
    local mutedCount = 0

    for _, playerSrc in ipairs(QBCore.Functions.GetPlayers()) do
        if playerSrc ~= src then
            local targetPed = GetPlayerPed(playerSrc)
            if targetPed ~= 0 and DoesEntityExist(targetPed) then
                local distance = #(adminCoords - GetEntityCoords(targetPed))
                if distance <= radius then
                    local ok = setMuteForSource(playerSrc, reason, adminName, minutes)
                    if ok then
                        mutedCount = mutedCount + 1
                    end
                end
            end
        end
    end

    if mutedCount == 0 then
        notify(src, ('No se encontraron jugadores dentro de %.1f metros'):format(radius), 'error')
        return
    end

    notify(src, ('/mutearea aplicado: %s jugador(es) muteados por %s minuto(s).'):format(mutedCount, minutes), 'success')
end)

QBCore.Commands.Add('unmute', 'Quitar mute a un jugador. Uso: /unmute [id] (Solo Admin Discord)', {
    { name = 'id', help = 'ID del jugador objetivo.' }
}, true, function(source, args)
    if not CheckPermission(source, 'mute') then return end
    local src = source

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, 'Debes indicar un ID valido.', 'error')
        return
    end

    local identifier = getPreferredIdentifier(targetId)
    if not identifier then
        notify(src, 'No se pudo obtener el identificador del jugador.', 'error')
        return
    end

    if not mutesByIdentifier[identifier] then
        notify(src, 'El jugador no esta muteado.', 'error')
        return
    end

    mutesByIdentifier[identifier] = nil
    applyVoiceMute(targetId, false)
    TriggerClientEvent('celestia_admin:client:SetMuteStatus', targetId, false)
    
    notify(targetId, 'Tu mute ha sido retirado por un administrador.', 'success')
    notify(src, ('Mute retirado a ID %s.'):format(targetId), 'success')
end)
