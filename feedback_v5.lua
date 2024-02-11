--[[
Prerequisites:
 - Create a "votes" folder on the nitmod repertory.
 Ex : \nitmod\votes
]]

-- Fonction pour supprimer les espaces blancs au début et à la fin d'une chaîne
function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Function to split a string into a table using a delimiter
local function splitString(inputString, delimiter)
    local parts = {}
    for part in inputString:gmatch("[^" .. delimiter .. "]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Function to read file content
local function readFile(filename)
    local fd, len = et.trap_FS_FOpenFile(filename, et.FS_READ)
    if fd == -1 then
        return nil
    end

    local filedata = et.trap_FS_Read(fd, len)
    et.trap_FS_FCloseFile(fd)

    return filedata
end

-- Function to write content to a file
local function writeFile(filename, content)
    local fd, len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
    if fd == -1 then
        return false
    end

    et.trap_FS_Write(content, #content, fd)
    et.trap_FS_FCloseFile(fd)

    return true
end

-- Function to handle file existence check and creation
local function createFileIfNotExists(filename)
    local filedata = readFile(filename)

    if not filedata then
        et.G_Print("File " .. filename .. " does not exist. Creating the file...\n")
        writeFile(filename, "")
        et.G_Print("File " .. filename .. " created successfully.\n")
    end
end

-- Function to load votes from a file
function chargerVotes(fichierVotes)
    createFileIfNotExists(fichierVotes)

    local votes = {
        like = 0,
        dislike = 0,
        totalVotes = 0,
    }

    local filedata = readFile(fichierVotes)

    if filedata then
        for line in filedata:gmatch("[^\r\n]+") do
            local key, value = line:match("(%S+):%s+(%S+)")
            if key and value then
                key = key:lower()
                value = tonumber(value)
                if key == "likes" then
                    votes.like = value
                elseif key == "dislikes" then
                    votes.dislike = value
                elseif key == "totalvotes" then
                    votes.totalVotes = value
                end
            end
        end
    else
        -- et.G_Print("Error: Unable to open file " .. fichierVotes .. "\n")
    end

    -- Add these prints for debugging
    -- et.G_Print("Likes: " .. votes.like .. "\n")
    -- et.G_Print("Dislikes: " .. votes.dislike .. "\n")
    -- et.G_Print("Total Votes: " .. votes.totalVotes .. "\n")

    return votes
end

Modname = "Vote like or dislike - HalCroves/Bertha"
Version = "2.5"

-- Table pour stocker les joueurs ayant déjà voté
local playersVoted = {}

-- Nouvelle variable pour compter les votes du joueur
local votesCount = 0

-- Nom du dossier de sauvegarde
local dossierVotes = "votes/"

-- Nom du fichier de sauvegarde pour la map actuelle
local fichierVotes

-- Initialisation des variables
local votes = {
    like = 0,
    dislike = 0,
    totalVotes = 0,
}
-- don't touche this
local MAX_VOTES_PER_MAP = 3

-- Show percentage for each vote
-- False/true
local ShowPercentageForEachVote = false

-- Show percentage at the end of map
-- False/true
local ShowNumberVotesAtTheEnd = true

-- Show percentage at the first of map
-- False/true
local ShowNumberVotesAtTheFirst = true

function et_InitGame(levelTime, randomseed, restart)
    et.G_Print("^z[" .. Modname .. "^z] Version:" .. Version .. " Loaded\n")
    et.RegisterModname(et.Q_CleanStr(Modname) .. "   " .. Version .. "   " .. et.FindSelf())

    local mapname = et.trap_Cvar_Get("mapname")

    -- Nom du fichier de sauvegarde pour la map actuelle
    fichierVotes = dossierVotes .. "vote_" .. mapname .. ".txt"

    -- Vérifier la présence du fichier et le créer s'il est absent
    createFileIfNotExists(fichierVotes)

    -- Initialisation des variables
    votes = chargerVotes(fichierVotes)

    -- Réinitialiser le marqueur feedbackMessageSent
    feedbackMessageSent = false

    MessageSentTop = false

    -- Nom du fichier de sauvegarde pour les joueurs ayant voté pour la map actuelle
    local fichierPlayersVotes = dossierVotes .. "players_vote_" .. mapname .. ".txt"
    createFileIfNotExists(fichierPlayersVotes)
end

-- Function to save votes to a file
local function sauvegarderVotes(addVote, clientNum, mapname)
    local fichierVotes = dossierVotes .. "vote_" .. mapname .. ".txt"
    createFileIfNotExists(fichierVotes)

    local existingVotes = chargerVotes(fichierVotes)

    local playerName = et.gentity_get(clientNum, "pers.netname")
    local clientGuid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "n_guid")

    local lines = {}
    local foundPlayer = false

    local fichierPlayersVotes = dossierVotes .. "players_vote_" .. mapname .. ".txt"
    createFileIfNotExists(fichierPlayersVotes)

    local filedataPlayers = readFile(fichierPlayersVotes)

    if filedataPlayers then
        for line in filedataPlayers:gmatch("[^\r\n]+") do
            local parts = splitString(line, ";")  -- Corrected line
            local storedClientGuid = parts[2]
            local storedPlayerName = parts[1]
    
            if #parts == 5 and storedClientGuid == clientGuid and parts[3] == mapname then
                local previousVote = parts[4]
                if previousVote == "like" then
                    existingVotes.like = math.max(existingVotes.like - 1, 0)
                elseif previousVote == "dislike" then
                    existingVotes.dislike = math.max(existingVotes.dislike - 1, 0)
                end
    
                votesCount = tonumber(parts[5]) or 0
                if votesCount < 0 then votesCount = 0 end
                votesCount = math.min(votesCount + 1, MAX_VOTES_PER_MAP)
                parts[5] = tostring(votesCount)
    
                parts[4] = addVote
                foundPlayer = true
                parts[1] = playerName
            end
            table.insert(lines, table.concat(parts, ";"))
        end
    end

    if not foundPlayer then
        table.insert(lines, playerName .. ";" .. clientGuid .. ";" .. mapname .. ";" .. addVote .. ";1")
    end

    local filedataPlayersUpdated = table.concat(lines, "\n")
    writeFile(fichierPlayersVotes, filedataPlayersUpdated)

    if addVote == "like" then
        existingVotes.like = existingVotes.like + 1
    else
        existingVotes.dislike = existingVotes.dislike + 1
    end

    existingVotes.totalVotes = existingVotes.like + existingVotes.dislike

    local pourcentageLiked = existingVotes.totalVotes ~= 0 and math.floor((existingVotes.like / existingVotes.totalVotes) * 100 + 0.5) or 0

    local fileContent = "Map: " .. mapname .. "\n" ..
                        "Likes: " .. existingVotes.like .. "\n" ..
                        "Dislikes: " .. existingVotes.dislike .. "\n" ..
                        "Total Votes: " .. existingVotes.totalVotes .. "\n" ..
                        "Liked map: " .. pourcentageLiked .. "%\n"

    writeFile(fichierVotes, fileContent)
end

-- Fonction pour vérifier si le match est en cours
local function isGameInProgress()
    local gameState = et.trap_Cvar_Get("gamestate")
    return gameState == "0" or gameState == "" or gameState == "3" -- 0 pour "GAME_STATE_PLAYING", 3 pour "GAME_STATE_POSTGAME"
end

-- Fonction pour vérifier si le joueur a déjà voté en utilisant le n_guid
local function hasPlayerVoted(clientNum, mapname)
    local clientGuid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "n_guid")
    local fichierPlayersVotes = dossierVotes .. "players_vote_" .. mapname .. ".txt"

    createFileIfNotExists(fichierPlayersVotes)

    local filedataPlayers = readFile(fichierPlayersVotes)

    if filedataPlayers then
        for line in filedataPlayers:gmatch("[^\r\n]+") do
            local parts = splitString(line, ";")
            if #parts == 5 and parts[2] == clientGuid and parts[3] == mapname then
                return true, parts[4]  -- Retourner le vote du joueur
            end
        end
    end

    return false, nil
end

-- Mettre un code couleur en fonction du pourcentage
local function getColorCode(pourcentage)
    if pourcentage >= 75 then
        return "^2"  -- Vert pourcentage élevé
    elseif pourcentage >= 50 then
        return "^3"  -- Orange pourcentage moyen
    else
        return "^1"  -- Rouge pourcentage bas
    end
end

-- Fonction pour extraire le pourcentage de "liked map"
local function extractLikedMapPercentage(mapname)
    local fichierVotes = dossierVotes .. "vote_" .. mapname .. ".txt"

    createFileIfNotExists(fichierVotes)

    local filedata = readFile(fichierVotes)

    if filedata then
        local pourcentageLiked = 0

        for line in filedata:gmatch("[^\r\n]+") do
            if line:find("Liked map:") then
                local value = line:match("(%d+)%%")
                if value then
                    pourcentageLiked = tonumber(value)
                    break
                end
            end
        end

        return pourcentageLiked
    else
        return 0
    end
end

-- Fonction pour extraire le nombre de votes "Likes" et "Dislikes"
local function extractVotes(mapname)
    local fichierVotes = dossierVotes .. "vote_" .. mapname .. ".txt"

    createFileIfNotExists(fichierVotes)

    local filedata = readFile(fichierVotes)

    if filedata then
        local likes = 0
        local dislikes = 0
        local totalVotes = 0

        for line in filedata:gmatch("[^\r\n]+") do
            local likesMatch = line:match("Likes: (%d+)")
            if likesMatch then
                likes = tonumber(likesMatch)
            end

            local dislikesMatch = line:match("Dislikes: (%d+)")
            if dislikesMatch then
                dislikes = tonumber(dislikesMatch)
            end

            local totalVotesMatch = line:match("Total Votes: (%d+)")
            if totalVotesMatch then
                totalVotes = tonumber(totalVotesMatch)
            end

            -- Sortir de la boucle si les trois informations sont trouvées
            if likes > 0 and dislikes > 0 and totalVotes > 0 then
                break
            end
        end

        return likes, dislikes, totalVotes
    else
        return 0, 0, 0
    end
end

-- Fonction de vote -> LIKE
local function likeCommand(clientNum, mapname)
    local playerName = et.gentity_get(clientNum, "pers.netname")
    local addVote = "like"

    local hasVoted, previousVote = hasPlayerVoted(clientNum, mapname)

    -- Vérifier si le match est en cours
    if not isGameInProgress() then
        et.trap_SendServerCommand(clientNum, "chat \"^3Map Feedback: ^1Voting is not allowed at the moment! You must wait for the match to start.^7\"")
        return
    end

    -- Vérifier si le joueur a atteint le nombre maximum de votes
    if votesCount >= MAX_VOTES_PER_MAP then
        et.trap_SendServerCommand(clientNum, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7you have reached the maximum number of votes on ^3" .. mapname .. " ^7map!\"")
        return
    end
    
    if hasVoted then
        if previousVote == addVote then
            et.trap_SendServerCommand(clientNum, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7you have already voted ^2LIKE^7. You can change your vote using ^1/dislike^7.\"")
        else
            votes.like = votes.like + 1
            votes.dislike = votes.dislike - 1
            
            -- Mettre à jour le fichier "players_vote_<mapname>.txt"
            playersVoted[clientNum] = addVote
            sauvegarderVotes(addVote, clientNum, mapname)

            -- Ajouter le % de like
            if ShowPercentageForEachVote == true then 
                local pourcentageLiked = extractLikedMapPercentage(mapname)
                local colorCode = getColorCode(pourcentageLiked)
                et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7changed their vote to ^2LIKE^7 for ^3"..mapname.." ^7map! Liked map: " .. colorCode.. pourcentageLiked .. "/100.\"")
            else 
                et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7changed their vote to ^2LIKE^7 for ^3"..mapname.." ^7map!\"")
            end
        end
    else
        -- Le joueur n'a pas encore voté
        votes.like = votes.like + 1
        votes.totalVotes = votes.totalVotes + 1

        -- Marquer le joueur comme ayant voté
        playersVoted[clientNum] = addVote
        -- Sauvegarder les votes après chaque nouveau vote
        sauvegarderVotes(addVote, clientNum, mapname)

        -- Ajouter le % de like
        if ShowPercentageForEachVote == true then 
            local pourcentageLiked = extractLikedMapPercentage(mapname)
            local colorCode = getColorCode(pourcentageLiked)
            et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7gave a ^2LIKE ^7for ^3"..mapname.." ^7map! Liked map: " .. colorCode.. pourcentageLiked .. "/100.\"")
        else
            et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7gave a ^2LIKE ^7for ^3"..mapname.." ^7map!\"")
        end
    end
end

-- Fonction de vote -> DISLIKE
local function dislikeCommand(clientNum, mapname)
    local playerName = et.gentity_get(clientNum, "pers.netname")
    local addVote = "dislike"

    local hasVoted, previousVote = hasPlayerVoted(clientNum, mapname)

    -- Vérifier si le match est en cours
    if not isGameInProgress() then
        et.trap_SendServerCommand(clientNum, "chat \"^3Map Feedback: ^1Voting is not allowed at the moment! You must wait for the match to start.^7\"")
        return
    end

    -- Vérifier si le joueur a atteint le nombre maximum de votes
    if votesCount >= MAX_VOTES_PER_MAP then
        et.trap_SendServerCommand(clientNum, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7you have reached the maximum number of votes on ^3" .. mapname .. " ^7map!\"")
        return
    end
    
    if hasVoted then
        if previousVote == addVote then
            et.trap_SendServerCommand(clientNum, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7you have already voted ^1DISLIKE^7. You can change your vote using ^2/like^7.\"")
        else
            votes.like = votes.like - 1
            votes.dislike = votes.dislike + 1
            
            -- Mettre à jour le fichier "players_vote_<mapname>.txt"
            playersVoted[clientNum] = addVote
            sauvegarderVotes(addVote, clientNum, mapname)

            -- Ajouter le % de like
            if ShowPercentageForEachVote == true then
                local pourcentageLiked = extractLikedMapPercentage(mapname)
                local colorCode = getColorCode(pourcentageLiked)
                et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7changed their vote to ^1DISLIKE^7 for ^3"..mapname.." ^7map! Liked map: " .. colorCode.. pourcentageLiked .. "/100.\"")
            else
                et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7changed their vote to ^1DISLIKE^7 for ^3"..mapname.." ^7map!\"")
            end
        end
    else
        -- Le joueur n'a pas encore voté
        votes.dislike = votes.dislike + 1
        votes.totalVotes = votes.totalVotes + 1

        -- Marquer le joueur comme ayant voté
        playersVoted[clientNum] = addVote
        -- Sauvegarder les votes après chaque nouveau vote
        sauvegarderVotes(addVote, clientNum, mapname)
        
        -- Ajouter le % de like
        if ShowPercentageForEachVote == true then 
            local pourcentageLiked = extractLikedMapPercentage(mapname)
            local colorCode = getColorCode(pourcentageLiked)
            et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7gave a ^1DISLIKE ^7for ^3"..mapname.." ^7map! Liked map: " .. colorCode.. pourcentageLiked .. "/100.\"")
        else
            et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7gave a ^1DISLIKE ^7for ^3"..mapname.." ^7map!\"")
        end
    end
end


-- Fonction pour traiter les commandes des joueurs via la console "/"
-- Fonction pour traiter les commandes des joueurs via le "!"
function et_ClientCommand(clientNum, command)
    local argc = et.trap_Argc()
    local i = 0
    local arg = {}
    local mapname = et.trap_Cvar_Get("mapname")
    local gameState = et.trap_Cvar_Get("gamestate")

    while (i < argc) do
        arg[i + 1] = et.trap_Argv(i)
        i = i + 1
    end

    if gameState == "3" then
        if (arg[1] == "say" and arg[2] ~= nil) then
            if (arg[2] == "+") then
                likeCommand(clientNum, mapname)
                return 1 -- ne pas avoir l'affichage de la commande
            elseif (arg[2] == "-") then
                dislikeCommand(clientNum, mapname)
                return 1 -- ne pas avoir l'affichage de la commande
            end
        end
    else
        -- Ajoutez ici d'autres conditions pour gérer les commandes dans d'autres états du jeu
        if command:find("^like") then
            likeCommand(clientNum, mapname)
            return 1 -- ne pas avoir de message 'unknow cmd xx'
        elseif command:find("^dislike") then
            dislikeCommand(clientNum, mapname)
            return 1 -- ne pas avoir de message 'unknow cmd xx'
        elseif arg[2] == "!like" then
            likeCommand(clientNum, mapname)
            return 1 -- ne pas avoir l'affichage de la commande
        elseif arg[2] == "!dislike" then
            dislikeCommand(clientNum, mapname)
            return 1 -- ne pas avoir l'affichage de la commande
        end
    end

    return 0
end

-- Variable pour suivre si le message a déjà été envoyé en fin de map
local feedbackMessageSent = false

-- Variable pour suivre si le message a déjà été envoyé en début de map
local MessageSentTop = false

-- Fonction pour vérifier si la carte est terminée
local function checkStatusGame()
    local gameState = et.trap_Cvar_Get("gamestate")
    local mapname = et.trap_Cvar_Get("mapname")
    local warmup = et.trap_Cvar_Get("g_warmup")

    -- 3 pour "GAME_STATE_POSTGAME"
    if gameState == "3" and not feedbackMessageSent then
        -- La carte est terminée, envoyez un message à tous les joueurs
        et.trap_SendServerCommand(-1, "chat \"^3Map Feedback: ^7Do you like the map? Type ^2+ ^7or ^1-^7. Thanks for your feedback! \"")

        -- Afficher le nombre de vote à la fin
        if ShowNumberVotesAtTheEnd == true then
            local liked, disliked = extractVotes(mapname)
            et.trap_SendServerCommand(-1, "chat \"^3Current Votes:^7 "..liked.." likes and "..disliked.." dislikes.\"")
        end

        -- Marquer que le message a été envoyé
        feedbackMessageSent = true
    end

    -- 0 la map vient de commencer
    if gameState == "0" and not MessageSentTop then
        -- Afficher le nombre de vote en début de map
        if ShowNumberVotesAtTheFirst == true then
            local liked, disliked = extractVotes(mapname)
            et.trap_SendServerCommand(et.EXEC_APPEND, "chat \"^3Map Feedback: ^7Do you like the map? Type ^2!like ^7or ^1!dislike^7. Thanks for your feedback! \"")
            et.trap_SendConsoleCommand(et.EXEC_APPEND, "chat ^3Current Votes:^7 "..liked.." likes and "..disliked.." dislikes.\n");
        end

        -- Marquer que le message a été envoyé
        MessageSentTop = true
    end
    
end

function et_RunFrame(levelTime)
    checkStatusGame()
end