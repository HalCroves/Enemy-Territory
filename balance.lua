modname = "balance"
version = "0.1"

function et_InitGame(levelTime, randomSeed, restart)
    et.RegisterModname(modname .. " " .. version)
end

unevenDiff = 2
maxUnevenTime = 30
maxUnevenDiff = 4

axisPlayers = {}
alliedPlayers = {}
unevenTime = -1

function et_RunFrame(levelTime)
    if math.mod(levelTime, 6000) ~= 0 then
        return
    end

    local numAlliedPlayers = #alliedPlayers
    local numAxisPlayers = #axisPlayers

    local function balanceTeams(clientNum, team, enemyTeam, messageColor, messageTeam)
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " " .. team)
        et.trap_SendServerCommand(-1, "chat \"balancing teams... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 moved to ^" .. messageColor .. messageTeam .. "\"")
    end

    if numAlliedPlayers >= numAxisPlayers + maxUnevenDiff then
        balanceTeams(alliedPlayers[numAlliedPlayers], "r", "1", "1", "AXIS")
    elseif numAxisPlayers >= numAlliedPlayers + maxUnevenDiff then
        balanceTeams(axisPlayers[numAxisPlayers], "b", "4", "4", "ALLIES")
    elseif numAlliedPlayers >= numAxisPlayers + unevenDiff then
        if unevenTime > 0 and tonumber(levelTime) - unevenTime >= maxUnevenTime * 1000 then
            balanceTeams(alliedPlayers[numAlliedPlayers], "r", "1", "1", "AXIS")
        elseif unevenTime <= 0 then
            unevenTime = tonumber(levelTime)
        end
    elseif numAxisPlayers >= numAlliedPlayers + unevenDiff then
        if unevenTime > 0 and tonumber(levelTime) - unevenTime >= maxUnevenTime * 1000 then
            balanceTeams(axisPlayers[numAxisPlayers], "b", "4", "4", "ALLIES")
        elseif unevenTime <= 0 then
            unevenTime = tonumber(levelTime)
        end
    else
        unevenTime = -1
    end
end

function et_ClientSpawn(clientNum, revived, teamChange, restoreHealth)
    if teamChange ~= 0 then
        local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))
        local numAlliedPlayers = #alliedPlayers
        local numAxisPlayers = #axisPlayers

        local function removePlayerFromList(playerList, clientNum)
            for i, num in ipairs(playerList) do
                if num == clientNum then
                    table.remove(playerList, i)
                    break
                end
            end
        end

        if team == 1 then
            removePlayerFromList(alliedPlayers, clientNum)
            if numAlliedPlayers >= numAxisPlayers + unevenDiff then
                table.insert(axisPlayers, 1, clientNum)
            else
                table.insert(axisPlayers, clientNum)
            end
        elseif team == 2 then
            removePlayerFromList(axisPlayers, clientNum)
            if numAxisPlayers >= numAlliedPlayers + unevenDiff then
                table.insert(alliedPlayers, 1, clientNum)
            else
                table.insert(alliedPlayers, clientNum)
            end
        else
            removePlayerFromList(alliedPlayers, clientNum)
            removePlayerFromList(axisPlayers, clientNum)
        end
    end
end

function et_ClientDisconnect(clientNum)
    for i, num in ipairs(alliedPlayers) do
        if num == clientNum then
            table.remove(alliedPlayers, i)
            break
        end
    end

    for i, num in ipairs(axisPlayers) do
        if num == clientNum then
            table.remove(axisPlayers, i)
            break
        end
    end
end
