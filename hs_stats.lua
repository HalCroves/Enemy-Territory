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