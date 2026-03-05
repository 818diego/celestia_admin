local QBCore = exports['qb-core']:GetCoreObject()
local bringBackPositions = {}
local copiedCoordsByAdmin = {}

local function notify(source, message, msgType)
    TriggerClientEvent('QBCore:Notify', source, message, msgType or 'primary')
end

local function canUseTeleport(source)
    return IsStaff(source) or source == 1 or source == 0
end

local function savePreviousPosition(targetId)
    local targetPed = GetPlayerPed(targetId)
    if targetPed == 0 or not DoesEntityExist(targetPed) then
        return false
    end

    bringBackPositions[targetId] = {
        coords = GetEntityCoords(targetPed),
        time = os.time()
    }

    return true
end

local function getPlayerCoords(playerId)
    local ped = GetPlayerPed(playerId)
    if ped == 0 or not DoesEntityExist(ped) then
        return nil
    end

    return GetEntityCoords(ped)
end

local function teleportTargetToAdmin(adminId, targetId)
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(adminId, 'Jugador no encontrado', 'error')
        return
    end

    if adminId == targetId then
        notify(adminId, 'No puedes traerte a ti mismo', 'error')
        return
    end

    local adminPed = GetPlayerPed(adminId)
    local targetPed = GetPlayerPed(targetId)

    if adminPed == 0 or targetPed == 0 or not DoesEntityExist(adminPed) or not DoesEntityExist(targetPed) then
        notify(adminId, 'No se pudo obtener el ped del jugador', 'error')
        return
    end

    if not savePreviousPosition(targetId) then
        notify(adminId, 'No se pudo guardar la posicion anterior del jugador', 'error')
        return
    end

    local adminCoords = GetEntityCoords(adminPed)
    SetEntityCoords(targetPed, adminCoords.x, adminCoords.y, adminCoords.z)

    notify(adminId, ('Has traido al jugador ID %s'):format(targetId), 'success')
    notify(targetId, ('Has sido teletransportado por un administrador. Seras devuelto en %s minutos.'):format(Config.BringBackTimeout or 5), 'primary')
end

local function returnTargetToPreviousPosition(adminId, targetId)
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(adminId, 'Jugador no encontrado', 'error')
        return
    end

    local saved = bringBackPositions[targetId]
    if not saved then
        notify(adminId, 'No hay una posicion guardada para este jugador', 'error')
        return
    end

    local targetPed = GetPlayerPed(targetId)
    if targetPed == 0 or not DoesEntityExist(targetPed) then
        notify(adminId, 'No se pudo obtener el ped del jugador', 'error')
        return
    end

    SetEntityCoords(targetPed, saved.coords.x, saved.coords.y, saved.coords.z)
    bringBackPositions[targetId] = nil

    notify(adminId, ('Has devuelto al jugador ID %s a su posicion anterior'):format(targetId), 'success')
    notify(targetId, 'Has sido devuelto a tu posicion anterior por un administrador', 'primary')
end

local function handleTeleportCommand(source, args, action)
    if not CheckPermission(source, action) then return end

    local targetId = tonumber(args[1])
    if not targetId then
        notify(source, 'Debes indicar un ID valido', 'error')
        return
    end

    if action == 'bring' then
        teleportTargetToAdmin(source, targetId)
        return
    end

    if action == 'bringback' then
        returnTargetToPreviousPosition(source, targetId)
    end
end

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
                    notify(targetId, 'Has sido devuelto automaticamente por limite de tiempo', 'primary')
                end
                bringBackPositions[targetId] = nil
            end
        end
        Citizen.Wait(10000)
    end
end)

QBCore.Commands.Add('tptome', 'Traer jugador hacia ti. Uso: /tptome [id] (Staff)', {
    {name = 'id', help = 'ID del jugador. Ejemplo: /tptome 12'}
}, true, function(source, args)
    handleTeleportCommand(source, args, 'bring')
end)

QBCore.Commands.Add('tpdv', 'Devolver jugador a su ubicacion anterior. Uso: /tpdv [id] (Staff)', {
    {name = 'id', help = 'ID del jugador. Ejemplo: /tpdv 12'}
}, true, function(source, args)
    handleTeleportCommand(source, args, 'bringback')
end)

QBCore.Commands.Add('coordstotp', 'Guardar tus coordenadas actuales para /tpcoords. Uso: /coords (Staff)', {}, false, function(source)
    if not CheckPermission(source, 'tpcoords') then return end
    local src = source

    local coords = getPlayerCoords(src)
    if not coords then
        notify(src, 'No se pudo obtener tu posicion actual', 'error')
        return
    end

    copiedCoordsByAdmin[src] = {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }

    notify(src, ('Coordenadas guardadas: x=%.2f, y=%.2f, z=%.2f'):format(coords.x, coords.y, coords.z), 'success')
end)

QBCore.Commands.Add('tpcoords', 'Teletransportar jugador a coordenadas guardadas con /coords. Uso: /tpcoords [id] (Staff)', {
    {name = 'id', help = 'ID del jugador. Ejemplo: /tpcoords 12'}
}, true, function(source, args)
    if not CheckPermission(source, 'tpcoords') then return end
    local src = source

    local savedCoords = copiedCoordsByAdmin[src]
    if not savedCoords then
        notify(src, 'Primero usa /coords para guardar una posicion', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, 'Debes indicar un ID valido. Ejemplo: /tpcoords 12', 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(src, 'Jugador no encontrado', 'error')
        return
    end

    if not savePreviousPosition(targetId) then
        notify(src, 'No se pudo guardar la posicion anterior del jugador', 'error')
        return
    end

    local targetPed = GetPlayerPed(targetId)
    if targetPed == 0 or not DoesEntityExist(targetPed) then
        notify(src, 'No se pudo obtener el ped del jugador', 'error')
        return
    end

    SetEntityCoords(targetPed, savedCoords.x, savedCoords.y, savedCoords.z)

    notify(src, ('Has teletransportado al jugador ID %s a las coordenadas guardadas'):format(targetId), 'success')
    notify(targetId, 'Has sido teletransportado por un administrador', 'primary')
end)

QBCore.Commands.Add('tpplaza', 'Enviar a un jugador a la plaza central (Staff)', {
    {name = 'id', help = 'ID del jugador. Ejemplo: /tpplaza 12'}
}, true, function(source, args)
    if not CheckPermission(source, 'tpplaza') then return end
    local src = source

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, 'Debes indicar un ID valido. Ejemplo: /tpplaza 12', 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(src, 'Jugador no encontrado', 'error')
        return
    end

    local targetPed = GetPlayerPed(targetId)
    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
        notify(src, 'No se pudo obtener el ped del jugador', 'error')
        return
    end

    local plazaCoords = Config.Teleports.PlazaCoords
    if not plazaCoords then
        notify(src, 'Las coordenadas de la plaza no están configuradas en config.lua', 'error')
        return
    end

    if not savePreviousPosition(targetId) then
        notify(src, 'No se pudo guardar la posicion anterior del jugador', 'error')
        return
    end

    SetEntityCoords(targetPed, plazaCoords.x, plazaCoords.y, plazaCoords.z)
    SetEntityHeading(targetPed, plazaCoords.w or 0.0)

    notify(src, ('Has enviado al jugador ID %d a la Plaza Central'):format(targetId), 'success')
    notify(targetId, 'Has sido enviado a la Plaza Central por un administrador', 'primary')
end)

AddEventHandler('playerDropped', function()
    local src = source
    bringBackPositions[src] = nil
    copiedCoordsByAdmin[src] = nil
end)
