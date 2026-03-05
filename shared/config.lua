Config = {}

Config.MaxDistance = 50.0 -- Distancia maxima en metros para que el comando /wall muestre informacion de jugadores.
Config.BringBackTimeout = 5 -- Tiempo en minutos para devolver automaticamente a un jugador traido con /bring si no se usa /bringback.

Config.AdminCommands = {
    God = {
        MaxHealth = 200, -- Vida maxima que se aplica al jugador al usar /god.
        ArmorOnRevive = 0, -- Armadura que recibe el jugador al ser curado/revivido con /god.
    },
    GodArea = {
        MinRadius = 1.0, -- Radio minimo permitido (en metros) para ejecutar /godarea.
        MaxRadius = 9999999.0, -- Radio maximo permitido (en metros) para ejecutar /godarea.
    },
    Punishments = {
        BanTableName = 'celestia_admin_bans', -- Nombre de la tabla SQL donde se guardan los baneos.
        DefaultKickReason = 'Expulsado por administracion.', -- Razon por defecto para /kick si no se envia texto.
        DefaultBanReason = 'Baneado por administracion.' -- Razon por defecto para /ban si no se envia texto.
    },
    Moderation = {
        DefaultAdvReason = 'Conducta indebida.', -- Motivo por defecto para /adv si no se envia texto.
        DefaultMuteReason = 'Comportamiento inapropiado en chat/voz.', -- Motivo por defecto para /mute y /mutearea.
        DefaultMuteMinutes = 10, -- Duracion por defecto del mute en minutos si no se especifica.
        MinMuteMinutes = 1, -- Duracion minima permitida para un mute en minutos.
        MaxMuteMinutes = 240, -- Duracion maxima permitida para un mute en minutos.
        MuteAreaMinRadius = 1.0, -- Radio minimo permitido (en metros) para /mutearea.
        MuteAreaMaxRadius = 100.0 -- Radio maximo permitido (en metros) para /mutearea.
    },
    Vehicles = {
        DvAreaMinRadius = 1.0, -- Radio minimo permitido (en metros) para /dvarea.
        DvAreaMaxRadius = 150.0, -- Radio maximo permitido (en metros) para /dvarea.
        TuneRepairVehicle = true, -- Si esta en true, /tuning tambien repara el vehiculo.
        TunePowerMultiplier = 35.0, -- Multiplicador extra de potencia del motor al usar /tuning.
        TuneTorqueMultiplier = 25.0, -- Multiplicador extra de torque al usar /tuning.
        TuneTopSpeedIncrease = 35.0 -- Aumento adicional de velocidad final al usar /tuning.
    },
    Teleports = {
        PlazaCoords = vector4(156.76, -994.3, 29.35, 254.96), -- Coordenadas de la plaza central (Legion Square por defecto)
    }
}

