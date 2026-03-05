local QBCore = exports['qb-core']:GetCoreObject()

local pendingDvAreaRequests = {}
local pendingTuneRequests = {}

local function notify(source, message, msgType)
    TriggerClientEvent('QBCore:Notify', source, message, msgType or 'primary')
end

local function getVehicleConfig()
    local defaults = {
        DvAreaMinRadius = 1.0,
        DvAreaMaxRadius = 150.0,
        DvAreaIgnoreOccupied = true,
        TuneRepairVehicle = true,
        TunePowerMultiplier = 35.0,
        TuneTorqueMultiplier = 25.0,
        TuneTopSpeedIncrease = 35.0
    }

    local vehicleConfig = Config.AdminCommands and Config.AdminCommands.Vehicles
    if not vehicleConfig then
        return defaults
    end

    defaults.DvAreaMinRadius = vehicleConfig.DvAreaMinRadius or defaults.DvAreaMinRadius
    defaults.DvAreaMaxRadius = vehicleConfig.DvAreaMaxRadius or defaults.DvAreaMaxRadius
    if vehicleConfig.DvAreaIgnoreOccupied ~= nil then
        defaults.DvAreaIgnoreOccupied = vehicleConfig.DvAreaIgnoreOccupied
    end
    if vehicleConfig.TuneRepairVehicle ~= nil then
        defaults.TuneRepairVehicle = vehicleConfig.TuneRepairVehicle
    end
    defaults.TunePowerMultiplier = vehicleConfig.TunePowerMultiplier or defaults.TunePowerMultiplier
    defaults.TuneTorqueMultiplier = vehicleConfig.TuneTorqueMultiplier or defaults.TuneTorqueMultiplier
    defaults.TuneTopSpeedIncrease = vehicleConfig.TuneTopSpeedIncrease or defaults.TuneTopSpeedIncrease

    return defaults
end

RegisterNetEvent('celestia_admin:server:dvAreaResult', function(requestId, deletedCount)
    local src = source
    if pendingDvAreaRequests[src] ~= requestId then
        return
    end

    pendingDvAreaRequests[src] = nil
    deletedCount = tonumber(deletedCount) or 0

    if deletedCount <= 0 then
        notify(src, 'No se borraron vehiculos en el area indicada', 'error')
        return
    end

    notify(src, ('/dvarea completado: %s vehiculo(s) borrado(s)'):format(deletedCount), 'success')
end)

RegisterNetEvent('celestia_admin:server:tuningResult', function(requestId, ok, reason)
    local src = source
    if pendingTuneRequests[src] ~= requestId then
        return
    end

    pendingTuneRequests[src] = nil

    if not ok then
        notify(src, reason or 'No se pudo aplicar el tuning', 'error')
        return
    end

    notify(src, 'Tuning de rendimiento aplicado al maximo', 'success')
end)

QBCore.Commands.Add('dvarea', 'Borrar vehiculos dentro de un radio. Uso: /dvarea [metros] (Solo Admin Discord)', {
    { name = 'metros', help = 'Radio en metros. Ejemplo: /dvarea 30' }
}, true, function(source, args)
    if not CheckPermission(source, 'dvarea') then return end
    local src = source

    local radius = tonumber(args[1])
    local cfg = getVehicleConfig()

    if not radius then
        notify(src, 'Debes indicar un radio valido. Ejemplo: /dvarea 30', 'error')
        return
    end

    if radius < cfg.DvAreaMinRadius or radius > cfg.DvAreaMaxRadius then
        notify(src, ('El radio debe estar entre %.1f y %.1f metros'):format(cfg.DvAreaMinRadius, cfg.DvAreaMaxRadius), 'error')
        return
    end

    local requestId = ('dvarea:%s:%s'):format(src, os.time())
    pendingDvAreaRequests[src] = requestId

    TriggerClientEvent('celestia_admin:client:deleteVehiclesInArea', src, requestId, radius, cfg.DvAreaIgnoreOccupied)
end)

QBCore.Commands.Add('tuning', 'Tunear al maximo el vehiculo actual (rendimiento). Uso: /tuning (Solo Admin Discord)', {}, false, function(source)
    if not CheckPermission(source, 'tuning') then return end
    local src = source

    local cfg = getVehicleConfig()
    local requestId = ('tuning:%s:%s'):format(src, os.time())
    pendingTuneRequests[src] = requestId

    TriggerClientEvent(
        'celestia_admin:client:applyMaxPerformanceTune',
        src,
        requestId,
        cfg.TuneRepairVehicle,
        cfg.TunePowerMultiplier,
        cfg.TuneTorqueMultiplier,
        cfg.TuneTopSpeedIncrease
    )
end)

AddEventHandler('playerDropped', function()
    local src = source
    pendingDvAreaRequests[src] = nil
    pendingTuneRequests[src] = nil
end)
