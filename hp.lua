modname="Fix HP for class"
version="1.0"

function et_InitGame()
        et.RegisterModname(modname.." "..version)
end

function et_ClientSpawn(clientNum, revived)
    local team = et.gentity_get(clientNum, "sess.sessionTeam")
    local class = et.gentity_get(clientNum, "sess.latchPlayerType")

    -- Définition des HP max
    local maxHP = 156
    if class == 1 then -- 1 = Medic
        maxHP = 140
    end

    -- Appliquer les HP max
    et.gentity_set(clientNum, "health", maxHP)
    et.gentity_set(clientNum, "ps.stats", 3, maxHP) -- Mettre à jour le stat HP Max
end

function et_Obituary(victim, killer, meansOfDeath)
    -- Vérifier si le joueur a été "revive"
    local isRevive = (meansOfDeath == 37) -- 37 = MOD_REVIVE
    if isRevive then
        et_ClientSpawn(victim, true) -- Réappliquer les HP max
    end
end
