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
    
    if macAddress == "N/A" or macAddress == "" then
        et.gentity_set(clientNum, "sess.muted", 1)
    else
        for _, allowedMAC in ipairs(macAddressesToCheck) do
            if starts_with(macAddress, allowedMAC) then
                et.gentity_set(clientNum, "sess.muted", 1)
                return
            end
        end
        et.gentity_set(clientNum, "sess.muted", 0)
    end
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
