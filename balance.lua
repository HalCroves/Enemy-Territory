unevenDiff = 2
max_unevenTime = 20
max_unevenDiff = 4

axisPlayers = {}
alliedPlayers = {}
unevenTime = -1

function et_RunFrame(levelTime)
    local numAlliedPlayers = #alliedPlayers
    local numAxisPlayers = #axisPlayers

    -- Compter le nombre de vrais joueurs dans chaque équipe
    local numAlliedBots = 0
    local numAxisBots = 0
    local maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))

    for i = 0, maxClients - 1 do
        local team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
        local isBot = tonumber(et.gentity_get(i, "pers.localClient"))

        if isBot == 0 then
            if team == 1 then
                numAxisBots = numAxisBots + 1
            elseif team == 2 then
                numAlliedBots = numAlliedBots + 1
            end
        end
    end

    et.G_Print("Resetting Uneven Time\n")
    et.G_Print("Num Allied Players: " .. numAlliedPlayers .. ", Num Axis Players: " .. numAxisPlayers .. "\n")
    et.G_Print("Num Allied Bots: " .. numAlliedBots .. ", Num Axis Bots: " .. numAxisBots .. "\n")

    if numAlliedPlayers >= (numAxisPlayers + numAxisBots + max_unevenDiff) then
        local clientNum = alliedPlayers[numAlliedPlayers]
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " r ; qsay équilibrage des équipes... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 déplacé vers ^1AXIS")
    elseif numAxisPlayers >= (numAlliedPlayers + numAlliedBots + max_unevenDiff) then
        local clientNum = axisPlayers[numAxisPlayers]
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " b ; qsay équilibrage des équipes... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 déplacé vers ^4ALLIES")
    elseif numAlliedPlayers >= (numAxisPlayers + numAxisBots + unevenDiff) then
        if unevenTime > 0 then
            if tonumber(levelTime) - unevenTime >= max_unevenTime * 1000 then
                local clientNum = alliedPlayers[numAlliedPlayers]
                et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " r ; qsay équilibrage des équipes... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 déplacé vers ^1AXIS")
            end
        else
            unevenTime = tonumber(levelTime)
        end
    elseif numAxisPlayers >= (numAlliedPlayers + numAlliedBots + unevenDiff) then
        if unevenTime > 0 then
            if tonumber(levelTime) - unevenTime >= max_unevenTime * 1000 then
                local clientNum = axisPlayers[numAxisPlayers]
                et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " b ; qsay équilibrage des équipes... " .. et.gentity_get(clientNum, "pers.netname") .. "^7 déplacé vers ^4ALLIES")
            end
        else
            unevenTime = tonumber(levelTime)
        end
    else
        et.G_Print("No Uneven Teams\n")
        unevenTime = -1
    end
end

function et_ClientSpawn(clientNum, revived, teamChange, restoreHealth)
    if teamChange ~= 0 then
        local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))
        local isBot = tonumber(et.gentity_get(clientNum, "pers.localClient"))

        et.G_Print("Player Spawned - Client: " .. clientNum .. ", Team: " .. team .. ", IsBot: " .. isBot .. "\n")

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

                for i, num in ipairs(axisPlayers) do
                    if num == clientNum then
                        return
                    end
                end

                if numAlliedPlayers >= numAxisPlayers + unevenDiff then
                    et.G_Print("Adding Player to Axis\n")
                    table.insert(axisPlayers, 1, clientNum)
                else
                    et.G_Print("Adding Player to Axis\n")
                    table.insert(axisPlayers, clientNum)
                end
            elseif team == 2 then
                for i, num in ipairs(axisPlayers) do
                    if num == clientNum then
                        table.remove(axisPlayers, i)
                        break
                    end
                end

                for i, num in ipairs(alliedPlayers) do
                    if num == clientNum then
                        return
                    end
                end

                if numAxisPlayers >= numAlliedPlayers + unevenDiff then
                    et.G_Print("Adding Player to Allied\n")
                    table.insert(alliedPlayers, 1, clientNum)
                else
                    et.G_Print("Adding Player to Allied\n")
                    table.insert(alliedPlayers, clientNum)
                end
            else
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
            end
        end
    end
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
end
