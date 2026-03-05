local playerRoles = {}

local function GetDiscordId(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(id, 1, 8) == "discord:" then
            return string.sub(id, 9)
        end
    end
    return nil
end

local function FetchPlayerRoles(source)
    local discordId = GetDiscordId(source)
    if not discordId then return end

    local guildId = Config.Discord.GuildId
    local botToken = Config.Discord.BotToken

    if guildId == "" or botToken == "" then
        print("^1[celestia_admin] ERROR: BotToken o GuildId no configurados en discord.lua^7")
        return
    end
    local endpoint = ("https://discord.com/api/v10/guilds/%s/members/%s"):format(guildId, discordId)
    PerformHttpRequest(endpoint, function(status, result, headers)
        if status == 200 then
            local data = json.decode(result)
            if data and data.roles then
                playerRoles[source] = data.roles
            end
            print(json.encode(data.roles))
        else
            print(("^1[celestia_admin] ERROR: No se pudieron obtener roles para %s (Status: %s)^7"):format(GetPlayerName(source), status))
        end
    end, "GET", "", {["Content-Type"] = "application/json", ["Authorization"] = "Bot " .. botToken})
end

AddEventHandler('playerJoining', function()
    local src = source
    FetchPlayerRoles(src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    playerRoles[src] = nil
end)

RegisterNetEvent('celestia_admin:server:refreshRoles', function()
    FetchPlayerRoles(source)
end)

function HasDiscordRole(source, roleKey)
    if source == 0 then return true end
    
    local roles = playerRoles[source]
    if not roles then 
        FetchPlayerRoles(source)
        return false 
    end

    local targetRoleId = Config.Discord.Roles[roleKey]
    if not targetRoleId or targetRoleId == "ID_AQUÍ" then return false end

    for _, playerRoleId in ipairs(roles) do
        if playerRoleId == targetRoleId then
            print(("^2[celestia_admin] El jugador %s tiene el rol de Discord: %s (%s)^7"):format(GetPlayerName(source), roleKey, targetRoleId))
            return true
        end
    end

    print(("^1[celestia_admin] El jugador %s NO tiene el rol de Discord: %s (%s)^7"):format(GetPlayerName(source), roleKey, targetRoleId))
    return false
end

function IsStaff(source)
    if source == 0 then return true end
    local roles = playerRoles[source]
    if not roles then 
        FetchPlayerRoles(source)
        return false 
    end
    for _, targetRoleId in pairs(Config.Discord.Roles) do
        if targetRoleId ~= "ID_AQUÍ" then
            for _, playerRoleId in ipairs(roles) do
                if playerRoleId == targetRoleId then
                    return true
                end
            end
        end
    end
    return false
end

exports('IsStaff', IsStaff)
exports('HasDiscordRole', HasDiscordRole)
