---------------------------------
------- Dynamite counter --------
-------  By Necromancer  --------
-------    5/04/2009     --------
------- www.usef-et.org  --------
---------------------------------

SHOW = 2
-- 0 means disable
-- 1 means only the team that planted the dyno
-- 2 means everyone

ONE = 1
-- if set to 1, will process only one dynamite per place.
-- set to 0 to process all dyno's.

-- This script can be freely used and modified as long as the original author\s are mentioned (and their homepage: www.usef-et.org)

-- <TIME> gets substituted by the time left
-- <PLACE> substituted by the thing going to blow
-- default - well, default message if nothing specified. (self-explanatory)
-- message[dynamite_time_left] = message_to_show
MESSAGE = {}
MESSAGE.DEFAULT = "^1<TIME> ^wSeconds till explosion!!"
MESSAGE[20] = "^a<TIME> ^wSeconds till ^2<PLACE> ^wexplosion!!"
MESSAGE[10] = "^a<TIME> ^wSeconds till ^2<PLACE> ^wexplosion!!"
MESSAGE[3] = ""
MESSAGE[2] = ""
MESSAGE[1] = ""
MESSAGE[0] = "^1>>> B00M <<<"

TIME_TO_ADD = 30 -- Time to add (in seconds) when a dynamite is defused

if et.trap_Cvar_Get("gamename") == "etpro" then
    CHAT = "b 8"
    POPUP = "etpro"
else
    CHAT = "chat"
    POPUP = "nitmod"
end

timer = {}

OLD = os.time()

-- Seuils de temps pour les messages d'avertissement
WARNING_THRESHOLDS = {60, 30, 10}

-- Délai minimum entre les messages d'avertissement (en secondes)
WARNING_DELAY = 10

-- Derniers temps d'envoi des avertissements
last_warning_sent = {}

-- Fonction pour envoyer des messages d'avertissement
function check_warnings(current_time)
    local time_left = et.trap_Cvar_Get("timelimit") * 60 - (current_time - OLD)
    for _, threshold in ipairs(WARNING_THRESHOLDS) do
        if time_left <= threshold and time_left > (threshold - 10) then
            if not last_warning_sent[threshold] or (current_time - last_warning_sent[threshold]) >= WARNING_DELAY then
                local message = string.format("^1Attention^w! Il ne reste que ^2%d ^wsecondes jusqu'à la fin de la carte!", time_left)
                et.trap_SendServerCommand(-1, string.format('%s \"%s\"\n', CHAT, message))
                last_warning_sent[threshold] = current_time
            end
        end
    end
end

function et_RunFrame(levelTime)
    current = os.time()
    for dyno, temp in pairs(timer) do
        if timer[dyno]["time"] - current >= 0 then
            for key, temp in pairs(timer[dyno]) do
                if type(key) == "number" then
                    if timer[dyno]["time"] - current == key then
                        send_print(timer, dyno, key)
                        timer[dyno][key] = nil
                    end
                end
            end
        else
            place_destroyed(timer[dyno]["place"])
        end
    end
    
    -- Vérifiez les messages d'avertissement sur le temps restant
    check_warnings(current)
end

-- Les autres fonctions restent inchangées
function place_destroyed(place)
    for dynamite, temp in pairs(timer) do
        if timer[dynamite]["place"] == place then
            timer[dynamite] = nil
        end
    end
end

function send_print(timer, dyno, ttime)
    if SHOW == 0 then return end
    if SHOW == 1 then
        for player = 0, tonumber(et.trap_Cvar_Get("sv_maxclients")) - 1, 1 do
            if et.gentity_get(player, "sess.sessionTeam") == timer[dyno]["team"] then
                print_message(player, ttime, timer[dyno]["place"])
            end
        end
    else
        print_message(-1, ttime, timer[dyno]["place"])
    end
end

function print_message(slot, ttime, place)
    message = MESSAGE.DEFAULT
    if type(MESSAGE[ttime]) == "string" and MESSAGE[ttime] ~= "" then
        message = MESSAGE[ttime]
    end
    message = string.gsub(message, "<TIME>", ttime)
    message = string.gsub(message, "<PLACE>", place)
    et.trap_SendServerCommand(slot, string.format('%s \"%s\"\n', CHAT, message))
end

function et_Print(text)
    start, stop = string.find(text, POPUP .. " popup:", 1, true)
    if start and stop then
        start, stop, team, plant = string.find(text, POPUP .. " popup: (%S+) planted \"([^%\"]*)\"")
        if start and stop then
            if ONE ~= 0 then
                for dynamite, temp in pairs(timer) do
                    if timer[dynamite]["place"] == plant then
                        return
                    end
                end
            end

            if team == "axis" then team = 1
            else team = 2 end
            index = table.getn(timer) + 1
            timer[index] = {}
            timer[index]["team"] = team
            timer[index]["place"] = plant
            timer[index]["time"] = os.time() + 30

            for key, temp in pairs(MESSAGE) do
                if type(key) == "number" then
                    timer[index][key] = true
                end
            end
        end

        start, stop, team, plant = string.find(text, POPUP .. " popup: (%S+) defused \"([^%\"]*)\"")
        if start and stop then
            if team == "axis" then team = 1
            else team = 2 end
            for index, temp in pairs(timer) do
                if timer[index]["place"] == plant then
                    timer[index] = nil
                    -- Update the map's time limit directly
                    local currentTimeLimit = tonumber(et.trap_Cvar_Get("timelimit")) or 0
                    local newTimeLimit = currentTimeLimit + (TIME_TO_ADD / 60) -- Adding time in minutes
                    et.trap_SendConsoleCommand(et.EXEC_APPEND, "set timelimit " .. tostring(newTimeLimit) .. "\n")
                    et.trap_SendServerCommand(-1, string.format('%s \"%d seconds added to the map time!\"\n', CHAT, TIME_TO_ADD))
                    return
                end
            end
        end
    end
end
