local QBCore = exports['qb-core']:GetCoreObject()
local isSpectating = false
local spectateTarget = nil
local lastCoords = nil
local spectateCam = nil

local function ToggleSpectate(state, targetId, targetCoords)
    local playerPed = PlayerPedId()
    
    if state then
        isSpectating = true
        spectateTarget = targetId
        lastCoords = GetEntityCoords(playerPed)
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
        SetEntityCoords(playerPed, targetCoords.x, targetCoords.y, targetCoords.z - 20.0, false, false, false, false)
        SetEntityVisible(playerPed, false, false)
        SetEntityCollision(playerPed, false, false)
        SetEntityInvincible(playerPed, true)
        FreezeEntityPosition(playerPed, true)
        CreateThread(function()
            local adminPed = playerPed
            local retries = 50
            local targetPlayer = -1
            while isSpectating and retries > 0 do
                targetPlayer = GetPlayerFromServerId(spectateTarget)
                if targetPlayer ~= -1 and DoesEntityExist(GetPlayerPed(targetPlayer)) then
                    break
                end
                Wait(100)
                retries = retries - 1
            end

            if not isSpectating or retries <= 0 then
                isSpectating = false
                QBCore.Functions.Notify("No se pudo cargar al jugador para espectar", "error")
            else
                while isSpectating do
                    local targetPed = GetPlayerPed(GetPlayerFromServerId(spectateTarget))
                    
                    if DoesEntityExist(targetPed) then
                        local currentTargetCoords = GetEntityCoords(targetPed)
                        SetEntityCoords(adminPed, currentTargetCoords.x, currentTargetCoords.y, currentTargetCoords.z - 20.0, false, false, false, false)
                        
                        if not spectateCam then
                            spectateCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                            SetCamActive(spectateCam, true)
                            RenderScriptCams(true, false, 0, true, true)
                            DoScreenFadeIn(500)
                        end

                        AttachCamToEntity(spectateCam, targetPed, 0.0, -3.0, 1.0, true)
                        PointCamAtEntity(spectateCam, targetPed, 0.0, 0.0, 0.0, true)
                    else
                        isSpectating = false
                        QBCore.Functions.Notify("Objetivo perdido o fuera de rango", "error")
                    end
                    Wait(0)
                end
            end            
            if spectateCam then
                RenderScriptCams(false, false, 0, true, true)
                DestroyCam(spectateCam, false)
                spectateCam = nil
            end
            SetEntityCoords(adminPed, lastCoords.x, lastCoords.y, lastCoords.z, false, false, false, false)
            SetEntityVisible(adminPed, true, true)
            SetEntityCollision(adminPed, true, true)
            SetEntityInvincible(adminPed, false)
            FreezeEntityPosition(adminPed, false)
            DoScreenFadeIn(500)
        end)
    else
        isSpectating = false
    end
end

RegisterNetEvent('celestia_admin:client:ToggleSpectate', function(state, targetId, targetCoords)
    ToggleSpectate(state, targetId, targetCoords)
end)
