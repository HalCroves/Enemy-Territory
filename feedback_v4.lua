--[[
Prerequisites:
 - Create a "votes" folder at the root of the server.
]]

-- Fonction pour charger les votes à partir du fichier - doit être chargé avant le et_InitGame
function chargerVotes(fichierVotes)
    local votes = {
        like = 0,
        dislike = 0,
        totalVotes = 0,
    }

    local fichier = io.open(fichierVotes, "r")
    if fichier then
        -- Lire les statistiques existantes à partir du fichier
        for line in fichier:lines() do
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
        fichier:close()
    else
        -- et.G_Print("Erreur: Impossible d'ouvrir le fichier " .. fichierVotes .. "\n")
    end

    -- Ajoutez ces impressions pour déboguer
    -- et.G_Print("Likes: " .. votes.like .. "\n")
    -- et.G_Print("Dislikes: " .. votes.dislike .. "\n")
    -- et.G_Print("Total Votes: " .. votes.totalVotes .. "\n")

    return votes
end

Modname = "Vote like or dislike - HalCroves/Bertha"
Version = "2.3"

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


function et_InitGame(leveltime, randomseed, restart)
    et.G_Print("^z[" .. Modname .. "^z] Version:" .. Version .. " Loaded\n")
    et.RegisterModname(et.Q_CleanStr(Modname) .. "   " .. Version .. "   " .. et.FindSelf())

    local mapname = et.trap_Cvar_Get("mapname")

    -- Nom du fichier de sauvegarde pour la map actuelle
    fichierVotes = dossierVotes .. "vote_" .. mapname .. ".txt"

    -- Vérifier la présence du fichier et le créer s'il est absent
    local fichier = io.open(fichierVotes, "r")
    if not fichier then
        et.G_Print("Le fichier " .. fichierVotes .. " n'existe pas. Création du fichier...\n")

        local nouveauFichier, erreur = io.open(fichierVotes, "w")
        if nouveauFichier then
            nouveauFichier:close()
            et.G_Print("Fichier " .. fichierVotes .. " créé avec succès.\n")
        else
            et.G_Print("Erreur : " .. erreur .. "\n")
        end
    else
        fichier:close()
    end

    -- Initialisation des variables
    votes = chargerVotes(fichierVotes)

    -- Réinitialiser le marqueur feedbackMessageSent
    feedbackMessageSent = false

    -- Nom du fichier de sauvegarde pour les joueurs ayant voté pour la map actuelle
    local fichierPlayersVotes = dossierVotes .. "players_vote_" .. mapname .. ".txt"

    -- Vérifier la présence du fichier et le créer s'il est absent
    local fichierPlayers = io.open(fichierPlayersVotes, "r")
    if not fichierPlayers then
        et.G_Print("Le fichier " .. fichierPlayersVotes .. " n'existe pas. Création du fichier...\n")

        local nouveauFichierPlayers, erreurPlayers = io.open(fichierPlayersVotes, "w")
        if nouveauFichierPlayers then
            nouveauFichierPlayers:close()
            et.G_Print("Fichier " .. fichierPlayersVotes .. " créé avec succès.\n")
        else
            et.G_Print("Erreur : " .. erreurPlayers .. "\n")
        end
    else
        fichierPlayers:close()
    end
end

-- Fonction pour supprimer les espaces blancs au début et à la fin d'une chaîne
function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Fonction pour diviser une chaîne en parties en utilisant un délimiteur
local function splitString(inputString, delimiter)
    local parts = {}
    for part in string.gmatch(inputString, "[^" .. delimiter .. "]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Fonction pour sauvegarder les votes dans un fichier
local function sauvegarderVotes(addVote, clientNum, mapname)
    local dossierVotes = "votes/"
    local fichierVotes = dossierVotes .. "vote_" .. mapname .. ".txt"
    local fichierPlayersVotes = dossierVotes .. "players_vote_" .. mapname .. ".txt"

    -- Charger les valeurs existantes à partir du fichier
    local existingVotes = chargerVotes(fichierVotes)

    -- Trouver et mettre à jour le vote précédent du joueur dans le fichier players_vote_<mapname>.txt
    local playerName = et.gentity_get(clientNum, "pers.netname")
    local clientGuid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "n_guid")

    local lines = {}
    local foundPlayer = false

    -- Charger les lignes du fichier en mémoire
    local fichierPlayers = io.open(fichierPlayersVotes, "r")
    if fichierPlayers then
        for line in fichierPlayers:lines() do
            local parts = splitString(line, ";")
            local storedClientGuid = parts[2]
            local storedPlayerName = parts[1]

            if #parts == 5 and storedClientGuid == clientGuid and parts[3] == mapname then
                -- Le joueur a déjà voté, mettre à jour le dernier champ de la ligne
                local previousVote = parts[4]
                if previousVote == "like" then
                    existingVotes.like = math.max(existingVotes.like - 1, 0)
                elseif previousVote == "dislike" then
                    existingVotes.dislike = math.max(existingVotes.dislike - 1, 0)
                end

                -- Mettre à jour le champ du nombre de votes
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
        fichierPlayers:close()
    end

    -- Si le joueur n'a pas été trouvé, ajouter une nouvelle ligne
    if not foundPlayer then
        table.insert(lines, playerName .. ";" .. clientGuid .. ";" .. mapname .. ";" .. addVote .. ";1")  -- 1 est le nombre initial de votes
    end

    -- Sauvegarder les lignes dans le fichier
    local fichierPlayers = io.open(fichierPlayersVotes, "w")
    if not fichierPlayers then
        -- et.G_Print("Erreur : Impossible d'ouvrir le fichier " .. fichierPlayersVotes .. "\n")
        return
    end

    for _, line in ipairs(lines) do
        fichierPlayers:write(line .. "\n")
    end

    fichierPlayers:close()

    -- Mettre à jour les valeurs existantes avec les nouvelles statistiques de votes en fonction du like ou dislike
    if addVote == "like" then
        existingVotes.like = existingVotes.like + 1
    else
        existingVotes.dislike = existingVotes.dislike + 1
    end

    existingVotes.totalVotes = existingVotes.like + existingVotes.dislike

    -- Vérifier si totalVotes est différent de zéro avant de calculer le pourcentage -> arrondi à 0.5
    local pourcentageLiked = existingVotes.totalVotes ~= 0 and math.floor((existingVotes.like / existingVotes.totalVotes) * 100 + 0.5) or 0

    -- Sauvegarder les valeurs mises à jour
    local fichier = io.open(fichierVotes, "w")
    if not fichier then
        -- et.G_Print("Erreur : Impossible d'ouvrir le fichier " .. fichierVotes .. "\n")
        return
    end

    fichier:write("Map: " .. mapname .. "\n")
    fichier:write("Likes: " .. existingVotes.like .. "\n")
    fichier:write("Dislikes: " .. existingVotes.dislike .. "\n")
    fichier:write("Total Votes: " .. existingVotes.totalVotes .. "\n")
    fichier:write("Liked map: " .. pourcentageLiked .. "%\n")
    fichier:close()
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

    local fichierPlayers = io.open(fichierPlayersVotes, "r")
    if fichierPlayers then
        for line in fichierPlayers:lines() do
            local parts = splitString(line, ";")
            if #parts == 5 and parts[2] == clientGuid and parts[3] == mapname then
                fichierPlayers:close()
                return true, parts[4]  -- Retourner le vote du joueur
            end
        end
        fichierPlayers:close()
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

    local fichier = io.open(fichierVotes, "r")
    if not fichier then
        return 0  -- Retourner 0 en cas d'erreur ou si le fichier n'existe pas
    else
        --et.G_Print("Fichier OK")
    end

    local pourcentageLiked = 0

    -- Recherche de la ligne contenant "Liked map"
    local likedMapLine
    for line in fichier:lines() do
        if line:find("Liked map:") then
            likedMapLine = line
            break
        end
    end

    -- Extraction du pourcentage si la ligne est trouvée
    if likedMapLine then
        local value = likedMapLine:match("(%d+)%%")
        if value then
            --et.G_Print("Liked map trouvé : " .. value)
            pourcentageLiked = tonumber(value)
        else
            --et.G_Print("Pourcentage non trouvé")
        end
    else
        --et.G_Print("Liked map pas vu")
    end

    fichier:close()

    return pourcentageLiked
end

-- Fonction pour extraire le nombre de votes "Likes" et "Dislikes"
local function extractVotes(mapname)
    local fichierVotes = dossierVotes .. "vote_" .. mapname .. ".txt"

    local fichier = io.open(fichierVotes, "r")
    if not fichier then
        return 0, 0, 0  -- Retourner 0 en cas d'erreur ou si le fichier n'existe pas
    else
        --et.G_Print("Fichier OK")
    end

    local likes = 0
    local dislikes = 0
    local totalVotes = 0

    -- Recherche des lignes contenant "Likes" et "Dislikes"
    for line in fichier:lines() do
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

    fichier:close()

    return likes, dislikes, totalVotes
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

-- Variable pour suivre si le message a déjà été envoyé
local feedbackMessageSent = false

-- Fonction pour vérifier si la carte est terminée
local function checkGameEnd()
    local gameState = et.trap_Cvar_Get("gamestate")
    local mapname = et.trap_Cvar_Get("mapname")

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
end

function et_RunFrame(levelTime)
    checkGameEnd()
end