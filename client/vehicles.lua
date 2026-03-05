local function requestControl(entity, maxAttempts)
    if not DoesEntityExist(entity) then
        return false
    end

    maxAttempts = maxAttempts or 20

    for _ = 1, maxAttempts do
        if NetworkHasControlOfEntity(entity) then
            return true
        end

        NetworkRequestControlOfEntity(entity)
        Wait(25)
    end

    return NetworkHasControlOfEntity(entity)
end

RegisterNetEvent('celestia_admin:client:deleteVehiclesInArea', function(requestId, radius, ignoreOccupied)
    local ped = PlayerPedId()
    local origin = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local deletedCount = 0

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if DoesEntityExist(vehicle) then
            local distance = #(origin - GetEntityCoords(vehicle))
            if distance <= radius then
                local shouldDelete = true

                if ignoreOccupied then
                    local driver = GetPedInVehicleSeat(vehicle, -1)
                    -- Keep vehicles driven by real players, but allow NPC-driven vehicles to be removed.
                    shouldDelete = (driver == 0) or (driver ~= 0 and not IsPedAPlayer(driver))
                end

                if shouldDelete and requestControl(vehicle, 25) then
                    SetEntityAsMissionEntity(vehicle, true, true)
                    DeleteVehicle(vehicle)

                    if not DoesEntityExist(vehicle) then
                        deletedCount = deletedCount + 1
                    end
                end
            end
        end
    end

    TriggerServerEvent('celestia_admin:server:dvAreaResult', requestId, deletedCount)
end)

RegisterNetEvent('celestia_admin:client:applyMaxPerformanceTune', function(requestId, repairVehicle, powerMultiplier, torqueMultiplier, topSpeedIncrease)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        TriggerServerEvent('celestia_admin:server:tuningResult', requestId, false, 'Debes estar dentro de un vehiculo para usar /tuning')
        return
    end

    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        TriggerServerEvent('celestia_admin:server:tuningResult', requestId, false, 'Debes ser el conductor para usar /tuning')
        return
    end

    if not requestControl(vehicle, 40) then
        TriggerServerEvent('celestia_admin:server:tuningResult', requestId, false, 'No se pudo tomar control del vehiculo')
        return
    end

    SetVehicleModKit(vehicle, 0)

    local maxEngine = GetNumVehicleMods(vehicle, 11) - 1
    local maxBrakes = GetNumVehicleMods(vehicle, 12) - 1
    local maxTransmission = GetNumVehicleMods(vehicle, 13) - 1
    local maxSuspension = GetNumVehicleMods(vehicle, 15) - 1
    local maxArmor = GetNumVehicleMods(vehicle, 16) - 1

    if maxEngine >= 0 then SetVehicleMod(vehicle, 11, maxEngine, false) end
    if maxBrakes >= 0 then SetVehicleMod(vehicle, 12, maxBrakes, false) end
    if maxTransmission >= 0 then SetVehicleMod(vehicle, 13, maxTransmission, false) end
    if maxSuspension >= 0 then SetVehicleMod(vehicle, 15, maxSuspension, false) end
    if maxArmor >= 0 then SetVehicleMod(vehicle, 16, maxArmor, false) end

    ToggleVehicleMod(vehicle, 18, true)
    ToggleVehicleMod(vehicle, 22, true)

    powerMultiplier = tonumber(powerMultiplier) or 35.0
    torqueMultiplier = tonumber(torqueMultiplier) or 25.0
    topSpeedIncrease = tonumber(topSpeedIncrease) or 35.0

    SetVehicleEnginePowerMultiplier(vehicle, powerMultiplier)
    SetVehicleEngineTorqueMultiplier(vehicle, torqueMultiplier)
    ModifyVehicleTopSpeed(vehicle, topSpeedIncrease)

    if repairVehicle then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
    end

    TriggerServerEvent('celestia_admin:server:tuningResult', requestId, true)
end)
