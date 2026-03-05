local QBCore = exports['qb-core']:GetCoreObject()

local function hasAdminRole(source)
    return HasDiscordRole(source, 'admin')
end

local function notify(source, message, msgType)
    TriggerClientEvent('QBCore:Notify', source, message, msgType or 'primary')
end

local function getPunishmentConfig()
    local defaults = {
        BanTableName = 'celestia_admin_bans',
        DefaultKickReason = 'Expulsado por administracion.',
        DefaultBanReason = 'Baneado por administracion.'
    }

    local punishments = Config.AdminCommands and Config.AdminCommands.Punishments
    if not punishments then
        return defaults
    end

    defaults.BanTableName = punishments.BanTableName or defaults.BanTableName
    defaults.DefaultKickReason = punishments.DefaultKickReason or defaults.DefaultKickReason
    defaults.DefaultBanReason = punishments.DefaultBanReason or defaults.DefaultBanReason

    return defaults
end

local function getPreferredIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    local priority = { 'license:', 'license2:', 'discord:', 'fivem:', 'xbl:', 'live:' }

    for _, prefix in ipairs(priority) do
        for _, identifier in ipairs(identifiers) do
            if identifier:sub(1, #prefix) == prefix then
                return identifier
            end
        end
    end

    return identifiers[1]
end

local function getSourceName(source)
    if source == 0 then
        return 'Console'
    end

    local name = GetPlayerName(source)
    if name and name ~= '' then
        return name
    end

    return ('ID %s'):format(source)
end

local function getActiveBanByIdentifier(identifier)
    local tableName = getPunishmentConfig().BanTableName
    local sql = ('SELECT id, reason, banned_by_name, banned_at FROM `%s` WHERE identifier = ? AND active = 1 LIMIT 1'):format(tableName)
    return MySQL.single.await(sql, { identifier })
end

local function addBan(identifier, playerName, reason, adminIdentifier, adminName)
    local tableName = getPunishmentConfig().BanTableName
    local sql = ([[
        INSERT INTO `%s` (`identifier`, `player_name`, `reason`, `banned_by_identifier`, `banned_by_name`, `active`)
        VALUES (?, ?, ?, ?, ?, 1)
    ]]):format(tableName)

    return MySQL.insert.await(sql, { identifier, playerName, reason, adminIdentifier, adminName })
end

local function deactivateBanById(banId, adminIdentifier, adminName)
    local tableName = getPunishmentConfig().BanTableName
    local sql = ([[
        UPDATE `%s`
        SET `active` = 0,
            `unbanned_by_identifier` = ?,
            `unbanned_by_name` = ?,
            `unbanned_at` = CURRENT_TIMESTAMP
        WHERE `id` = ? AND `active` = 1
    ]]):format(tableName)

    return MySQL.update.await(sql, { adminIdentifier, adminName, banId })
end

local function deactivateBanByIdentifier(identifier, adminIdentifier, adminName)
    local tableName = getPunishmentConfig().BanTableName
    local sql = ([[
        UPDATE `%s`
        SET `active` = 0,
            `unbanned_by_identifier` = ?,
            `unbanned_by_name` = ?,
            `unbanned_at` = CURRENT_TIMESTAMP
        WHERE `identifier` = ? AND `active` = 1
    ]]):format(tableName)

    return MySQL.update.await(sql, { adminIdentifier, adminName, identifier })
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    deferrals.defer()

    local src = source
    local identifier = getPreferredIdentifier(src)

    if not identifier then
        deferrals.done('No se pudo validar tu identificador. Contacta a un administrador.')
        return
    end

    local activeBan = getActiveBanByIdentifier(identifier)
    if activeBan then
        local message = ('Estas baneado del servidor.\nBan ID: %s\nRazon: %s\nAdmin: %s'):format(
            activeBan.id,
            activeBan.reason,
            activeBan.banned_by_name
        )
        deferrals.done(message)
        return
    end

    deferrals.done()
end)

QBCore.Commands.Add('kick', 'Expulsar a un jugador. Uso: /kick [id] [razon] (Solo Admin Discord)', {
    { name = 'id', help = 'ID del jugador objetivo. Ejemplo: /kick 12 Troll' },
    { name = 'razon', help = 'Razon opcional del kick.' }
}, true, function(source, args)
    local src = source
    if not hasAdminRole(src) then
        notify(src, 'No tienes permisos para usar /kick', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, 'Debes indicar un ID valido. Ejemplo: /kick 12 Troll', 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(src, 'Jugador no encontrado', 'error')
        return
    end

    local cfg = getPunishmentConfig()
    local reason = table.concat(args, ' ', 2)
    if reason == '' then
        reason = cfg.DefaultKickReason
    end

    local adminName = getSourceName(src)
    local targetName = getSourceName(targetId)

    DropPlayer(targetId, ('Has sido expulsado del servidor.\nRazon: %s\nAdmin: %s'):format(reason, adminName))
    notify(src, ('Jugador expulsado: %s (ID %s) | Razon: %s'):format(targetName, targetId, reason), 'success')
end)

QBCore.Commands.Add('ban', 'Banear a un jugador. Uso: /ban [id] [razon] (Solo Admin Discord)', {
    { name = 'id', help = 'ID del jugador objetivo. Ejemplo: /ban 12 Uso de cheats' },
    { name = 'razon', help = 'Razon opcional del ban.' }
}, true, function(source, args)
    local src = source
    if not hasAdminRole(src) then
        notify(src, 'No tienes permisos para usar /ban', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, 'Debes indicar un ID valido. Ejemplo: /ban 12 Uso de cheats', 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        notify(src, 'Jugador no encontrado', 'error')
        return
    end

    local targetIdentifier = getPreferredIdentifier(targetId)
    if not targetIdentifier then
        notify(src, 'No se pudo obtener un identificador del jugador objetivo', 'error')
        return
    end

    local existingBan = getActiveBanByIdentifier(targetIdentifier)
    if existingBan then
        notify(src, ('Ese jugador ya esta baneado. Ban ID: %s'):format(existingBan.id), 'error')
        return
    end

    local cfg = getPunishmentConfig()
    local reason = table.concat(args, ' ', 2)
    if reason == '' then
        reason = cfg.DefaultBanReason
    end

    local adminIdentifier = getPreferredIdentifier(src) or 'console'
    local adminName = getSourceName(src)
    local targetName = getSourceName(targetId)

    local banId = addBan(targetIdentifier, targetName, reason, adminIdentifier, adminName)
    if not banId then
        notify(src, 'No se pudo registrar el ban en la base de datos', 'error')
        return
    end

    DropPlayer(targetId, ('Has sido baneado del servidor.\nBan ID: %s\nRazon: %s\nAdmin: %s'):format(banId, reason, adminName))
    notify(src, ('Jugador baneado: %s (ID %s) | Ban ID: %s'):format(targetName, targetId, banId), 'success')
end)

QBCore.Commands.Add('unban', 'Desbanear por Ban ID o identificador. Uso: /unban [banId|identifier] (Solo Admin Discord)', {
    { name = 'banId_o_identifier', help = 'Ejemplo: /unban 15 o /unban license:xxxx' }
}, true, function(source, args)
    local src = source
    if not hasAdminRole(src) then
        notify(src, 'No tienes permisos para usar /unban', 'error')
        return
    end

    local token = args[1]
    if not token or token == '' then
        notify(src, 'Debes indicar un Ban ID o un identificador. Ejemplo: /unban 15', 'error')
        return
    end

    local adminIdentifier = getPreferredIdentifier(src) or 'console'
    local adminName = getSourceName(src)
    local affectedRows

    local banId = tonumber(token)
    if banId then
        affectedRows = deactivateBanById(banId, adminIdentifier, adminName)
    else
        affectedRows = deactivateBanByIdentifier(token, adminIdentifier, adminName)
    end

    if not affectedRows or affectedRows < 1 then
        notify(src, 'No se encontro un ban activo con ese dato', 'error')
        return
    end

    notify(src, ('Unban aplicado correctamente. Registros actualizados: %s'):format(affectedRows), 'success')
end)
