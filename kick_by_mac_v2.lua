-- Fonction pour vérifier si l'adresse MAC commence par la chaîne spécifiée
function starts_with(str, start)
   return str and str:sub(1, #start) == start
end

function extractMacAddress(userinfo)
   -- Extraire l'adresse MAC du userinfo.
   local _, _, macAddress = string.find(userinfo, "\\x\\([%w%-]+)\\")
   
   return macAddress or "N/A"
end

local timers = {} -- Tableau pour stocker les temporisateurs
local macAddressesToCheck = {"00-20-18", "AA-BB-CC", "DD-EE-FF", "1C-1B-0D"} -- Ajoutez autant d'adresses MAC que nécessaire
local checkInterval = 10 -- configurer le délai de vérification en millisecondes
local messageKick = "You have been kicked by the administrator for a security policy violation." -- message de kick
local badPseudo = "You have been kicked for using an unauthorized name." -- message de kick (pseudo changed)
local newPseudo = "Ilove|Ps|"

-- Liste des GUID autorisés (whitelist)
local allowGuids = {
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", -- ETPlayer
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", -- ETPlayer
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", -- ETPlayer
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", -- ETPlayer
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", -- ETPlayer
}

function setTimer(clientNum, delay)
   local timer = {
      startTime = et.trap_Milliseconds(),
      delay = delay,
      clientNum = clientNum
   }
   table.insert(timers, timer)
end

-- Fonction pour vérifier si le GUID est autorisé
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

function checkMacAddress(clientNum, isBot)
    -- Si c'est un bot, ne pas effectuer de vérification
    if isBot then
        return
    end

    local userinfo = et.trap_GetUserinfo(clientNum)
    
    -- Vérifier si le GUID est autorisé
    if isGuidAllowed(clientNum) then
        -- Ignorer les joueurs ayant un GUID autorisé
        return
    end

    -- Obtenir l'adresse MAC du userinfo.
    local macAddress = extractMacAddress(userinfo)

    -- Vérifier l'adresse MAC spécifique "00-00-00-00"
    if macAddress == "00-00-00-00" then
        -- Si l'adresse MAC est "00-00-00-00", kicker immédiatement
        et.trap_DropClient(clientNum, messageKick, 0)
        return
    end

    -- Vérifier si l'adresse MAC est dans la liste des adresses à vérifier
    for _, allowedMAC in ipairs(macAddressesToCheck) do
        if starts_with(macAddress, allowedMAC) then
            -- Si oui, mettre le joueur en spectateur 
            et.trap_SendConsoleCommand(et.EXEC_APPEND, "put " .. clientNum .. " s")
            -- Puis kicker le joueur
            et.trap_DropClient(clientNum, messageKick, 0) -- kick immédiatement
            return -- Sortir de la boucle dès qu'une correspondance est trouvée
        end
    end
end

function checkTimers(levelTime)
   local i = 1
   while i <= #timers do
      local timer = timers[i]
      if levelTime - timer.startTime >= timer.delay then
         checkMacAddress(timer.clientNum)
         table.remove(timers, i)
      else
         i = i + 1
      end
   end
end

function et_ClientConnect(clientNum, firstTime, isBot)
    -- Enregistrer un temporisateur pour retarder l'exécution de la vérification de l'adresse MAC
    setTimer(clientNum, checkInterval)
    -- Appeler directement checkMacAddress pour gérer les cas spécifiques comme "00-00-00-00"
    checkMacAddress(clientNum, isBot)
end

function et_ClientUserinfoChanged(clientNum)
   -- Cette fonction sera appelée lorsque les informations sur l'utilisateur changent
   checkMacAddress(clientNum)

   local userinfo = et.trap_GetUserinfo(clientNum)
   local _, _, name = string.find(userinfo, "name\\([^\\]+)\\")
   
   if name then
      -- et.G_Print("ClientUserinfoChanged: " .. clientNum .. " New Name: " .. name .. "\n")

      -- Vérifier si le nom est "UnnamedPlayer" et exécuter les commandes
      if name == "UnnamedPlayer" then
         local combinedCommands = "put " .. clientNum .. " s; rename " .. clientNum .. " " .. newPseudo
         et.trap_SendConsoleCommand(et.EXEC_APPEND, combinedCommands)
         --et.trap_DropClient(clientNum, badPseudo, 0) -- kick immédiatement
      end
   end
end

function et_RunFrame(levelTime)
   -- Cette fonction est appelée à chaque frame
   checkTimers(levelTime)
end
