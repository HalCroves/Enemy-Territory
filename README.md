# Enemy-Territory

## Liste des scripts lua
+ balance.lua : équilibre automatiquement les teams (bots + joueurs)
+ funnymsg.lua : afficher des messages troll en fonction de la mort du joueur.
+ hs_stats.lua : afficher les stats d'headshots par arme.
+ mod.lua : lancer plusieurs scripts lua avec un seul fichier.
+ radar.lua : désactiver le brouillard et l'herbe.
+ stats.lua : Stats headshots + meilleur tireur en fonction des armes.
+ feedback_v4.lua : permet de voter pour une map (like/dislike).

## Feedback_v4.lua
> [!NOTE]
> There are two variables that can be used:
>+ Show percentage for each vote -> False|true
>```local ShowPercentageForEachVote = false```
>+ Show percentage at the end of the card -> False|true
>```local ShowNumberVotesAtTheEnd = true```

## balance.lua
> [!NOTE]
> There are one variable that can be modified:
>+ Check time 
>```max_unevenTime = 20```
