function extractIPAddress(userinfo)
    -- Extraire l'adresse IP du userinfo.
    local _, _, ipAddress = string.find(userinfo, "\\ip\\([%d%.]+):")
    return ipAddress or "N/A"
end

local timers = {} -- Tableau pour stocker les temporisateurs
local checkInterval = 1000 -- configurer le délai de vérification en millisecondes (1 seconde)
local messageKick = "You have been kicked by the administrator for a security policy violation." -- message de kick

function setTimer(clientNum, delay)
    local timer = {
        startTime = et.trap_Milliseconds(),
        delay = delay,
        clientNum = clientNum
    }
    table.insert(timers, timer)
end

function isBlockedIP(ipAddress)
    local handle = io.popen("curl -s https://blackbox.ipinfo.app/lookup/" .. ipAddress)
    local result = handle:read("*a")
    handle:close()

    return result
end

function checkIPAddress(clientNum)
    local userinfo = et.trap_GetUserinfo(clientNum)
    
    -- Extraire l'adresse IP du userinfo.
    local ipAddress = extractIPAddress(userinfo)

    -- DEBUG : Afficher l'adresse IP
    -- et.G_Print("Adresse IP du joueur connecté : " .. ipAddress .. "\n")

    if ipAddress == "N/A" then
        return -- Sortir si l'adresse IP n'a pas pu être extraite
    end

    -- Vérifier l'adresse IP via le service blackbox.ipinfo.app
    local result = isBlockedIP(ipAddress)

    -- Gérer les différents résultats possibles
    if result == "Y" then
        et.G_Print("IP " .. ipAddress .. " est un VPN/Proxy.\n")
        et.trap_DropClient(clientNum, messageKick, 0) -- Kick immédiatement
    elseif result == "E" then
        et.G_Print("IP " .. ipAddress .. " est invalide.\n")
    elseif result == "N" then
        et.G_Print("IP " .. ipAddress .. " n'est pas un VPN/Proxy.\n")
    else
        et.G_Print("Erreur lors de la vérification de l'IP: " .. result .. "\n")
    end
end

function checkTimers(levelTime)
    local i = 1
    while i <= #timers do
        local timer = timers[i]
        if levelTime - timer.startTime >= timer.delay then
            checkIPAddress(timer.clientNum)
            table.remove(timers, i)
        else
            i = i + 1
        end
    end
end

function et_ClientConnect(clientNum, firstTime, isBot)
    -- Enregistrer un temporisateur pour retarder l'exécution de la vérification de l'adresse IP
    setTimer(clientNum, checkInterval)
    -- et.G_Print("Vérification de l'adresse IP dans " .. checkInterval .. " millisecondes...\n")
end

function et_ClientUserinfoChanged(clientNum)
    -- Cette fonction sera appelée lorsque les informations sur l'utilisateur changent
    checkIPAddress(clientNum)
end

function et_RunFrame(levelTime)
    -- Cette fonction est appelée à chaque frame
    checkTimers(levelTime)
end