RegisterNetEvent('celestia_admin:client:applyGodState', function(maxHealth, armor)
    local ped = PlayerPedId()

    maxHealth = tonumber(maxHealth) or 200
    armor = tonumber(armor) or 0

    SetEntityMaxHealth(ped, maxHealth)
    SetEntityHealth(ped, maxHealth)
    SetPedArmour(ped, armor)
    ClearPedBloodDamage(ped)
end)
