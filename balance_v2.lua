modname = "Auto balance"
version = "0.2a"

function et_InitGame(levelTime,randomSeed,restart)
	et.RegisterModname(modname .. " " .. version)
end

-- Max diff pour les joueurs (laisser 2)
unevenDiff = 2

-- Max diff pour les bots (laisser 1 (permet de faire du 2v2 au lieu du 1v3))
unevenBotDiff = 1

-- Temps de check
max_unevenTime = 20

-- Max diff pour les joueurs (laisser 4)
max_unevenDiff = 4

axisPlayers = {}
alliedPlayers = {}
newPlayers = {}  -- Ajout de la table pour stocker les nouveaux arrivants
unevenTime = -1

function et_RunFrame(levelTime)
    local numAlliedPlayers = #alliedPlayers
    local numAxisPlayers = #axisPlayers

    -- Count the number of real players in each team
    local numAlliedRealPlayers = 0
    local numAxisRealPlayers = 0

    -- Count the number of bots in each team
    local numAlliedBots = 0
    local numAxisBots = 0

    local maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))

    for i = 0, maxClients - 1 do
        local team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
        local isBot = tonumber(et.gentity_get(i, "pers.localClient"))

        if team ~= nil and isBot ~= nil then
            if isBot == 0 then
                if team == 1 then
                    numAxisRealPlayers = numAxisRealPlayers + 1
                elseif team == 2 then
                    numAlliedRealPlayers = numAlliedRealPlayers + 1
                end
            elseif isBot == 1 then
                if team == 1 then
                    numAxisBots = numAxisBots + 1
                elseif team == 2 then
                    numAlliedBots = numAlliedBots + 1
                end
            end
        end
    end

    -- Check for uneven teams among new players
    if #newPlayers > 0 then
        for i, clientNum in ipairs(newPlayers) do
            local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))
            local isBot = tonumber(et.gentity_get(clientNum, "pers.localClient"))

            if isBot == 0 then
                if team == 1 and numAlliedRealPlayers >= (numAxisRealPlayers + unevenDiff) then
                    et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " r ; qsay Team balancing... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 moved to ^1AXIS")
                elseif team == 2 and numAxisRealPlayers >= (numAlliedRealPlayers + unevenDiff) then
                    et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " b ; qsay Team balancing... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 moved to ^4ALLIES")
                end
            end

            -- Remove the player from the newPlayers table
            table.remove(newPlayers, i)
        end
    end

    -- Balance teams based on real players
    if numAlliedRealPlayers >= (numAxisRealPlayers + unevenDiff) then
        local clientNum = alliedPlayers[numAlliedPlayers]
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " r ; qsay Team balancing... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 moved to ^1AXIS")
    elseif numAxisRealPlayers >= (numAlliedRealPlayers + unevenDiff) then
        local clientNum = axisPlayers[numAxisPlayers]
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " b ; qsay Team balancing... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 moved to ^4ALLIES")
    elseif numAlliedRealPlayers >= (numAxisRealPlayers + max_unevenDiff) then
        local clientNum = alliedPlayers[numAlliedPlayers]
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " r ; qsay Team balancing... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 moved to ^1AXIS")
    elseif numAxisRealPlayers >= (numAlliedRealPlayers + max_unevenDiff) then
        local clientNum = axisPlayers[numAxisPlayers]
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " b ; qsay Team balancing... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 moved to ^4ALLIES")
    else
        unevenTime = -1
    end

    -- Balance teams based on bots
    if numAlliedBots > numAxisBots + unevenBotDiff then
        local numBotsToMove = numAlliedBots - numAxisBots
        for i = 1, numBotsToMove do
            local botNum = findBotOnTeam(2)  -- Find a bot in the Allies team
            if botNum ~= nil then
                et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. botNum .. " r ; qsay Team balancing... " .. et.gentity_get(botNum, "pers.netname") .. "^7 moved to ^1AXIS")
            else
                break
            end
        end
    elseif numAxisBots > numAlliedBots + unevenBotDiff then
        local numBotsToMove = numAxisBots - numAlliedBots
        for i = 1, numBotsToMove do
            local botNum = findBotOnTeam(1)  -- Find a bot in the Axis team
            if botNum ~= nil then
                et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. botNum .. " b ; qsay Team balancing... " .. et.gentity_get(botNum, "pers.netname") .. "^7 moved to ^4ALLIES")
            else
                break
            end
        end
    end
end

function findBotOnTeam(team)
    local maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))

    for i = 0, maxClients - 1 do
        local teamNum = tonumber(et.gentity_get(i, "sess.sessionTeam"))
        local isBot = tonumber(et.gentity_get(i, "pers.localClient"))

        if teamNum == team and isBot == 1 then
            return i
        end
    end

    return nil
end

function et_ClientSpawn(clientNum, revived, teamChange, restoreHealth)
    if teamChange ~= 0 then
        local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))
        local isBot = tonumber(et.gentity_get(clientNum, "pers.localClient"))

        if isBot == 0 then
            local numAlliedPlayers = #alliedPlayers
            local numAxisPlayers = #axisPlayers

            if team == 1 then
                for i, num in ipairs(alliedPlayers) do
                    if num == clientNum then
                        table.remove(alliedPlayers, i)
                        break
                    end
                end

                if numAlliedPlayers >= numAxisPlayers + unevenDiff then
                    table.insert(axisPlayers, 1, clientNum)
                else
                    table.insert(axisPlayers, clientNum)
                end
            elseif team == 2 then
                for i, num in ipairs(axisPlayers) do
                    if num == clientNum then
                        table.remove(axisPlayers, i)
                        break
                    end
                end

                if numAxisPlayers >= numAlliedPlayers + unevenDiff then
                    table.insert(alliedPlayers, 1, clientNum)
                else
                    table.insert(alliedPlayers, clientNum)
                end
            end

        end
    end
end

function et_ClientConnect(clientNum,firstTime,isBot)
    -- Add the new player to the newPlayers table
    table.insert(newPlayers, clientNum)
end

function et_ClientDisconnect(clientNum)
    for i, num in ipairs(alliedPlayers) do
        if num == clientNum then
            table.remove(alliedPlayers, i)
            return
        end
    end
    for i, num in ipairs(axisPlayers) do
        if num == clientNum then
            table.remove(axisPlayers, i)
            return
        end
    end

    -- Remove the player from the newPlayers table
    table.remove(newPlayers, i)
end
