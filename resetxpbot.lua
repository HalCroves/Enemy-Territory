local resetXPBots = false

-- Fonction pour vérifier si le match est en cours
local function isGameInProgress()
    local gameState = et.trap_Cvar_Get("gamestate")
    return gameState == "0" or gameState == "" or gameState == "3" -- 0 pour "GAME_STATE_PLAYING", 3 pour "GAME_STATE_POSTGAME"
end

function et_ClientBegin(clientNum)
    if not resetXPBots and not isGameInProgress() then
        local maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
        
        for i = 0, maxClients - 1 do
            if tonumber(et.gentity_get(i, "pers.localClient")) == 1 then
                et.trap_SendConsoleCommand(et.EXEC_APPEND, "!resetxp " .. i .. ";")
            end
        end
        resetXPBots = true
    end
end
