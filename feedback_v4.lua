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
Version = "2.0"

-- Table pour stocker les joueurs ayant déjà voté
local playersVoted = {}

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
local function sauvegarderVotes(addVote, clientNum)
    local dossierVotes = "votes/"
    local mapname = et.trap_Cvar_Get("mapname")
    local fichierVotes = dossierVotes .. "vote_" .. mapname .. ".txt"
    local fichierPlayersVotes = dossierVotes .. "players_vote_" .. mapname .. ".txt"

    -- Charger les valeurs existantes à partir du fichier
    local existingVotes = chargerVotes(fichierVotes)

    -- Trouver et mettre à jour le vote précédent du joueur dans le fichier players_vote_<mapname>.txt
    local playerName = et.gentity_get(clientNum, "pers.netname")
    local clientGuid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")

    local lines = {}
    local foundPlayer = false

    -- Charger les lignes du fichier en mémoire
    local fichierPlayers = io.open(fichierPlayersVotes, "r")
    if fichierPlayers then
        for line in fichierPlayers:lines() do
            local parts = splitString(line, ";")
            if #parts == 4 and parts[1] == playerName and parts[2] == clientGuid and parts[3] == mapname then
                -- Le joueur a déjà voté, mettre à jour le dernier champ de la ligne
                local previousVote = parts[4]
                if previousVote == "like" then
                    existingVotes.like = math.max(existingVotes.like - 1, 0)
                elseif previousVote == "dislike" then
                    existingVotes.dislike = math.max(existingVotes.dislike - 1, 0)
                end

                parts[4] = addVote
                foundPlayer = true
            end
            table.insert(lines, table.concat(parts, ";"))
        end
        fichierPlayers:close()
    end

    -- Si le joueur n'a pas été trouvé, ajouter une nouvelle ligne
    if not foundPlayer then
        table.insert(lines, playerName .. ";" .. clientGuid .. ";" .. mapname .. ";" .. addVote)
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

-- Fonction de vote -> LIKE
local function likeCommand(clientNum, mapname)
    local playerName = et.gentity_get(clientNum, "pers.netname")
    local addVote = "like"

    -- Vérifier si le match est en cours
    if not isGameInProgress() then
        et.trap_SendServerCommand(clientNum, "chat \"^1Voting is not allowed at the moment!^7\"")
        return
    end

    -- Vérifier si le joueur a déjà voté
    if not playersVoted[clientNum] then
        votes.like = votes.like + 1
        votes.totalVotes = votes.totalVotes + 1
        et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7gave a ^2LIKE ^7for ^3"..mapname.." ^7map!\"")

        -- Marquer le joueur comme ayant voté
        playersVoted[clientNum] = addVote
        -- Sauvegarder les votes après chaque nouveau vote
        sauvegarderVotes(addVote, clientNum)
    else
        -- Le joueur a déjà voté
        local previousVote = playersVoted[clientNum]
        if previousVote == addVote then
            et.trap_SendServerCommand(clientNum, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7you have already voted ^2LIKE^7. You can change your vote using ^1/dislike^7.\"")
        else
            votes.like = votes.like + 1
            votes.dislike = votes.dislike - 1
            et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7changed their vote to ^2LIKE^7 for ^3"..mapname.." ^7map!\"")
            -- Mettre à jour le fichier "players_vote_<mapname>.txt"
            playersVoted[clientNum] = addVote
            sauvegarderVotes(addVote, clientNum)
        end
    end
end

-- Fonction de vote -> DISLIKE
local function dislikeCommand(clientNum, mapname)
    local playerName = et.gentity_get(clientNum, "pers.netname")
    local addVote = "dislike"

    -- Vérifier si le match est en cours
    if not isGameInProgress() then
        et.trap_SendServerCommand(clientNum, "chat \"^1Voting is not allowed at the moment!^7\"")
        return
    end

    -- Vérifier si le joueur a déjà voté
    if not playersVoted[clientNum] then
        votes.dislike = votes.dislike + 1
        votes.totalVotes = votes.totalVotes + 1
        et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7gave a ^1DISLIKE ^7for ^3"..mapname.." ^7map!\"")

        -- Marquer le joueur comme ayant voté
        playersVoted[clientNum] = addVote
        -- Sauvegarder les votes après chaque nouveau vote
        sauvegarderVotes(addVote, clientNum)
    else
        -- Le joueur a déjà voté
        local previousVote = playersVoted[clientNum]
        if previousVote == addVote then
            et.trap_SendServerCommand(clientNum, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7you have already voted ^1DISLIKE^7. You can change your vote using ^2/like^7.\"")
        else
            votes.like = votes.like - 1
            votes.dislike = votes.dislike + 1
            et.trap_SendServerCommand(-1, "chat \"^3Map Feedback:^7 " .. playerName .. " ^7changed their vote to ^1DISLIKE^7 for ^3"..mapname.." ^7map!\"")
            -- Mettre à jour le fichier "players_vote_<mapname>.txt"
            playersVoted[clientNum] = addVote
            sauvegarderVotes(addVote, clientNum)
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

    -- 3 pour "GAME_STATE_POSTGAME"
    if gameState == "3" and not feedbackMessageSent then
        -- La carte est terminée, envoyez un message à tous les joueurs
        et.trap_SendServerCommand(-1, "chat \"^3Map Feedback: ^7Do you like the map? Open console and type ^2/like ^7or ^1/dislike^7. Thanks for your feedback! \"")

        -- Marquer que le message a été envoyé
        feedbackMessageSent = true
    end
end

function et_RunFrame(levelTime)
    checkGameEnd()
end
