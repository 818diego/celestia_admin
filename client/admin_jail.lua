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

RegisterNetEvent('celestia_admin:client:AdminJail', function(status, expiresAt, reason)
    local playerPed = PlayerPedId()
    local config = Config.AdminCommands.Moderation.AdminJail
    
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
                if dist > config.Radius then
                    SetEntityCoords(currentPed, config.Coords.x, config.Coords.y, config.Coords.z, false, false, false, true)
                    QBCore.Functions.Notify("No puedes salir de la prisión administrativa", "error")
                end
                SetEntityVisible(currentPed, true)
                SetLocalPlayerVisibleLocally(true)
                ResetEntityAlpha(currentPed)
                if expiresAt > 0 and os.time() >= expiresAt then
                    isInAdminJail = false
                    TriggerEvent('celestia_admin:client:AdminJail', false) -- Auto-liberación
                    QBCore.Functions.Notify("Tu tiempo en la prisión administrativa ha terminado", "success")
                end
                DisableControlAction(0, 24, true) -- Attack
                DisableControlAction(0, 25, true) -- Aim
                DisablePlayerFiring(PlayerId(), true)
                Wait(500)
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
