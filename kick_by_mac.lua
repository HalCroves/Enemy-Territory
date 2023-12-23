-- Fonction pour vérifier si l'adresse MAC commence par la chaîne spécifiée
function starts_with(str, start)
   return str and str:sub(1, #start) == start
end

function extractMacAddress(userinfo)
   -- Extraire l'adresse MAC du userinfo.
   local _, _, macAddress = string.find(userinfo, "\\x\\([%w%-]+)\\")
   
   return macAddress or "N/A"
end

function et_ClientConnect(clientNum, firstTime, isBot)
   local userinfo = et.trap_GetUserinfo(clientNum)
   
   -- Get adresse MAC du userinfo.
   local macAddress = extractMacAddress(userinfo)

   -- DEBUG : Afficher l'adresse mac
   -- et.G_Print("Adresse MAC du joueur connecté : " .. macAddress .. "\n")
   
   -- Vérifier si l'adresse MAC commence par "XX-XX-XX"
   if starts_with(macAddress, "XX-XX-XX") then
      -- Si oui, kicker le joueur
      et.trap_DropClient(clientNum, "Kicked by admin", 600) -- kick for 10 mins
   else
      et.G_Print("MAC : " .. (macAddress or "N/A") .. "\n")
   end
end