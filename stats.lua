-- Initialiser une table pour stocker les statistiques
local playerStats = {}

function et_InitGame(levelTime, randomSeed, restart)
    et.G_Print("Stat Tracking Loaded\n")
    et.RegisterModname("Stat Tracking")

    -- Configurer une minuterie pour afficher les statistiques toutes les 5 secondes
    et.trap_SendServerCommand(-1, "sv_cvar cg_chatStatsTimer 5000") -- Modifier la fréquence selon vos besoins
end

function et_ClientDisconnect(clientNum)
    -- Réinitialiser les statistiques du joueur lors de sa déconnexion
    playerStats[clientNum] = nil
end

function et_ClientCommand(clientNum, command)
    if command == "printstats" then
        et_PrintTopStatsToChat()
        return 1
    end

    return 0
end

function et_PrintTopStatsToChat()
    -- Trier les joueurs en fonction de chaque statistique, du plus élevé au plus bas, pour chaque statistique
    -- Field OPS
    local sortedPlayersFieldOpsAirstrike = sortPlayersByStat("fieldOpsAirstrike")
    local sortedPlayersfieldOpsAirstrikeSupport = sortPlayersByStat("fieldOpsAirstrikeSupport")
    
    -- Covert OPS
    local sortedPlayerscovertOpsk43Headshot = sortPlayersByStat("covertOpsk43Headshot")
    local sortedPlayerscovertOpsgarandHeadshot = sortPlayersByStat("covertOpsgarandHeadshot")
    local sortedPlayerscovertOpsK43 = sortPlayersByStat("covertOpsK43")
    local sortedPlayerscovertOpsGarand = sortPlayersByStat("covertOpsGarand")
    local sortedPlayerscovertOpsFG42 = sortPlayersByStat("covertOpsFG42")
    local sortedPlayerscovertOpsSatchel = sortPlayersByStat("covertOpsSatchel")
    local sortedPlayerscovertOpsAkimboColt = sortPlayersByStat("covertOpsAkimboColt")
    local sortedPlayerscovertOpsColt = sortPlayersByStat("covertOpsColt")
    local sortedPlayerscovertOpsAkimboLuger = sortPlayersByStat("covertOpsAkimboLuger")
    local sortedPlayerscovertOpsLuger = sortPlayersByStat("covertOpsLuger")
    local sortedPlayerscovertOpsSten = sortPlayersByStat("covertOpsSten")

    -- Normal Weapon
    local sortedPlayersMp40 = sortPlayersByStat("Mp40")
    local sortedPlayersThompson = sortPlayersByStat("Thompson")
    local sortedPlayersGrenade = sortPlayersByStat("Grenade")
    local sortedPlayersAkimboColt = sortPlayersByStat("AkimboColt")
    local sortedPlayersColt = sortPlayersByStat("Colt")
    local sortedPlayersAkimboLuger = sortPlayersByStat("AkimboLuger")
    local sortedPlayersLuger = sortPlayersByStat("Luger")
    local sortedPlayersKnife = sortPlayersByStat("Knife")
    local sortedPlayersThrowKnife = sortPlayersByStat("ThrowKnife")
    
    -- Soldier
    local sortedPlayerssoldierPanzer = sortPlayersByStat("soldierPanzer")
    local sortedPlayerssoldierFlameThrower = sortPlayersByStat("soldierFlameThrower")
    local sortedPlayerssoldierMG42 = sortPlayersByStat("soldierMG42")
    local sortedPlayerssoldierMortar = sortPlayersByStat("soldierMortar")

    -- Engeneer
    local sortedPlayersengineerK43Nade = sortPlayersByStat("engineerK43Nade")
    local sortedPlayersengineerK43 = sortPlayersByStat("engineerK43")  
    local sortedPlayersengineerM1GarandNade = sortPlayersByStat("engineerM1GarandNade")
    local sortedPlayersengineerM1Garand = sortPlayersByStat("engineerM1Garand")  
    local sortedPlayersengineerDynamite = sortPlayersByStat("engineerDynamite")
    local sortedPlayersengineerTripmine = sortPlayersByStat("engineerTripmine")
    local sortedPlayersengineerMine = sortPlayersByStat("engineerMine")

    -- Générer le tableau des statistiques
    local tableau = ""

    local statsTable = {
        {sortedPlayersFieldOpsAirstrike, "Airstrike"},
        {sortedPlayersfieldOpsAirstrikeSupport, "Airstrike Support"},
        {sortedPlayerscovertOpsk43Headshot, "K43 Headshot"},
        {sortedPlayerscovertOpsgarandHeadshot, "Garand Headshot"},
        {sortedPlayerscovertOpsK43, "K43"},
        {sortedPlayerscovertOpsGarand, "Garand"},
        {sortedPlayerscovertOpsSatchel, "Satchel"},
        {sortedPlayerscovertOpsFG42, "FG42"},
        {sortedPlayerscovertOpsAkimboColt, "Silenced Akimbo Colt"},   
        {sortedPlayerscovertOpsColt, "Silenced Colt"},
        {sortedPlayerscovertOpsAkimboLuger, "Silenced Akimbo Luger"},
        {sortedPlayerscovertOpsLuger, "Silenced Luger"},
        {sortedPlayerscovertOpsSten, "Sten"},
        {sortedPlayersMp40, "Mp40"},
        {sortedPlayersThompson, "Thompson"},
        {sortedPlayersGrenade, "Grenade"},
        {sortedPlayersAkimboColt, "Akimbo Colt"},
        {sortedPlayersColt, "Colt"},
        {sortedPlayersAkimboLuger, "Akimbo Luger"},
        {sortedPlayersLuger, "Luger"},
        {sortedPlayersKnife, "Knife"},
        {sortedPlayersThrowKnife, "Throw Knife"},
        {sortedPlayerssoldierPanzer, "Panzer"},
        {sortedPlayerssoldierFlameThrower, "FlameThrower"},
        {sortedPlayerssoldierMG42, "MG42"},
        {sortedPlayerssoldierMortar, "Mortar"},
        {sortedPlayersengineerK43Nade, "Riffle K43 Nade"},
        {sortedPlayersengineerK43, "Riffle K43"},
        {sortedPlayersengineerM1GarandNade, "Garand M1 Nade"},
        {sortedPlayersengineerM1Garand, "Garand M1 Nade"},
        {sortedPlayersengineerDynamite, "Dynamite"},
        {sortedPlayersengineerTripmine, "Tripmine"},
        {sortedPlayersengineerMine, "Mine"}
    }

    local displayHeaderFooter = false

    for _, statData in ipairs(statsTable) do
        if hasNonZeroValues(statData[1]) then
            if not displayHeaderFooter then
                tableau = tableau .. "----------------------------------------\n"
                tableau = tableau .. "^3Top Players ^2Stats^7:\n"
                displayHeaderFooter = true
            end
    
            local playerName, statValue = getPlayerStatText(statData[1])
            local killPlural = (statValue and statValue > 1) and "s" or ""  -- Condition pour déterminer "kill" ou "kills"
            tableau = tableau .. "^7 - " .. statData[2] .. " ^1->^7 " .. playerName .. " ^7(" .. statValue .. " Kill" .. killPlural .. ")\n"
        end
    end
    
    
    if displayHeaderFooter then
        tableau = tableau .. "----------------------------------------\n"
    else
        tableau = tableau .. "^1Il n'y a pas de statistiques pour le moment."
    end

    -- Afficher le tableau dans la console
    et.trap_SendServerCommand(-1, "print \"" .. tableau .. " \n\"")
    et_PrintHeadshotStats()
end

-- Fonction pour vérifier si au moins une statistique a une valeur différente de zéro
function hasNonZeroValues(sortedPlayers)
    for _, playerData in ipairs(sortedPlayers) do
        if playerData.statValue ~= 0 then
            return true
        end
    end
    return false
end

-- Fonction pour obtenir le texte de statistique d'un joueur
function getPlayerStatText(sortedPlayers)
    local maxPlayersToShow = 1
    local playerName = et.gentity_get(sortedPlayers[1].clientNum, "pers.netname")
    local statValue = sortedPlayers[1].statValue
    return playerName, statValue
end


function sortPlayersByStat(statName)
    -- Trier les joueurs en fonction d'une statistique particulière
    local sortedPlayers = {}
    for clientNum, stats in pairs(playerStats) do
        table.insert(sortedPlayers, {
            clientNum = clientNum,
            statValue = stats[statName] or 0
        })
    end

    table.sort(sortedPlayers, function(a, b)
        return a.statValue > b.statValue
    end)

    return sortedPlayers
end
--[[
function et.PrintTopPlayerForStat(sortedPlayers, maxPlayersToShow, statName)
    -- Afficher le top joueur pour une statistique particulière
    for i = 1, math.min(maxPlayersToShow, #sortedPlayers) do
        local clientNum = sortedPlayers[i].clientNum
        local playerName = et.gentity_get(clientNum, "pers.netname")
        local statValue = sortedPlayers[i].statValue

        -- Afficher chaque statistique séparément si la valeur est différente de 0
        if statValue ~= 0 then
            et.trap_SendServerCommand(-1, "chat \"" .. playerName .. " " .. statName .. ": " .. statValue .. "\"")
        end
    end
end

function et_RunFrame(levelTime)
    -- Vérifier la minuterie pour afficher les statistiques toutes les 5 secondes
    local currentTime = et.trap_Milliseconds()

    if not lastStatsPrintTime then
        lastStatsPrintTime = currentTime
    end

    if currentTime - lastStatsPrintTime >= 5000 then
        et_PrintTopStatsToChat()
        lastStatsPrintTime = currentTime
    end
end
]]

function et_ClientSpawn(clientNum, revived, teamChange, restoreHealth)
    -- Initialiser les statistiques du joueur lors de son spawn
    if not playerStats[clientNum] then
        playerStats[clientNum] = {
            --Field OPS
            fieldOpsAirstrike = 0,
            fieldOpsAirstrikeSupport = 0,

            -- Covert OPS
            covertOpsk43Headshot = 0,
            covertOpsgarandHeadshot = 0,
            covertOpsK43 = 0,
            covertOpsGarand= 0,
            covertOpsFG42 = 0,
            covertOpsSatchel = 0,
            covertOpsAkimboColt = 0,
            covertOpsColt = 0,
            covertOpsAkimboLuger = 0,
            covertOpsLuger = 0,
            covertOpsSten = 0,

            -- Normal Weapons
            Mp40 = 0,
            Thompson = 0,
            Grenade = 0,
            AkimboColt = 0,
            Colt = 0,
            AkimboLuger = 0,
            Luger = 0,
            ThrowKnife = 0,
            Knife = 0,

            -- Soldat
            soldierPanzer = 0,
            soldierFlameThrower = 0,
            soldierMG42 = 0,

            -- Ingénieur
            engineerK43Nade = 0,
            engineerK43 = 0,
            engineerM1GarandNade = 0,
            engineerM1Garand = 0,
            engineerDynamite = 0,
            engineerTripmine = 0,
            engineerMine = 0
        }
    end
end

function et_Obituary(victimNum, killerNum, meansOfDeath)
    -- Récupérer le nom du joueur tué
    local victimName = et.gentity_get(victimNum, "pers.netname") or "Unknown"

    -- Récupérer le nom du joueur tueur
    local killerName = et.gentity_get(killerNum, "pers.netname") or "Unknown"

    -- Ajouter ces lignes pour imprimer le MOD dans la console du serveur
    et.G_Print("Death by MOD: " .. killerName .. " a tué " .. victimName .. " avec l'arme number " .. meansOfDeath .. "\n")

    --et.trap_SendServerCommand(-1, "chat \"Death by MOD: " .. killerName .. " a tué " .. victimName .. " avec l'arme number " .. meansOfDeath .. "\n")

    -- Mettre à jour les statistiques en fonction de la cause de la mort
    if meansOfDeath == 25 then -- Mort due à un airstrike aérien de FieldOps
        if playerStats[killerNum] then
            playerStats[killerNum].fieldOpsAirstrike = playerStats[killerNum].fieldOpsAirstrike + 1
        end
    elseif meansOfDeath == 50 then -- Mort par headshot avec le K43
        if playerStats[killerNum] then
            playerStats[killerNum].covertOpsk43Headshot = (playerStats[killerNum].covertOpsk43Headshot or 0) + 1
        end
    elseif meansOfDeath == 45 then -- Mort par headshot avec le Garand
        if playerStats[killerNum] then
            playerStats[killerNum].covertOpsgarandHeadshot = (playerStats[killerNum].covertOpsgarandHeadshot or 0) + 1
        end
    elseif meansOfDeath == 13 then -- FG42
        if playerStats[killerNum] then
            playerStats[killerNum].covertOpsFG42 = (playerStats[killerNum].covertOpsFG42 or 0) + 1
        end
    elseif meansOfDeath == 8 then -- MP40
        if playerStats[killerNum] then
            playerStats[killerNum].Mp40 = playerStats[killerNum].Mp40 + 1
        end
    elseif meansOfDeath == 9 then -- Thomson
        if playerStats[killerNum] then
            playerStats[killerNum].Thompson = playerStats[killerNum].Thompson + 1
        end
    elseif meansOfDeath == 22 then -- Airstrike
        if playerStats[killerNum] then
            playerStats[killerNum].fieldOpsAirstrikeSupport = playerStats[killerNum].fieldOpsAirstrikeSupport + 1
        end
    elseif meansOfDeath == 15 then -- Panzerfaust
        if playerStats[killerNum] then
            playerStats[killerNum].soldierPanzer = playerStats[killerNum].soldierPanzer + 1
        end
    elseif meansOfDeath == 17 then -- MOD_FLAMETHROWER
        if playerStats[killerNum] then
            playerStats[killerNum].soldierFlameThrower = playerStats[killerNum].soldierFlameThrower + 1
        end
    elseif meansOfDeath == 43 then -- MG42
        if playerStats[killerNum] then
            playerStats[killerNum].soldierMG42 = playerStats[killerNum].soldierMG42 + 1
        end
    elseif meansOfDeath == 51 then -- Mortar
        if playerStats[killerNum] then
            playerStats[killerNum].soldierMortar = playerStats[killerNum].soldierMortar + 1
        end
    elseif meansOfDeath == 38 then -- RiffleNade K43 Axis
        if playerStats[killerNum] then
            playerStats[killerNum].engineerK43Nade = playerStats[killerNum].engineerK43Nade + 1
        end
    elseif meansOfDeath == 37 then -- Riffle K43 Axis
        if playerStats[killerNum] then
            playerStats[killerNum].engineerK43 = playerStats[killerNum].engineerK43 + 1
        end
    elseif meansOfDeath == 39 then -- M1 Garand Nade allies
        if playerStats[killerNum] then
            playerStats[killerNum].engineerM1GarandNade = playerStats[killerNum].engineerM1GarandNade + 1
        end
    elseif meansOfDeath == 36 then -- M1 Garand allies
        if playerStats[killerNum] then
            playerStats[killerNum].engineerM1Garand = playerStats[killerNum].engineerM1Garand + 1
        end
    elseif meansOfDeath == 21 then -- Dynamite
        if playerStats[killerNum] then
            playerStats[killerNum].engineerDynamite = playerStats[killerNum].engineerDynamite + 1
        end
    elseif meansOfDeath == 66 then -- tripmine
        if playerStats[killerNum] then
            playerStats[killerNum].engineerTripmine = playerStats[killerNum].engineerTripmine + 1
        end
    elseif meansOfDeath == 40 then -- Mine terrestre
        if playerStats[killerNum] then
            playerStats[killerNum].engineerMine = playerStats[killerNum].engineerMine + 1
        end
    elseif meansOfDeath == 18 then -- Grenade
        if playerStats[killerNum] then
            playerStats[killerNum].Grenade = playerStats[killerNum].Grenade + 1
        end
    elseif meansOfDeath == 52 then -- Akimbo colt allies
        if playerStats[killerNum] then
            playerStats[killerNum].AkimboColt = playerStats[killerNum].AkimboColt + 1
        end
    elseif meansOfDeath == 7 then -- colt allies
        if playerStats[killerNum] then
            playerStats[killerNum].Colt = playerStats[killerNum].Colt + 1
        end
    elseif meansOfDeath == 6 then -- luger axis
        if playerStats[killerNum] then
            playerStats[killerNum].Luger = playerStats[killerNum].Luger + 1
        end
    elseif meansOfDeath == 53 then -- Akimbo luger axis
        if playerStats[killerNum] then
            playerStats[killerNum].AkimboLuger = playerStats[killerNum].AkimboLuger + 1
        end
    elseif meansOfDeath == 41 then -- Satchel
        if playerStats[killerNum] then
            playerStats[killerNum].covertOpsSatchel = playerStats[killerNum].covertOpsSatchel + 1
        end
    elseif meansOfDeath == 54 then -- Silenced Akimbo colt allies
        if playerStats[killerNum] then
            playerStats[killerNum].covertOpsAkimboColt = playerStats[killerNum].covertOpsAkimboColt + 1
        end
    elseif meansOfDeath == 44 then -- Silenced colt allies
        if playerStats[killerNum] then
            playerStats[killerNum].covertOpsColt = playerStats[killerNum].covertOpsColt + 1
        end
    elseif meansOfDeath == 55 then -- Silenced Akimbo luger Axis
        if playerStats[killerNum] then
            playerStats[killerNum].covertOpsAkimboLuger = playerStats[killerNum].covertOpsAkimboLuger + 1
        end
    elseif meansOfDeath == 12 then -- Silenced luger Axis
        if playerStats[killerNum] then
            playerStats[killerNum].covertOpsLuger = playerStats[killerNum].covertOpsLuger + 1
        end
    elseif meansOfDeath == 10 then -- Sten
        if playerStats[killerNum] then
            playerStats[killerNum].covertOpsSten = playerStats[killerNum].covertOpsSten + 1
        end
    elseif meansOfDeath == 49 then -- Covert Ops K43
        if playerStats[killerNum] then
            playerStats[killerNum].covertOpsK43 = playerStats[killerNum].covertOpsK43 + 1
        end
    elseif meansOfDeath == 11 then -- Covert Ops Garand
        if playerStats[killerNum] then
            playerStats[killerNum].covertOpsGarand= playerStats[killerNum].covertOpsGarand + 1
        end
    elseif meansOfDeath == 63 then -- lancé de couteau
        if playerStats[killerNum] then
            playerStats[killerNum].ThrowKnife= playerStats[killerNum].ThrowKnife + 1
        end
    elseif meansOfDeath == 5 then -- couteau
        if playerStats[killerNum] then
            playerStats[killerNum].Knife= playerStats[killerNum].Knife + 1
        end
    end
end


function et_PrintHeadshotStats()
    local headshotStats = {}

    -- Parcourir tous les joueurs
    for clientNum, stats in pairs(playerStats) do
        -- La valeur 22 représente le nombre maximum d'armes différentes dans le jeu
        for j = 0, 22 do
            local weaponStats = et.gentity_get(clientNum, "sess.aWeaponStats", j)
            local headshots = weaponStats[3] or 0

            -- Ajouter le nombre d'headshots par arme au tableau
            if headshots > 0 then
                if not headshotStats[j] then
                    headshotStats[j] = {maxHeadshots = 0, player = nil}
                end

                -- Mettre à jour si le nombre d'headshots actuel est plus grand que le max enregistré
                if headshots > headshotStats[j].maxHeadshots then
                    headshotStats[j].maxHeadshots = headshots
                    headshotStats[j].player = {clientNum = clientNum, headshots = headshots}
                end
            end
        end
    end

    -- Afficher le classement des headshots par arme
    local tableauHeadshots = ""
    tableauHeadshots = tableauHeadshots .. "^3Top Players ^2HS Stats^7:\n"
    for weapon, data in pairs(headshotStats) do
        local weaponName = GetWeaponName(weapon) or "Unknown"
        local playerName = et.gentity_get(data.player.clientNum, "pers.netname") or "Unknown"
        --tableauHeadshots = tableauHeadshots .. "^7 - " .. weaponName .. " ^1->^7 " .. data.maxHeadshots .. " Headshots\n"
        if data.player then
            tableauHeadshots = tableauHeadshots .. "^3-^7 " .. weaponName .. " - " .. playerName .. " ^7: " .. data.player.headshots .. " Headshots\n"
        end
    end
    tableauHeadshots = tableauHeadshots .. "----------------------------------------\n"

    -- Afficher le tableau des headshots dans la console
    et.trap_SendServerCommand(-1, "print \"" .. tableauHeadshots .. " \n\"")
end

-- Table de correspondance entre les codes d'arme et les noms
local weaponNames = {
    [0] = "Knife",
    [1] = "Luger",
    [2] = "Colt",
    [3] = "MP40",
    [4] = "Thompson",
    [5] = "Sten",
    [6] = "FG42",
    [7] = "Panzerfaust",
    [8] = "Flamethrower",
    [9] = "Grenade",
    [10] = "Mortar",
    [11] = "Dynamite",
    [12] = "Airstrike",
    [13] = "Artillery",
    [14] = "Syringe",
    [15] = "Smoke",
    [16] = "Satchel",
    [17] = "Grenade Launcher",
    [18] = "Landmine",
    [19] = "MG42",
    [20] = "Garand",
    [21] = "K43"
}

function GetWeaponName(weaponCode)
    return weaponNames[weaponCode] or "Unknown"
end