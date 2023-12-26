-- Variable pour suivre si la commande a déjà été executée
local executeCustomCmd = false

function et_RunFrame(levelTime)
    local gameState = et.trap_Cvar_Get("gamestate")

    -- Logique de vérification du warmup
    if gameState == "1" and not executeCustomCmd then
        -- Le jeu est en warmup, exécutez la commande !funon
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "funon\n")

        -- Marquer que la commande a été envoyé
        executeCustomCmd = true
    end
end