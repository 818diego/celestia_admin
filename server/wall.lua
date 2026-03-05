local QBCore = exports['qb-core']:GetCoreObject()
local playerWallStates = {} 
local playerCache = {}      

local function getDiscord(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(id, 1, 8) == "discord:" then
            return id
        end
    end
    return "No encontrado"
end

local function updatePlayerCache(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        playerCache[src] = {
            discord = getDiscord(src),
            group = Player.PlayerData.group or "user",
            wallActive = playerWallStates[src] or false,
            charName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            job = Player.PlayerData.job.label .. " (" .. Player.PlayerData.job.grade.level .. ")",
            cash = Player.PlayerData.money['cash'],
            bank = Player.PlayerData.money['bank']
        }
    end
end

QBCore.Commands.Add('wall', 'Activar/Desactivar Wall (Staff)', {}, false, function(source, args)
    if not CheckPermission(source, 'wall') then return end
    playerWallStates[source] = not playerWallStates[source]
    if not playerCache[source] then updatePlayerCache(source) end
        playerCache[source].wallActive = playerWallStates[source]
        TriggerClientEvent('celestia_admin:client:toggleWall', source, playerWallStates[source])
        local msg = playerWallStates[source] and "Activado" or "Desactivado"
        TriggerClientEvent('QBCore:Notify', source, "Wall " .. msg, "success")
end)

RegisterNetEvent('celestia_admin:server:requestPlayersData', function()
    local src = source
    if not CheckPermission(src, 'wall') then return end
    local data = {}
    local players = QBCore.Functions.GetPlayers()
    for _, playerSrc in ipairs(players) do
        updatePlayerCache(playerSrc)
        local ped = GetPlayerPed(playerSrc)
        if DoesEntityExist(ped) then
            data[#data + 1] = {
                id = playerSrc,
                health = GetEntityHealth(ped) - 100,
                armor = GetPedArmour(ped),
                discord = playerCache[playerSrc].discord,
                group = playerCache[playerSrc].group,
                charName = playerCache[playerSrc].charName,
                job = playerCache[playerSrc].job,
                cash = playerCache[playerSrc].cash,
                bank = playerCache[playerSrc].bank,
                wallActive = playerCache[playerSrc].wallActive
            }
        end
    end
    TriggerClientEvent('celestia_admin:client:setPlayersData', src, data)
end)

AddEventHandler('playerDropped', function()
    local src = source
    playerWallStates[src] = nil
    playerCache[src] = nil
end)
