function et_InitGame( levelTime, randomSeed, restart )

	for local i=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do

		if et.gentity_get(i, "pers.localClient") == 1 then
			et.trap_SendConsoleCommand(et.EXEC_APPEND, "!resetxp " .. i .. ";")
		end
	end
end