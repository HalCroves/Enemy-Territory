# Enemy-Territory

## Liste des scripts lua
+ balance.lua: Automatically balances teams (bots + players).
+ dyna_v2.lua: Dynamite counter with a message for the last 30 seconds and adds extra time if a dynamite is defused during the last 30 seconds.
+ dyna_v3.lua: Dynamite counter that adds extra time when a dynamite is defused during the last 30 seconds.
+ feedback_v4.lua: Enables map voting (like/dislike).
+ feedback_v5.lua: Enables map voting at the end of a round (like/dislike).
+ funnymsg.lua: Displays troll messages based on the player's death.
+ hs_stats.lua: Displays headshot stats by weapon.
+ kick_by_mac.lua: Kicks players based on multiple MAC addresses.
+ kick_VPN_Windows.lua: Kicks players using a VPN (compatible with Windows).
+ kick_VPN_Linux.lua: Kicks players using a VPN (compatible with Windows + Linux).
+ mod.lua: Runs multiple Lua scripts with a single file.
+ radar.lua: Disables fog and grass.
+ stats.lua: Tracks headshot stats and best shooter by weapon.
+ resetxpbot_nitmod.lua: Resets bot XP at the beginning of each map.
+ restrictSpec.lua : add restriction for players in spectator.

## balance.lua
> [!NOTE]
> There are one variable that can be modified:
>+ Check time 
>```max_unevenTime = 20```

## dyna_v2.lua
> [!NOTE]
> There are two variable that can be modified:
>+ Délai minimum entre les messages d'avertissement (en secondes) :
>```WARNING_THRESHOLDS = {60, 30, 10}```
>+ Time to add (in seconds) when a dynamite is defused :
>```TIME_TO_ADD = 30```

## dyna_v3.lua
> [!NOTE]
> There are two variable that can be modified:
>+ Time to add (in seconds) when a dynamite is defused :
>```TIME_TO_ADD = 30```

## Feedback_v54.lua/Feedback_v5.lua
> [!NOTE]
> There are two variables that can be used:
>+ Show percentage for each vote -> False|true
>```local ShowPercentageForEachVote = false```
>+ Show percentage at the end of the card -> False|true
>```local ShowNumberVotesAtTheEnd = true```

## kick_by_mac.lua
> [!NOTE]
> Possibilité de renseigner une adresse mac complète ou de renseigner un début d'adresse mac.

## resetxpbot_nitmod.lua
> [!NOTE]
> There are one variable that can be modified:
>+ Enable/disable the resetxpbot : true/false
>```local resetXPBot = true```

## RestrictSpec.lua
> [!NOTE]
> Priority Whitelist GUID:
>+ Players whose GUID is in allowedGuids can always speak and join a team.
>+ This applies even if they don't have a MAC address (Linux players).

> Invalid MAC = restriction:
>+ Players without a MAC address (N/A, empty, or 00-00-00-00-00-00) cannot speak or join a team.
>+ They receive a specific message explaining that no MAC address is detected.

> Blacklisted MAC = restriction:
>+ Players whose MAC address is in blockedMACPrefixes cannot speak or join a team.
>+ They receive a specific message indicating they need to contact an administrator.

> Valid and non-blacklisted MAC = allowed:
>+ Players with a valid MAC address that is not in the blacklist can speak and join a team.
>+ They receive no message and play normally.
