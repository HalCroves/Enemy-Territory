--[[ A GARDER
    Mod -> Nitmod
    -- 4 = Grenade
    -- 5 = Couteau
    -- 63 = lancé de couteau 
    -- 15 = panzer (allies/axis)
    -- 21 = dynamite (axis/allies)
    -- 22 = airstrike (allies/axis)
    -- 25 = support airstrike
    -- 38 = riffle (axis)
    -- 39 = riffle (allies)
    -- 40 = mines (allies/axis)
    -- 41 = satchel (allies/axis)
    -- 51 = mortar (allies/axis)
    -- 58 = goomba
    -- 66 = tripmine
]]

function et_Obituary(victimnum, killernum, meansofdeath)
    local victimhealth = et.gentity_get(victimnum, "health")

    -- Quand la victime meurt d'un ennemi et que sa vie est <= à 0
    if victimhealth <= 0 then
        -- Mean of Death pour le couteau
        local knifeDeath = 5

        -- Mean of Death pour le lancé de couteau
        local ThrowknifeDeath = 63

        -- Liste des meansofdeath associés aux explosifs
        local explosivesList = {4, 15, 21, 22, 25, 38, 39, 40, 41, 51, 66}

        -- Mean of Death pour fell
        local FellToHisDeath = 62

        -- Mean of Death pour MOD_TRIGGER_HURT
        local TriggerHurtDeath = 34

        -- Mean of Death pour GOOMBA
        local GoombaDeath = 58

        -- DEBUG
        -- et.trap_SendServerCommand(victimnum, meansofdeath)
        -- et.trap_SendServerCommand(killernum, meansofdeath)
        --

        -- Vérifie si meansofdeath est dans la liste des explosifs
        if table.contains(explosivesList, meansofdeath) then
            local killername = string.gsub(et.gentity_get(killernum, "pers.netname"), "%^$", "^^ ")

            local messages = {
                "Boom! ^7%s^V just exploded you into oblivion!",
                "You tried to play catch with ^7%s^V's explosive toy. Spoiler: You lost!",
                "Lesson learned: Don't stand next to explosives. Thanks, ^7%s^V!",
                "Did someone order a fireworks show? Oh, it's just ^7%s^V!",
                "Note to self: Avoid being near ^7%s^V when they have explosives.",
                "You just got a front-row seat to ^7%s^V's explosive masterpiece!",
                "Kaboom! ^7%s^V turned you into confetti!",
                "You thought you were safe, but then ^7%s^V happened.",
                "When ^7%s^V has explosives, the floor is lava!",
                "Congratulations! You just experienced ^7%s^V's explosive hospitality.",
                "Who needs enemies when you have friends like ^7%s^V with explosives?",
                "It's not a party until ^7%s^V brings the explosives!",
                "RIP you. Thanks to ^7%s^V and their explosive love.",
                "Next time, ask ^7%s^V for a warning before detonating explosives near you.",
                "Note: ^7%s^V + explosives = disaster for you!",
                "Explosive encounter brought to you by ^7%s^V.",
                "You're not a cat, but curiosity still killed you. Thanks, ^7%s^V!",
                "Guess what? ^7%s^V just made you the star of their explosive show!"
            }

            local randomMessage = messages[math.random(1, #messages)]

            et.trap_SendServerCommand(victimnum, string.format("cp \"%s\"", string.format(randomMessage, killername)))
        -- Mort par coup de couteau
        elseif meansofdeath == knifeDeath then
            local killername = string.gsub(et.gentity_get(killernum, "pers.netname"), "%^$", "^^ ")
            local victimname = string.gsub(et.gentity_get(victimnum, "pers.netname"), "%^$", "^^ ")
        
            local messages = {
                "%s^V was silently taken down by ^7%s^V's ninja skills!",
                "%s^V couldn't outsmart ^7%s^V's sharp wit and sharper blade!",
                "Stealth level: ^7%s^V. Victim: %s^V. Outcome: Silent but deadly!",
                "%s^V met ^7%s^V's knife in a dark alley. It didn't end well for %s^V!",
                "They say curiosity killed the cat. In this case, it was %s^V, and the weapon was ^7%s^V's knife!",
                "Roses are red, violets are blue, %s^V just got stabbed by ^7%s^V, and it's not a haiku.",
                "Warning: %s^V is allergic to knives, especially those wielded by ^7%s^V!",
                "%s^V thought they were the hunter. ^7%s^V had different plans.",
                "In a world full of bullets, %s^V took a stab at being different. ^7%s^V approved!",
                "They say the pen is mightier than the sword. ^7%s^V prefers knives. Sorry, %s^V!",
                "%s^V went for a midnight snack. ^7%s^V served a slice of surprise!",
                "Knife to meet you, %s^V! Courtesy of ^7%s^V's cutlery skills.",
                "%s^V was stabbed by ^7%s^V, and the award for 'Best Plot Twist' goes to...",
                "Lesson learned: Don't challenge ^7%s^V to a knife fight, %s^V!",
                "They say revenge is a dish best served cold. ^7%s^V serves it with a side of knives!",
                "Silent, deadly, and unexpectedly witty: ^7%s^V's knife strikes again, claiming %s^V!",
                "%s^V took a stab at greatness. ^7%s^V provided the inspiration!",
                "When life gives you lemons, %s^V, ^7%s^V suggests making lemonade... with a knife twist!"
            }

            local randomMessage = messages[math.random(1, #messages)]

            et.trap_SendServerCommand(-1, string.format("chat \"%s\"", string.format(randomMessage, victimname, killername)))
        -- Mort par lancé de couteau
        elseif meansofdeath == ThrowknifeDeath then
            local killername = string.gsub(et.gentity_get(killernum, "pers.netname"), "%^$", "^^ ")
            local victimname = string.gsub(et.gentity_get(victimnum, "pers.netname"), "%^$", "^^ ")
        
            local messages = {
                "%s^V dodged bullets, but a flying knife? Not so much!",
                "Catch! %s^V just caught ^7%s^V's knife with their face!",
                "Who needs a bow when ^7%s^V delivers knives with precision?",
                "%s^V played a game of 'Dodge the Bullet,' but ^7%s^V played 'Dodge the Knife'!",
                "In the battle of bullets versus knives, %s^V found out knives can fly!",
                "Roses are red, violets are blue, %s^V got a knife, and it's from ^7%s^V too!",
                "Warning: %s^V is a master of both throwing shade and throwing knives!",
                "They say lightning doesn't strike twice, but knives thrown by ^7%s^V do!",
                "%s^V took a stab at survival. ^7%s^V provided the stabbing!",
                "Plot twist: %s^V's life story involves a unexpected ending with ^7%s^V's knife!",
                "Did you hear about %s^V? Yeah, they got the point... literally!",
                "No bullets, no problem. ^7%s^V delivers death with style!",
                "Note to self: Don't stand still when ^7%s^V has a knife in hand!",
                "They say knives are silent killers. %s^V would agree, thanks to ^7%s^V!",
                "In the game of life, %s^V just drew the short straw... or should we say, the short knife?",
                "Ever heard of knife-throwing mastery? Now you have, thanks to ^7%s^V and their victim %s^V!",
                "When %s^V throws a knife, even the Matrix can't dodge it!",
                "Surprise delivery! %s^V received a knife courtesy of ^7%s^V!",
                "%s^V tried to dodge, but ^7%s^V's knife had other plans!",
                "They say the pen is mightier than the sword. In this case, the knife wins. Sorry, %s^V!",
            }

            local randomMessage = messages[math.random(1, #messages)]

            et.trap_SendServerCommand(-1, string.format("chat \"%s\"", string.format(randomMessage, victimname, killername)))
        -- Mort par gravité/ejécté
        elseif meansofdeath == FellToHisDeath then
            local victimname = string.gsub(et.gentity_get(victimnum, "pers.netname"), "%^$", "^^ ")
                
            local messages = {
                "Gravity decided %s^V needed a break!",
                "%s^V embraced the art of flying without wings!",
                "Who needs stairs? Not %s^V, apparently!",
                "Floor is lava? More like floor is boring for %s^V!",
                "%s^V's attempt at parkour ended in a graceful descent.",
                "Defying gravity is overrated, right %s^V?",
                "Someone tell %s^V this isn't a diving competition!",
                "%s^V took a leap of faith... and missed!",
                "The ground said 'hello' to %s^V in the most unexpected way!",
                "In another life, %s^V might have been a bird. Today, not so much!",
                "%s^V's fall was so majestic, even the birds were jealous!",
                "Gravity: 1, %s^V: 0. Better luck next time!",
                "Has anyone seen %s^V? Last seen defying gravity!",
            }

            local randomMessage = messages[math.random(1, #messages)]

            et.trap_SendServerCommand(-1, string.format("chat \"%s\"", string.format(randomMessage, victimname)))
        -- Mort par écrasement (Goomba)
        elseif meansofdeath == GoombaDeath then
            local victimname = string.gsub(et.gentity_get(victimnum, "pers.netname"), "%^$", "^^ ")

            local messages = {
                "%s^V thought they were playing ET, not Mario Kart!",
                "Splat! %s^V just became modern art on the battlefield.",
                "When %s^V said they wanted a closer look, they didn't mean under someone's boot!",
                "Gravity: 1, %s^V: 0. Better luck in the next respawn!",
                "They say timing is everything. %s^V's timing for avoiding being squashed? Not so great.",
                "%s^V learned the hard way that not all hugs are friendly.",
                "In the epic tale of %s^V versus the ground, the ground emerged victorious!",
                "Note to self: When %s^V is around, watch out for falling players!",
                "%s^V's attempt at a sneak attack turned into a squishy surprise!",
                "Squish, squash, splat! %s^V's fate on the battlefield.",
                "Next time, %s^V should look both ways before crossing the battlefield.",
                "Friendly fire takes a new meaning when %s^V is on your team!",
                "News flash: %s^V just discovered the floor is not a trampoline.",
                "When %s^V said they wanted a foot massage, this wasn't what they had in mind!",
                "They say laughter is the best medicine. %s^V disagrees after being squashed.",
                "%s^V's attempt at a tactical roll turned into a tactical pancake.",
                "Gravity's favorite pastime? Turning %s^V into a pancake!",
                "If %s^V were a pancake, they'd be the flat and not-so-tasty kind!",
                "When %s^V said they wanted to be closer to the action, this wasn't what they had in mind!",
            }

            local randomMessage = messages[math.random(1, #messages)]

            et.trap_SendServerCommand(-1, string.format("chat \"%s\"", string.format(randomMessage, victimname)))
        -- Tomber au fond de la map
        elseif meansofdeath == TriggerHurtDeath then
            local victimname = string.gsub(et.gentity_get(victimnum, "pers.netname"), "%^$", "^^ ")
        
            local messages = {
                "Oops! %s^V forgot to bring a shield to the gunfight!",
                "%s^V's health bar tried its best, but the enemy had other plans!",
                "In a world of bullets, %s^V was tragically unarmed!",
                "%s^V's last words: 'I probably shouldn't stand in front of that.'",
                "Breaking news: %s^V discovered that bullets hurt!",
                "Lesson learned: Bullets and %s^V don't mix well!",
                "RIP %s^V's health bar. It fought bravely, but the enemy was too strong!",
                "Note to self: Find cover next time, %s^V!",
                "%s^V was mortally wounded, but the enemy promises to send flowers!",
                "In the epic battle of %s^V vs. bullets, bullets emerged victorious!",
            }

            local randomMessage = messages[math.random(1, #messages)]

            et.trap_SendServerCommand(-1, string.format("chat \"%s\"", string.format(randomMessage, victimname)))
        end
    end
end

-- Fonction utilitaire pour vérifier si une valeur est dans une table
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end
