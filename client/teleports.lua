local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('celestia_admin:client:teleportToWaypoint', function()
    local waypoint = GetFirstBlipInfoId(8)
    if DoesBlipExist(waypoint) then
        local waypointCoords = GetBlipInfoIdCoord(waypoint)
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local entity = vehicle ~= 0 and vehicle or playerPed
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
        SetEntityCoords(entity, waypointCoords.x, waypointCoords.y, 1000.0, false, false, false, true)
        FreezeEntityPosition(entity, true)
        Wait(500)
        local groundFound = false
        local groundZ = 0.0
        for i = 1000, 0, -25 do
            SetEntityCoordsNoOffset(entity, waypointCoords.x, waypointCoords.y, i + 0.0, false, false, false)
            Wait(0)
            local found, z = GetGroundZFor_3dCoord(waypointCoords.x, waypointCoords.y, i + 0.0, false)
            if found then
                groundZ = z
                groundFound = true
                break
            end
        end

        if not groundFound then
            local raycast = StartExpensiveSynchronousShapeTestLosProbe(waypointCoords.x, waypointCoords.y, 1000.0, waypointCoords.x, waypointCoords.y, 0.0, 1, entity, 0)
            local _, hit, endCoords = GetShapeTestResult(raycast)
            if hit then
                groundZ = endCoords.z
                groundFound = true
            end
        end

        SetEntityCoords(entity, waypointCoords.x, waypointCoords.y, groundZ + 1.0, false, false, false, true)
        FreezeEntityPosition(entity, false)

        if vehicle ~= 0 then
            SetVehicleOnGroundProperly(vehicle)
        end
        
        DoScreenFadeIn(500)
        QBCore.Functions.Notify("Teletransportado con éxito", "success")
    else
        QBCore.Functions.Notify("No tienes ningún punto marcado en el mapa", "error")
    end
end)
