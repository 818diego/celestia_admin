local QBCore = exports['qb-core']:GetCoreObject()
local isFrozen = false

RegisterNetEvent('celestia_admin:client:ToggleFreeze', function(state)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    isFrozen = state
    
    if isFrozen then
        if vehicle ~= 0 then
            FreezeEntityPosition(vehicle, true)
        end
        FreezeEntityPosition(playerPed, true)
        CreateThread(function()
            while isFrozen do
                DisableControlAction(0, 32, true) -- W
                DisableControlAction(0, 33, true) -- S
                DisableControlAction(0, 34, true) -- A
                DisableControlAction(0, 35, true) -- D
                DisableControlAction(0, 71, true) -- Acelerador
                DisableControlAction(0, 72, true) -- Freno
                DisableControlAction(0, 24, true) -- Ataque
                DisableControlAction(0, 25, true) -- Apuntar
                DisableControlAction(0, 69, true) -- Saltar
                DisableControlAction(0, 22, true) -- Saltar (Ped)
                DisableControlAction(0, 140, true) -- Melee
                DisableControlAction(0, 141, true) -- Melee
                DisableControlAction(0, 142, true) -- Melee
                DisableControlAction(0, 257, true) -- Disparo
                DisableControlAction(0, 263, true) -- Disparo
                DisableControlAction(0, 264, true) -- Disparo
                if vehicle ~= 0 then
                    SetVehicleEngineOn(vehicle, false, true, true)
                end
                
                Wait(0)
            end
        end)
    else
        if vehicle ~= 0 then
            FreezeEntityPosition(vehicle, false)
        end
        FreezeEntityPosition(playerPed, false)
    end
end)
