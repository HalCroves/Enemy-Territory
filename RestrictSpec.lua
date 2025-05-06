--===================================================--
--==                CONFIGURATION                  ==--
--===================================================--
local checkInterval = 10 -- Délai de vérification en millisecondes
local enableDebugLogs = false -- Désactivé pour éviter les logs trop verbeux

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
    ["XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"] = true, -- ETPlayer
    ["XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"] = true, -- ETPlayer
}

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


-- Fonction pour extraire des informations du userinfo plus précise
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

-- Amélioration de la fonction de vérification des préfixes
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
--==       VÉRIFICATION COMBINÉE (GUID + MAC)      ==--
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
    -- 1. WHITELIST GUID - Si le joueur a un GUID autorisé, lui permettre de jouer
    if allowedGuids[guid] then
        if enableDebugLogs then
            logPrint("[CHECK] Client #%d autorise par GUID whitelist\n", clientNum)
        end
        et.gentity_set(clientNum, "sess.muted", 0)
        return
    end
    
    -- 2. Vérifier l'équipe du joueur
    local team = getPlayerTeam(clientNum)
    if team ~= TEAM_SPECTATOR then
        -- Le joueur n'est pas en spectateur, il peut parler
        if enableDebugLogs then
            logPrint("[CHECK] Client #%d est dans une équipe active - Unmute\n", clientNum)
        end
        et.gentity_set(clientNum, "sess.muted", 0)
        return
    end
    
    -- 3. Appliquer les restrictions pour les spectateurs
    if enableDebugLogs then
        logPrint("[CHECK] Client #%d est spectateur - Mute appliqué\n", clientNum)
    end
    et.gentity_set(clientNum, "sess.muted", 1)
end

-- Message à afficher aux joueurs bloqués - MAC
local function sendBlockedMessage(clientNum)
    if enableDebugLogs then
        logPrint("[BLOCK] Envoi du message de blocage au client #%d\n", clientNum)
    end
    et.trap_SendServerCommand(clientNum, "chat \"^sSKONTAKTUJ SIE Z ADMINEM SERWERA ^7--> ^sABY ODBLOKOWAC DOSTEP^q! ^0-------------------------------------------------------------\"")
    et.trap_SendServerCommand(clientNum, "chat \"^1CONTACT THE SERVER ADMINISTRATOR ^7--> ^1TO UNLOCK^s! ^0-------------------------------------------------------------\"")
end

-- Message pour les joueurs non whitelistés - GUID
function sendNotWhitelistedMessage(clientNum)
    if enableDebugLogs then
        logPrint("[BLOCK] Envoi du message de non-whitelist au client #%d\n", clientNum)
    end
    et.trap_SendServerCommand(clientNum, "chat \"^3VOTRE COMPTE N'EST PAS WHITELISTE - CONTACTEZ UN ADMINISTRATEUR^7\"")
    et.trap_SendServerCommand(clientNum, "chat \"^3YOUR ACCOUNT IS NOT WHITELISTED - CONTACT AN ADMINISTRATOR^7\"")
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
    
    -- 1. WHITELIST GUID - Vérifier si le GUID est autorisé
    if allowedGuids[guid] then
        if enableDebugLogs then
            logPrint("[COMMAND] Client #%d autorise par whitelist GUID\n", clientNum)
        end
        return -- Autoriser les joueurs avec un GUID autorisé
    end
    
    -- 2. Vérifier l'équipe du joueur
    local team = getPlayerTeam(clientNum)
    
    -- 3. Vérifier si l'adresse MAC est blacklistée
    local isBlacklistedMAC = false
    if macAddress ~= "N/A" and macAddress ~= "" then
        for prefix in pairs(blockedMACPrefixes) do
            if starts_with(macAddress, prefix) then
                isBlacklistedMAC = true
                if enableDebugLogs then
                    logPrint("[COMMAND] Client #%d a une adresse MAC blacklistee (%s)\n", clientNum, prefix)
                end
                break
            end
        end
    end
    
    -- 4. Gérer les commandes spécifiques
    
    -- 4.1 Commande "team" - Permettre de rejoindre une équipe mais pas de devenir spectateur
    if cmd == "team" then
        local targetTeam = tonumber(et.trap_Argv(1))
        
        -- Permettre de rejoindre une équipe active
        if targetTeam ~= TEAM_SPECTATOR then
            if enableDebugLogs then
                logPrint("[COMMAND] Client #%d autorisé à rejoindre l'équipe %d\n", clientNum, targetTeam)
            end
            return -- Autoriser le changement d'équipe
        end
        
        -- Bloquer le passage en spectateur
        if enableDebugLogs then
            logPrint("[COMMAND] Commande 'team %d' bloquée pour client #%d\n", targetTeam, clientNum)
        end
        
        -- Afficher le message approprié
        if isBlacklistedMAC then
            sendBlockedMessage(clientNum)
        else
            sendNotWhitelistedMessage(clientNum)
        end
        
        return 1 -- Bloquer la commande
    end
    
    -- 4.2 Commandes de chat - Afficher un message si en spectateur
    if (cmd == "say" or cmd == "say_team") and team == TEAM_SPECTATOR then
        if enableDebugLogs then
            logPrint("[CHAT] Client #%d tente de parler en spectateur\n", clientNum)
        end
        
        -- Afficher le message approprié
        if isBlacklistedMAC then
            sendBlockedMessage(clientNum)
        else
            sendNotWhitelistedMessage(clientNum)
        end
        
        return 1 -- Bloquer la commande
    end
    
    -- 5. Gérer le statut muet en fonction de l'équipe
    if team == TEAM_SPECTATOR then
        et.gentity_set(clientNum, "sess.muted", 1)
    else
        et.gentity_set(clientNum, "sess.muted", 0)
    end
    
    return -- Laisser passer les autres commandes
end

-- Fonction pour détecter les changements d'équipe
function et_ClientUserinfoChanged(clientNum)
    -- Obtenir l'ancienne équipe (si disponible dans le cache)
    local oldTeam = -1
    if clientCache[clientNum] and clientCache[clientNum].team then
        oldTeam = clientCache[clientNum].team
    end
    
    -- Obtenir la nouvelle équipe
    local newTeam = getPlayerTeam(clientNum)
    
    -- Mettre à jour le cache
    if not clientCache[clientNum] then
        clientCache[clientNum] = extractUserInfo(clientNum)
    end
    clientCache[clientNum].team = newTeam
    
    -- Vérifier si le joueur a changé d'équipe
    if oldTeam ~= newTeam then
        if enableDebugLogs then
            logPrint("[TEAM] Client #%d a changé d'équipe: %d -> %d\n", clientNum, oldTeam, newTeam)
        end
        
        -- Si le joueur rejoint une équipe active, le débloquer
        if newTeam ~= TEAM_SPECTATOR then
            et.gentity_set(clientNum, "sess.muted", 0)
            if enableDebugLogs then
                logPrint("[TEAM] Client #%d a rejoint une équipe active - Unmute\n", clientNum)
            end
        else
            -- Vérifier les restrictions pour les spectateurs
            checkClientRestrictions(clientNum)
        end
    end
    
    return 0
end