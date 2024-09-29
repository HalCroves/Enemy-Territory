# Enemy-Territory

## Liste des scripts lua
+ balance.lua : équilibre automatiquement les teams (bots + joueurs).
+ dyna_v2.lua : dynamite counter avec message pour les 30 dernières secondes et ajout de temps quand une dynamite est désamorcée dans les 30 dernières secondes.
+ dyna_v3.lua : dynamite counter avec ajout de temps quand une dynamite est désamorcée dans les 30 dernières secondes.
+ feedback_v5 : permet de voter pour une carte en fin de map (like/dislike).
+ funnymsg.lua : afficher des messages troll en fonction de la mort du joueur.
+ hs_stats.lua : afficher les stats d'headshots par arme.
+ kick_by_mac : kicker les joueurs en fonction de plusieurs adresses mac.
+ kick_VPN_Windows : kicker les joueurs qui utilisent un VPN (compatible Windaube).
+ kick_VPN_Linux : kicker les joueurs qui utilisent un VPN (compatible Windaube + Linux).
+ mod.lua : lancer plusieurs scripts lua avec un seul fichier.
+ radar.lua : désactiver le brouillard et l'herbe.
+ stats.lua : Stats headshots + meilleur tireur en fonction des armes.
+ feedback_v4.lua : permet de voter pour une map (like/dislike).

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
