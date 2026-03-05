local QBCore = exports['qb-core']:GetCoreObject()
local disconnects = {}

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
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

RegisterNetEvent('celestia_admin:client:AddDisconnectLog', function(name, id, coords, reason)
    local config = Config.AdminCommands.DisconnectLogs
    local visibleTime = (config and config.VisibleTime or 60) * 1000
    
    table.insert(disconnects, {
        name = name,
        id = id,
        coords = coords,
        reason = reason,
        endTime = GetGameTimer() + visibleTime
    })
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local now = GetGameTimer()
        
        if #disconnects > 0 then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local config = Config.AdminCommands.DisconnectLogs
            local maxDistance = config and config.MaxDistance or 50.0
            
            sleep = 0
            for i = #disconnects, 1, -1 do
                local data = disconnects[i]
                if now > data.endTime then
                    table.remove(disconnects, i)
                else
                    local dist = #(playerCoords - data.coords)
                    if dist <= maxDistance then
                        local text = string.format("~r~[JUGADOR DESCONECTADO]~w~\n~y~ID:~w~ %d\n~y~Nombre:~w~ %s\n~y~Motivo:~w~ %s", 
                            data.id, data.name, data.reason)
                        DrawText3D(data.coords.x, data.coords.y, data.coords.z + 1.0, text)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
