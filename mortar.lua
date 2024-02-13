--[[
This lua changes mortar bombs to 999.
created by ETc|#.Jay.#

]]

Modname = "Mortar Mod"
Version = "1.1"

function et_InitGame(levelTime, randomSeed, restart)
    et.G_Print("["..Modname.."] Version: "..Version.." Loaded\n")
    et.RegisterModname(et.Q_CleanStr(Modname).."   "..Version.."   "..et.FindSelf())
    et.trap_SendConsoleCommand(et.EXEC_NOW,"sets Mortar_Mod 1.0")
end

function et_ClientSpawn(clientNum,revived)
    et.gentity_set(clientNum, "ps.ammoclip", 33, 499)
    et.gentity_set(clientNum, "ps.ammo", 33, 500)
end