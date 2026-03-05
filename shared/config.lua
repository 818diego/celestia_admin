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
    }
}

