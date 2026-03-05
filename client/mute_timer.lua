local isMuted = false
local muteExpiresAt = 0
local muteReason = ""

RegisterNetEvent('celestia_admin:client:SetMuteStatus', function(status, expiresAt, reason)
    isMuted = status
    muteExpiresAt = expiresAt or 0
    muteReason = reason or ""
end)

local function DrawMuteUI(minutes, seconds, reason)
    local x, y = 0.5, 0.92
    local width, height = 0.18, 0.07
    DrawRect(x, y, width, height, 15, 15, 15, 230)
    DrawRect(x, y - height/2, width, 0.003, 220, 53, 69, 255)
    SetTextFont(4)
    SetTextScale(0.32, 0.32)
    SetTextColour(220, 53, 69, 255)
    SetTextJustification(0)
    SetTextCentre(true)
    SetTextProportional(true)
    BeginTextCommandDisplayText("STRING")
    SetTextFont(4)
    SetTextScale(0.32, 0.32)
    SetTextColour(220, 53, 69, 255)
    SetTextJustification(0)
    SetTextCentre(true)
    SetTextProportional(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName("SIN ACCESO A VOZ")
    EndTextCommandDisplayText(x, y - 0.03)
    SetTextFont(4)
    SetTextScale(0.55, 0.55)
    SetTextColour(255, 255, 255, 255)
    SetTextJustification(0)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(string.format("%02d:%02d", minutes, seconds))
    EndTextCommandDisplayText(x, y - 0.012)
    
    -- Motivo del mute
    if reason and reason ~= "" then
        SetTextFont(0)
        SetTextScale(0.24, 0.24)
        SetTextColour(180, 180, 180, 255)
        SetTextJustification(0)
        SetTextCentre(true)
        BeginTextCommandDisplayText("STRING")
        local displayReason = reason
        if #displayReason > 40 then
            displayReason = string.sub(displayReason, 1, 37) .. "..."
        end
        AddTextComponentSubstringPlayerName("MOTIVO: " .. displayReason:upper())
        EndTextCommandDisplayText(x, y + 0.018)
    end
end

CreateThread(function()
    while true do
        if isMuted then
            local now = GetCloudTimeAsInt()
            local remaining = muteExpiresAt - now

            if remaining > 0 then
                local minutes = math.floor(remaining / 60)
                local seconds = remaining % 60
                
                DrawMuteUI(minutes, seconds, muteReason)
                Wait(0)
            else
                isMuted = false
                Wait(1000)
            end
        else
            Wait(1000) -- Ahorrar recursos si no está muteado
        end
    end
end)
