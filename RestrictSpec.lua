--===================================================--
--==                CONFIGURATION                  ==--
--===================================================--
local checkInterval = 10 -- Délai de vérification en millisecondes
local enableDebugLogs = false -- Activer les logs de débogage

-- Constantes pour les équipes
local TEAM_FREE = 0
local TEAM_AXIS = 1
local TEAM_ALLIES = 2
local TEAM_SPECTATOR = 3

--===================================================--
--==                  LOG HELPER                   ==--
--===================================================--
-- Fonction pour formater correctement les messages de log
function logPrint(format, ...)
    -- Pré-formater le message avec string.format
    local formattedMessage = string.format(format, ...)
    -- Envoyer le message pré-formaté à G_Print
    et.G_Print(formattedMessage)
end

--===================================================--
--==              BLACKLIST MAC ADRESS             ==--
--===================================================--
-- Liste des préfixes MAC à bloquer
local blockedMACPrefixes = {
    ["00-20-18"] = true, -- Cheat
    ["88-AE-DD"] = true, -- Narkotyk
    --["D8-43-AE"] = true, -- Hal
    ["DD-EE-FF"] = true, -- ETPlayer
    ["1C-1B-0D"] = true, -- ETPlayer
}

--===================================================--
--==              WHITELIST USER GUID              ==--
--===================================================--
-- Liste des GUID autorisés
local allowedGuids = {
    --["BAA2F454FC56604AD1D96E80DCD738AA"] = true, -- Narkotyk
    ["XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"] = true, -- ETPlayer
    ["XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"] = true, -- ETPlayer
}

-- Fonction pour compter les éléments d'une table
function getTableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

logPrint("===== RestrictSpec chargé - Blacklist: %d préfixes MAC, Whitelist: %d GUIDs =====\n", 
    getTableSize(blockedMACPrefixes), getTableSize(allowedGuids))

--===================================================--
--==                CACHE CLIENT DATA              ==--
--===================================================--
local clientCache = {}
local timers = {}

--===================================================--
--==                HELPER FUNCTIONS               ==--
--===================================================--
-- Fonction pour obtenir l'équipe du joueur
function getPlayerTeam(clientNum)
    local team = et.gentity_get(clientNum, "sess.sessionTeam")
    return tonumber(team) or TEAM_SPECTATOR
end

-- Fonction pour extraire des informations du userinfo
function extractUserInfo(clientNum)
    local userinfo = et.trap_GetUserinfo(clientNum)
    local data = {}
    
    -- Extraire l'adresse MAC avec une expression régulière améliorée
    local _, _, macAddress = string.find(userinfo, "\\x\\([%w%-%:]+)\\")
    data.macAddress = macAddress or "N/A"
    
    -- Extraire le GUID
    local _, _, guid = string.find(userinfo, "n_guid\\([^\\]+)\\")
    data.guid = guid or "N/A"
    
    -- Mettre à jour le cache
    clientCache[clientNum] = data
    
    if enableDebugLogs then
        logPrint("[EXTRACT] Client #%d: MAC=%s, GUID=%s\n", clientNum, data.macAddress, data.guid)
    end
    
    return data
end

-- Fonction pour vérifier si une MAC commence par un préfixe blacklisté
function starts_with(str, prefix)
    if not str or not prefix then return false end
    
    -- Convertir en minuscules pour une comparaison insensible à la casse
    local lowerStr = string.lower(str)
    local lowerPrefix = string.lower(prefix)
    
    -- Log de débogage uniquement si activé
    if enableDebugLogs then
        logPrint("[DEBUG] Comparaison: '%s' commence par '%s'? %s\n", 
            lowerStr, lowerPrefix, tostring(string.sub(lowerStr, 1, string.len(lowerPrefix)) == lowerPrefix))
    end
    
    return string.sub(lowerStr, 1, string.len(lowerPrefix)) == lowerPrefix
end

-- Fonction pour vérifier si une MAC est valide
function isValidMAC(macAddress)
    if macAddress == "N/A" or macAddress == "" or macAddress == "00-00-00-00-00-00" then
        return false
    end
    return true
end

-- Fonction pour vérifier si une MAC est blacklistée
function isBlacklistedMAC(macAddress)
    if not isValidMAC(macAddress) then
        return false
    end
    
    for prefix in pairs(blockedMACPrefixes) do
        if starts_with(macAddress, prefix) then
            return true
        end
    end
    
    return false
end

-- Fonction pour ajouter un timer
function setTimer(clientNum, delay)
    -- Éviter les doublons
    for i, timer in ipairs(timers) do
        if timer.clientNum == clientNum then
            -- Mise à jour du timer existant
            timers[i].startTime = et.trap_Milliseconds()
            if enableDebugLogs then
                logPrint("[TIMER] Mise à jour du timer pour client #%d\n", clientNum)
            end
            return
        end
    end
    
    -- Ajouter un nouveau timer
    table.insert(timers, {
        startTime = et.trap_Milliseconds(),
        delay = delay,
        clientNum = clientNum
    })
    if enableDebugLogs then
        logPrint("[TIMER] Nouveau timer créé pour client #%d, délai=%dms\n", clientNum, delay)
    end
end

-- Fonction pour vérifier les timers
function checkTimers(levelTime)
    for i = #timers, 1, -1 do
        local timer = timers[i]
        if levelTime - timer.startTime >= timer.delay then
            if enableDebugLogs then
                logPrint("[TIMER] Timer expiré pour client #%d\n", timer.clientNum)
            end
            checkClientRestrictions(timer.clientNum)
            table.remove(timers, i)
        end
    end
end

--===================================================--
--==         VÉRIFICATION DES RESTRICTIONS         ==--
--===================================================--

-- Fonction pour vérifier les restrictions du client
function checkClientRestrictions(clientNum)
    -- Extraire ou obtenir les données du client depuis le cache
    local data = clientCache[clientNum] or extractUserInfo(clientNum)
    local macAddress = data.macAddress
    local guid = data.guid
    
    if enableDebugLogs then
        logPrint("[CHECK] Verification du client #%d - MAC: %s, GUID: %s\n", clientNum, macAddress, guid)
    end
    
    -- 1. WHITELIST GUID - Si le joueur a un GUID autorisé, lui permettre de jouer, peu importe sa MAC
    if allowedGuids[guid] then
        if enableDebugLogs then
            logPrint("[CHECK] Client #%d autorisé par GUID whitelist\n", clientNum)
        end
        et.gentity_set(clientNum, "sess.muted", 0)
        return
    end
    
    -- 2. Vérifier si l'adresse MAC est valide
    if not isValidMAC(macAddress) then
        if enableDebugLogs then
            logPrint("[CHECK] Client #%d a une adresse MAC invalide - RESTRICTION APPLIQUEE\n", clientNum)
        end
        et.gentity_set(clientNum, "sess.muted", 1)
        return
    end
    
    -- 3. Vérifier si l'adresse MAC est blacklistée
    if isBlacklistedMAC(macAddress) then
        if enableDebugLogs then
            logPrint("[CHECK] Client #%d a une adresse MAC blacklistée - RESTRICTION APPLIQUEE\n", clientNum)
        end
        et.gentity_set(clientNum, "sess.muted", 1)
        return
    end
    
    -- 4. Joueur normal avec MAC valide et non blacklistée
    if enableDebugLogs then
        logPrint("[CHECK] Client #%d a une adresse MAC valide et non blacklistée - AUTORISÉ\n", clientNum)
    end
    et.gentity_set(clientNum, "sess.muted", 0)
end

-- Message à afficher aux joueurs bloqués - MAC blacklistée
local function sendBlockedMessage(clientNum)
    if enableDebugLogs then
        logPrint("[BLOCK] Envoi du message de blocage au client #%d\n", clientNum)
    end
    et.trap_SendServerCommand(clientNum, "chat \"^1CONTACT THE SERVER ADMINISTRATOR ^7--> ^1TO UNLOCK^s! ^0-------------------------------------------------------------\"")
end

-- Message pour les joueurs avec MAC invalide
function sendInvalidMACMessage(clientNum)
    if enableDebugLogs then
        logPrint("[BLOCK] Envoi du message de MAC invalide au client #%d\n", clientNum)
    end
    et.trap_SendServerCommand(clientNum, "chat \"^3YOUR MAC ADDRESS IS NOT DETECTED - CONTACT AN ADMINISTRATOR^7\"")
end

--===================================================--
--==                 EVENT HANDLERS                ==--
--===================================================--

function et_ClientConnect(clientNum, firstTime, isBot)
    if isBot then 
        if enableDebugLogs then
            logPrint("[CONNECT] Bot détecté (#%d) - Ignoré\n", clientNum)
        end
        return 
    end
    
    if enableDebugLogs then
        logPrint("[CONNECT] Nouveau client #%d connecté (firstTime=%s)\n", clientNum, tostring(firstTime))
    end

    -- Extraire immédiatement les informations et les mettre en cache
    extractUserInfo(clientNum)
    
    -- Planifier une vérification après un court délai
    setTimer(clientNum, checkInterval)
end

function et_RunFrame(levelTime)
    checkTimers(levelTime)
end

function et_ClientCommand(clientNum, command)
    -- Obtenir les informations du client
    local data = clientCache[clientNum] or extractUserInfo(clientNum)
    local macAddress = data.macAddress
    local guid = data.guid
    
    local cmd = string.lower(et.trap_Argv(0))
    if enableDebugLogs then
        logPrint("[COMMAND] Client #%d execute la commande: %s\n", clientNum, cmd)
    end
    
    -- 1. WHITELIST GUID - Si le joueur a un GUID autorisé, lui permettre de jouer, peu importe sa MAC
    if allowedGuids[guid] then
        if enableDebugLogs then
            logPrint("[COMMAND] Client #%d autorisé par GUID whitelist\n", clientNum)
        end
        return -- Autoriser les joueurs avec un GUID autorisé
    end
    
    -- 2. Vérifier si l'adresse MAC est valide
    if not isValidMAC(macAddress) then
        if enableDebugLogs then
            logPrint("[COMMAND] Client #%d a une adresse MAC invalide\n", clientNum)
        end
        
        -- Bloquer les commandes "team" et "say"
        if cmd == "team" or cmd == "say" or cmd == "say_team" then
            sendInvalidMACMessage(clientNum)
            return 1 -- Bloquer la commande
        end
        
        return -- Laisser passer les autres commandes, mais le joueur reste muet
    end
    
    -- 3. Vérifier si l'adresse MAC est blacklistée
    if isBlacklistedMAC(macAddress) then
        if enableDebugLogs then
            logPrint("[COMMAND] Client #%d a une adresse MAC blacklistée\n", clientNum)
        end
        
        -- Bloquer les commandes "team" et "say"
        if cmd == "team" or cmd == "say" or cmd == "say_team" then
            sendBlockedMessage(clientNum)
            return 1 -- Bloquer la commande
        end
        
        return -- Laisser passer les autres commandes, mais le joueur reste muet
    end
    
    -- 4. Joueur normal avec MAC valide et non blacklistée
    return -- Autoriser toutes les commandes
end

-- Fonction pour détecter les changements d'équipe
function et_ClientUserinfoChanged(clientNum)
    -- Mise à jour des informations du client
    extractUserInfo(clientNum)
    
    -- Vérifier les restrictions après changement d'équipe
    checkClientRestrictions(clientNum)
    
    return 0
end

function et_ClientDisconnect(clientNum)
    if enableDebugLogs then
        logPrint("[DISCONNECT] Client #%d déconnecté\n", clientNum)
    end
    
    -- Nettoyer le cache quand un client se déconnecte
    clientCache[clientNum] = nil
    
    -- Supprimer les timers associés à ce client
    local timersRemoved = 0
    for i = #timers, 1, -1 do
        if timers[i].clientNum == clientNum then
            table.remove(timers, i)
            timersRemoved = timersRemoved + 1
        end
    end
    
    if enableDebugLogs then
        logPrint("[DISCONNECT] %d timers supprimés pour client #%d\n", timersRemoved, clientNum)
    end
end