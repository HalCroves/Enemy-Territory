-- Liste des adresses MAC à kicker
local macAddressesToKick = {
    "XX-XX-XX",
    "YY-YY-YY",
}

-- Fonction pour vérifier si l'adresse MAC est dans la liste des adresses à kicker
function isMacAddressToKick(macAddress)
    for _, address in ipairs(macAddressesToKick) do
        if starts_with(macAddress, address) then
            return true
        end
    end
    return false
end

function et_ClientConnect(clientNum, firstTime, isBot)
   local userinfo = et.trap_GetUserinfo(clientNum)
   
   -- Get adresse MAC du userinfo.
   local macAddress = extractMacAddress(userinfo)

   -- DEBUG : Afficher l'adresse mac
   -- et.G_Print("Adresse MAC du joueur connecté : " .. macAddress .. "\n")
   
   -- Vérifier si l'adresse MAC est dans la liste à kicker
   if isMacAddressToKick(macAddress) then
      -- Si oui, kicker le joueur
      et.trap_DropClient(clientNum, "Kicked by admin", 600) -- kick for 10 mins
   else
      et.G_Print("MAC : " .. (macAddress or "N/A") .. "\n")
   end
end
