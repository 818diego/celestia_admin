local QBCore = exports['qb-core']:GetCoreObject()
local isInAdminJail = false
local jailTask = nil
local originalModel = nil

local function loadModel(model)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end
    return true
end

RegisterNetEvent('celestia_admin:client:AdminJail', function(status, durationMs, reason)
    local playerPed = PlayerPedId()
    local config = Config.AdminCommands.Moderation.AdminJail
    local expiresAt = (durationMs and durationMs > 0) and (GetGameTimer() + durationMs) or 0
    
    isInAdminJail = status
    
    if isInAdminJail then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle ~= 0 then
            TaskLeaveVehicle(playerPed, vehicle, 16)
            Wait(1000)
        end

        originalModel = GetEntityModel(playerPed)
        
        local modelHash = GetHashKey(config.AnimalModel)
        if loadModel(config.AnimalModel) then
            SetPlayerModel(PlayerId(), modelHash)
            SetModelAsNoLongerNeeded(modelHash)
            Wait(50) -- Delay mínimo para regeneración
            playerPed = PlayerPedId()
            -- Forzar visibilidad y resetear componentes
            SetPedDefaultComponentVariation(playerPed)
            SetPedComponentVariation(playerPed, 0, 0, 0, 0)
            SetEntityVisible(playerPed, true)
            SetEntityAlpha(playerPed, 255, false)
            ResetEntityAlpha(playerPed)
        end
        
        SetEntityVisible(playerPed, true)
        SetEntityAlpha(playerPed, 255, false)
        ResetEntityAlpha(playerPed)
        SetLocalPlayerVisibleLocally(true) 
        SetEntityCoords(playerPed, config.Coords.x, config.Coords.y, config.Coords.z, false, false, false, true)
        SetEntityHeading(playerPed, config.Coords.w)
        SetEntityInvincible(playerPed, true)
        SetEntityProofs(playerPed, true, true, true, true, true, true, true, true)
        
        CreateThread(function()
            while isInAdminJail do
                local currentPed = PlayerPedId()
                local coords = GetEntityCoords(currentPed)
                local dist = #(coords - vector3(config.Coords.x, config.Coords.y, config.Coords.z))
                local timerText = "~r~ME HE PORTADO MAL :(~w~"
                if expiresAt > 0 then
                    local remaining = math.ceil((expiresAt - GetGameTimer()) / 1000)
                    if remaining <= 0 then
                        isInAdminJail = false
                        TriggerEvent('celestia_admin:client:AdminJail', false)
                        QBCore.Functions.Notify("Tu tiempo ha terminado", "success")
                        break
                    end
                    local mins = math.floor(remaining / 60)
                    local secs = remaining % 60
                    timerText = timerText .. string.format("\n~y~Tiempo restante:~w~ %02d:%02d", mins, secs)
                else
                    timerText = timerText .. "\n~y~Tiempo restante:~w~ PERMANENTE"
                end
                timerText = timerText .. "\n~y~Motivo:~w~ " .. reason

                SetTextScale(0.40, 0.40)
                SetTextFont(4)
                SetTextProportional(1)
                SetTextColour(255, 255, 255, 215)
                SetTextOutline()
                SetTextEntry("STRING")
                SetTextCentre(1)
                AddTextComponentString(timerText)
                DrawText(0.5, 0.90)

                if dist > config.Radius then
                    SetEntityCoords(currentPed, config.Coords.x, config.Coords.y, config.Coords.z, false, false, false, true)
                    QBCore.Functions.Notify("No puedes salir de la prisión administrativa", "error")
                end
                
                SetEntityVisible(currentPed, true)
                SetLocalPlayerVisibleLocally(true)
                ResetEntityAlpha(currentPed)
                
                DisableControlAction(0, 24, true) 
                DisableControlAction(0, 25, true) 
                DisablePlayerFiring(PlayerId(), true)
                Wait(0)
            end
        end)
    else
        local currentPed = PlayerPedId()
        SetEntityInvincible(currentPed, false)
        SetEntityProofs(currentPed, false, false, false, false, false, false, false, false)
        SetEntityVisible(currentPed, true)
        SetEntityAlpha(currentPed, 255, false)
        ResetEntityAlpha(currentPed)
        SetLocalPlayerVisibleLocally(true)        
        if originalModel then
            RequestModel(originalModel)
            while not HasModelLoaded(originalModel) do Wait(0) end
            SetPlayerModel(PlayerId(), originalModel)
            SetModelAsNoLongerNeeded(originalModel)
            TriggerServerEvent('qb-clothes:loadPlayerSkin') -- QBCore estándar
            TriggerEvent('qb-clothes:client:loadPlayerSkin') -- QBCore estándar
            TriggerEvent('illenium-appearance:client:reloadSkin') -- Illenium Appearance
            Wait(500)
            currentPed = PlayerPedId()
        end
        local plaza = Config.AdminCommands.Teleports.PlazaCoords
        if plaza then
            SetEntityCoords(currentPed, plaza.x, plaza.y, plaza.z, false, false, false, true)
            SetEntityHeading(currentPed, plaza.w or 0.0)
        end
        
        QBCore.Functions.Notify("Has sido liberado de la prisión administrativa", "success")
    end
end)
