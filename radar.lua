atmosphericeffects = "cg_atmosphericeffects 0"
drawfoliage = "r_drawfoliage 0"

function et_MapLoaded()
    local mapname = et.trap_Cvar_Get("mapname")

    -- Vérifier si la carte est "radar"
    if mapname == "radar" then
        -- Forcer les cvars spécifiques pour la carte "radar"
		et.trap_SendConsoleCommand(et.EXEC_APPEND, "forcecvar\ " .. atmosphericeffects .. "\n")
		et.trap_SendConsoleCommand(et.EXEC_APPEND, "forcecvar\ " .. drawfoliage .. "\n")
    end
end

function et_InitGame(leveltime, randomseed, restart)
    -- Appeler la fonction après le chargement de la carte
    et_MapLoaded()
end