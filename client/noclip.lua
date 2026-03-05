local QBCore = exports['qb-core']:GetCoreObject()
local noclipEnabled = false
local ent = nil
local noclipCam = nil
local speed = 1.0
local minY, maxY = -89.0, 89.0
local inputRotEnabled = false
local disableControls = { 32, 33, 34, 35, 12, 13, 14, 15, 16, 17, 51, 52, 85, 86, 249 }

local function checkInputRotation()
    Citizen.CreateThread(function()
        while inputRotEnabled do
            while not noclipCam or IsPauseMenuActive() do Wait(0) end
            local axisX = GetDisabledControlNormal(0, 1)
            local axisY = GetDisabledControlNormal(0, 2)
            local sensitivity = GetProfileSetting(14) * 2
            if GetProfileSetting(15) == 0 then
                sensitivity = -sensitivity
            end
            if math.abs(axisX) > 0 or math.abs(axisY) > 0 then
                local rotation = GetCamRot(noclipCam, 2)
                local rotz = rotation.z + (axisX * sensitivity)
                local yValue = axisY * sensitivity
                local rotx = rotation.x
                if rotx + yValue > minY and rotx + yValue < maxY then
                    rotx = rotation.x + yValue
                end
                SetCamRot(noclipCam, rotx, rotation.y, rotz, 2)
                local newHeading = (360 + rotz) % 360
                local playerPed = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                if vehicle ~= 0 then
                    SetEntityHeading(vehicle, newHeading)
                    SetEntityHeading(playerPed, newHeading)
                else
                    SetEntityHeading(playerPed, newHeading)
                end
            end
            Wait(0)
        end
    end)
end

local function toggleNoclip()
    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local inVehicle = vehicle ~= 0

        if inVehicle then
            ent = vehicle
        else
            ent = playerPed
        end

        DoScreenFadeOut(200)
        Wait(200)

        local pos = GetEntityCoords(ent)
        local rot = GetEntityRotation(ent)
        noclipCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos.x, pos.y, pos.z, 0.0, 0.0, rot.z, 75.0, true, 2)
        AttachCamToEntity(noclipCam, ent, 0.0, 0.0, 0.0, true)
        RenderScriptCams(true, false, 3000, true, false)
        
        FreezeEntityPosition(ent, true)
        SetEntityCollision(ent, false, false)
        SetEntityAlpha(ent, 0, false)
        SetPedCanRagdoll(playerPed, false)
        SetEntityVisible(ent, false, false)

        if not inVehicle then
            ClearPedTasksImmediately(playerPed)
        else
            FreezeEntityPosition(playerPed, true)
            SetEntityCollision(playerPed, false, false)
            SetEntityAlpha(playerPed, 0, false)
            SetEntityVisible(playerPed, false, false)
        end

        DoScreenFadeIn(200)
        
        while noclipEnabled do
            Wait(0)
            local _, fv = GetCamMatrix(noclipCam)
            local multiplier = 1.0

            if IsControlPressed(2, 21) then -- SHIFT (Rápido)
                multiplier = 4.0
            elseif IsControlPressed(2, 19) then -- ALT (Lento)
                multiplier = 0.25
            end

            -- Movimiento W/S
            if IsDisabledControlPressed(2, 32) then -- W
                local setPos = GetEntityCoords(ent) + fv * (speed * multiplier)
                SetEntityCoordsNoOffset(ent, setPos.x, setPos.y, setPos.z, false, false, false)
                if not inVehicle then
                    SetEntityCoordsNoOffset(playerPed, setPos.x, setPos.y, setPos.z, false, false, false)
                end
            elseif IsDisabledControlPressed(2, 33) then -- S
                local setPos = GetEntityCoords(ent) - fv * (speed * multiplier)
                SetEntityCoordsNoOffset(ent, setPos.x, setPos.y, setPos.z, false, false, false)
                if not inVehicle then
                    SetEntityCoordsNoOffset(playerPed, setPos.x, setPos.y, setPos.z, false, false, false)
                end
            end

            -- Movimiento A/D
            if IsDisabledControlPressed(2, 34) then -- A
                local setPos = GetOffsetFromEntityInWorldCoords(ent, -speed * multiplier, 0.0, 0.0)
                SetEntityCoordsNoOffset(ent, setPos.x, setPos.y, setPos.z, false, false, false)
                if not inVehicle then
                    SetEntityCoordsNoOffset(playerPed, setPos.x, setPos.y, setPos.z, false, false, false)
                end
            elseif IsDisabledControlPressed(2, 35) then -- D
                local setPos = GetOffsetFromEntityInWorldCoords(ent, speed * multiplier, 0.0, 0.0)
                SetEntityCoordsNoOffset(ent, setPos.x, setPos.y, setPos.z, false, false, false)
                if not inVehicle then
                    SetEntityCoordsNoOffset(playerPed, setPos.x, setPos.y, setPos.z, false, false, false)
                end
            end

            -- Subir/Bajar (E / Q)
            if IsDisabledControlPressed(2, 38) then -- E
                local setPos = GetOffsetFromEntityInWorldCoords(ent, 0.0, 0.0, multiplier * speed)
                SetEntityCoordsNoOffset(ent, setPos.x, setPos.y, setPos.z, false, false, false)
                if not inVehicle then
                    SetEntityCoordsNoOffset(playerPed, setPos.x, setPos.y, setPos.z, false, false, false)
                end
            elseif IsDisabledControlPressed(2, 44) then -- Q
                local setPos = GetOffsetFromEntityInWorldCoords(ent, 0.0, 0.0, multiplier * -speed)
                SetEntityCoordsNoOffset(ent, setPos.x, setPos.y, setPos.z, false, false, false)
                if not inVehicle then
                    SetEntityCoordsNoOffset(playerPed, setPos.x, setPos.y, setPos.z, false, false, false)
                end
            end

            local camRot = GetCamRot(noclipCam, 2)
            local newHeading = (360 + camRot.z) % 360
            SetEntityHeading(ent, newHeading)
            SetEntityHeading(playerPed, newHeading)
            SetEntityRotation(playerPed, 0.0, 0.0, newHeading, 2, true)

            SetEntityVisible(ent, false, false)
            if inVehicle then SetEntityVisible(playerPed, false, false) end

            for i = 1, #disableControls do
                DisableControlAction(2, disableControls[i], true)
            end
            DisablePlayerFiring(PlayerId(), true)
        end

        DoScreenFadeOut(200)
        Wait(200)

        DestroyCam(noclipCam, false)
        noclipCam = nil
        RenderScriptCams(false, false, 3000, true, false)

        local currentPos = GetEntityCoords(ent)
        local groundZ = 0.0
        local foundGround, groundCoords = GetGroundZFor_3dCoord(currentPos.x, currentPos.y, currentPos.z, false)
        if foundGround then
            groundZ = groundCoords
        else
            local raycast = StartExpensiveSynchronousShapeTestLosProbe(currentPos.x, currentPos.y, currentPos.z, currentPos.x, currentPos.y, currentPos.z - 1000.0, 1, ent, 0)
            local _, hit, endCoords = GetShapeTestResult(raycast)
            groundZ = hit and endCoords.z or currentPos.z
        end

        local groundPosition = vector3(currentPos.x, currentPos.y, groundZ)
        FreezeEntityPosition(ent, false)
        SetEntityCollision(ent, true, true)
        ResetEntityAlpha(ent)
        SetPedCanRagdoll(playerPed, true)
        SetEntityVisible(ent, true, false)
        ClearPedTasksImmediately(playerPed)

        if inVehicle then
            FreezeEntityPosition(playerPed, false)
            SetEntityCollision(playerPed, true, true)
            ResetEntityAlpha(playerPed)
            SetEntityVisible(playerPed, true, false)
            SetEntityCoordsNoOffset(ent, groundPosition.x, groundPosition.y, groundPosition.z, false, false, false)
            SetPedIntoVehicle(playerPed, ent, -1)
        else
            SetEntityCoordsNoOffset(playerPed, groundPosition.x, groundPosition.y, groundPosition.z, false, false, false)
        end

        DoScreenFadeIn(200)
    end)
end

function toggleNoClipMode(forceMode)
    if forceMode ~= nil then
        noclipEnabled = forceMode
    else
        noclipEnabled = not noclipEnabled
    end
    inputRotEnabled = noclipEnabled
    
    if noclipEnabled then
        toggleNoclip()
        checkInputRotation()
    end
end

RegisterNetEvent('celestia_admin:client:toggleNoClip', function()
    toggleNoClipMode()
end)

