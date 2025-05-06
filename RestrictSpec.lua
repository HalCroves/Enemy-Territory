--===================================================--
--==              BLACKLIST MAC ADRESS             ==--
--===================================================--

local macAddressesToCheck = {
    "00-20-18", -- Cheat
    "88-AE-DD", -- Narkotyk
    "AA-BB-CC", -- ETPlayer
    "DD-EE-FF", -- ETPlayer
    "1C-1B-0D", -- ETPlayer
} 

--===================================================--
--==              WHITELIST USER GUID              ==--
--===================================================--

local allowGuids = {
    --"BAA2F454FC56604AD1D96E80DCD738AA", -- Narkotyk
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", -- ETPlayer
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", -- ETPlayer
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", -- ETPlayer
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", -- ETPlayer
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", -- ETPlayer
}

--===================================================--
--==                HELPER FUNCTIONS               ==--
--===================================================--

-- Fonction pour extraire l'adresse MAC du userinfo
function extractMacAddress(userinfo)
    -- Récupérer l'adresse MAC depuis le userinfo
    local mac = et.Info_ValueForKey(userinfo, "mac") or "N/A"
    return mac
end

-- Fonction pour vérifier si une chaîne commence par un préfixe donné
function starts_with(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

-- Fonction pour vérifier si le GUID du joueur est dans la liste des autorisés
function isGuidAllowed(clientNum)
    local guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
    for _, allowedGuid in ipairs(allowGuids) do
        if guid == allowedGuid then
            return true
        end
    end
    return false
end

--===================================================--
--==                  SPAM PROTECTION              ==--
--===================================================--

function et_ClientCommand(clientNum, command)
    local userinfo = et.trap_GetUserinfo(clientNum)
    local macAddress = extractMacAddress(userinfo)
    
    -- Vérifier si l'adresse MAC est vide ou nulle
    if macAddress == "N/A" or macAddress == "" then
        -- Player Mute
        et.gentity_set(clientNum, "sess.muted", 1)
        
        -- Bloquer la commande "team" si le joueur essaie de rejoindre une équipe
        local cmd = string.lower(et.trap_Argv(0))
        if cmd == "team" then
            -- Spec message
            et.trap_SendServerCommand(clientNum, "chat \"^sSKONTAKTUJ SIE Z ADMINEM SERWERA ^7--> ^sABY ODBLOKOWAC DOSTEP^q! ^0-------------------------------------------------------------\"")
            et.trap_SendServerCommand(clientNum, "chat \"^1CONTACT THE SERVER ADMINISTRATOR ^7--> ^1TO UNLOCK^s! ^0-------------------------------------------------------------\"")
            return 1
        end
        return
    end
              
    -- Guid whitelist
    if isGuidAllowed(clientNum) then
        return
    end

    for _, allowedMAC in ipairs(macAddressesToCheck) do
        if starts_with(macAddress, allowedMAC) then
            -- Player Mute
            et.gentity_set(clientNum, "sess.muted", 1)
            
            -- Spam 'Join Team'
            local cmd = string.lower(et.trap_Argv(0))
            if cmd == "team" then
                -- Spec message
                et.trap_SendServerCommand(clientNum, "chat \"^sSKONTAKTUJ SIE Z ADMINEM SERWERA ^7--> ^sABY ODBLOKOWAC DOSTEP^q! ^0-------------------------------------------------------------\"")
                et.trap_SendServerCommand(clientNum, "chat \"^1CONTACT THE SERVER ADMINISTRATOR ^7--> ^1TO UNLOCK^s! ^0-------------------------------------------------------------\"")
                return 1
            end
        end
    end
end
