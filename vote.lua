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
        et.G_Print("Erreur: Impossible d'ouvrir le fichier " .. fichierVotes .. "\n")
    end

    -- Ajoutez ces impressions pour déboguer
    et.G_Print("Likes: " .. votes.like .. "\n")
    et.G_Print("Dislikes: " .. votes.dislike .. "\n")
    et.G_Print("Total Votes: " .. votes.totalVotes .. "\n")

    return votes
end

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
end

-- Fonction pour supprimer les espaces blancs au début et à la fin d'une chaîne
function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Fonction pour sauvegarder les votes dans un fichier
local function sauvegarderVotes(addVote)
    local dossierVotes = "votes/"
    local mapname = et.trap_Cvar_Get("mapname")
    local fichierVotes = dossierVotes .. "vote_" .. mapname .. ".txt"

    -- Charger les valeurs existantes à partir du fichier
    local existingVotes = chargerVotes(fichierVotes)

    -- DEBUG
    -- et.trap_SendServerCommand(-1, "chat \"^3Map vote:^7 " .. addVote)

    -- Mettre à jour les valeurs existantes avec les nouvelles statistiques de votes en fonction du like ou dislike 
    -- Permet d'éviter d'avoir des x2 ou des +1 partout...
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
        et.G_Print("Erreur : Impossible d'ouvrir le fichier " .. fichierVotes .. "\n")
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

-- Fonction pour gérer la commande !like
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
        playersVoted[clientNum] = true
        -- Sauvegarder les votes après chaque nouveau vote
        sauvegarderVotes(addVote)
    else
        et.trap_SendServerCommand(clientNum, "chat \"^1You have already voted!^7\"")
    end
end

-- Fonction pour gérer la commande !dislike
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
        playersVoted[clientNum] = true
        -- Sauvegarder les votes après chaque nouveau vote
        sauvegarderVotes(addVote)
    else
        et.trap_SendServerCommand(clientNum, "chat \"^1You have already voted!^7\"")
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