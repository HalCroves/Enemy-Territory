local resetXPBot = true
local gameStarted = false

function et_InitGame(levelTime, randomSeed, restart)
    gameStarted = false
    et.G_Print("InitGame: Le jeu a été initialisé. En attente de début de la partie...\n")
end

function et_RunFrame(levelTime)
    -- Vérification si la partie a commencé
    local gamestate = tonumber(et.trap_Cvar_Get("gamestate"))

    if not gameStarted then
        if gamestate == 0 then
            gameStarted = true
			if resetXPBot == true then
            	resetBotsXP()
			end
        end
    end
end

function isBot(clientNum)
    -- Récupère le userinfo du client
    local userinfo = et.trap_GetUserinfo(clientNum)
    et.G_Print("isBot: Userinfo du client " .. clientNum .. ": " .. userinfo .. "\n")

    -- Recherche la chaîne "BOT" dans le champ "n_guid"
    local guid = string.match(userinfo, "\\n_guid\\([^\\]+)")

    if guid and string.find(guid, "BOT") then
        et.G_Print("isBot: Client " .. clientNum .. " est identifié comme un bot (GUID: " .. guid .. ").\n")
        return true
    else
        et.G_Print("isBot: Client " .. clientNum .. " n'est pas un bot (GUID: " .. tostring(guid) .. ").\n")
        return false
    end
end

function resetBotsXP()
    local maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))

    for i = 0, maxClients - 1 do
        -- Vérifie si identifié comme bot
        if isBot(i) then
            et.G_Print("resetBotsXP: Reset XP pour le bot avec l'ID: " .. i .. "\n")
            et.trap_SendConsoleCommand(et.EXEC_APPEND, "!resetxp " .. i .. "\n")
        end
    end
end
