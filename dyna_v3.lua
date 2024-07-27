---------------------------------
------- Dynamite counter --------
-------  By Necromancer  --------
-------    5/04/2009     --------
------- www.usef-et.org  --------
-------     UPDATED      --------
-------    27/07/2024     --------
------ By HalCroves/Bertha -------
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
end

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
        -- Traitement pour la dynamite plantée
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

        -- Traitement pour la dynamite désamorcée
        start, stop, team, plant = string.find(text, POPUP .. " popup: (%S+) defused \"([^%\"]*)\"")
        if start and stop then
            if team == "axis" then team = 1
            else team = 2 end
            for index, temp in pairs(timer) do
                if timer[index]["place"] == plant then
                    local time_left = et.trap_Cvar_Get("timelimit") * 60 - (os.time() - OLD)
                    if time_left <= 30 then
                        -- Ajouter du temps à la carte
                        local currentTimeLimit = tonumber(et.trap_Cvar_Get("timelimit")) or 0
                        local newTimeLimit = currentTimeLimit + (TIME_TO_ADD / 60) -- Ajoute le temps en minutes
                        et.trap_SendConsoleCommand(et.EXEC_APPEND, "set timelimit " .. tostring(newTimeLimit) .. "\n")
                        et.trap_SendServerCommand(-1, string.format('%s \"%d seconds added to the map time!\"\n', CHAT, TIME_TO_ADD))
                    end
                    timer[index] = nil
                    return
                end
            end
        end
    end
end
