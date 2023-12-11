Modname = "CustomMod - HalCroves/Bertha"
Version = "0.1a"

-- Fonction utilitaire pour charger un script Lua
function loadScript(scriptPath)
    local success, errorMsg = pcall(dofile, scriptPath)

    if not success then
        et.G_Print("Erreur lors du chargement du script '" .. scriptPath .. "': " .. errorMsg .. "\n")
    end
end

-- Charger d'autres scripts ici
loadScript("D:/Serveur + Bot/Wolfenstein - Enemy Territory/nitmod/funnymsg.lua")
loadScript("D:/Serveur + Bot/Wolfenstein - Enemy Territory/nitmod/vote.lua")
loadScript("D:/Serveur + Bot/Wolfenstein - Enemy Territory/nitmod/radar.lua")
loadScript("D:/Serveur + Bot/Wolfenstein - Enemy Territory/nitmod/xp.lua")
loadScript("D:/Serveur + Bot/Wolfenstein - Enemy Territory/nitmod/stats.lua")

function et_InitGame(levelTime, randomSeed, restart)
    et.G_Print("^z["..Modname.."^z] Version:"..Version.." Loaded\n")
    et.RegisterModname(et.Q_CleanStr(Modname).."   "..Version.."   "..et.FindSelf())
end