local QBCore = exports['qb-core']:GetCoreObject()
local isWallActive = false
local playersData = {}
local maxDistance = Config.MaxDistance or 50.0

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.40, 0.40)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        
        local textLen = #text
        for i = 1, textLen, 99 do
            AddTextComponentString(string.sub(text, i, i + 98))
        end
        
        DrawText(_x, _y)
    end
end

local function startWallThread()
    Citizen.CreateThread(function()
        while isWallActive do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, data in ipairs(playersData) do
                local serverId = tonumber(data.id)
                
                -- Omitimos al propio jugador local
                if serverId ~= GetPlayerServerId(PlayerId()) then
                    local targetPlayer = GetPlayerFromServerId(serverId)
                    
                    -- Solo procedemos si el jugador está en el rango de streaming (targetPlayer ~= -1)
                    if targetPlayer ~= -1 then
                        local targetPed = GetPlayerPed(targetPlayer)

                        if DoesEntityExist(targetPed) then
                            local targetCoords = GetEntityCoords(targetPed)
                            local distance = #(playerCoords - targetCoords)
                            
                            if distance <= maxDistance then
                        local groupLabel = string.format(" [~r~%s~w~]", data.group:gsub("^%l", string.upper))
                        local infoStr = string.format("[~r~%s~w~] %s (~y~%s~w~)%s [~r~HP: %d%%~w~] [~b~AP: %d%%~w~]", 
                            tostring(data.id), tostring(data.charName), tostring(data.job), groupLabel, math.floor(math.max(0, data.health)), math.floor(data.armor or 0))
                        local moneyStr = string.format("~g~Cash: $%d ~w~| ~b~Bank: $%d", 
                            math.floor(data.cash or 0), math.floor(data.bank or 0))
                                DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.2, infoStr)
                                DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.1, moneyStr)
                            end
                        end
                    end
                end
            end
            Citizen.Wait(0)
        end
    end)
end

RegisterNetEvent('celestia_admin:client:setPlayersData', function(data)
    if isWallActive then
        playersData = data
    end
end)

local function startDataUpdateThread()
    Citizen.CreateThread(function()
        while isWallActive do
            TriggerServerEvent('celestia_admin:server:requestPlayersData')
            Citizen.Wait(2000)
        end
    end)
end

RegisterNetEvent('celestia_admin:client:toggleWall', function(state)
    isWallActive = state
    if isWallActive then
        startWallThread()
        startDataUpdateThread()
    else
        playersData = {}
    end
end)
