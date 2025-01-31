modname = "Auto balance"
version = "0.3a"

function et_InitGame(levelTime,randomSeed,restart)
	et.RegisterModname(modname .. " " .. version)
end

-- Nombre maximum de joueurs en plus qu'une équipe peut avoir avant équilibrage
-- Exemple : 3 signifie qu'on peut avoir du 3v1 avant que l'équilibrage automatique ne se déclenche
unevenDiff = 4

-- Nombre maximum de bots en plus qu'une équipe peut avoir avant équilibrage
-- Exemple : 2 signifie qu'on peut avoir du 3 bots contre 1 bot
unevenBotDiff = 3

-- Temps entre chaque vérification d'équilibrage en secondes
max_unevenTime = 20

-- Différence maximale absolue avant forçage d'équilibrage
-- Si la différence de joueurs dépasse cette valeur, un équilibrage forcé se produit immédiatement
max_unevenDiff = 7


--[[
Pour configurer un déséquilibre important (ex: 3 bots + 1 joueur vs 8 adversaires), on peux faire :
 - Augmenter unevenDiff (ex: unevenDiff = 4 ou plus) pour permettre plus de différence avant équilibrage.
 - Augmenter unevenBotDiff (ex: unevenBotDiff = 3) pour autoriser plus de bots d'un côté.
 - Augmenter max_unevenDiff (ex: max_unevenDiff = 7) pour encore plus de tolérance.
]]

axisPlayers = {}  -- Liste des joueurs dans l'équipe Axis
alliedPlayers = {}  -- Liste des joueurs dans l'équipe Allied
newPlayers = {}  -- Liste des nouveaux joueurs
unevenTime = -1  -- Timer de suivi pour l'équilibrage

function et_RunFrame(levelTime)
    -- Compter le nombre de joueurs et de bots dans chaque équipe
    local numAlliedPlayers, numAxisPlayers = #alliedPlayers, #axisPlayers
    local numAlliedRealPlayers, numAxisRealPlayers = 0, 0
    local numAlliedBots, numAxisBots = 0, 0
    local maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))

    for i = 0, maxClients - 1 do
        local team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
        local isBot = tonumber(et.gentity_get(i, "pers.localClient"))
        
        if team and isBot ~= nil then
            if isBot == 0 then  -- Joueur réel
                if team == 1 then numAxisRealPlayers = numAxisRealPlayers + 1
                elseif team == 2 then numAlliedRealPlayers = numAlliedRealPlayers + 1 end
            elseif isBot == 1 then  -- Bot
                if team == 1 then numAxisBots = numAxisBots + 1
                elseif team == 2 then numAlliedBots = numAlliedBots + 1 end
            end
        end
    end

    -- Équilibrer les joueurs réels si la différence dépasse la limite maximale
    if numAlliedRealPlayers >= (numAxisRealPlayers + max_unevenDiff) then
        balanceTeams(alliedPlayers, "r", "AXIS")
    elseif numAxisRealPlayers >= (numAlliedRealPlayers + max_unevenDiff) then
        balanceTeams(axisPlayers, "b", "ALLIES")
    end

    -- Équilibrer les bots si nécessaire
    if numAlliedBots > numAxisBots + unevenBotDiff then
        moveBots(2, "r", "AXIS")
    elseif numAxisBots > numAlliedBots + unevenBotDiff then
        moveBots(1, "b", "ALLIES")
    end
end

-- Fonction pour déplacer un joueur d'une équipe à l'autre en cas de déséquilibre
function balanceTeams(playerList, team, teamName)
    local clientNum = playerList[#playerList]  -- Dernier joueur ajouté à l'équipe
    if clientNum then
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " " .. team .. " ; qsay Team balancing... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 moved to ^1" .. teamName)
    end
end

-- Fonction pour déplacer un bot d'une équipe à l'autre en cas de déséquilibre
function moveBots(fromTeam, toTeam, teamName)
    local botNum = findBotOnTeam(fromTeam)
    if botNum then
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. botNum .. " " .. toTeam .. " ; qsay Team balancing... " .. et.gentity_get(botNum, "pers.netname") .. "^7 moved to ^1" .. teamName)
    end
end

-- Fonction pour trouver un bot dans une équipe spécifique
function findBotOnTeam(team)
    local maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
    for i = 0, maxClients - 1 do
        local teamNum = tonumber(et.gentity_get(i, "sess.sessionTeam"))
        local isBot = tonumber(et.gentity_get(i, "pers.localClient"))
        if teamNum == team and isBot == 1 then return i end
    end
    return nil
end
