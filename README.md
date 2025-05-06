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

## testrictSpec.lua
> [!NOTE]
> Gestion des équipes :
>+ Les joueurs ne sont muets que lorsqu'ils sont spectateurs
>+ Une fois dans une équipe active, ils peuvent parler normalement

> Commande "team" :
>+ Les joueurs peuvent rejoindre une équipe active via la commande "team"
>+ Ils ne peuvent pas retourner en spectateur via cette commande

> Tentatives de chat :
>+ Si un joueur spectateur tente de parler, il reçoit le message approprié selon son statut (MAC blacklistée ou GUID non whitelisté)
>+ Les joueurs dans une équipe active peuvent parler librement

> Changements d'équipe :
>+ Le script détecte automatiquement les changements d'équipe
>+ Il met à jour le statut muet/non-muet en conséquence
