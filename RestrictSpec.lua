local timers = {} -- Tableau pour stocker les temporisateurs
local checkInterval = 10 -- configurer le délai de vérification en millisecondes

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
    local _, _, macAddress = string.find(userinfo, "\\x\\([%w%-]+)\\")
    if macAddress then
        -- Log pour vérifier l'adresse MAC extraite
        et.G_Printf("MAC extraite avant normalisation : %s\n", macAddress)
    end
    return macAddress or "N/A"
end

-- Fonction pour ajouter un timer
function setTimer(clientNum, delay)
   for _, timer in ipairs(timers) do
       if timer.clientNum == clientNum then
           return
       end
   end
   local timer = {
      startTime = et.trap_Milliseconds(),
      delay = delay,
      clientNum = clientNum
   }
   table.insert(timers, timer)
end

-- Fonction pour vérifier si une chaîne commence par un préfixe donné
function starts_with(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

-- Fonction pour vérifier si le GUID du joueur est dans la liste des autorisés
function isGuidAllowed(clientNum)
    local userinfo = et.trap_GetUserinfo(clientNum)
    local _, _, guid = string.find(userinfo, "cl_guid\\([^\\]+)\\")
    
    if guid then
        for _, allowedGuid in ipairs(allowGuids) do
            if guid == allowedGuid then
                return true
            end
        end
    end
    
    return false
end

-- Fonction pour vérifier la table
function checkTimers(levelTime)
   for i = #timers, 1, -1 do
       local timer = timers[i]
       if levelTime - timer.startTime >= timer.delay then
           checkMacAddress(timer.clientNum)
           table.remove(timers, i)
       end
   end
end

-- Fonction pour vérifier l'adresse mac / muted
function checkMacAddress(clientNum)
    local userinfo = et.trap_GetUserinfo(clientNum)
    local macAddress = extractMacAddress(userinfo)
    et.G_Printf("Adresse MAC extraite : %s\n", macAddress)
    
    if macAddress == "N/A" or macAddress == "" then
        et.G_Printf("Adresse MAC invalide pour le client %d\n", clientNum)
        et.gentity_set(clientNum, "sess.muted", 1)
        return
    end
    
    -- Vérifier si l'adresse MAC commence par un préfixe blacklisté
    for _, blockedMACPrefix in ipairs(macAddressesToCheck) do
        if starts_with(macAddress, blockedMACPrefix) then
            et.G_Printf("Adresse MAC blacklistée : %s\n", macAddress)
            et.gentity_set(clientNum, "sess.muted", 1)
            return
        else
            et.G_Printf("Adresse MAC non correspondante : %s (Comparée à %s)\n", macAddress, blockedMACPrefix)
        end
    end
    
    -- Si aucune correspondance trouvée, ne pas mute
    et.G_Printf("Adresse MAC autorisée : %s\n", macAddress)
    et.gentity_set(clientNum, "sess.muted", 0)
end

-- Fonction permettant de déclencher le timer à la connextion
function et_ClientConnect(clientNum, firstTime, isBot)
    if isBot then return end
    -- Enregistrer un temporisateur pour retarder l'exécution de la vérification de l'adresse MAC
    setTimer(clientNum, checkInterval)
end

-- Fonction pour vérifier à x moments
function et_RunFrame(levelTime)
   checkTimers(levelTime)
end
