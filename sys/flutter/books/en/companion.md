# NetHack Spoilers {#nethack-spoilers}

**A Traveler's Companion to the Mazes of Menace**

*You feel like someone is helping you.*

NetHack is among the oldest computer games still actively maintained, its code in continuous development for more than four decades. Its roots trace back to Rogue, a 1980 computer game by Michael Toy and Glenn Wichman that was inspired by Dungeons and Dragons. In Rogue, the dungeon was randomly generated and drawn with ordinary text characters. Your hero was an `@`, the monsters were letters, and death was permanent. Built on Ken Arnold's curses library and carried across the world inside Berkeley's BSD Unix, Rogue became the most popular game on the college campuses of its day, inspiring a whole genre of similar games called "roguelikes."

NetHack got its start when Jay Fenlason, a high school junior at Lincoln-Sudbury Regional High School in Massachusetts, wanted his own custom version of Rogue. Since Rogue's source code was closely guarded to discourage cheating, he had to start from scratch. His school ran a Unix minicomputer kept alive by its own students, and there, with his classmates Kenny Woodland, Mike Thome, and Jon Payne, he built Hack, a game with monsters that had names, wands that shot beams, and a dungeon that remembered each floor you left behind. His teacher Brian Harvey sent it out on a USENIX tape in 1982, with Jay's note in the README calling it "my first semester programming project" and giving his home phone number.

Hack might have ended there, but because its source code was open, it was passed freely from one programmer to the next. In 1984 Andries Brouwer, a mathematician in the Netherlands, rewrote it substantially and posted Hack 1.0 to Usenet for anyone to take. He added the player roles, the pet that follows you down the stairs, and the shopkeepers. Copies and variants then multiplied across the early Internet faster than any one author could follow.

In 1987, Mike Stephenson gathered those scattered versions back together, and with Izchak Miller, Janet Walz, and a widening circle of volunteers, merged them into a single game. They named it NetHack, after the network that had made the collaboration possible, and called themselves the DevTeam. They are still at it. **Version 5.0 was released in May 2026.** Over forty years, the DevTeam has grown NetHack into the most unforgivingly intricate and emblematic roguelike, with a thriving culture of fun and community beyond the game itself. Much of that culture took shape on the rec.games.roguelike.nethack newsgroup in the 1990s and thrives today at the NetHack Wiki, the r/nethack forum, the game's Discord and IRC channels, and public servers like nethack.alt.org and hardfought.org. This guide stands on their work.

One of the wonderful things about NetHack is that it is so rich, so intricate, that the game is not spoiled by spoilers. The more you know its secrets, the more interesting the game becomes. And so in that spirit, we hope this new collection of 5.0 spoilers helps bring the joy of NetHack to a new generation of players.

Welcome to NetHack!

---

## Before You Read Further {#before-you-read-further}

**A word of caution.** This guide will change how you experience the Mazes. Once you know that a floating eye can paralyze you with a glance, you can never un-know it. Some adventurers prefer the thrill of discovery to the comfort of preparation. If that is you, close the Companion now and learn the hard way. There is real joy in that.

**Looking for the manual instead?** If you want commands, item lists, and bare mechanics without spoilers, you want the **[Guide to the Mazes of Menace](../guidebook/)** that comes with the game. The document you are reading is a *strategic* guide. It assumes you already know how to play and want to know how to *survive*.

Read on if you have been stripped of your belongings by one too many water nymphs, if you cannot survive [the Gnomish Mines](#the-gnomish-mines), or if you have grown tired of the gods abandoning you to starve with no food rations on level four. We will do our best to keep you alive.

### How to Use This Book {#how-to-use-this-book}

On a first descent, read [What to Pack](#what-to-pack), [The Golden Rules](#the-golden-rules-of-early-survival), and [Saving Yourself from Imminent Death](#delayed-deaths). Leave the tables and the endgame chapters alone until the dungeon gives you a reason to open them.

During a game, use the contents and index as a field manual. Look up the monster in front of you, the message you just saw, or the object you are about to use. The item chapters put the common, useful cases first; the tables are there when you need an exact price or number.

**Conventions.** `@`, `#pray`, and other fixed-width text are things you will see or type in the game. **Bold text** marks a rule worth remembering. *Dlvl* is dungeon depth and *XL* is experience level. Prices are in zorkmids (*zm*). A note marked **new in 5.0** matters especially if you learned the game on 3.6; returning players can start with [What Changed Since Last Time](#what-changed-since-last-time).

#### Dungeon Emergency Checklist {#dungeon-emergency-checklist}

When a turn has gone bad, stop typing and read the messages again.

1. Check HP, hunger, encumbrance, and every status word.
2. Look for the up stair, a door you can close, or another one-turn escape. Inventory search comes after the obvious exit.
3. If you cannot walk away, engrave `Elbereth` in dust before the monster reaches you. Use a permanent engraving when you have time.
4. Prayer can cure a life-threatening problem when your alignment and Luck are sound and enough time has passed. In Gehennom, expect less.
5. For stoning, eat a lizard corpse. For sliming, use fire. For illness, use blessed healing or non-cursed extra healing. For strangulation, remove the amulet or pray.
6. If nothing in the pack saves you, write down the death. NetHack is very good at making the same mistake memorable.

---

## Table of Contents {#table-of-contents}

**Part One: Before You Set Out**

1. [Choosing Your Expedition](#choosing-your-expedition) — Roles, races, and alignments
2. [What to Pack](#what-to-pack) — Starting equipment and early priorities
3. [Your First Descent](#your-first-descent) — Surviving the early dungeon

**Part Two: Dungeon Sights**

4. [The Lay of the Land](#the-lay-of-the-land) — Rooms, corridors, and dungeon features (with map)
5. [Field Guide to Dungeon Fauna](#field-guide-to-dungeon-fauna) — Monster classes at a glance
6. [Points of Interest](#points-of-interest) — Fountains, altars, thrones, and sinks
7. [Branches and Landmarks](#branches-and-landmarks) — The Mines, Sokoban, and beyond
8. [Traps and Hazards](#traps-and-hazards) — What the dungeon has in store for you
9. [Feelings and Sounds](#feelings-and-sounds) — Cryptic messages the dungeon uses to tell you what just happened

**Part Three: Survival**

10. [Saving Yourself from Imminent Death](#delayed-deaths) — Warning messages and the cure to reach for
11. [Engravings and Elbereth](#engravings) — Writing on the floor and making a ward
12. [The Art of Combat](#the-art-of-combat) — Hit probability, damage, and tactics
13. [Things That Will Kill You](#things-that-will-kill-you) — Top-ten killers, common deaths, mimics, dragons
14. [Saving and Bones](#saving-and-bones) — How runs continue across sessions, and what dead heroes leave behind
15. [Ways to Die Instantly](#ways-to-die-instantly) — Instadeaths and how to recognize them
16. [Divine Relations](#divine-relations) — Prayer, sacrifice, and altars
17. [Making Friends](#making-friends) — Pets, taming, and peaceful coexistence

**Part Four: Gear and Provisions**

18. [A Practical Identification Strategy](#a-practical-identification-strategy) — Figuring out what you've found (with flowchart)
19. [Provisions and Dining](#provisions-and-dining) — Food, nutrition, and dining
20. [The Apothecary](#the-apothecary) — Potions and their many uses
21. [The Scroll Rack](#the-scroll-rack) — Scrolls, their effects, and confused reading
22. [Wands](#wands) — Magical implements
23. [Rings and Amulets](#rings-and-amulets) — Jewelry, for better or worse
24. [Tools of the Trade](#tools-of-the-trade) — From pickaxes to magic lamps
25. [The Armory](#the-armory) — Weapons, armor, and hitting things
26. [Curses and How to Break Them](#curses-and-how-to-break-them) — Spotting them, undoing them, surviving them

**Part Five: Mastery and Endgame**

27. [Spellcasting](#spellcasting) — Magic for the studious adventurer
28. [Luck and Fortune](#luck-and-fortune) — The hidden numbers that shape your fate
29. [Exercising Your Stats](#exercising-your-stats) — Habits that slowly drift Str, Dex, Con, and Wis
30. [Enhancing Skills](#enhancing-skills) — Mastering specific styles of combat and magic
31. [Wishes and Wishing](#wishes-and-wishing) — Getting what you want
32. [Artifacts](#artifacts) — Legendary equipment and how to obtain it
33. [Into Gehennom](#into-gehennom) — The Castle gateway and the realm below
34. [The Ascension](#the-ascension) — Assembling the kit and climbing back out

**Appendices**

35. [Advanced Controls](#advanced-controls) — Command counts, prefixes, and efficiency techniques
36. [Customization](#options-worth-knowing-about) — rcfile options worth knowing
37. [Sokoban Solutions](#sokoban-solutions) — All eight level variants, solved
38. [Voluntary Challenges](#voluntary-challenges) — Conducts and self-imposed restrictions
39. [Shops: Credit, Debt, and Trouble](#shopping-and-shopkeeper-pricing) — Commerce in the dungeon
40. [Weapons Tables](#weapons-tables)
41. [Armor Tables](#armor-tables)
42. [Spell Tables](#spell-tables)
43. [Bestiary Tables](#bestiary-tables)
44. [Intrinsic and Extrinsic Tables](#intrinsic-and-extrinsic-tables) — Properties you can attain and where they come from
45. [What Changed Since Last Time](#what-changed-since-last-time) — What's new in 5.0 vs 3.6.x, and what to do about it
46. [Acknowledgements](#acknowledgements) — Standing on the shoulders of giants

## Part One: Before You Set Out {#part-one-before-you-set-out}

### Choosing Your Expedition {#choosing-your-expedition}

Choose a **role**, **race**, and **alignment** before you enter the Mazes; together they determine your equipment, abilities, gods, and safe artifacts. For a first expedition, choose a **Lawful human or dwarf Valkyrie**: she starts strong, resists cold, and has a clear route to a good weapon. If another role sounds more fun, take it—the first few deaths teach more than the character menu does.

#### The Roles {#the-roles}

| Role | Alignments | Races | Early edge | Main difficulty |
|---|---|---|---|---|
| Archeologist | Lawful, Neutral | Human, dwarf, gnome | Digging and identification tools | Fragile in melee |
| Barbarian | Neutral, Chaotic | Human, orc | High HP and poison resistance | Little useful magic |
| Cave Dweller | Lawful, Neutral | Human, dwarf, gnome | Tough, simple, good ranged start | Few built-in resistances |
| Healer | Neutral | Human, gnome | Healing, sleep wand, poison resistance | Weak weapon and armor |
| Knight | Lawful | Human | Armor, pony, lance, long sword | Mounting and conduct mistakes |
| Monk | Any | Human | Speed, resistances, martial arts | Armor and diet restrictions |
| Priest | Any | Human, elf | Sees BUC status at a glance | Middling opening offense |
| Ranger | Neutral, Chaotic | Human, elf, gnome, orc | Bow, arrows, displacement | Wants distance to fight well |
| Rogue | Chaotic | Human, orc | Daggers, stealth, lock pick | Light armor |
| Samurai | Lawful | Human | Fast, well armed, good bow | Conduct penalties |
| Tourist | Neutral | Human | Darts, camera, mapping | Very weak opening |
| Valkyrie | Lawful, Neutral | Human, dwarf | Excellent shield and cold resistance | Must find magical defenses later |
| Wizard | Neutral, Chaotic | Human, elf, gnome, orc | Magic resistance and a deep kit | Low HP and no food |

The [intrinsic tables](#intrinsic-and-extrinsic-tables) give the exact level-by-level abilities for every role and race.

Your role sets your opening inventory, later intrinsics, skill caps, and Quest. Those differences change how you solve the same dungeon: a Valkyrie can trade blows early, a Wizard kills at range, and an Archeologist can dig around the fight.

**Archeologist** *(Lawful or Neutral).* The Indiana Jones of the Mazes. You set out with a pickaxe, a bullwhip, a tinning kit to preserve food, a touchstone for identifying gems, and your lucky fedora: the pack of an explorer not a warrior. The pickaxe is special, part weapon and part tool. Swing it in a fight, but also use it to dig your own way through the world: cut a new hallway, break into a sealed vault to reach the gold inside, or dig straight down to the level below. Your touchstone tells a true gem from cut glass with a single rub, and your training lets you read a scroll's label the moment you pick it up, so scrolls identify themselves as you find them. You are thin-skinned at first, so the early levels reward patience and stealth over trading blows. But you are sharp, born with the Intelligence and Wisdom of a natural spellcaster. Although you do not begin with any magic, you grow into it as spellbooks find their way to you. In time you can become an expert at combat with the pickaxe and saber, and in the spells of Divination. These include magic mapping, a spell that reveals a whole level's map in an instant. One rule every Archeologist learns: never smash a historic statue. You alone can tell which statues are historic, and destroying a piece of the past offends your god and costs you alignment.

**Barbarian** *(Neutral or Chaotic).* Raw muscle, and the most hit points of any role. Your game is to hit hard and outlast whatever hits back; you can dispatch most problems in the early Mazes with a few strikes of your heavy weapon. You begin already **[immune to poison](#damage-resistances)**, which rules out a whole category of early deaths, and you carry a great two-handed weapon (a two-handed sword or a battle-axe), a one-handed backup, a suit of ring mail, and food. For the first stretch of the game you can simply wade in and swing. Trouble comes later, once you have coasted comfortably to the middle of the game and meet monsters whose magic ignores muscle entirely. Start hunting magic resistance early, most reliably a suit of gray dragon scale mail. Because poison cannot touch you, you can also taste-test risky potions and foods that would lay a weaker adventurer low.

**Cave Dweller** *(Lawful or Neutral).* The simplest role in the game, and a fine place to learn the dungeon without a lot of moving parts. You are primitive but sturdy: a club, a sling with a pile of flint stones to fling, leather armor, and hit points that climb generously as you grow. There are no spellbooks to study and no starting spells. What makes the Cave Dweller distinctive is what you lack: no resistances at all to begin with. Where other roles are handed protection from fire or cold or poison, you earn each one by eating the right corpse. A fire ant grants fire resistance and a killer bee can grant poison resistance. In a fight you can grow expert with the club, mace, quarterstaff, spear, and sling, and like the Barbarian a master of bare-handed combat, so even weaponless you hit hard. Low starting Intelligence and narrow spell skills make scrolls more dependable than spellbooks. Choose the dwarf or human background for the heaviest melee.

**Healer** *(Neutral).* The dungeon's doctor. You arrive equipped for medicine rather than war: a stethoscope, a small surgeon's scalpel, healing potions by the handful, three spellbooks of healing magic already blessed so they will not blow up when you read them, and a **wand of sleep**. That wand is your best early defense. Most monsters in the first levels have no defense against sleep, and a single charge drops even a dangerous one where it stands. Save the charges for threats you cannot safely kill another way. The stethoscope is useful from turn one: press it to a monster to hear exactly how much fight it has left, or to yourself to learn your own hidden condition. Two gifts come built in. You are immune to poison, and the potion of sickness can't touch you, so a mystery potion can never poison or sicken you, though paralysis or sleep still can. You are no brawler, so lean on the wand and, later, on your spells. In time you grow expert with the knife, quarterstaff, dart, and unicorn horn, and in the healing arts, and around the middle of the game you shift from drinking healing to casting it.

**Knight** *(Lawful).* Chivalry, on horseback. You ride to war with a code of honor and a companion at your side: a **saddled pony** trots with you from the first turn, alongside a long sword, a **lance**, and a full suit of armor, helmet, shield, and gloves. On foot, the lance can be used as a reach weapon, but charge from horseback with the lance, a joust, and you land crushing damage no one else can match, for no other role wields a lance so well. Riding your steed you can carry more, but climbing into the saddle is riskier than it looks: a failed mount throws you for 10--14 HP, most of a new Knight's life, and early on you fail nearly half the time, so do not rush to ride. Let the pony grow up first, into a horse and then a warhorse, and mount when the odds favor you. Two marks of the order: as a Lawful knight holding a long sword, you have the best chance in the game of drawing **[Excalibur](#excalibur-artifact)** from a fountain, and your code forbids striking a fleeing, sleeping, or helpless foe, which costs you standing if you do. Feed the pony apples, keep the carrots to cure blindness, and pick your fights with honor.

**Monk** *(Any alignment).* You begin unarmed and can train your martial arts to a level of mastery no other role can reach, until your bare fists strike harder than most swords. From the very start you can [see the invisible](#senses-and-perception), shrug off sleep, and move with unusual speed, and you gain new powers faster than any other role. To keep the combat bonuses, stay light and unburdened. Any body armor costs 20 points of accuracy, a shield cancels your martial bonus, and metal on your head, hands, or feet clouds your magic, so you fight best in little more than the **robe** you begin in, which sharpens your spellcasting rather than dulling it. Guard the robe and keep to the vegetarian diet if you want to preserve your conduct.

**Priest** *(Any alignment, matching your god).* Your faith gives you an immediate read on every item's condition: blessed, cursed, or uncursed. You never have to wonder whether the cloak on the floor is safe to wear. You set out with a mace, a robe and shield, and four flasks of **holy water**, and you can always make more: set potions of water on an altar of your faith and pray, and the whole pile turns holy at once. Your god favors you at the altar in another way, too. When sacrifice yields your first artifact gift, it is guaranteed to be **Demonbane**, a blessed silver mace made to smite demons. Each worthy offering has a one-in-six chance to produce that first gift. You are a capable fighter who grows into a formidable caster of clerical magic, expert with a whole rack of blunt weapons and in the healing, divination, and cleric schools. One caution: guard your Luck. Do not kill peaceful monsters or break mirrors before you have sacrificed your way into your god's good graces, or the answer to a desperate prayer may not be the one you hoped for.

**Ranger** *(Neutral or Chaotic).* The hunter, most at home striking from a distance. You begin with a bow and a deep quiver of arrows, and a **+2 cloak of displacement** that makes attackers swing at an image of you a step from where you truly stand, one of the safest opening hands in the game. Your gift is volume: with a bow trained high, a single turn can loose two or three arrows at once, and few things survive that for long. You notice everything as well, spotting hidden passages and traps as you walk without stopping to search. Two pieces of woodcraft are worth remembering. Your finest arrows, the enchanted **+2** stack, break far less often than ordinary ones, so save them for real fights and spend the cheap arrows on the harmless newts of the first level. And your place is at range: step back, keep a wall at your shoulder, and let the arrows do the work rather than trading blows on the front line.

**Rogue** *(Chaotic).* A thief in the dark, quick with a blade and quieter on your feet. You travel light: a short sword, a fistful of throwing daggers, leather armor, a **lock pick** that opens any door, chest, or box from the very first turn, and a sack to carry your finds. You move in near-silence, slipping past sleeping monsters without waking them, and when you strike an enemy that is fleeing or caught off guard, your **backstab** drives the blow home for far more damage than the same strike would deal head-on. Your daggers are made to be thrown, not thrust: you hurl several in a single turn. Later you can coat darts and any arrows, bolts, or shuriken you find with the poison you start carrying. Daggers cannot be poisoned. Stay in the shadows, and avoid the loud, clumsy actions, like kicking at doors or wading into a crowd, that give your position away.

**Samurai** *(Lawful).* A disciplined warrior of the old school, fast and deadly with a blade. You carry a **katana**, one of the finest single-handed swords in the dungeon, a shorter companion sword called a **wakizashi**, a **yumi** longbow with a quiver of arrows, and a suit of splint mail, and you move with a quickness other warriors have to earn. The katana carries you cleanly through the early game. Its companion, though, is the wrong partner for two-blade fighting: the little wakizashi doesn't share the katana's swordsmanship, so when you find an ordinary long sword, take that up instead and fight with a blade in each hand, both swinging with your full skill. Don't forget the bow at your back, either. Trained up, the yumi makes you a ranged threat to rival a Ranger, two or three arrows a turn from a warrior already fearsome up close.

**Tourist** *(Neutral).* You arrive on holiday: a loud Hawaiian shirt, a credit card, an **expensive camera**, a small mountain of **+2 darts**, a couple of healing potions, and four scrolls of magic mapping. You have almost no armor, few hit points, and no real weapon, so early on nearly anything can kill you. Your survival hangs on cleverness rather than muscle. The camera is the trick: a flash blinds whatever is bearing down on you, and a blinded monster is one you can pepper with darts from a safe distance while your pet closes in to finish it. Save the mapping scrolls for the levels that look most dangerous. Shopkeepers can smell a tourist: until you are seasoned, they overcharge you and lowball what they buy. Leave serious shopping for later in the run. Survive that brutal opening and the Tourist blossoms: your quest reward, the Platinum Yendorian Express Card, grants magic resistance and helps recharge tools. With a good Intelligence score, a late-game Tourist also casts well. The hardest role in the game, and a badge of honor for anyone who ascends one.

**Valkyrie** *(Lawful or Neutral; female only).* The classic recommendation for anyone chasing a first ascension, and for good reason: strong from the start, hard to kill, and simple to play. A warrior-maiden of the North, you begin with a spear, a dagger, and a sturdy **+3 small shield**, already **resistant to cold**, with combat stats that let you meet the early dungeon head-on. The gods have set your late game aside for you, too. Your first guaranteed sacrifice gift, whatever your alignment, is **[Mjollnir](#mjollnir)**, a thunderous war hammer. A Valkyrie with Strength 25 can throw it and usually catch it on the return. You can grow skilled with a wider range of weapons than nearly anyone. The one thing not to do is coast. Your muscles carry you a long way, but the demons of Gehennom hurl magic that ignores armor and hit points alike, so line up magic resistance and reflection before you enter Gehennom.

**Wizard** *(Neutral or Chaotic).* You set out already holding a treasure most adventurers spend the whole game hoping to find: a **cloak of magic resistance**, which turns aside a whole category of deadly magic from the very first turn. Around it you carry a quarterstaff, a wand, a pair of rings, a handful of potions and scrolls, a magic marker, and the **force bolt** spell to fling at anything that comes close. The early game is the fragile part. Your body is weak and your spell energy is thin, so fight carefully and lean on your wand and force bolt rather than your fists. As you study each school of spellcasting you begin to recognize its spellbooks on sight. A Wizard who reaches the middle game with a broad library has an answer to most fights. Keep the quarterstaff in hand as you cast, since it steadies your spells, and mind two quirks: you start with no food and a kitten who will not share, and your own force bolt will shatter potions lying on the ground (see [Spellcasting](#spellcasting)).

#### The Races {#the-races}

Your race affects your starting and maximum attributes, and which intrinsics you get. No stat can go below 3; the table lists the maximum each race can reach for each attribute.

| Race  | Str    | Int | Wis | Dex | Con | Cha | Intrinsics                     |
|-------|--------|-----|-----|-----|-----|-----|--------------------------------|
| Human | 18/100 | 18  | 18  | 18  | 18  | 18  | —                              |
| Elf   | 18     | 20  | 20  | 18  | 16  | 18  | Infravision; sleep res at XL 4 |
| Dwarf | 18/100 | 16  | 16  | 20  | 20  | 16  | Infravision                    |
| Gnome | 18/50  | 19  | 18  | 18  | 18  | 18  | Infravision                    |
| Orc   | 18/50  | 16  | 16  | 18  | 18  | 16  | Infravision, poison res        |

**Human.** No [infravision](#senses-and-perception), no poison resistance, no special talents. Every role is open to you, but gnomes and orcs are still hostile; being human does not make the Mines friendly.

**Dwarf.** Sturdy fighters with the best Dex and Con caps and matching human Strength. Infravision from level 1, the best HP gain per level of any race, pick-axe digging at twice the normal speed, and a feel for buried treasure under your feet. Mines residents are mostly peaceful to you. Available for: Archeologist, Cave Dweller, Valkyrie.

**Elf.** Infravision plus [sleep resistance](#damage-resistances) at XL 4. Fragile HP but with the best Int and Wis caps and the best Pw (spell energy) growth per level of any race, plus an innate bow bonus (+1 to-hit with any bow, +2 with an elven bow) that applies even to roles that don't normally pick one up. Elf Priests and Wizards get a free musical instrument. Available for: Priest, Ranger, Wizard.

**Gnome.** Infravision from level 1, slightly higher Int cap than a human, and most gnomes and dwarves in the Mines are peaceful to you. The early branch turns from a meat grinder into a friendly shopping trip. Touchstones identify gems for you without needing to be blessed. Gnome Rangers also reach crossbow multishot at Str 16 instead of Str 18. Available for: Archeologist, Cave Dweller, Healer, Ranger, Wizard.

**Orc.** Poison resistance from level 1 is useful, and it lets you eat kobold corpses safely (free nutrition in the early dungeon). Orcs may also eat other orcs without a cannibalism penalty. Lower stat caps overall, and many humans, elves, and dwarves are race-hostile to orcs. Monsters that are normally peaceful, including shopkeepers, priests, and watchmen, stay peaceful. Other orcs aren't automatically peaceful either. Available for: Barbarian, Ranger, Rogue, Wizard.

#### Alignment {#alignment}

It is tempting to read Lawful, Neutral, and Chaotic as good, balanced, and evil. The game does not judge you that way. Alignment is a number that measures how well you have kept your god's rules.

Killing a hostile monster usually raises that number. Killing a peaceful monster costs every alignment 5 points, and murdering one also costs Luck. Some roles add rules of their own: Knights lose standing for striking helpless foes, and Samurai for attacking peaceful ones. A damaged record can be repaired through ordinary hostile kills and [sacrifice](#sacrifice).

Alignment also determines your god, your Quest, and which artifacts you can handle safely. Lawful characters can draw Excalibur from a fountain at XL 5 or later. Rogues are always Chaotic; dwarves are always Lawful. For the full altar rules, see [Altars and Alignment](#altars-and-alignment).

---

### What to Pack {#what-to-pack}

Your starting kit is fixed by your role and suited to its strengths, but you'll want to improve on it. In the early game, keep an eye out for these items as you descend. They'll shore up most roles' weaknesses.

#### The Early Shopping List {#the-early-shopping-list}

**A source of nutrition.** You will get hungry. It happens faster than you think. But your main food source isn't going to be the rations in your pack. Unless you're playing a vegetarian role, **most of your food in the early dungeon is the corpses of the things you kill.** Eat fresh kills as you go (`e`, then choose the corpse on your square), and rations become emergency backup rather than the main course. Grab every food ration you see, sure, but two or three is plenty to carry; you don't need to hoard. Tripe rations are for your pet, not for you.

**A way to identify things.** In the early game, your primary identification tools are altars (drop items to see if they flash blessed/cursed), your pet (it is reluctant to step on cursed items), and experimentation. A scroll of identify is valuable, but you might not find one for a while. A touchstone (a gray stone that identifies gems) is helpful. At shops you will learn to recognize some items by their prices: the cheapest scroll is an identify scroll, and the cheapest potion is a healing potion. The full identification playbook is in [A Practical Identification Strategy](#a-practical-identification-strategy).

**Armor improvements.** At AC 6 or worse, with no altar or pet to test what you find, put on ordinary body armor, helmets, shields, and cloaks. A curse on one of those is usually less dangerous than walking around unarmored. Test boots and gloves first: cursed levitation, fumbling, or trapped hands can leave you unable to escape.

**Your weapon.** Most roles should keep the weapon they started with: it matches your best skill, which you can [`#enhance`](#enhancing-skills) through practice, and switching weapons also discards any enchantment it may have started with. Pick a replacement if you're a Tourist, Cave Dweller, or Healer who starts with a feeble weapon, or if it matches your skills (check the `#enhance` chapter), or it's **silver** (a hefty bonus against werecreatures, vampires, demons, shades, and imps). Ordinary zombies and mummies ignore it. Prefer one-handed if you want the option to hold a shield.

**A throwing stack.** Keep daggers, darts, spears, or a bow and arrows ready, not buried in a bag. A floating eye should never be fought in melee. Rothes, homunculi, killer bees, and soldier ants are also much safer if you begin hurting them before they reach you.

**Restraint.** New adventurers pick up everything they find. Veterans pick up everything they need. The difference is about forty pounds and the ability to outrun a gnome lord. If your status line reads "Burdened," you're carrying more than you can use. You are also moving slow enough for some monsters to land two hits per one of yours. When your pile of stuff gets too heavy, drop the non-essentials. Careful about what you leave for monsters, though. They can pick up what you drop, and they can loot containers. You can drop stuff a level up; monsters don't carry stashes between levels.

---

### Your First Descent {#your-first-descent}

You step down the stairs. The air is cool and damp. A corridor stretches before you, branching into darkness. Your pet trots beside you.

Welcome to the dungeon.

The first few levels go easy on you, which is a relative term. Monsters are weaker, but so are you: minimal gear, low HP, and none of the resistances that make the mid-game survivable. More adventurers die on levels one through five than anywhere else, not because the monsters are fierce but because you have so little to answer them with.

#### The Golden Rules of Early Survival {#the-golden-rules-of-early-survival}

**Rule 1: Don't fight what you can't beat.** Decide after the first exchange, not when you are down to your last few hit points. Take the up stair if you can. Otherwise reach a door you can close, then a corridor. If there is no way out, engrave `Elbereth` in the dust with `E`, then `-`, before the monster reaches you.

```
  Bad: fighting in the open       Good: corridor chokepoint

  ┌─────·──────┐                  ┌─────·──────┐
  │·o··Z·······│                  │·o···Z······│
  │··k·@·G·Z···│                  │··k··G······│
  │····o·······│                  │·o··········+##@
  │··G·········│                  │··G·········│
  └────────────┘                  └────────────┘

  You're surrounded.              They come to you one at a time.
```

**Rule 2: Don't eat things you don't understand.** Monster corpses can grant powerful intrinsics, or they can poison you, give you food poisoning, or worse. Until you know what a corpse does, leave it on the ground. (Kobold `k` meat, for example, is poisonous and confers nothing.) The exceptions: you can always safely eat food rations, lembas wafers, cram rations, and fruits. Lichen corpses are safe and never rot. Lizard corpses are safe, never rot, and cure petrification. Keep one in *open* inventory, not buried in a bag: if a cockatrice touches you, you have two turns to chew. Newt corpses are safe, and they sometimes restore 1–3 Pw, which is the first sustainable mana source a spellcaster will see.

**Rule 3: Your pet is your friend.** Your starting pet fights alongside you and picks up items (a pet is reluctant to step onto a cursed item, which makes that a useful test), and can even be trained to steal from shops. Keep it fed by dropping tripe rations or corpses near it.

**Rule 4: Learn to pray.** If you are about to die (hit points critically low, Weak with no food, turning to stone) you can pray to your god (`#pray`) for help. In the early game, with decent alignment and non-negative Luck, prayer will almost certainly save you. Do not pray in the first 300 turns. After a prayer, count on waiting about a thousand turns to be safe; the actual recovery averages around 500 but can run much longer. Praying at the wrong time (when your god is angry, when you're in [Gehennom](#gehennom), or when you've prayed too recently) can make things much worse. Don't waste it on minor problems (see [Divine Relations](#divine-relations) for the full mechanics). If you have lost alignment, kill ordinary hostile monsters; kobolds and orcs are useful targets even for a Neutral character.

**Rule 5: Explore thoroughly but move purposefully.** Every turn costs nutrition, so standing around for hundreds of turns starves you, but rushing past rooms misses items you need. Explore each level fairly completely (check rooms, open doors, and use `s`, or `10s`, to look for hidden passages), then move on when you've found what it offers. Once you know the down stair, do not spend hundreds of turns tapping walls. If you are Hungry and the level has no food left, go down.

**Rule 6: Build your defenses.** In the first half of the game, your goal isn't treasure but the resistances that carry you through the late game. The three most important are **[magic resistance](#damage-resistances)**, **reflection**, and **[poison resistance](#damage-resistances)**. Poison resistance is an *intrinsic* from eating the right corpse: a killer bee, giant spider, yellow mold, or a [black pudding](#a-note-on-puddings) kicked from a sink. Magic resistance and reflection come from gear: dragon scale mail (gray for MR, silver for reflection), a cloak of MR or amulet of reflection, a silver shield (reflection), or an artifact from your god, [the Quest](#the-quest), or a wish.

**Rule 7: Type deliberately, never autorepeat.** Each key you press is a turn. If you hold a movement key down and let it autorepeat, your character marches blindly until something stops them, usually a monster you didn't intend to engage, a trap that's just been revealed, or a fountain you didn't mean to quaff. Press each key once and pause. To cross long corridors without one keypress per square, learn the **shift-direction** shortcut: capital `H J K L Y U B N` runs past items and doors but stops for a monster ahead or one that hits you. `G`+direction is the cautious version; it also stops beside monsters, items, and doors. Autorepeat offers neither protection.

#### Dungeon Hazards (and How to Survive Them) {#dungeon-hazards-and-how-to-survive-them}

Here's a short list of common early deaths and how to prevent them:

**Starvation.** Eat when you're Hungry (the status message), not when you're Weak or Fainting. If you are Hungry with no food, descend; a cleared floor will not grow a new ration. Weak already counts as a prayer emergency. At Fainting, eat or pray at once.

**Floating eyes.** They're the `e` on the map. Small, blue, and seemingly harmless. If you hit one in melee, you'll be paralyzed, and every monster in the vicinity will take free shots at your frozen body. Use ranged attacks, or just walk around them. They are very slow.

**Rotted corpses.** If you eat a corpse that's been on the ground too long, you'll get food poisoning, which is lethal without treatment. Eat corpses fresh, within about 30 turns of the kill for a guaranteed-safe meal. Past that, the rot roll turns random; past ~175 turns an uncursed corpse is certainly tainted. If you do get food poisoning, use blessed healing, non-cursed extra or full healing, a unicorn horn, or a eucalyptus leaf. Pray only if the requirements in [Divine Relations](#prayer) are satisfied.

**Falling down stairs while overburdened.** If you're carrying too much, taking the stairs can make you tumble for 1–3 HP. A cockatrice corpse in your pack is harmless; a wielded one can stone you in the fall.

**Caught in the open by a pack.** Jackals bite for only 1d2 each, but small packs of two to four spawn on the upper levels and surround you in open rooms. Killer bees, soldier ants, and gnomes arrive the same way. Retreat to a doorway or corridor at the first sign of more than two attackers. If they have not reached you yet, hold your ground and let them spend the approach turns; stepping toward a pack gives those turns away.

**Pushing too quickly into [the Mines](#the-gnomish-mines).** The deeper Mines below Minetown are crowded with armored dwarves and gnome lords. If you're not ready for armored melee packs, head back to the main branch and return later.

#### Supply Containers {#supply-containers}

New in NetHack 5.0: somebody has been leaving care packages.

Every level above [the Oracle](#the-oracle) has a 2/3 chance of hosting a "supply chest": usually a chest (sometimes a large box), usually locked, seeded with at least one survivability item. The contents pool: potion of healing (about a 50% chance per chest, sometimes a pair), or otherwise potion of extra healing / speed / gain energy, scroll of enchant weapon, enchant armor, confuse monster, or scare monster, wand of digging, or spellbook of healing. There's also a 2/3 chance of an extra random item, biased toward low-level spellbooks. The Mines branch level gets a different gift: a guaranteed food ration, cram ration, or lembas wafer.

These look like ordinary containers, no special marking. Above the Oracle, check every chest and large box. A locked one yields to a credit card, a key, or a wand of opening, or `#force` it. Pry with a dagger if you can: blades very rarely snap, while a blunt weapon may smash the box and any healing potion inside.

---

## Part Two: Dungeon Sights {#part-two-dungeon-sights}

The map is full of punctuation, but only a few marks should stop you in your tracks. Read [Points of Interest](#points-of-interest) when you find dungeon furniture and [Branches and Landmarks](#branches-and-landmarks) before taking an unfamiliar stair. The field guide is meant for lookup: find the letter, then follow the link if the short warning is not enough.

### The Lay of the Land {#the-lay-of-the-land}

The Mazes are laid out fresh every game, but the branches, special levels, and their rough depths stay the same. Once you know that shape, you can usually tell what is coming next.

#### The Big Picture {#the-big-picture}

The dungeon is a branching tree with a main trunk and several side branches. Exact depths vary; the diagram gives the usual shape.

The **Dungeons of Doom** form the upper half, roughly levels 1 through 27. Side branches lead to the **[Gnomish Mines](#the-gnomish-mines)** (where you can find a *[luckstone](#luck-and-fortune)* and *[shops](#shopping-and-shopkeeper-pricing)*), **[Sokoban](#sokoban)** (a *[puzzle](#sokoban)* with a prize at the top), your **[Quest](#the-quest)** dungeon (in which your role's leader sends you on a mission to retrieve a precious artifact), and sometimes **Fort Ludios** (a vault full of gold). The trunk ends at **The Castle**, the gateway to [Gehennom](#gehennom).

**Gehennom** is the lower half: lava-filled maze levels and demon lords, with the **Amulet of Yendor** at the bottom in [Moloch's Sanctum](#molochs-sanctum). Once you have it, you climb back up through the **Elemental Planes** to the **Astral Plane**, where your god awaits your offering.

![Branches extend left and right of the main trunk. Pearls indicate approximate dungeon levels. ★ marks the three Invocation items.](asset:assets/images/spoiler_dmap_en.webp)

#### The Map Symbols {#the-map-symbols}

Everything in the dungeon is represented by a symbol on the screen. Learn to read them at a glance:

| Symbol   | Meaning                       |
| -------- | ----------------------------- |
| `.`      | Floor (room)                  |
| `#`      | Corridor, tree, or cloud       |
| `-`  `│` | Wall (horizontal, vertical)   |
| `+`      | Closed door (or spellbook)    |
| `<`      | Stairs up                     |
| `>`      | Stairs down                   |
| `{`      | Fountain (bright blue) or sink (white) |
| `_`      | Altar                         |
| `\`      | Throne                        |
| `^`      | Trap (once revealed)          |
| `@`      | You (or a human-type monster) |
| `` ` ``  | Boulder                       |
| `}`      | Water or lava                 |

Letters represent monsters: `d` for dogs, `D` for dragons, `Z` for zombies. Colors help distinguish within a class: a red `D` is a red dragon, while a gray `D` is a gray dragon (see [Field Guide to Dungeon Fauna](#field-guide-to-dungeon-fauna)).

**Color memo: branch staircases turn yellow.** Staircases that lead into a sub-branch (Mines or Sokoban) display in yellow once you've used them. Ordinary main-trunk stairs stay default-colored, so on a level with several stairs the yellow one is your way back into the branch.

Item symbols are punctuation marks:

| Symbol | Item Class         |
| ------ | ------------------ |
| `)`    | Weapons            |
| `[`    | Armor              |
| `%`    | Food (comestibles) |
| `!`    | Potions            |
| `?`    | Scrolls            |
| `/`    | Wands              |
| `=`    | Rings              |
| `"`    | Amulets            |
| `(`    | Tools              |
| `+`    | Spellbooks         |
| `*`    | Gems and stones    |
| `$`    | Gold (zorkmids, abbreviated **zm**) |

#### Room Types {#room-types}

Most rooms in the dungeon are ordinary, empty or with a few items and monsters scattered about. But some rooms are special:

```
   A shop:                 A zoo:                 A throne room:
   ┌───────┐               ┌────────┐             ┌────────┐
   │[?!=/("│               │Z··Z$Z··│             │··Z·Z·Z·│
   │)%*[?!(│               │$Z···$Z·│             │·Z·\··Z·│
   │··@····│               │·Z$Z··Z$│             │··Z·Z···│
   └──+────┘               └───+────┘             └───+────┘
      #                        #                      #
   @ = shopkeeper          Z = sleeping           \ = throne
   Items for sale.         $ = gold piles         Monsters guard.
```

**Shops.** Identified by the shopkeeper inside, usually near the door. Shops sell items of a particular type: general stores, armor shops, weapon shops, scroll shops, potion shops, and more. Items on the shop floor belong to the shopkeeper; pick one up and you'll be quoted a price. You can sell items too. Shopkeepers are extremely powerful in combat, so don't steal unless you have a plan.

**Temples.** A room with an altar and a priest or priestess tending it. The altar's alignment matters: if it matches yours, you can sacrifice here for good effects. If it doesn't, the resident priest won't be friendly about your attempts. The priest will also accept gold donations in exchange for clairvoyance or a permanent AC bonus See [Donating to Priests](#donating-to-priests).

**Throne rooms.** A room with a [*throne* (`\`)](#thrones), a sleeping ruler at the throne, and a full court of monsters filling the rest. Sitting on the throne has random effects, sometimes wonderful, sometimes terrible.

**Zoos.** A room packed with sleeping monsters and gold. Each sleeper that can see you from within ten squares has a one-in-seven chance to wake each turn. Stealth prevents that. Fight from the doorway so only one or two can reach you at a time.

**Barracks.** A room full of soldiers. They're organized and armed, but they're also carrying good equipment. Worth clearing if you can handle the fight.

**Beehives.** A room full of killer bees and royal jelly. The bees are dangerous in numbers, but royal jelly is excellent food.

**Themed rooms.** The dungeon also has dozens of rooms that are odd in shape (pillars, a room inside a room) or in their contents. Some to look out for:

- **Light source rooms.** They reliably contain a lit oil lamp. Free torch.
- **Buried treasure.** A burned engraving somewhere on the floor reads *"Dig 3 east 2 south"* (or wherever) and points to a buried chest plus 3–12 random items. A pick-axe earns its weight here.
- **Massacre.** Floor strewn with human adventurer corpses. None grants an intrinsic. A human who eats one commits cannibalism, and a non-Chaotic sacrifice of one is a serious offense.
- **Mausoleum.** A small interior chamber with one waiting monster (mummy, vampire, lich, or zombie) or a human corpse. Open the door carefully.
- **Spider nest, buried zombies, trap room, teleportation hub.** Treat these as traps. Spider nests and buried zombies scale with depth, so back out and return with what the room calls for. Trap rooms may hold anything from arrow traps to anti-magic fields or land mines.
- **Pillared and divided rooms.** Some rooms contain pillars, an inner chamber, or a blocked center. Use those corners to protect an [Elbereth](#elbereth) square or keep a polearm target at reach.

Themed rooms are mixed in with ordinary rooms; a level may have several.

---

### Field Guide to Dungeon Fauna {#field-guide-to-dungeon-fauna}

The Mazes are home to hundreds of monster species, organized into classes denoted by letters. Lowercase letters are generally smaller or less dangerous; uppercase letters are larger or more threatening. Color further distinguishes individual species within a class.

Here is a quick field guide to what each letter means, roughly ordered by how early you might encounter them. For the full level / speed / AC / attack details on every monster, see the [Bestiary Tables](#bestiary-tables) appendix.

#### Common Early Encounters {#common-early-encounters}

| Sym    | Class                  | Notes                                                                      |
| ------ | ---------------------- | -------------------------------------------------------------------------- |
| [`a`](#ants-and-insects-a)    | [Ants](#ants-and-insects-a)      | Soldier ants are a frequent early-game killer: speed 18, two attacks per turn (bite + strength-draining sting), and they travel in packs. Killer bees, giant ants, fire ants are all the same shape of problem. |
| [`b`](#blobs-b)    | [Blobs](#blobs-b)     | Acidic or gelatinous. Acid blobs have no active attack. They only splash 1d8 acid back when *you* hit *them*, and the splash can corrode your weapon. Kill at range. Eat for [resistances](#useful-corpse-effects). |
| [`B`](#bats-and-birds-b)    | [Bats](#bats-and-birds-b)      | Speed is the danger. Bats and giant bats move at 22 against your base 12, so they bite almost twice per one of your swings. A giant bat's 1d6 bites wear a new character down quickly. Vampire bats add a Strength-draining bite. |
| [`d`](#dogs-and-canines-d)    | [Dogs and other canines](#dogs-and-canines-d) | Jackals bite for only 1d2, but on the first few levels a pack of them kills more characters than anything else. Foxes bite for 1d3 and are faster, but spawn alone. Tame dogs and cats help fight everything else. |
| [`e`](#eyes-and-spheres-e)    | [Eyes](#eyes-and-spheres-e)      | A floating eye paralyzes you when struck in melee; use a missile or walk around it. Gas spores explode for 4d6 when killed, so shoot from at least two squares away. Flaming, freezing, and shocking spheres also explode nearby. |
| [`f`](#felines-f)    | [Cats](#felines-f)      | Like dogs, often starting pets. Domestic cats can be tamed with tripe; wild felines need magic. |
| [`G`](#gnomes-g)    | [Gnomes](#gnomes-g)    | The Mines have a lot of them. Most are peaceful to gnomes and dwarves. Lords and kings are stronger but need no separate rule. |
| [`h`](#humanoids-h)    | [Humanoids](#humanoids-h) | Dwarves, bugbears, mind flayers. A dwarf with a mattock hits for 1d8 plus 1d12, enough to kill a first-level character in two swings. Start at range. |
| [`i`](#imps-and-minor-demons-i)    | [Imps](#imps-and-minor-demons-i)      | Mostly minor pests, but a homunculus's bite can put you to sleep. Without sleep resistance, fight at range. |
| [`j`](#jellies-j)    | [Jellies](#jellies-j)   | They do not move. Walk around them; melee can trigger passive acid damage.               |
| [`k`](#kobolds-k)    | [Kobolds](#kobolds-k)   | Weak, but every kobold corpse is poisonous. Very rarely one carries poisoned darts.      |
| [`o`](#orcs-o)    | [Orcs](#orcs-o)      | Numerous and modest in strength one-on-one; dangerous in packs. Hill orcs and Mordor orcs are the common upper-dungeon variants. |
| [`r`](#rodents-r)    | [Rodents](#rodents-r)   | Rats and rock moles. Rock moles eat metal items, so protect your gear.                  |
| [`s`](#arachnids-and-centipedes-s)    | [Spiders](#arachnids-and-centipedes-s)   | Cave spiders are weak (eat them for poison resistance). Giant spiders poison.            |
| [`x`](#xans-and-fantastic-insects-x)    | [Grid bugs](#xans-and-fantastic-insects-x) | The weakest monster in the game; they can't even move diagonally. They leave no corpse. The `x` class also covers the much-later **xan**, whose sting cripples your legs (slow movement until it heals). |
| [`:`](#lizards)    | [Lizards](#lizards)   | Newts, geckos, and iguanas are individually weak. The class matters mostly for the corpses: **lizard corpses cure [petrification](#petrification-stoning)** (carry one for cockatrice insurance), and newt corpses may restore 1–3 mana. |

#### Mid-Dungeon Threats {#mid-dungeon-threats}

| Sym    | Class             | Notes                                                                                                |
| ------ | ----------------- | ---------------------------------------------------------------------------------------------------- |
| [`A`](#angelic-beings-a)    | [Angels](#angelic-beings-a)            | Powerful, usually aligned. Don't fight your own.                                                     |
| [`C`](#centaurs-c)    | [Centaurs](#centaurs-c)          | Fast (speed 18-20). Half spawn with a bow or crossbow, but they'll still close into melee for weapon and kick attacks. Mountain centaurs hit hardest: 1d10 weapon plus *two* 1d6 kicks per turn. |
| [`E`](#elementals-e)    | [Elementals](#elementals-e)        | Hard to kill. Air elementals [engulf](#engulfment); earth elementals phase through walls. |
| [`f`](#felines-f)    | [Displacer beast](#felines-f)   | Cat-class, but vicious: AC −10 and a hard three-attack melee. Eat the corpse for temporary intrinsic Displacement. |
| [`F`](#fungi-and-molds-f)    | [Fungi](#fungi-and-molds-f)             | Molds do not move, so walk around them. Shriekers summon other monsters.                              |
| [`g`](#gremlins-g)    | [Gremlins / gargoyles](#gremlins-g)   | Heavy claws plus a special trick. Gremlins **strip a random intrinsic on hit at night** and **multiply when wet** (don't kick one into a fountain). Gargoyles are slow but armored (AC −4) with three-attack salvos; winged gargoyles fly. |
| [`'`](#golems)    | [Golems](#golems)            | Built things. Iron golems hit hard and resist nearly everything; clay, stone, and wood golems are softer. Glass golems leave gems on death. |
| [`H`](#giant-humanoids-h)    | [Giants](#giant-humanoids-h)            | Strong melee, throw boulders, and carry gems. Their corpses can raise Strength.                      |
| [`J`](#jabberwocks-j)    | [Jabberwock](#jabberwocks-j)        | Four 2d10 attacks per turn, about 44 damage if all four land.                                        |
| [`K`](#keystone-kops-k)    | [Keystone Kops](#keystone-kops-k)     | The shopkeeper-summoned constabulary. They appear when you steal, refuse to pay, or anger a shopkeeper. Individually weak but they swarm, and they jeer at you. |
| [`l`](#leprechauns-l)    | [Leprechauns](#leprechauns-l)       | Steal your gold and teleport away. A single claw can grab up to *all* of your purse. Hide gold in a sack, drop it elsewhere, or fight at range. |
| [`L`](#liches-l)    | [Liches](#liches-l)            | Spellcasters. Arch-liches are among the most dangerous monsters in the game because they cast touch of death. |
| [`m`](#mimics-m)    | [Mimics](#mimics-m)            | Disguised as items, walls, doors, fountains, altars, or boulders. See [A note on mimics](#a-note-on-mimics). |
| [`M`](#mummies-m)    | [Mummies](#mummies-m)           | Aggressive undead with physical claw attacks. They leave the already-rotten corpse of their base race; there is no aging effect. Mummy wrapping worn as a cloak blocks invisibility, useful when a shopkeeper refuses to serve you. |
| [`n`](#nymphs-n)    | [Nymphs](#nymphs-n)            | [Steal items from your inventory, then teleport away](#a-note-on-nymphs). Fight from range. |
| [`N`](#nagas-n)    | [Nagas](#nagas-n)             | Large serpent-bodied creatures. Red nagas breathe fire, black nagas spit acid, golden nagas cast spells, guardian nagas spit Str-drain poison and have a paralyzing bite. Tough; speeds 12–16. |
| [`O`](#ogres-o)    | [Ogres](#ogres-o)             | Heavy hitters for the upper dungeon, and they travel in groups; ogre lords and kings hit harder still. Don't get surrounded. |
| [`p`](#piercers-p)    | [Piercers](#piercers-p)          | Disguise as stalactites and drop for 2d6 damage (iron 3d6, glass 4d6). A hard helmet blocks the blow; good AC may let you dodge. |
| [`P`](#puddings-and-oozes-p)    | [Puddings](#puddings-and-oozes-p)          | [Black and brown puddings split when hit in melee with an iron or metal weapon](#a-note-on-puddings) (scalpel and tsurugi count). Good to eat for [intrinsics](#useful-corpse-effects). |
| [`q`](#quadrupeds-q)    | [Quadrupeds](#quadrupeds-q)        | Multi-attack mid-game bruisers. The **rothe** is the famous one (three attacks per turn at sluggish speed 9, dangerous in packs); mumakil are solo two-attack bruisers (4d12 butt + 2d6 bite).                              |
| [`R`](#rust-monsters-and-disenchanters-r)    | [Rust monster](#rust-monsters-and-disenchanters-r) | Rust monsters corrode worn iron armor when they hit you, and your wielded iron weapon when you hit them. Use mithril, silver, or wood, or strip iron gear before the fight. Disenchanters appear only in Gehennom; see [Enchantment Drain](#enchantment-drain). |
| [`S`](#snakes-s)    | [Snakes](#snakes-s)            | Cobras and pit vipers poison. Water moccasins come from fountains.                                   |
| [`t`](#trappers-and-lurkers-t)    | [Trappers / lurkers above](#trappers-and-lurkers-t) | Hide in plain sight on floor or ceiling and [engulf you](#engulfment) when you walk under/onto them. |
| [`T`](#trolls-t)    | [Trolls](#trolls-t)            | [Regenerate. They come back from the dead unless you eat or tin the corpse](#a-note-on-trolls). |
| [`u`](#unicorns-and-horses-u)    | [Horses / unicorns](#unicorns-and-horses-u) | Wild horses spawn hostile but can be tamed and ridden. Unicorn color marks alignment: your own spawns peaceful. Throw hostile unicorns gems; see [Luck and Fortune](#luck-and-fortune). |
| [`U`](#umber-hulks-u)    | [Umber hulk](#umber-hulks-u)        | Its gaze confuses you whenever you can see it. A blindfold makes you immune.                          |
| [`v`](#vortices-v)    | [Vortices](#vortices-v)          | Fast [engulfing](#engulfment) clouds, except for the slow fog cloud. Dust blinds; ice freezes; energy shocks and drains Pw; steam and fire burn. Kill at range. |
| [`w`](#worms-w)    | [Worms](#worms-w)             | Long worms grow tail segments as they move and can be a corridor in themselves. |
| [`W`](#wraiths-w)    | [Wraiths](#wraiths-w)           | [Drain levels on hit](#level-drain). But [their corpses grant a level](#a-note-on-wraiths), so eat them fresh. |
| [`y`](#lights-y)    | [Yellow/black lights](#lights-y) | Explode adjacent. Yellow blinds you; black hallucinates you. Black lights are invisible without *see invisible*. Kill at range. |
| [`Y`](#apelike-creatures-y)    | [Yetis](#apelike-creatures-y)             | Big white brutes. A yeti corpse grants cold resistance about one time in three.              |
| [`z`](#zruties-z)    | [Zruty](#zruties-z)             | Slow, but attacks with two 3d4 claws and a 3d6 bite each turn.                                |
| [`Z`](#zombies-z)    | [Zombies](#zombies-z)           | Slow and numerous. A wand or spell of undead turning deals 1d8 and makes them flee. Race-based zombies drop an already-old corpse of their base race. |

#### Very Dangerous Monsters {#very-dangerous-monsters}

| Sym    | Class            | Notes                                                                                                    |
| ------ | ---------------- | -------------------------------------------------------------------------------------------------------- |
| [`c`](#cockatrices-c)    | [Cockatrices](#cockatrices-c)      | **Touch = [instant petrification](#petrification-stoning).** Never hit one barehanded. Wield their corpse with gloves as a weapon. |
| [`D`](#dragons-d)    | [Dragons](#dragons-d)          | [Each color has its own breath weapon, resistance, and scale mail property](#a-note-on-dragons). See note below. |
| [`h`](#humanoids-h)    | [Mind flayers](#humanoids-h)     | [Drain intelligence on hit](#brainlessness). **At Int 3, the next tentacle that lands kills you.** A helmet blocks 7/8 tentacles. Kill from range. |
| [`V`](#vampires-v)    | [Vampires](#vampires-v)         | [Drain levels](#level-drain). Vampire lords fly and are fast. |
| [`w`](#worms-w)    | [Purple worms](#worms-w)     | The big worm: [swallows you whole on a hit, then digests](#engulfment). Cut your way out from inside. |
| [`X`](#xorns-x)    | [Xorn](#xorns-x)             | Passes through walls. Three claws and a bite per turn; hard to ambush and hard to escape from. |
| [`;`](#sea-monsters)    | [Sea monsters](#sea-monsters)     | [Drowning is an instadeath](#drowning). Don't fight in water without a plan. |
| [`&`](#major-demons)    | [Demons](#major-demons)           | Major demons (Orcus, Demogorgon, Asmodeus) are boss-level threats.                                       |
| [`@`](#humans-and-elves)    | [Humans (hostile)](#humans-and-elves) | Includes the Wizard of Yendor, the most persistent nuisance in the game.                          |
| [`Q`](#quantum-mechanics-q)    | [Quantum mechanics / genetic engineers](#quantum-mechanics-q) | Quantum mechanics teleport their target on a hit; genetic engineers (new in 5.0) polymorph their target. |

#### Special Symbols {#special-symbols}

A few map glyphs aren't monsters in the conventional sense, but you'll see them and need to know what they mean.

| Sym    | What it is               | Notes                                                                                                |
| ------ | ------------------------ | ---------------------------------------------------------------------------------------------------- |
| `I`    | Invisible monster marker | The game remembers the last spot you sensed something you couldn't see. The `I` stays there until you bump it or step on the square; the monster has usually moved. |
| `~`    | Long worm tail segment   | Part of a long worm's body. Hitting the tail damages the worm and shortens the chain; hitting the head (the `w`) is full melee. |
| `]`    | Strange object           | **Always a [mimic](#a-note-on-mimics).** No ordinary item ever displays as `]` (compare `[`, armor, and `]` is its mirror). |
| `⎕`(space) | Ghost            | Ghosts left from bones files. The glyph is a literal space, which paints over the floor underneath: in a room, a ghost shows as a one-square *gap* in the floor where a `.` should be. Walk into the gap to identify it. |

---

### Points of Interest {#points-of-interest}

As you descend, make time for the landmarks. Scattered throughout the levels are fixtures that reward the curious, and occasionally punish them.

#### Fountains `{` {#fountains}

Ah, fountains. That gentle bubbling sound has lured more adventurers to their doom than any trap, with the promise of a cool refreshing drink.

About one in seven randomly placed fountains is a **magic fountain**, regardless of your Luck. It is indistinguishable from an ordinary one until you drink. With non-negative Luck, a successful magic draught says *Wow! This makes you feel great!*, restores every attribute to its maximum, and raises every attribute by one. That consumes the magic charge. (Pre-placed fountains like those in Minetown or [the Oracle](#the-oracle), and fountains created from another feature, are never magic. Also: dipping gets no benefits from magic charge but could consume it.)

**Quaffing from an ordinary fountain** is a dangerous slot machine with dozens of random effects including:

| Outcome           | Effect                                                |
| ----------------- | ----------------------------------------------------- |
| Water demon       | A water demon appears, hostile                        |
| Water nymph       | A water nymph appears and tries to steal an item      |
| Water moccasins   | A swarm of snakes appears                             |
| Curse some items  | "This water's no good!" (items in your main inventory may be cursed; items inside a bag are safe) |
| Poisonous water   | "The water is contaminated!" Str damage (poison resistance blocks the worst) |
| See invisible     | You gain the ability to see invisible creatures       |
| Detect monsters   | Brief view of every monster on the level              |
| Self-knowledge    | A brief enlightenment readout of your own state       |
| Scare monsters    | Bad breath, every monster on the level panics        |
| Nothing           | "The cool draught refreshes you." or "This tepid water is tasteless." |

Most of the time, nothing happens. A demon appears about 1/30; on shallow levels it may grant a wish instead of attacking, working out to roughly 1 wish per 150 quaffs and dropping to zero past Dlvl
20. To take the risk: put your items in a bag (cursing protection), engrave [Elbereth](#elbereth) (demons keep their distance), and have a charm- or scare-monster effect ready in case a demon appears.

**Dipping in a fountain** is how a Lawful character gets Excalibur. If you're at least XL 5, dipping a long sword may transform it into [Excalibur](#excalibur-artifact), one of the finest weapons in the dungeon. Knights get a generous 1/6 chance per dip; everyone else gets a meager 1/30. Otherwise, dipping can rust your gear, summon hostile water creatures, or occasionally uncurse the dipped item.

At XL 5, a Lawful Knight carrying a long sword should dip in every fountain until Excalibur appears. Each dip carries roughly a one-in-three chance of drying the fountain up, so a single one rarely lasts long enough to deliver on its own. Don't worry about the rust you collect along the way; the instant the sword becomes Excalibur, that rust is wiped clean and the blade turns permanently rustproof. A couple of cautions: leave the Minetown fountains alone, since draining a town fountain brings the Watch down on you, and if you're not lawful, don't dip at all, because the Lady of the Lake will only curse the sword. Other lawful roles can try, but at 1-in-30 a dip they should pack patience.

#### Altars `_` {#altars}

An altar is a consecrated stone shrine, marked `_` on the map and aligned to one of the three gods. Drop your gear on it to learn at a glance what is blessed or cursed, and sacrifice fresh corpses on it to earn your god's favor.

**Dropping items on an altar** (`d` for one, `D` to drop several at once) reveals their BUC status instantly. **Amber flash** → Blessed. **No flash** → Uncursed. **Black flash** → Cursed.

It costs nothing and never runs out, so haul unknown gear to the first altar you find before putting it on. (Drop the whole pile at once; you'll see one flash per item.)

**Sacrificing monster corpses on an altar** (`#offer`, while standing on it) earns your god's favor. A stale corpse simply does nothing; a fresh, difficult monster is worth more. Sacrifice enough and your deity may reward you with an artifact weapon aligned to your cause. Don't sacrifice your starting pet: the alignment loss is severe and the residual aggravate-monster intrinsic sticks around for the rest of the run. See [Divine Relations](#divine-relations) for the full theology.

**Converting an altar** is risky enough that the details matter. With a non-negative alignment record, a cross-aligned sacrifice either flips the altar or costs 1 Luck; either result may summon a minion. With a negative record, the altar converts *you* instead. Read [Altars and Alignment](#altars-and-alignment) before trying it.

#### Thrones `\` {#thrones}

A throne is an ornate royal seat, marked `\`, that turns up now and then in a room of its own. Sitting on one (`#sit`) is the purest gamble in the Mazes: the list of possible outcomes reads like a wish list shuffled with a hit list:

- A wish (most reliable at non-negative Luck)
- Genocide of one monster species
- Free identification of one to four items in your pack (or, one time in five, your entire inventory)
- A stat boost or a stat drain
- An electric shock
- Full healing
- A crowd of hostile monsters, summoned for your amusement
- Confusion
- A curse on as many as six items; at positive Luck, long blindness and lost Luck instead
- Magic mapping of the level
- [See invisible](#senses-and-perception)
- All your gold, vanished
- Teleportation; with bad Luck, every monster on the level wakes instead

About one time in three, something happens, but you won't know which column of the ledger it's going to hit. Sit on a throne when you're strong enough to survive the worst row of that table. A wish can still come at Luck -1, but non-negative Luck guarantees the favorable branch when that outcome is rolled. Even when nothing happens, the throne may vanish in a puff of logic, so you might get several tries or none at all. (Vlad's throne in the Tower is special: it never vanishes without granting a wish first.) Kicking a throne is a different gamble. One kick in three, once per throne, dislodges 300–500 gold and up to six gems. Of the failed kicks, one in four drops you through a trap door.

#### Sinks `{` {#sinks}

They say a dungeon has everything but the kitchen sink. The Mazes of Menace has the kitchen sink too, the white `{` on the map, and it is more colorful hazard than convenience. You can kick it, drink from it, or drop things down it: a couple of those tricks pay off, but most fizzle, and several can hurt you.

**Kicking a sink** usually produces a harmless *Klunk!* Four kicks in five do nothing. A successful kick might shake loose a ring or summon a [black pudding](#a-note-on-puddings) (dangerous, though its glob is a [triple-resistance snack](#useful-corpse-effects)) or an *amorous demon* posing as "the dish washer" (the same incubus/succubus as [a seduction encounter](#seduction)), or just stub your toe. Each non-stub outcome fires at most once per sink. Worth a try early on only if you can handle whatever climbs out.

**Dropping a ring down a sink** produces a message distinctive to the ring's type, one for each of the twenty-eight rings, decoded in the table below. Searching and slow digestion return at once. Of the other rings, one in twenty comes back and one in five of the rest is buried beneath the sink, where a pick-axe can recover it; the rest are gone. It's most useful when you have a duplicate ring to spare, or when you're starving and gambling that an unknown ring is slow digestion. For anything else, price-ID, an altar, or a scroll of identify tells you as much and keeps the ring.

| Message                                              | Ring                  | Ring kept? |
|------------------------------------------------------|-----------------------|------------|
| *"You thought your ring got lost in the sink, but there it is!"* | searching | **yes**    |
| *"The ring is regurgitated!"*                        | slow digestion        | **yes**    |
| *"The sink quivers upward for a moment."*            | levitation            | no         |
| *"You smell rotten slime molds."* (or your custom fruit)              | poison resistance     | no         |
| *"Several flies buzz angrily around the sink."*     | aggravate monster     | no         |
| *"Static electricity surrounds the sink."*           | shock resistance      | no         |
| *"You hear loud noises coming from the drain."*      | conflict              | no         |
| *"The water flow seems fixed."*                      | sustain ability       | no         |
| *"The water flow seems stronger/weaker now."*        | gain strength         | no         |
| *"The water flow seems greater/lesser now."*         | gain constitution     | no         |
| *"The water flow hits/misses the drain."*            | increase accuracy     | no         |
| *"The water's force seems greater/smaller now."*     | increase damage       | no         |
| *"Suddenly, [items] vanish from the sink!"*<br>any other items on the sink square vanish too | hunger                | no |
| *"The sink vanishes."*<br>sink moves to a new spot                     | teleportation         | no |
| *"The sink transforms into a fountain/throne/altar/grave!"*<br>(or rarely *"The sink vanishes."* if grave generation fails) | polymorph             | no |
| *"The faucets flash brightly for a moment."*         | adornment             | no |
| *"The sink looks as good as new."*                   | regeneration          | no |
| *"The sink glows silver (or black) for a moment."*   | protection            | no |
| *"The sink glows white for a moment."*               | warning               | no |
| *"The sink seems to blend into the floor for a moment."* | stealth           | no |
| *"You don't see anything happen to the sink."*       | invisibility          | no |
| *"You see some air in the sink."*                    | see invisible         | no |
| *"You see the ring slide right down the drain!"*     | free action           | no |
| *"The hot water faucet flashes brightly for a moment."* | fire resistance    | no |
| *"The cold water faucet flashes brightly for a moment."* | cold resistance   | no |
| *"The sink looks like it is being beamed aboard somewhere."* | teleport control | no |
| *"The sink momentarily looks like a regularly erupting geyser."* | polymorph control | no |
| *"The sink looks nothing like a fountain."*          | protection from shape changers | no |

**Quaffing from a sink** rolls one of twenty random effects, most of them nothing. The good ones are thin: about a 1-in-20 chance a ring turns up at your feet (once per sink), and a similar chance a random potion is poured down your throat, which is a gamble in itself. The bad ones are worse: one sip in twenty polymorphs you uncontrollably, another unleashes a water elemental (a serious fight in the early game), and others scald, gas, or sicken you. On balance it is more hazard than help: an entertaining gamble if that is your idea of fun, but not something to rely on. If you do quaff, keep HP and an escape route in reserve.

**Pouring potions down a sink** (by dipping) produces telltale effects, a clever way to narrow down potion identities without risking a sip. Five potions print unique sink-only messages:

| Sink message                                                 | Potion             |
| ------------------------------------------------------------ | ------------------ |
| *"The sink transforms into a fountain/throne/altar/grave!"* (or *"The sink vanishes."*) | polymorph                     |
| *"Muddy waste pops up from the drain..."* (first time per sink also drops a ring) | levitation |
| *"It leaves an oily film on the basin."*                     | oil                |
| *"The drain seems less clogged."* (blind: *"a sucking sound"*)| acid               |
| *"You sense a ring lost down the drain."* (once per sink)    | object detection   |

For most other potions, the sink instead prints *"A wisp of vapor rises up..."* and then applies the same vapor effect as breathing a broken potion: the side effect normally identifies the potion. Sleeping and paralysis leave you helpless for 1–5 turns; hallucination gives only a momentary vision. Wasted on water, fruit juice, gain level, gain energy, and monster detection: those all just print *"nothing seems to happen."*

#### Vaults {#vaults}

A vault is a tiny walled-off 2×2 room not connected to the rest of the level. Each one holds a pile of gold. You will usually find one by digging through stone or by teleporting in. The engraving *"ad aerarium"* on a level marks one nearby (see [Engravings](#engravings)). A scroll of gold detection (or object detection) will spotlight the gold pile through the walls, and magic mapping reveals the closet directly.

There is no door, and no obvious way out. After about thirty turns inside, a vault guard appears and asks *"Who are you?"* You have two real answers.

**Tell the truth.** The guard makes you drop your gold, opens a temporary corridor, leads you out, and re-seals the vault behind him. You lose every coin, but you escape.

**Answer *Croesus*** (or *Kroisos* or *Creosote*). The guard takes that as the vault owner's name and politely leaves. Lawful characters lose one alignment point for lying. You keep your gold but stay sealed in alone with your treasure.

If you do not want to starve, follow the guard and leave the gold, unless you can dig or teleport out yourself. (If Croesus is dead because you killed him at Fort Ludios, the *Croesus* answer angers the guard instead; use the real-name route then.)

#### Statues {#statues}

A statue is a stone likeness of a monster, now and then a creature petrified where it stood. Most statues can be broken for any contents inside (with a pickaxe, wand of striking, or force bolt), but some are statue traps that animate the sculpted monster when struck or stepped on. For an Archeologist, the word *historic* appears in the name of a significant statue. Breaking one costs 1 alignment point.

---

### Branches and Landmarks {#branches-and-landmarks}

The main trunk of the dungeon goes straight down, but most of the rewards wait off to the side, in branches and at named landmarks roughly in the order that follows.

#### The Route {#the-route}

Explore the upper Dungeons of Doom until you have found an altar or another way to test curses. The Mines entrance appears on Dlvl 2–4, but note it and keep going unless you are ready: about XL 5, AC 5 or better, full HP, a throwing stack, and an escape item is a fair bar. Near the Oracle, take the upward branch through Sokoban for its bag of holding or amulet of reflection. Then visit Minetown, finish the Mines when you can handle the packs, return to the main dungeon for the Quest at XL 14, and continue through Medusa to the Castle.

**[Sokoban](#sokoban) or Mines first?** You usually encounter the Mines first (Dlvl 2 to 4), but the *strategic* suggestion for most beginners is Sokoban. It's a controlled puzzle crawl with mostly trivial monsters, and the prize at the top (reflection or a bag of holding) directly helps [the Mines](#the-gnomish-mines) run afterward. The Mines are a fairer fight after Sokoban: you come back with one of those prizes and a few more levels.

#### The Gnomish Mines {#the-gnomish-mines}

The entrance appears somewhere around dungeon levels 2 through 4, as a downward staircase. You'll know you're in the Mines because the walls become rough stone and the corridors get irregular, as pictured below.

```
               ··└       ·······?└┘·└─┐
                ··└      ·G···········│
                ···      ┐·····*······└
                 ··└┐    │··`········
            ┌──┐ ┐··│┌─┐┌┘········
          ┌─┘··└┐│··└┘·└┘······┌
         ┌┘·····│┌─·`·······<·┌
         │······└┘·····)······└┐
     └───┘····┌┐····)··········└─┘  └┐
┐·············││·`········@··········│
└─┐······─┐·──┴┼─┐···················└
  └──┐·   │····└─┘···┌┐h··············└
     └┐   └──┐·······│└─┐···┌┐·········│
             └──┐····└  └───┘ ─┐·│····┌┘
```

The Mines are populated primarily by gnomes and dwarves, with tougher variants (gnome lords, dwarf lords, then gnome and dwarf kings) appearing as you descend. If you're playing a gnome or dwarf, most of them will be peaceful, which makes the Mines a relatively comfortable detour. Everyone else fights through a steady stream of hostile gnomes and dwarves.

The Mines also have a notorious surprise guest: a mind flayer can spawn on any random Mines level outside Minetown, including Mine's End. *"You sense a faint wave of psychic energy"* on an unexplored Mines level is the warning. A mind flayer drains Intelligence on every successful tentacle hit. In the early game you may not have the helmet protection or ranged attack power you'll need to fight one safely. Retreat to prep, or skip the branch.

**Minetown** appears a few levels into the Mines. Usually it's a small settlement with shops and a temple. Visit after you can manage the Mines' packs, or return after Sokoban if the first trip turns ugly. The shops let you sell unwanted items for gold and buy useful gear. The temple has an altar (check the alignment) and a resident priest. If the altar matches your alignment, you've found a safe place to identify items by dropping them on it. The Minetown priest can also grant permanent AC reductions. A qualifying first donation grants 2–4 points of intrinsic protection, not just one. The price and threshold are easy to misread, so use the full table in [Donating to Priests](#donating-to-priests)).

Candles spawn often enough that you'll usually have enough by endgame, but you do need to source seven for the Candelabrum of Invocation later. **Izchak's lighting store** in Minetown is the clean answer: buy seven there. If the shop is absent (Orcish Town layout), seven are scattered on that level instead. Wax candles burn longer than tallow but either works, and mixing types is fine.

One in seven times, however, Minetown generates as **Orcish Town**: an overrun settlement with no shops, no priest, and iron bars blocking the entrances. There's still an unaligned altar, but you won't get any shopping done.

Watch out for the Minetown watch. The guards are peaceful unless you steal, attack a peaceful creature, break a door, or dig in town. Anger one and the whole watch turns on you.

**Mine's End** is the bottom of the Mines. All three Mine's End variants contain a guaranteed (not-cursed) luckstone, so you'll get one wherever you arrive. It adds 3 to your Luck and stops good Luck from wearing off; bless it and carry it for the rest of the game (see [How Luck Works](#how-luck-works)).

Finding it takes care. In most layouts the luckstone hides in a secret room, so if a maze dead-ends with no treasure in sight, search the walls (`s`, `10s`) for hidden doors rather than digging, which these levels resist. There may be several such rooms, so don't stop at the first. (One variant hides the luckstone among fakes: four [**mimics**](#a-note-on-mimics) disguised as gray stones, plus a real **cursed loadstone** that looks just like it and welds to your pack. Searching (`s`) beside a suspect stone exposes any mimic on the spot; a real stone just sits there. That leaves the luckstone and the loadstone, which a shop tells apart by price ($60 versus $1). Don't lean on the kick test here — wedged in its niche, even a real luckstone can thump like a loadstone.)

#### Sokoban {#sokoban}

The prize at the top is usually a **bag of holding**, otherwise an **amulet of reflection**. Either can settle a major equipment problem before the Mines become difficult.

The entrance staircase appears somewhere around dungeon levels 6 through 10 (one level below [the Oracle](#the-oracle)), and it goes up. Sokoban is a set of four puzzle levels where you push boulders onto holes or into place to open a path. Teleport doesn't work here, and you can't dig down off the entrance level (its floor is reinforced).

The puzzles are fixed (two variants per level, randomly chosen).

Each level has exactly one correct solution. If you push a boulder into a corner where it blocks your progress there is no way to start over. You're left with a few ways to cheat, which might or may not help: **squeeze past** the boulder (drop your stuff to fit), **dig the boulder** with a wielded pick-axe or mattock, or **fracture it** with force bolt or a wand of striking (a scroll of earth and polymorph also count). Each of these costs a point of Luck and breaks the Sokoban conduct. The walls themselves are non-diggable on every Sokoban level, and pits cannot be bypassed. Even flying or levitation will not carry you over an open pit; the air currents pull you down anyway. You can climb back out after falling.

The prize at the top is either a **bag of holding** or an **amulet of reflection**, both extremely valuable; the [Sokoban Solutions appendix](#sokoban-solutions) documents the per-variant 75/25 weighting. A cursed scroll of scare monster is placed under the prize as bait. A bag of holding lets you carry far more inventory at reduced weight. An amulet of reflection bounces ray attacks back at their casters.

The prize remains available after an infraction. The lost Luck does not clear when you finish a level; it drifts one point toward zero every 600 turns, unless an unblessed luckstone holds it there.

**Monsters behind boulders.** A monster trapped behind a boulder can't get to you, but you can still get to it: **thrown daggers or darts fly straight over a boulder**, and most attack spells (magic missile, cone of cold) pass over too. Don't clear the way with **force bolt or a wand of striking**, though; those shatter the boulder, which costs you Luck and a piece you need for the puzzle.

Every legitimate boulder-push exercises Strength. The puzzle gives you plenty of practice without any need to walk around Stressed.

For complete solutions to all eight level variants, see [Sokoban Solutions](#sokoban-solutions) in the appendices.

#### The Oracle {#the-oracle}

Somewhere in the mid-levels of the Dungeons of Doom (around levels 5 through 9), you'll find a special room containing the Oracle of Delphi, flanked by centaur statues (empty) and four fountains. Like every oracle since antiquity, she trades in riddles and takes payment up front.

She offers two services:

- **Minor consultations** are cheap (50 zorkmids) and produce fortune-cookie-style messages, drawn from the same true-rumor pool, mostly atmospheric, occasionally useful.
- **Major consultations** are expensive (500 + 50 × experience level) but pay back the gold in useful intel: hints about monsters, items, and rules.

The Oracle is peaceful and never attacks. Her room is a safe place to rest for a moment, though the fountains carry the usual risks.

Each type of consultation grants experience points the first time you buy it. If your first consultation ever is a major, you get 50–100 XP (it scales with your level). A minor first gives only 5 XP, and the major afterward gives less. Repeat consultations give nothing.

#### The Quest {#the-quest}

Sooner or later, your own people call. The Quest is a branch of the dungeon shaped for your role alone: a nemesis has seized your role's legendary artifact, and your leader summons you to prove yourself, defeat that nemesis, and bring it home. Around dungeon levels 11 through 16, a magic portal drops you onto it.

You'll know when you've reached the right level. The first time you arrive there, a faint telepathic call from your quest leader breaks through:

> *You receive a faint telepathic message .... Your help is urgently needed .... Look for a ...ic transporter. You couldn't quite make out that last message.*

You are now looking for a magic portal, which renders as a bright magenta `^` once you discover it. Like any trap, it stays hidden until you step on it (which also triggers it) or search the square.

To embark on your Quest, you will need experience level 14 and a friendly word with your quest leader on the first floor before they will let you descend. If you are prepared and worthy, your leader will send you to retrieve your role's quest artifact from a quest nemesis.

Mid-game XP is slow to earn, so the path to XL 14 usually includes eating a few [wraith corpses](#a-note-on-wraiths) (one experience level each), or a blessed potion of gain level. (On graveyard levels like the Valley of the Dead, an undead leaves a corpse only about a third as often, so lead a wraith out before killing it if you want the level-up.)

Each role has a unique Quest with unique maps, a unique nemesis, and a unique artifact reward. The Valkyrie hunts Lord Surtur for the [Orb of Fate](#orb-of-fate). A Samurai's path ends in a duel with Ashikaga Takauji over the [Tsurugi of Muramasa](#tsurugi-of-muramasa). The Wizard descends into the Dark One's stronghold for the [Eye of the Aethiopica](#eye-of-the-aethiopica). The [Artifacts](#artifacts) chapter has the full per-role list.

Most quest artifacts are worth carrying for the rest of the game. Each gives some mix of magic resistance, telepathy, warning, reflection, stealth, or luck. Check whether its protection works when carried or only when wielded or worn.

**A second important prize waits on the nemesis's square.** The **Bell of Opening** rides in the nemesis's pack and drops when you kill them. It is one of the three Invocation items, and you cannot finish the game without it: at the bottom of [Gehennom](#gehennom), on the vibrating square just above [Moloch's Sanctum](#molochs-sanctum), you ring the Bell, light the Candelabrum, and read the Book of the Dead to open the way down to the Amulet of Yendor (the full ritual is [The Heist](#the-heist)). Your quest artifact, meanwhile, lies under the nemesis's feet, placed when the level was generated. Grab both before you go; the Quest is the only place to get either.

A nemesis may have picked up an amulet of [life saving](#special-and-utility) along the way, so don't be shocked if one shrugs off a killing blow and you have to do it twice. The portal back to the main dungeon is on the first Quest level only. If you descend underprepared and have to turn back, you may have a long climb home.

The whole Quest hinges on your leader's approval. Below XL 14, or with too little alignment, you are expelled automatically and may return after fixing the problem. If you have changed alignment, the leader banishes you for good. Do not experiment with a helm of opposite alignment before the Quest.

#### The Rogue Level {#the-rogue-level}

Somewhere in the middle dungeon you'll cross a one-level historical district. *"You enter what seems to be an older, more primitive world."* The neighborhood is preserved as it was when **Rogue** was the only dungeon-crawl anyone had heard of, and a few details give the era away:

- All the wildlife is in capital letters: lowercase species hadn't been invented yet.
- Armor displays as `]`, food as `:`, amulets as `,`, and gold shares a symbol with gems (in Rogue they were the same thing).
- Doors don't close. Hinges came later.
- Tile mode switches off in favor of plain ASCII characters.
- No fountains, sinks, altars, shopkeepers, or priests, and no spellbooks, tools, or amulets in the natural item pool, all post-Rogue inventions.

Your modern tricks still work; you can engrave [Elbereth](#elbereth) here even though that was a Hack-era addition. A small anachronism.

#### Fort Ludios {#fort-ludios}

Fort Ludios is the stronghold of Croesus. It is optional and easy to miss: the portal appears between Dlvl 11 and Medusa, always inside a sealed vault, so dig in or break the door. The alarm wakes sixteen soldiers and a lieutenant. Four dragons guard the storerooms; a stone giant and four giant eels patrol the moat. Croesus waits on the throne and hits hard enough that you should shoot or zap him across the moat.

The level is non-diggable and blocks ordinary teleportation. Leave by the portal or by level teleport. The treasury holds 36,000 to 54,000 zm across sixty squares, with a land mine or spiked pit under roughly a third of them. The corner towers hold diamonds, emeralds, rubies, and amethysts; soldiers carry rations and serviceable weapons. None of it is required to win. The gold is the reason to come, and it buys protection from priests.

#### Medusa's Island {#medusas-island}

Medusa's level sits near the bottom of the Dungeons of Doom, around level 25. You'll know it by the large body of water and the statues scattered around (those used to be adventurers).

> *Arien Malec collected crossing strategies from RGRN posters back in the early 2000s, with input from Pat Rankin, Geoduck, Topi Linkala, and others. That is a condensed version of his guide.*

The level stacks three challenges on one island: **crossing the water** that surrounds it, the **giant eels** (electric eels on one layout) lurking in that water, and **Medusa herself**, whose gaze turns you to stone. Each gets its own section below. If you carried the amulet of reflection out of Sokoban, the third problem is already solved.

There is a downward staircase on the island itself that leads toward [the Castle](#the-castle). The level has four possible layouts, so don't rely on memorizing a single map.

**The Perseus statue.** One of the statues on the island is named **Perseus**, the mythological hero who killed Medusa with a mirrored shield. Break it with force bolt, striking, or a pick-axe to recover a (cursed) **shield of reflection** (75% in three of the four layouts; 25% in the fourth), a blessed +2 **scimitar** (50%), **levitation boots** (25% in three layouts; 75% in the fourth, the same layout that is stingy with the shield), and a **sack** to put them in (50%). The shield is cursed, so plan to uncurse it before swapping it in. The other statues on the level are intentionally empty.

**Surviving Medusa's gaze.** You need one of the following before entering her level:

- **Reflection** (amulet, shield, or silver dragon scale mail). Her gaze bounces back and stones her instead. That is the cleanest solution and the one most players use.
- **Blindfold or towel.** Wear it before entering line of sight. You'll need [telepathy](#senses-and-perception) or monster detection to navigate while blind. Works perfectly but makes the level harder to explore.
- **A mirror.** Apply it at an awake Medusa anywhere along a clear straight line. Every layout generates her asleep, so wake her from safety first.
- **One-shot kill.** A wand of death or finger of death can kill her before she gets a turn. Medusa resists stoning, so a cockatrice corpse does not work. Whatever you do, **don't eat her corpse**: she's the Gorgon, and the cadaver instantly petrifies whoever sits down for dinner.

**Crossing the water.** The island is surrounded by deep water. Your options, from safest to most desperate:

- **Levitation** (ring, boots, potion, or spell). The easiest way to cross. Eels can still grab you from adjacent water (see [Drowning](#drowning) in [Ways to Die Instantly](#ways-to-die-instantly)).
- **Water walking boots.** You walk on the surface. Eels can still grab you in adjacent water.
- **Wand of cold.** Zap the water to freeze a path of ice. Every other step may make you slip and lose two turns, and fire can melt the path again, but it gets you across.
- **Scroll of earth.** Creates boulders that fall into the water, making a boulder bridge. Slow but works if you have nothing else.
- **Polymorph** into a flying or swimming creature. Risky if you lack [polymorph control](#special-and-utility).
- **Jumping boots or the knight's jump.** Can leap across narrow water gaps, but requires careful positioning.

**Surviving the eels.** The water contains giant eels (and on one of the four layout variants, a kraken) that can grab and drown you. Critical rules:

- An **oilskin cloak** or **greased armor** makes the eel slip off on the grab attempt. Greasing wears off, so it's not fully reliable; oilskin doesn't.
- **[Magical breathing](#movement-and-spatial-behavior)** (amulet or polymorph) prevents the drown even after being grabbed.
- **Kill eels at range** whenever possible. Wands, spells, and thrown weapons all work. Don't melee eels in the water.
- Levitation and water walking do NOT protect against being grabbed by an eel in adjacent water. The drown check uses the *eel's* tile, not yours. Only oilskin/grease, magical breathing, or killing the eel first are reliable.

#### The Castle {#castle-overview}

The Castle is the grand finale of the sunlit dungeon and the doorway to everything worse below: a stone fortress ringed by a moat, with a drawbridge for its only entrance. Inside waits an army of defenders: soldiers in the barracks, dragons guarding the storerooms, and a court of high-letter monsters in the throne room. The reward that makes the siege worth it sits in a locked chest in one of the four corner towers, the **wand of wishing**, the most valuable find in the game.

The Castle also serves as the gateway to [Gehennom](#gehennom). For how to open the drawbridge and what to do once you're inside, see [The Castle](#the-castle) in Part Five.

---

### Traps and Hazards {#traps-and-hazards}

One trapdoor can separate you from your pet, your stash, and the stair you meant to use. Traps are invisible until you step on one, detect it with `s`, or reveal it by another means. Once discovered, they show up as `^`. Each search of an adjacent square has an independent chance of revealing a trap, but the chance is well under 100%, so search repeatedly in suspicious areas. Pets avoid only traps you have already found; watching them reveals nothing new.

A useful pattern to recognize: an unexplained corpse sitting alone on a room floor is often covering the trap that killed it. The corpse's `%` glyph draws on top of the `^`, so the trap stays hidden even after you would otherwise have seen it. The corpse may also be sitting on dropped gear from its owner, which makes the square worth investigating. Search the adjacent squares to reveal the trap, then `#untrap` to try to disarm it instead of stepping on.

Here are the traps you'll encounter, roughly grouped by how much you'll regret finding them:

#### Nuisance Traps {#nuisance-traps}

| Trap            | Effect                                              |
| --------------- | --------------------------------------------------- |
| Arrow trap      | Fires an arrow at you (modest damage)               |
| Dart trap       | Fires a dart, may be poisoned                       |
| Squeaky board   | Makes noise, wakes nearby monsters                  |
| Rust trap       | Splashes water: rusts iron worn armor, soaks cloak/suit/shirt, douses lit lamps |

Annoying but rarely lethal. The silver lining: arrow and dart traps produce free ammunition, and you can trigger them on purpose to stock up.

#### Movement Traps {#movement-traps}

| Trap             | Effect                                                     |
| ---------------- | ---------------------------------------------------------- |
| Pit              | You fall in, take minor damage, can climb out              |
| Spiked pit       | Like a pit, but with spikes (more damage, possible poison) |
| Trapdoor         | Drops you down a dungeon shaft. Usually one level, but with a 25%-per-level chance to keep falling, so you can land several deeper |
| Teleport trap    | Teleports you randomly on the level                        |
| Level teleporter | Teleports you to a random dungeon level                    |
| Hole             | Like a trapdoor, but you can see it                        |
| Magic portal     | Transports to a different branch (branch entrances)        |

Trapdoors and level teleporters are the most disruptive: one wrong step and you're separated from your pet, your stash, and your carefully explored map. But with [teleport control](#movement-and-spatial-behavior) (from an item or intrinsic), teleport traps become free transportation. **Levitation or flying** both make you immune to pits, holes, and trapdoors entirely. Except in [Sokoban](#sokoban), where the puzzle levels disable the skip and you fall in regardless.

#### Dangerous Traps {#dangerous-traps}

| Trap              | Effect                                      | Blocked or softened by |
| ----------------- | ------------------------------------------- | ---------------------- |
| Land mine         | Explosion and item damage                   | Levitation or flight   |
| Bear trap         | Holds you in place                          | Iron footwear prevents leg damage |
| Sleeping gas trap | Leaves you helpless for several turns      | Sleep resistance       |
| Fire trap         | Burns you and exposed inventory             | Fire resistance; bag the scrolls and potions |
| Magic trap        | Random magic, often blindness plus monsters | No general defense     |
| Anti-magic field  | Drains energy; may also damage you          | Positive iron footwear can absorb the drain |
| Polymorph trap    | Changes you into a random creature          | Magic resistance, Unchanging, or iron footwear |
| Rolling boulder   | Sends a boulder down a fixed track          | Stay out of the track  |

Fire traps threaten your pack, not just your health. The fire itself hurts, but the danger is what happens to your inventory: scrolls burn, potions shatter, and that stack of twenty scrolls of identify you've been hoarding is suddenly ash. [Fire resistance](#damage-resistances) saves your skin but *not* your belongings. Items inside a *sack* or *oilskin sack* survive the trap; the sack itself absorbs the burn. [Gehennom](#gehennom) is fire-trap country, so keep your consumables bagged.

With [polymorph control](#special-and-utility), a polymorph trap lets you choose a new form. Without it, the trap chooses for you, possibly turning you into a newt that cannot use any of your equipment. **[Magic resistance](#damage-resistances) and the [Unchanging](#special-and-utility) intrinsic both block the polymorph entirely.**

If you do get caught and polymorphed into a handless form, your gear drops to the floor on the spot. Don't panic and don't move: random polymorphs wear off in a few hundred turns, and your kit is at the square you're standing on. Defend the square if you can, pray if a monster has you in a corner, and pick everything up the moment you change back. (If you happen to be carrying a wand of polymorph or know the spell, zapping or casting it on yourself lets you reroll the form, but only if your current form can use a wand or cast.)

Sleeping gas is murder in monster-rich areas. You can't fight, you can't run, you can't even wake up on purpose. Monsters line up to hit you like it's a buffet. [Sleep resistance](#damage-resistances) from elven blood, orange dragon armor, or the right corpse prevents it.

Magic traps fire one of twenty random effects. A bit under half the time you get the dangerous one: a flash of light briefly blinds you and summons a few hostile monsters. One roll engulfs you in fire. The rest are harmless or even helpful: several are pure flavor, one toggles your invisibility, one uncurses worn and wielded items, and one tames the nearby monsters and raises your Charisma by a point. That last is why some players camp a known magic trap for the Charisma and cheaper shop prices, but it comes up only about one roll in twenty, and the fire and monster summons make the wait risky.

Bear traps clamp on for several turns. Try to step *diagonally* off the square; the diagonal escape is about five times faster than orthogonal. A wand of opening or spell of knock frees you on the spot.

Magic resistance blocks a teleport trap. If you want to use one, stand on it after it has been discovered and press `Ctrl+T`; the command does nothing from another square.

**Anti-magic fields hit harder if you're magic-resistant.** The trap drains spell energy, and having *magic resistance* also triggers an "anti-magic implosion" that costs you HP. The damage is d4 base, plus another d4 if you have half-physical or half-spell damage, plus d4 for wielding [Magicbane](#magicbane), plus d4 for carrying any one magic-resistance artifact (only one counts; the check breaks on first match). At worst that's 4d4 damage, quartered (rounded up) if you can pass through walls. The defense is finding the trap first (search) and stepping around it. A wand of cancellation aimed at a magical trap *does* remove the trap, but it triggers a 20 + 3d6 damage blast at the trap's square in the process; not a silent defuse.

Iron footwear (iron shoes or kicking boots) absorbs a surprising amount of trap punishment in 5.0: no leg damage from a bear trap, no spikes from a spiked pit, no polymorph from a polymorph trap (your shoes shift instead), and a positively- enchanted pair eats an anti-magic field's drain by losing one enchantment instead. Useful protection to have on if you haven't found anything better yet.

#### Searching and Detection {#searching-and-detection}

The best defense against traps is finding them before they find you:

- **Search (`s`)** repeatedly. Each search has an independent chance to reveal each adjacent trap, and Luck improves the odds. (The artifact/lenses search bonus only speeds up secret-door and secret-corridor discovery, not trap finding.)
- **Wand of secret door detection** reveals everything hidden in a roughly circular area around you (radius about eight, blocked by line of sight): secret doors, secret corridors, traps, trapped chests, and concealed monsters. It's not directional.
- **Crystal ball** can reveal traps across the entire level
- **Flying and levitation** make you immune to most floor traps (you still trigger webs and magic, teleport, level-teleport, polymorph, and anti-magic traps)
- **A scroll of gold detection read while confused** turns the gold-reveal into a *trap* reveal: every trap on the level lights up at once. Confused gold detection is the cheapest pre-Gehennom trap survey.

A good time to search is when the dungeon has already hinted that something is wrong: a stray corpse in the middle of an otherwise empty room, a scatter of arrows or darts on the floor, or a themed room whose gimmick is hidden hazards.

#### Finding Secret Doors {#finding-secret-doors}

The Dungeons of Doom were designed by architects who believed that every room should have one emergency exit that requires ten minutes of tapping on walls to locate. Secret doors and corridors are the game's passive-aggressive way of saying "you haven't explored *thoroughly* enough."

**When to search for secrets:**

- **Dead ends** that feel too convenient. If a corridor just stops, and you haven't found what you came for, there's probably a door in the surrounding walls
- **Suspiciously empty rooms** with no obvious exit. The exit exists; it's just been cunningly disguised as a wall
- **After exhausting all visible options.** When you've explored everything reachable and still haven't found the downstairs, it's time to stop wandering and start wall-tapping

**The systematic approach:**

Type `20s` to search twenty times in one spot. For new characters with average Luck, you need 15-22 searches to reliably reveal a secret. Searching once and moving on is announcing your intention to remain lost.

Move three squares along the wall and repeat. Each search reaches one square in every direction, so a stride of three gives complete wall coverage with no gaps and no wasted re-searching. The pattern looks tedious on paper because it *is* tedious, but tedium is cheaper than being trapped on Dlvl 1 forever.

A Ranger or Archeologist is spared much of that: both have automatic searching from the start (as does anyone wielding Excalibur), so they check every adjacent square automatically with each step and often turn up secrets just by walking the walls. A stubborn door may still want you to stop and search a few times.

**Items that help:**

- **Ring of searching** auto-searches every turn while it's worn
- **[Excalibur](#excalibur-artifact)** (or any artifact with the searching aura), wielded, adds its enchantment to your search bonus (a freshly-dipped +0 Excalibur adds nothing)
- **Lenses** worn (and you not blind) add +2 to the search bonus
- **Wand of secret door detection** instantly reveals nearby secrets in a radius
- **Blessed scroll of magic mapping** shows every secret door on the level (only the blessed version)

If the down stair is already known, take it. Wall-tapping is for a level whose exit or special room is still missing, not a ritual to perform on every floor.

#### Iron Bars {#iron-bars}

Iron bars look like a barrier but aren't solid: light passes through and tiny creatures (grid bugs, bats, rats) can squeeze between, though anything kitten-sized or larger is blocked. Pick-axes bounce off them, wands of digging fizzle, and striking or force bolt pass through harmlessly. What gets through is acid: a yellow dragon's breath, or a potion of acid shattered against the bars. The potion is the handy one. Wield it and force-fight (`F`) into the bars, and the splash dissolves them away. And if you happen to be chained to a heavy iron ball, you can wield the ball and batter the bars apart by hand, though it takes about twenty-five swings.

Usually, dig around them. Bars sit in a niche cut into a room wall, so digging diagonally past them or through the back wall reaches the contents without touching the bars. What's usually behind: a scroll of teleportation.

---

### Feelings and Sounds {#feelings-and-sounds}

The Mazes hide warnings inside bits of atmosphere. Learn the four emergency messages first; use the later tables when a stranger one appears.

(Caveat: being **deaf**, **swallowed**, or **underwater** silences the ambient-sound channel completely. Permadeaf conducts in particular lose every level-flavor cue. The feeling-from-corpse messages still come through.)

#### Emergencies {#emergencies}

| Message | What it means |
|---------|---------------|
| *"You feel feverish."* | Lycanthropy infection from a were-monster. *Quaff* holy water, eat wolfsbane, or `#pray`. |
| *"You are slowing down."* | You're turning to stone. Immediately eat a lizard corpse, drink acid, or `#pray`. |
| *"You are turning into a green slime."* | Green-slime contagion. Burn it off (read a fire scroll, cast fireball on yourself, or self-zap a wand of fire), or `#pray`. |
| *"You feel deathly sick."* | Terminal illness (Pestilence, Demogorgon). Quaff extra healing, eat eucalyptus, or `#pray`. |

#### Level Ambience {#level-ambience}

| Message                                          | What it means                                                            |
|--------------------------------------------------|--------------------------------------------------------------------------|
| *"You have a sad feeling for a moment, then it passes."* | Your pet just died offscreen.                                        |
| *"You hear bubbling water."*<br>*"You hear water falling on coins."* | Fountain on this level.                                          |
| *"You hear someone cursing shoplifters."*<br>*"You hear the chime of a cash register."* | Shop on this level.                                  |
| *"You hear someone counting gold coins."*<br>*"You hear the footsteps of a guard on patrol."*<br>*"You hear someone searching."* | Vault on this level. The "counting" message means there's still gold inside; "searching" means the vault is already empty. |
| *"You hear a wolf howling at the moon."* (or jackal) | A werecreature is somewhere on this level.                               |
| *"You hear crashing rock."*            | A tunneler (dwarf, rock mole, or umber hulk) just dug through stone.                    |
| *"You hear rumbling nearby."* (or *in the distance*) | A rolling boulder trap just fired offscreen. *"You hear a rumbling stop abruptly."* means a rolling boulder hit a teleport trap. |
| *"You hear a chugging sound."*         | A monster just drank a potion (usually healing themselves).                            |
| *"You hear a nearby zap."*             | A monster just zapped a wand at something offscreen.                                   |
| *"You hear a strange wind."*           | Oracle on this level.                                                                  |
| *"You hear a slurping sound."*         | A gelatinous cube just ate items off the floor on this level.                          |
| *"You hear a crunching sound."*        | A rust monster, rock mole, or other metallivore just ate something metallic.           |
| *"You hear a bugle playing reveille!"* | A soldier just woke nearby soldiers; expect a fight.                                   |

#### Intrinsics and Corpse Effects {#intrinsics-and-corpse-effects}

| Message | What it means |
|---------|---------------|
| *"You feel healthy."*                  | Intrinsic poison resistance from a corpse.                                             |
| *"You feel a momentary chill."*        | Intrinsic fire resistance from a corpse.                                               |
| *"You feel full of hot air."*          | Intrinsic cold resistance from a corpse.                                               |
| *"Your health currently feels amplified!"* | Intrinsic shock resistance from a corpse.                                          |
| *"You feel wide awake."*               | Intrinsic sleep resistance from a corpse.                                              |
| *"You feel very firm."*                | Intrinsic disintegration resistance from a corpse.                                     |
| *"You feel a strange mental acuity."*  | Intrinsic telepathy from a corpse.                                                     |
| *"You seem faster."*                   | Intrinsic speed from a quantum mechanic corpse. (If you already had speed, you instead "seem slower". Quantum corpses toggle.) |
| *"You feel a mild buzz."*              | A newt corpse restored 1–3 mana.                                                       |
| *"You see an image of someone stalking you. But it disappears."* (blind: *"You feel very self-conscious. Then it passes."*) | A fountain just granted you permanent *see invisible*. A good draught. |

#### Identification and Status Changes {#identification-and-status-changes}

| Message | What it means |
|---------|---------------|
| *"A feeling of loss comes over you."*  | You dipped something in a fountain and hit the uncurse outcome, but the item wasn't cursed. Nothing happened; despite the wording, you lost nothing. |
| *"You have a feeling of loss."*         | You read a scroll of charging but picked an item that can't be charged (only wands, rings, and certain tools take charges). The scroll is wasted. |
| *"You sense a lack of food nearby."*   | Scroll of food detection, no food on level.                                            |
| *"You feel materially poor."*          | Scroll of gold detection, no gold on level.                                            |
| *"You feel like someone is helping you."* | Scroll of remove curse; worn/wielded cursed items uncursed.                         |
| *"Your hands begin to glow red."*      | Scroll or spell of confuse monster. Your next melee strike will confuse the target. (Purple if you read it while already confused.) |
| *"You feel guilty."*                   | Blessed or confused scroll of punishment. The ball and chain don't attach, but the scroll is now identified. |
| *"Who was that Maud person anyway?"*<br>*"As your mind turns inward…"* | Scroll of amnesia. Some of your memorized spells are gone; a blessed scroll spares them. |
| *"You have an uneasy feeling…"*        | Cursed potion of enlightenment, or cursed potion of gain level in a no-rise spot. Identifies the potion; no other effect (a Wisdom exercise penalty for enlightenment). |
| *"You feel like a hypocrite."*         | You just attacked a monster while standing on Elbereth. The engraving is gone, and your alignment took a hit (flat −5 if your record is comfortably positive, otherwise −1 to −5). |
| *"You feel that monsters are aware of your presence."* | A monster just cast aggravate-monster, waking the level's monsters and sending them after you. |
| *"You feel that monsters have difficulty pinpointing your location."* | A cloak of displacement just turned on. *"…no longer have difficulty…"* means it just turned off. |
| *"You hear the rumble of distant thunder…"* | You killed your own pet (or tame creature): −15 alignment and −1 Luck. Prayer fails until your alignment is positive again. |
| *"You feel as if you need some help."* | A nearby monster just cast curse-items on you: something in your inventory was randomly cursed. BUC-test gear before relying on it. |
| *"You feel the presence of evil."* | A hostile water demon was just summoned from a fountain but isn't visible to you yet. It's coming. |
| *"You hear someone summoning something, and…"* (and *"…summoning <something>"*) | A priestly spell summoned insects or snakes offscreen. Mage summoning says *"Monsters appear from nowhere!"* |
| *"You feel mildly hot."* / *"You feel mildly chilly."* | A fire (or cold) attack hit you and your intrinsic resistance absorbed it. Useful confirmation that you actually have the resistance you think you do. |
| *"You feel rather itchy under your mummy wrapping."* | You just read a scroll, zapped a wand, or cast a spell of invisibility, but the mummy-wrapping cloak blocked it. You're not invisible — and you've just confirmed the scroll/wand is invisibility. |
| *"You feel less paranoid."* | Secret-door detection cleared an old `I` marker from the map; it says nothing about where the monster went. |
| *"You feel agile! You must have been working on your reflexes!"* (and Str / Wis / Con variants) | A stat just went up from the hidden exercise system. See [Exercising Your Stats](#exercising-your-stats) for what counts as exercise. The mirror message *"You haven't been working on reflexes lately"* fires after a streak of abuse instead. |
| *"You move very quietly."*             | Ring of stealth or elven cloak. (Elven boots give *"You walk very quietly"* instead.)  |
| *"Wow! This makes you feel good!"*     | Uncursed potion of restore ability; one drained attribute restored. |
| *"Wow! This makes you feel great!"*    | Blessed potion of restore ability, restoring all attributes, with no remaining troubles; or a magic-fountain hit. |

---

## Part Three: Survival {#part-three-survival}

When the game pauses on a dangerous turn, begin with [Saving Yourself from Imminent Death](#delayed-deaths). For ordinary fights, the short rule is simpler: enter at full HP, decide whether you are winning after the first exchange, and know which stair or door you will use if not. [Elbereth](#elbereth) belongs in the same mental kit as prayer and a healing potion; use it before the monster is adjacent.

### Saving Yourself from Imminent Death {#delayed-deaths}

Not every fatal threat kills instantly. The message tells you how long you have and what to reach for.

| Threat | Warning | Time | Reliable answers |
|---|---|---:|---|
| Stoning | *You are slowing down* | 5 turns; helpless after 3 | Lizard or acidic corpse, acid, prayer |
| Sliming | *You are turning into a green slime* | About 10 turns | Fire, cure sickness, suitable polymorph, prayer outside Gehennom |
| Food poisoning | *You feel deathly sick* | 10–19 turns | Non-cursed extra/full healing, blessed healing, eucalyptus, unicorn horn, prayer |
| Lava, no fire resistance | You fall into the lava | None | Prevent with levitation or flight |
| Lava, fire resistant | You sink into the lava | About a dozen turns | Levitate, teleport, step out, prayer |
| Eel or kraken wrap | The monster swings itself around you | The next landed wrap can drown | Magical breathing, kill or teleport the monster |
| Strangulation | *It constricts your throat!* | 6 turns | Remove or uncurse the amulet, pray |

**Sliming.** Being hit by a green slime or eating its glob starts a roughly ten-turn transformation. **Cures:** burn the slime off with fire (a wand of fire zapped at yourself, a scroll of fire read at self, a fire trap, a red dragon's breath); polymorph into a flame-bodied or slime-immune form; or cast the spell of *cure sickness*. An **amulet of unchanging** blocks the contagion entirely and even aborts a transformation already underway. Cancelling the green slime prevents new infections but does nothing to a timer already running. Prayer would cure it, but green slime lives in Gehennom where prayer fails, so don't plan on it.

**Illness (food poisoning).** Eating a rotten or badly aged corpse gives you food poisoning, which kills in 10–19 turns ("You feel deathly sick."). **Cures:** non-cursed extra or full healing, blessed healing, a unicorn horn, prayer, or a eucalyptus leaf. Poison resistance does not protect against food poisoning. That is *sickness resistance*, a separate intrinsic.

**Pestilence's terminal illness** is the harder cousin: vomiting won't clear it, and the timer is Constitution-dependent (~20+Con turns). The cures that *do* work: unicorn horn, prayer, eucalyptus leaf.

**Sinking in lava.** Without fire resistance, lava kills on contact and burns your pack first. With fire resistance, you sink instead and have about a dozen turns to leave. Levitate, teleport, step out, or pray. Fire resistance stops the burn, not the sinking.

**Drowning (being held).** When grabbed by an eel or kraken in water, the next wrap that lands can drown you. The drown check uses the eel's tile, so levitation, water walking, and encumbrance status are irrelevant once the grab lands. **Cures:** magical breathing (amulet or spell), kill or teleport the eel before it pulls you under, or avoid water entirely. See [Drowning](#drowning) above for the full picture.

**Strangulation.** An amulet of strangulation kills in six turns. Remove it immediately if it is not cursed. Otherwise uncurse it with remove curse or holy water, or pray.

### Engravings and Elbereth {#engravings}

You can write on the dungeon floor with the engrave command (`E`). Engravings serve a few practical purposes: writing **Elbereth** (covered next), running the engrave-test on an unidentified wand (covered in the wand chapter), or just leaving a note for whoever finds your bones file. The mechanics described here apply to *any* engraving, not just Elbereth.

**Methods, speed, and durability.** The tool you write with determines how quickly you can finish, how hard the engraving is to erase, and whether your stylus suffers wear.

| Method                    | Speed         | Durability     | Notes                             |
| ------------------------- | ------------- | -------------- | --------------------------------- |
| Finger (dust)             | Instant       | Fragile        | Smudges when monsters step on it  |
| Uncursed athame           | Instant       | Semi-permanent | Doesn't dull (cursed athame does) |
| Other edged weapon        | Several turns | Semi-permanent | Interruptible. Dulls to −3; a +0 blade stops at "Elberet," while +1 or better can finish the word. |
| Hard gem or diamond       | Several turns | Semi-permanent | Interruptible                     |
| Wand of digging           | Instant       | Semi-permanent | Good middle ground                |
| Wand of fire or lightning | Instant       | Permanent      | Burns the word into the floor     |

The three durability tiers correspond to how the text resists ordinary erosion:

- **Fragile (dust).** A monster stepping on the square smudges one character. In dust, an Elbereth lasts as long as the floor stays clear.
- **Semi-permanent (scratched into the floor).** Each monster step has a one-in-26 chance to chip a character. It lasts much longer than dust, but not forever.
- **Permanent (burned in).** The engraving doesn't erode at all under normal conditions. Only ice tiles or magical attacks can damage it.

**Engraving by hand can be interrupted.** Anything written by hand at multi-turn speed (non-athame edged weapon, gem) takes one turn per letter. If something breaks the engraving mid-word (an attack, a monster wandering into view, a passing earthquake), the partial word you leave behind does nothing useful. Instant methods (any wand, finger-in-dust, or an uncursed athame) finish in one action.

**Impairment and errors.** If you are blind, confused, stunned, or hallucinating, you have a chance of misspelling each letter, and that scrambling applies to *every* engraving method, including burns from a wand of fire. (Only the dust/blood surface-garble roll is skipped for harder methods.) A misspelled message has no special power; that matters most for Elbereth.

**Overwriting and combining.** Appending to an existing engraving is possible, but for named-word magic like Elbereth the engraving must read *exactly* that word and nothing else, so the appended text usually destroys the ward. To refresh, overwrite the square or pick a fresh one.

**Two engravings worth recognizing.** Most engravings you find are random flavor (graffiti, "elbereth" left by someone else, and the like). Two specific messages, though, are *trap markers* placed by the dungeon. *"Ad aerarium"* (Latin: *to the treasury*) marks a secret closet containing either a **vault teleporter** or a **level teleporter**. The vault teleporter is a one-shot trap that drops you into Croesus's 2×2 gold vault on the same level; pick up the gold and escape ahead of the vault guard. The level teleporter sends you to a random dungeon level, often unwelcome without teleport control. *"Vlad was here"* marks a secret closet containing a **trap door**. Both messages are easy to miss in the message log. Investigate them when you see them, and be ready for what is on the other side.

#### Elbereth {#elbereth}

##### Where the word comes from {#where-the-word-comes-from}

*Elbereth* is Sindarin for "Star-Queen," one of the Elvish names of **Varda Elentári**, highest of the Valar in J.R.R. Tolkien's *Silmarillion* and the one who set the stars in the sky. In *The Lord of the Rings* the Elves invoke her name for protection against evil: Frodo cries *"O Elbereth! Gilthoniel!"* on Weathertop and the Witch-king recoils, and Sam invokes her in Shelob's lair to make the Phial of Galadriel burn brighter. NetHack lifts the conceit directly: writing Varda's name on the dungeon floor is an appeal to a higher power for safe ground.

> *The mechanics below were inspired by Kate Nepveu's Elbereth FAQ. Kate also maintained steelypips.org, the long-running archive that preserved decades of community spoilers.*

##### The ward {#the-ward}

Writing the word **Elbereth** on the floor creates a protective ward. Most monsters will not melee-attack you while you stand on an Elbereth square; they mill around, frustrated, instead. The ward applies whether you wrote it or found it already engraved, and the underlying engraving method (dust, scratched, burned) does not affect the strength of the protection, only how long the engraving will survive.

##### Rules of the ward {#rules-of-the-ward}

- **It only works while you stand on it.** Step off and the protection ends. Stepping back on resumes it.
- **It must be the exact word.** "Elbereth," nothing more, nothing less. Misspellings (from impairment) and combined text don't count.
- **Some monsters ignore it.** Anything represented by `@` (humans, elves, player-like creatures), the Riders on the Astral Plane, Angels, minotaurs, unique/named monsters (quest nemeses, Vlad, the Wizard), shopkeepers, guards, and any blind monster will all walk right through. So will cornered monsters with no retreat path: a creature with nowhere to flee will fight rather than stand helplessly.
- **Elbereth doesn't work in Gehennom, on the Elemental Planes, or on the Astral Plane.** Below [the Castle](#the-castle), you're on your own.

##### Defiling the name of Elbereth (important) {#defiling-the-name-of-elbereth-important}

If you attack a monster while standing on Elbereth (whether by melee, thrown weapon, or wand zap), and that monster *would* have feared the ward, or is peaceful, the engraving is **deleted instantly, in full, regardless of how it was made.** Even a burned-permanent Elbereth disappears in one swing. You take an **alignment hit** ("You feel like a hypocrite") and see the message *"The engraving beneath you fades."* The hit is a flat −5 if your alignment record is comfortably positive (above +5); otherwise it is a random −1 to −5.

The durability table doesn't show that. "Permanent" and "semi-permanent" describe resistance to *passive* wear (monster footsteps, erosion). Your own hostile action wipes the word regardless of tier. So Elbereth is strictly **defensive**. Use it to heal, drink a potion, read a scroll, swap gear, regroup. Any attack from on top defiles it, so step off when you mean to fight back.

##### Practical use {#practical-use}

In an emergency, write Elbereth in the dust with your finger. It costs no item but does consume your action, so write before contact. Most monsters will back off and let you act. Once the immediate danger passes, you can either step off the dust ward to keep it for next time (it survives until a monster steps on the square), or upgrade to something more durable.

For a permanent safe spot, useful for stashing items, resting at a fixed retreat point, or anchoring a corridor fight, burn the word with a wand of fire or lightning. One turn, no interruption risk, and no ordinary wear. Blindness, confusion, stun, or hallucination can still scramble the spelling. A semi-permanent engraving (athame, weapon, gem, wand of digging) is the middle ground: durable, but the slow methods can be interrupted mid-word.

While levitating, you can't engrave with your finger or your weapon. A wand of fire, lightning, cold, or digging still works from above. You'll see "you gesture toward the floor below you" first, but the burn lands anyway.

**Never engrave on an altar or a grave.** On an altar, writing anything — Elbereth included — engraves *nothing* and angers your god: you lose Wisdom and alignment on your own altar, or Luck on any other. So the reflex to scrawl Elbereth when a monster corners you at an altar backfires; step off first. Engraving an undisturbed grave with a weapon or wand disturbs it and summons a ghoul (a bare finger only smudges it). And a fountain square can't be engraved at all.

A **scroll of scare monster** dropped on the floor is Elbereth's stronger cousin. Stand on it and most monsters keep their distance, and it beats the ward on three counts: it still works in Gehennom and on the Astral Plane where Elbereth is dead, it repels minotaurs and blind monsters that walk through Elbereth, and you can fight from it freely, since it is not an engraving and so never defiles or costs you the hypocrite alignment hit. It doesn't erode, and its square stays off-limits even when you step away. Its weakness is pickup: taking it may destroy it (cursed scrolls crumble on the first pickup, uncursed on the second), so leave it where you want the safe spot. The Castle wand chest is parked on top of a cursed one for exactly that reason. You can also spot one in a shop before buying: stand on an unidentified scroll, and if your pet backs away, it's a scare monster scroll, identified without a risky pickup.

### The Art of Combat {#the-art-of-combat}

The most important combat technique in the Mazes is knowing when *not* to fight. The second most important is making sure you hit really, really hard when you do.

#### To-Hit Calculation {#to-hit-calculation}

Every swing of your weapon is a d20 roll, modified by everything that matters in a sword fight:

- Your experience level (higher means you've seen things)
- Your weapon's enchantment (a +7 [Excalibur](#excalibur-artifact) hits *noticeably* better)
- Your Luck (the universe takes sides; the to-hit contribution caps around ±5 even though Luck itself ranges further)
- Your Strength and Dexterity bonuses (muscles plus agility, both matter)
- The monster's AC (the lower their AC, the harder they are to tag)

Add 1, your XL, Strength and Dexterity bonuses, about a third of your Luck, weapon enchantment and skill, then the target's AC. Your attack hits when the d20 rolls *under* that total. A negative target AC lowers the number, so enchantment and weapon skill matter more as you descend.

#### Damage {#damage}

Base damage depends on your weapon and whether the target is small or large. Most weapons favor one shape over the other: short blades for kobolds, two-handers for ogres. Added to base:

- Weapon enchantment (+1 per point)
- Strength bonus (up to +6 before a two-handed multiplier)
- Weapon skill bonus (depends on skill level)
- Special bonuses (silver damage, artifact bonuses, etc.)
- **Two-handed weapons** get a 50% bonus to the strength damage component, which makes giving up the shield slot worthwhile

At 18/100 Strength, that +6 becomes +9 on a two-handed sword. Its d12+9 averages about five more damage per swing than a long sword's d8+6, before enchantment and skill.

#### AC and Defense {#ac-and-defense}

Your AC determines how likely monsters are to hit *you*. AC starts at 10 (no armor) and goes down as you put pieces on; lower is better. The journey from "I die to gnomes" to "nothing can touch me" looks like this:

| Stage         | Typical AC | Protection level        |
| ------------- | ---------- | ----------------------- |
| Starting out  | 8 to 10    | Wearing a good attitude |
| Early dungeon | 2 to 5     | Basic armor equipped    |
| Mid-game      | -5 to 0    | Enchanted armor + cloak |
| Endgame       | -20 to -10 | Walking tank            |

Negative AC is rolled afresh on each attack, and monster level still adds to the chance to hit. At AC -20 an ogre connects about one swing in four, while a level-15 monster lands roughly two in three. Many late-game threats use special attacks (breath weapons, spells, gaze attacks) that ignore AC entirely. You can be wearing impenetrable armor and a disenchanter will still ruin your day.

**Seven slots, four paths down.** You can wear seven pieces at once: body suit, cloak, helmet, gloves, boots, shield, and shirt. Filling every slot with ordinary armor gets you from AC 10 to roughly AC 0. From there, the paths into negative AC are enchantment, swapping ordinary pieces for magic ones (many magic pieces carry an intrinsic on top of their AC bonus), and extrinsic Protection bought from any priest. See [the Armory](#armor-and-ac) for picks by slot.

**Test the dangerous slots first.** Drop boots and gloves on an altar, or see whether your pet is reluctant to cross them. At AC 6 or worse, with no test available, wear ordinary suits, helms, shields, and cloaks; being stuck in one is usually safer than staying unarmored. See [A Practical Identification Strategy](#a-practical-identification-strategy) for the full procedure.

**Changing armor takes turns and layers in order.** You wear armor with `W` and take it off with `T`. Shirt goes on first, body suit second, cloak last, so reaching an inner piece means shedding what's over it. A metal body suit takes **5 turns** to don or remove; leather 3, mithril 1; helmets and gloves take 1 turn each, boots 2; cloaks, shields, and the shirt are instant. A full Hawaiian-shirt-to-cloak swap can mean six exposed turns, and you take all incoming attacks during them, so save armor changes for a clear room or a corridor at your back.

#### Speed {#speed}

**Divide before you engage.** A useful number in a fight is the monster's speed divided by your effective speed: that ratio is how many times it acts for every action you take. A base-12 hero against a speed-18 centaur sees a ratio of 1.5, so the centaur lands three hits for every two of yours and wins a melee duel. Slip on speed boots (effective ~20) and the ratio flips to 0.9, and now it's your fight. Against an air elemental at speed 36, the ratio is 3.0 unboosted and 1.8 even with boots, still hopeless on foot. Ranged or skip. A ratio above 1.0 is a fight you lose to attrition unless you can drop the monster in your opening burst; a ratio below 1.0 is kiteable, so back into a corridor and strike between its steps. If you can't drop a faster monster, don't run in the open, since it only catches up and keeps hitting. Reduce how many can reach you instead: a doorway, a closed door, or the stairs.

**Under the hood.** Your base speed is **12**, and so is the cost of any action. Each creature builds up a private counter; when nobody can afford to move, every counter advances by that creature's **speed**, and that repeats until someone can act. A faster creature's counter simply fills more often, which is why the ratio above holds. Monster speeds come from the bestiary: zombies at 6, humans at 12, centaurs at 18, vampire bats at 20, air elementals at 36.

**Speed grants extra moves probabilistically.** **Fast** (from certain corpses) adds a +12 bonus to roughly one allocation in three, averaging effective speed ~16. **Very Fast** (speed boots, potion of speed, haste self) adds the same bonus to two allocations in three, averaging ~20. The roll is per-allocation, not sustained, so any single tense round may or may not give you the extra; the average is reliable over many actions. Very Fast doesn't stack with Fast; the better state wins. Speed boots are the easiest source: put them on once and stop spending potions or spell energy on speed.

**Encumbrance shaves the allocation directly.** It reduces the points your allocation gives you, after the intrinsic bonus is applied:

| Status        | Base points | Effective speed |
| ------------- | ----------- | --------------- |
| Unencumbered  | 12          | full            |
| Burdened      | 9           | −25%            |
| Stressed      | 6           | −50%            |
| Strained      | 3           | −75%            |
| Overtaxed     | 2           | −83%            |

A Stressed character with intrinsic Fast still moves slower than a baseline Unencumbered one. At Stressed, a speed-6 zombie keeps pace; at Strained it acts twice per move. Get to Unencumbered, ideally with a bag of holding.

**Reference: common monster speeds.**

| Speed | Tier                 | Examples                                          |
| ----- | -------------------- | ------------------------------------------------- |
| 0–1   | crawling             | molds, most fungi                                 |
| 6     | slow                 | zombies, gnomes, kobolds, dwarves                 |
| 12    | normal (your base)   | humans, elves, foocubi                            |
| 18    | fast                 | centaurs, ki-rin, soldier ants, fire ants         |
| 20    | very fast            | ravens, vampire bats                              |
| 22    | very fast            | bats, giant bats, steam and fire vortices         |
| 24    | extreme              | queen bees                                        |
| 36    | untouchable on foot  | air elementals                                    |

Speed boots earn their slot against the fast monsters. Against a speed-6 zombie your ratio only creeps from 0.5 to 0.3, but against a speed-18 centaur it drops from 1.5 to 0.9, the difference between losing a chase and winning a duel.

#### Two-Weapon Combat {#two-weapon-combat}

Some roles can fight with a weapon in each hand, which looks impressive and gives a second swing per turn. Each strike takes a flat to-hit and damage penalty by skill rank (−9/−7/−5/−3 to hit, −3/−1/0/+1 damage from Unskilled through Expert), and the loadout must be melee on both sides. No shield, no launcher, no thrown projectiles. Only **Rogue** and **Samurai** reach Expert; Valkyrie and Knight cap at Skilled; Barbarian at Basic. Rangers, Healers, Monks, and Wizards cannot use the style.

**When the second swing pays off.** The extra hit is worth its to-hit penalty only when your hit chance is already high and your damage is healthy. At Expert (−3/+1) with high enchantment against a moderate-AC target, a Samurai's katana + wakizashi out-damages the katana alone on most rounds. At Skilled (−5/0) the math is roughly a wash. Below Skilled the penalty usually swallows the benefit, so a Knight or Barbarian is better off with one good weapon. The two-handed bonus (3/2 Strength damage on bimanual weapons) is a strong alternative for any role without a two-weapon skill.

**Setting it up.** There is no separate command for the off-hand; the second weapon lives in a "secondary" slot you fill with the swap command. Wield the off-hand weapon with `w`, press `x` to push it into the secondary slot, then `w` your main weapon, and finally press `X` (capital, the two-weapon toggle) to fight with both. Press `X` again to go back to one weapon. The off-hand has to be a one-handed melee weapon. If it is cursed when you try to start, it slips to the floor.

#### Ranged Combat {#ranged-combat}

Hitting at distance is one of the dungeon's great advantages. Every turn a monster spends closing the gap is a turn you spend whittling its HP from a safer square. Rangers and Samurai live by their bows, but any role can set a quiver and reach for `f`. The toolkit:

**Fire, throw, and swap commands.**

- **`t`** is **throw**: pick an item from inventory and a direction.
- **`f`** is **fire**: throws whatever is in your **quiver** without re-prompting. Once set, repeated `f` is the fastest ranged attack you have.
- **`Q`** sets the **quiver**: pick the default thrown stack (arrows for a Ranger, daggers for a Rogue, shuriken or arrows for a Samurai). Set it once at the start of the run.
- **`x`** **swaps** primary and secondary weapons. Wield your bow, set a melee weapon as secondary, and `x` toggles between them. The common Ranger pattern is: shoot at range, swap to a dagger when the monster closes, swap back to the bow once it's dead.

**Launchers and ammo.** Bows (bow, elven bow, orcish bow, yumi) shoot arrows; crossbows shoot bolts (harder per shot but slower, and they need Str 18 for full multishot, or Str 16 for gnomes); slings shoot rocks or gems. Polearms strike at distance 2 with `a` (apply) instead. You can also throw daggers, darts, shuriken, javelins, and boomerangs without a launcher.

**Lining up the shot.** Projectiles travel in a straight line and can't bend around a corner or shoot diagonally through a closed doorway. If a monster is across a zigzag corridor, advance until the line opens. The shot stops at the first solid target along the path: if your pet is between you and the monster, you'll hit the pet. The same rules apply to wand zaps and spell rays.

**Multishot.** With the right skill and role, a single `f` launches multiple projectiles per turn. Rangers get +1 on any non-dagger ranged weapon; Rogues get +1 on thrown daggers; Samurai get +1 with a yumi and ya; Skilled adds +1 and Expert +2; the Longbow of Diana adds +1 while wielded. At Expert with a matching role, the game rolls from one projectile up to the maximum. An Expert Ranger averages about two and a half shots a turn.

**Conserving ammo.** Each arrow or bolt has a per-hit break chance: roughly 67% for a +0 stack, 25% for a +2 stack. Train multishot on a cheap found stack; save your +2s for fights that need them. A Ranger who walks out of the upper dungeon with thirty unbroken +2 arrows can keep shooting through the long fights.

#### Fighting Smart {#fighting-smart}

The dungeon rewards cowardice, cunning, and property damage. Make the fight unfair before it starts.

##### Position before contact {#position-before-contact}

**Use corridors.** Monsters can only approach one at a time in a corridor. Do not fight a crowd in an open room when a chokepoint is in reach.

**Pick the square before contact.** When you see a monster crossing an open room, walk toward the corridor or doorway you want to fight from, not toward the monster. Arrive at the chokepoint a turn before they do, and they meet you on your terms.

**Step around a corner.** An approaching monster spends an action rounding it. A monster that has just stepped next to you does not swing in that same action, so you attack first.

**Compare speeds before committing.** Their speed divided by yours gives the number of actions they take per action of yours (see the [Speed](#speed) subsection). Ratio above 1.0: you lose attrition fights, so commit fast, zap, or run before contact. Ratio below 1.0: every step you take is a free move.

**Keep an exit at your back.** Keep at least one square open toward your fallback: a staircase, a known corridor, an Elbereth square. Stairs are the best of these. Most monsters stay behind, though soldiers, watchmen, vampires, trolls, wraiths, and imps may follow when adjacent. On the return trip, expect the rest of the pack to be waiting at the stair.

**Doors and diagonals.** You cannot move diagonally through a doorway, so approach and leave orthogonally. **Closing a door** (`c` + direction) stops any monster that lacks the wits or hands to open it, most animals included. Close one behind you and a pursuing beast is stuck on the far side while you rest and heal. It also blocks your pet, handy when you want to slip away for a turn.

**Jump when you have a source.** With the jumping spell, jumping boots, or a Knight's innate jump, `#jump` crosses several squares in one turn. Use it to escape a faster monster, reach a corridor or an Elbereth square without walking through attacks of opportunity, clear most known traps (not fire traps or level portals, and not in Sokoban), burn off Satiated status before eating an intrinsic-granting corpse, or cross Medusa's island gap.

##### During the fight {#during-the-fight}

**Trade hits only when the math works.** Estimate how many rounds you need to drop the monster and how many it needs to drop you. If your number is smaller, trade. If theirs is smaller, retreat now: a turn spent backing up is cheaper than a death.

**Soften before they reach you.** A fire ant is scary in melee. A fire ant that you have already zapped three times is just a warm corpse. See [Ranged Combat](#ranged-combat) for the toolkit.

**Stay in your pet's path.** A pet next to the monster draws some of its attacks and adds its own. Step so the pet can reach the fight rather than blocking its approach.

**A sleeping room is not safe.** Each monster that sees you has a one-in-seven chance to wake every turn; dogs and human monsters wake at once. Stealth prevents the random wake-up. A hit wakes the target, whose growl may wake other sleeping monsters within roughly four squares for a gnome, farther for larger creatures. A packed room becomes a simultaneous brawl on swing two. Pull the pack one at a time by *backing away* into a corridor first (so they wake strung out in a line), or write [Elbereth](#elbereth) so they cluster around the ward instead of swarming. Then step off to engage individually; attacking from on top of the engraving defiles it.

##### When the fight goes badly {#when-the-fight-goes-badly}

**Know when to run.** The Mazes have no medals for bravery, only for survival. Retreat heals you, too: a level-1 hero out-heals a normal monster (~1 HP per 9 turns vs 1 per 20), and by mid-game you regenerate 5× faster than them, so backing off a slow non-regenerating threat (mimic, ogre, leocrotta) is essentially free HP. The exceptions are trolls, vampires, and the Wizard of Yendor: they regenerate every turn, sometimes faster than you. Don't try to outwait those. If the fight is past saving, use a scroll of teleportation, a wand of teleportation, or just run. Dead adventurers do not get second chances (unless wearing an amulet of [life saving](#special-and-utility)).

**Use conflict.** A ring of conflict makes monsters fight each other. Walk into a room full of enemies, put on the ring, and watch from the doorway as they destroy each other. Two 5.0 caveats: a monster has to *see* you for conflict to affect it (so blind or out-of-sight monsters keep their wits), and the chance scales with your **Charisma**. High Cha makes it noticeably more reliable. Low Cha makes it flaky.

**Elbereth for emergencies.** Write it, stand on it, recover. The monsters will mill around you looking confused and angry, which is exactly how you want them. Step off Elbereth before resuming the fight. Any attack from on top defiles the engraving and costs you alignment ("you feel like a hypocrite"). Elbereth is a rest stop, not a firing position.

##### Ranged and Frightened Monsters {#ranged-and-frightened-monsters}

**Ranged attackers retreat.** Archers and spellcasters back away when you close to melee range. A centaur archer may retreat and keep shooting. Cut off their retreat with corners and narrow passages, bring ranged options of your own, or use a wand of teleportation to skip past the dance. Spellcasters use the same room to keep casting while you struggle to close.

**Cornered scared monsters fight.** Elbereth and the engrave-and-regenerate tactic still work, but only when the monster has somewhere to go. A frightened monster that has nowhere to flee will turn and fight rather than stand helplessly while you recover. If you have carved [Elbereth](#elbereth) in a corridor and then backed a monster into a dead end, expect it to turn and fight. Keep an exit behind the monster.

**Watch your alignment around peacefuls.** Knights and Samurai take a special alignment hit for attacking the helpless, fleeing, or peaceful (a caitiff penalty for Knights, a giri-breaking penalty for Samurai). The Quest entrance check requires alignment record at least 20 *and* XL 14. These one-point penalties can be repaired by killing hostile monsters, but may delay your [Quest](#the-quest).

---

### Things That Will Kill You {#things-that-will-kill-you}

Only about **0.4% of dungeon expeditions end in ascension.**

**The early dungeon is deadly.** The monsters that kill the most characters all live on the upper levels: jackals, dwarves, soldier ants, gnome lords, sewer rats, giant bats, [small mimics](#a-note-on-mimics), gnomes, foxes, water moccasins. None of them are intrinsically dangerous to a prepared character. They get you because you haven't built HP, AC, or resistances yet, and they outnumber you. Spend the early turns clearing levels, finding altars, and getting BUC information before pushing deeper.

**On pacing.** Rest after fights and take a stair at full HP, or at least above 90%. Maximum HP predicts survival better than trying to keep XL even with Dlvl. Explore what you can use, but once the down stair is known, do not spend food on empty rooms or fruitless searches. Descend with a ranged attack and a way back out, such as a scroll or wand of teleportation. Most stair deaths begin with someone arriving on a fresh level already hurt and with no escape ready.

#### Common Combat Deaths {#common-combat-deaths}

Beyond the top ten, certain enemy categories kill more beginners than their depth or appearance would suggest. They come in packs, move faster than you, or have one attack you cannot afford to take.

**The [Gnomish Mines](#the-gnomish-mines) are a top killer.** The danger is the layout: Mines rooms are large open caves where four or five armed opponents have plenty of room to swarm around you. Use ranged attacks, or look for natural pinch points where the cave walls narrow. Dwarves hit harder than gnomes, and gnomish wizards (the first spellcasting enemy you meet) blast you with psychic bolts and can heal and hasten themselves. Lords and kings appear deeper, with differently colored `G` and `h` glyphs. Scout the first Mines level, but come back with about XL 5, AC 5 or better, full HP, a throwing stack, and one escape item. Sleep resistance helps, but is not a reason to wait forever.

**Sleep without resistance is a near-instadeath.** A homunculus (`i`) bite, a sleeping-gas trap, or later an orange dragon or Nazgul breath puts you to sleep for several turns. If you are alone in a corridor it costs you a couple of rounds. If you are surrounded by anything else, the surrounding monsters hit you freely while you cannot move. Sleep resistance comes from being an elf at XL 4, orange dragon armor, and several corpses. Neither the Wizard's cloak of magic resistance nor the Ranger's cloak of displacement supplies it.

**Bats and other speedsters** (`B`). Bats and giant bats clock in at speed 22, nearly twice your starting 12. They get two attacks for every one of yours, and a 1d4 bite at double rate chews through low HP fast. Ravens and vampire bats are speed 20 with two attacks each (and the vampire bat's second bite drains Strength). Fight from a doorway so they cannot circle you, or kill them at range. Centaurs (speed 18 to 20) and vortices raise the same problem later on.

**Ants and other pack travelers** (`a`). Soldier ants are speed 18 with two attacks (bite plus a Strength-draining sting) and travel in groups. Killer bees, giant ants, and fire ants are the same shape of problem. Treat any chittering or buzzing on an unexplored level as a reason to back up and find a chokepoint before the pack closes.

**Quadrupeds** (`q`). Rothes are three-attack pack hunters at sluggish speed 9: a single one is easy to outrun, but three in a room is several real fights stacked together. Mumakil are solo two-attack bruisers (4d12 butt plus 2d6 bite) that hit harder than anything else in the upper dungeon. Both wander mid-level rooms.

**Golems** (`'`). Most are slow but several hit disproportionately hard. The rope golem grapples on a hugs attack and pins you in place for adjacent friends to chew on. Clay and stone golems deliver 3d10 and 3d8 in a single claw. The iron golem is the heaviest threat here: level 18, 4d10 weapon plus a 4d6 poison-gas breath that drains Strength, and resistant to fire, cold, electricity, sleep, and poison. Most golems leave no corpse, so they cannot be eaten for intrinsics. Kill them quickly and at range when you can.

**Water demons from fountains** (`&`). Quaffing a fountain summons a water demon roughly 1 quaff in 30. The wish roll happens as the demon appears: a grateful one grants it immediately and vanishes; otherwise the level-8 demon attacks. Wish odds also drop with depth, so casual quaffing pays worse the deeper you go. Don't quaff from fountains until you have [magic resistance](#damage-resistances), reflection, or a clear path of retreat.

**Floating eyes** (`e`). Hit one in melee and you're paralyzed for 3 to 210 turns, about 100 on average; whatever passes by during the nap kills you. Kill at range, then eat the corpse for [telepathy](#senses-and-perception).

**Minotaurs** (`H`, in [the Castle](#the-castle) and maze levels of [Gehennom](#gehennom)). Three attacks (two 3d10 claws and a 2d8 head-butt) averaging about 42 damage per turn. The hardest hitter short of the Riders themselves (the three near-unkillable horsemen who guard the endgame). Use a wand of sleep, a thrown potion of paralysis (with [free action](#combat-and-defense)), or just dig down before they reach you. Minotaurs ignore Elbereth.

**Major demons gate in more major demons.** Once per attack round, a major demon has a one-in-16 chance to summon another outside Gehennom and a one-in-ten chance inside it.

#### Deadly Mistakes {#deadly-mistakes}

Routine mistakes kill more adventurers than exotic instadeaths. The list below is a field guide, not a server ranking.

**Eating mistakes.** Old corpses cause food poisoning, poisonous corpses ([deadly poison](#deadly-poison)) drop you fast, and eating while Satiated risks [choking](#choking). Watch your nutrition before committing to a heavy corpse, and pray immediately if you ate something you shouldn't have.

**Reading unidentified scrolls in a shop.** A confused or cursed scroll of teleportation level-teles you out of the shop with the unpaid merchandise still in your pack, turning the shopkeeper hostile when you return. A scroll of fire destroys shop goods you are liable for. Save the price-ID session for outside.

**Mount slips and riding accidents.** Getting on a steed rolls against your experience level plus the steed's tameness; a failure costs 10 to 14 HP. The dangerous cases are a cursed or greased saddle (the slip is essentially guaranteed and the fall hurts). The Confused or Fumbling or Glib cases have worse odds, and a fresh pet at XL 2 throws you 9 times in 20; a barely tame one does so about 17 times in 20.

**Pet kills.** Kittens, little dogs, housecats, and ponies all appear on the death list, almost always because the player put on a ring of conflict and forgot to take it off. Remove the ring before walking back to your pet.

**Boiling and shattering potions.** A potion dropped on Gehennom's hot floor breaks about half the time, harmlessly. Fire reaching the potions in your pack is what can boil them and kill you. Bagging your potion and scroll stash is wise: a fire trap or a red dragon's flames incinerate loose scrolls and potions, and a white dragon's frost shatters loose potions.

**Wands in the wrong hands.** Monsters use attack wands, and a ray can ricochet off a wall back into your face. Reflection and magic resistance matter long before Gehennom. Engrave-test an unknown wand before aiming it at anything alive.

**Killed by a grid bug.** The weakest monster in the game gets the last hit on someone who walked away from a real fight at 2 HP, or who decided to read a scroll on the turn one was adjacent. Don't read scrolls under threat.

**Killed by kicking.** Kicking sinks summons a [black pudding](#a-note-on-puddings), a foocubus, or worse. Kicking a door merely gives a harmless *Whammm!* when it fails, but a wall hurts. Trapped chests are a separate danger. Kick only when you can spare the consequence.

**Wrath of a god.** You prayed when your god wasn't willing. See [Divine Relations](#divine-relations) for the prayer cooldown and what counts as "trouble" worth a prayer.

**Scroll of genocide while confused.** Confused genocide removes your role's own species from the world (Valkyrie, Wizard, Samurai). You become the genocide. Don't read scrolls under confusion unless you already know what they are.

**Scroll of earth on yourself.** Buried under a pile of boulders you summoned on your own head.

Most early deaths are ordinary fights allowed to run one exchange too long.

#### A Note on Nymphs {#a-note-on-nymphs}

The `n` class (wood, water, mountain) doesn't want to kill you. She wants your inventory. In the early game a nymph pulls worn armor right off your body, undoing the AC you've assembled, and each successful claw hit also lifts a random item from your pack. Then she **teleports away** to a random spot on the same level. Your bag of holding, your amulet of reflection, a freshly-wished cloak of magic resistance: gone, across the map, often into a room you haven't explored. Few monsters set an early character back this hard, and it takes only one hit.

**Only theft.** Both claws use the same attack: each takes either an item from your pack or something you are wearing. She costs you gear, not hit points.

**Defenses.** The rule is never to let a nymph reach melee range. Kill at range (darts, force bolt, a wand of anything). [Engrave **Elbereth**](#elbereth): nymphs respect it. Or drop your most irreplaceable items on the floor before approaching. Whatever's not in your pack can't be stolen. Since she does no HP damage, a character stripped to nothing, no worn gear, empty pack, can even fight a nymph bare-handed in perfect safety. It won't stop her blinking away between hits, but she has nothing left to take.

**Already robbed?** She keeps what she took until she dies, so you have to hunt her down and kill her: the loot drops from her corpse. A robbed nymph stays on the same level unless she later falls through a trapdoor or wanders onto a staircase, which carries your item off with her.

**Never engage a nymph while carrying the Amulet of Yendor** during the Ascension Run. If she steals it, you abandon your climb to hunt her down and kill her, and the mysterious force does not pause while you search.

#### A Note on Mimics {#a-note-on-mimics}

Mimics are far tougher than their depth suggests: their claws hit hard enough to kill a low-level character outright, and small mimics rank in the top ten causes of death. The reprieve is that **all mimics are slow** (speed 3, less than half your base speed). If you uncloak one and don't like the matchup, walk away and come back stronger; it isn't going anywhere.

You meet them mostly in **shops**: an average shop has one or two in the aisles masquerading as merchandise, with more as you descend.

**The visual tell.** A mimic appearing as a generic "strange object" renders on the map as `]`, a mirror of `[`, the armor class. No real item ever displays as `]`, so a `]` anywhere is always a mimic.

**How to uncover one safely.** Searching an adjacent square (`s`) reveals a concealed mimic. Throw a cheap item at the suspected square; the mimic uncloaks and the item lands harmlessly. A stethoscope applied to the square also uncloaks. Telepathy, ESP, astral vision, and a wand of secret door detection see through the disguise and show the mimic as `m`. Your pet won't step onto a mimic.

**Recognizing a large mimic before it grabs you.** Once an `m` is uncloaked you see its color: small mimics are brown, large mimics red, giant mimics magenta. Depth also helps: large and giant mimics don't generally appear until mid-dungeon, so almost every mimic in the upper levels is a small one with a 3d4 claw.

**Sticking.** A **small mimic hits hard but never holds you** (you can always step away). A **large or giant mimic glues you in place** on a successful claw hit: you can't move, take stairs, or drop through a hole. And once stuck you have only about a **1-in-13 chance each turn** to pull free while it's awake. Kill it (it's slow), teleport out, or put it to sleep first. The best protection is to avoid the hold: since it only lands from melee, **searching (`s`) as you move through a shop** reveals a large or giant mimic before you step next to it, and one you've spotted can never grab you.

**Eating the corpse** turns you into a pile of gold (or, while hallucinating, an orange) for 20 / 40 / 50 turns depending on size. Anything that tries to pick "you" up snaps the spell.

#### A Note on Werecreatures {#a-note-on-werecreatures}

A bite from a **werejackal, wererat, or werewolf** can infect you with **lycanthropy**, and the infection, not the bite, is the danger. You then transform into the beast at random, roughly every 60 to 80 turns and more often at night. Each shift forces you out of your armor; a werewolf destroys your body armor and shirt but drops the cloak intact, then leaves you in a weak beast body. You revert on your own, but a mid-fight transform leaves you stripped at the worst possible moment.

When the werecreature *summons help*, write Elbereth at once. The summoned animals respect it, but the werecreature's human `@` form walks through, so keep an exit as well.

**Curing it.** Quaff **holy water**, `#pray`, or eat a **sprig of wolfsbane**. Summon a pet army first, though: a few turns in beast form spent on `#monster` call up wolves (or rats or jackals) that **stay tame after you cure**, a free pack you can later grow into something fiercer at a polymorph trap.

A potion of polymorph or a polytrap, while you're infected, turns you into your *were-form* rather than a random monster, and doesn't cure you.

#### A Note on Puddings {#a-note-on-puddings}

Puddings are the dungeon's signature self-multiplying monsters, and their leftover globs are also among the best food you can find. The class lives in the mid-dungeon and Gehennom. **Brown and black puddings split when you hit them with an iron or metal weapon**: one becomes two, two becomes four, and your long-sword grinding session turns into a swarm. **Black pudding additionally corrodes your wielded weapon** on its passive return-hit, so each round of splitting is also a step toward your blade rusting away.

**Defenses.** Melee with a **silver or wooden weapon** (silver dagger, elven dagger, club, quarterstaff). These don't trigger the split. Mithril also bypasses the check. Fire kills without splitting; brown and black puddings resist cold. Most attack spells work too.

**Gray ooze** doesn't split, but it rusts armor on a hit; don't engage in your starting iron suit if you can avoid it.

**Eat the globs.** A pudding leaves a **glob** rather than a corpse, and the globs are some of the best food in the game. Unlike corpses, globs can't be sacrificed at an altar, so puddings can't be farmed for offerings. The globs remain edible for about 500 turns and are packed with resistances. A brown-pudding glob grants **cold, shock, and poison resistance** over repeated eats; a gray-ooze glob grants **fire, cold, and poison resistance**; a black-pudding glob also grants **cold, shock, and poison resistance**. Brown pudding and gray ooze are *vegetarian*-safe; black pudding is not. Globs of the same color merge into one meal with one resistance roll, so eat them one at a time off the floor before they combine. The full intrinsic table is in [Useful Corpse Effects](#useful-corpse-effects).

#### A Note on Dragons {#a-note-on-dragons}

Dragons deserve a full briefing. Each color has its own breath weapon, resistance, scale mail property, and degree of desire to kill you specifically. The summary:

**Gray** dragon scale mail grants magic resistance, the most important defensive property in the game. Gray dragons are the ones you most want to kill for their skin, and also the ones most likely to make you regret trying.

**Silver** dragon scale mail grants reflection, turning away most ray attacks.

**Black** dragons disintegrate everything you're wearing along with you, including your magic resistance. Carry reflection or eat enough black dragons to grow [disintegration resistance](#damage-resistances) before going where they live. Their scale mail grants disintegration resistance plus [drain resistance](#damage-resistances), a rare extrinsic source of the latter.

**Yellow** dragon scale mail gives more than its label. Listed power is acid resistance, but it also grants **stoning resistance**, the same outright immunity acid blob corpses give. If you find a yellow dragon and don't already have stone-res, killing it is worth the trip. Yellow dragons are no rarer than the other colors.

**Orange** dragon scale mail grants sleep resistance *and* free action (the ring's effect), bundled into one slot.

**White** dragon scale mail grants cold resistance *and* slow digestion, which slows hunger on long descents.

**Red** dragon scale mail grants fire resistance *and* infravision, the same effect as a ring of infravision or being elven.

**Green** dragon scale mail grants poison resistance *and* sickness resistance, covering both poison and illness attacks.

**Blue** dragon scale mail grants shock resistance *and* intrinsic **speed**, same tier as speed boots. (Wearing both at once doesn't make you faster; either alone reaches Very Fast.) That combination makes blue an excellent general-purpose choice.

**Gold** dragons breathe fire. Their scale mail has no elemental resistance but is permanently lit (radius 4 blessed, 3 uncursed, 2 cursed), so it can replace torches and oil. It also confers hallucination resistance.

All scale mails are dragonhide, body-slot, and +9 AC worn. Dragonhide resists rust, corrosion, and fire, but not disenchantment. The choice of which color to chase is usually whichever dragon's territory you can reach safely; about one in three adult-dragon kills drops a set of scales, which you can wear directly or convert to scale mail by reading a non-cursed scroll of enchant armor while wearing them.

#### A Note on Trolls {#a-note-on-trolls}

The `T` class doesn't stay dead. After you kill a troll, its corpse sits on the floor for a few hidden turns and then stands back up at full HP, fresh and angry. About three troll corpses in four get back up within fifty turns.

**Stopping the revival.** Eat the corpse, tin it, feed it to a pet, or kick it into lava. Teleport only moves it elsewhere on the same level, and striking does not destroy it.

**Trolls drop their gear when they die.** A revived troll re-collects what it was carrying, so a revive-and-recollect cycle leaves piles of mixed troll-gear and dead-troll bodies on the same square. Pick up the gear before they wake up. The loot is yours either way.

**Class members.** Plain troll, ice troll, rock troll, water troll, and the late-game Olog-hai. All revive, and the corpse behaves the same way regardless of variant. The Olog-hai is the variant to fear, a three-attack hitter at level 13.

#### A Note on Wraiths {#a-note-on-wraiths}

The `W` class has a touch attack that **drains an experience level**, one of the few permanent character setbacks in the game. You lose maximum HP, energy, and the most recent skill slot, but not attribute points. A potion of restore ability returns lost levels. The wraith can land the touch again if you let it, so plan the kill from across the room.

**The corpse gives you a level.** The touch is melee-range only, so engage at distance or from inside a corridor where you control the spacing. A wraith corpse rots at the ordinary rate; eat it while it is fresh and the room is safe.

**Farming wraiths.** Mid-to-late-game players hunt wraiths in the upper Quest and throughout Gehennom for experience levels. A *cursed* scroll of genocide naming "wraith" reverse-genocides four to six fresh wraiths at your feet, a ready-made banquet if you can drop each one in the turn it arrives. The classic setup is to stand on stairs (so you can escape if it goes wrong), drop a stack of cursed scrolls, and graze. Some ascending heroes credit a wraith binge for the experience levels that carried them through Gehennom.

#### A Note on Seduction {#seduction}

The **amorous demon** (`&`, gray) appears as a **succubus** to male heroes and an **incubus** to female ones. A same-sex foocubus just claws at you and never starts the seduction. The encounter is a Cha+Int gamble: five bad outcomes vs. five good ones, plus a payment phase. Handled badly it can drain a level, an attribute, and 6–15 HP; handled well it grants a level, an attribute, full HP, and extra max Pw.

**Mechanics.** The demon must be adjacent and not on cooldown. It strips off your worn armor one piece at a time (cloak, suit, boots, gloves, shield, helm, shirt). The items are unequipped to your inventory, not taken or dropped on the floor; the strip only costs you the slot for the rest of the encounter. You get a yes/no prompt before each piece comes off with probability Cha/20 (so Cha 18 prompts about 9 times in 10; Cha 10 about half the time). **If you're still wearing a body armor or cloak when the strip ends, the encounter ends right there** and the demon walks away. A hard-to-remove suit is the simplest defense.

If you do get to the act, the outcome rolls against your combined Cha+Int (capped at 32). At the cap the bad-outcome chance is about 6%; at Cha+Int = 20 it's about 40%; at 10 it's nearly 70%. Check your stats before you accept.

| Bad outcome (low Cha+Int)         | Good outcome (high Cha+Int) |
|-----------------------------------|------------------------------|
| Energy drained (Pw → 0, −1d10 max)| +1d5 max Pw, refilled        |
| −1 Constitution                   | +1 Constitution              |
| −1 Wisdom                         | +1 Wisdom                    |
| Lose 1 XP level (drain res blocks)| Gain 1 XP level              |
| 6–15 HP damage                    | HP restored to max           |

The demon then charges 500+ zorkmids (high Cha can refuse; peaceful demons charge 1/5). Being asleep or otherwise unresponsive defers the attempt entirely.

**Strategic note.** At high Cha+Int the encounter is net-positive, and the armor-removal step strips *cursed* worn pieces too, an amorous demon can be the cheapest curse-removal in the dungeon. Some players keep one alive to farm XP and attributes. Don't try this at experience level 1, though: the level-drain outcome is fatal.

#### A Note on Light Bursts {#light-bursts}

**Yellow lights** (`y`, level 3) and **black lights** (`y`, level 5) attack by exploding the moment you're adjacent. Yellow lights **blind you** for 10d20 turns (a *blessed* potion of healing or any extra/full healing cures, or a unicorn horn); black lights **hallucinate you** for 10d12 turns (unicorn horn cures, or wait). Both lights die in the explosion; the blindness or hallucination is what endangers you. **Defenses:** kill them at range with wands, thrown daggers, or breath weapons. *Warning* detects them through their invisibility; *telepathy* does not (mindless).

---

### Saving and Bones {#saving-and-bones}

A single NetHack run can span multiple play sessions. Two mechanisms govern what carries across that gap: **saves**, which preserve your game between sessions, and **bones files**, which preserve a dead adventurer's level for a future hero to stumble into.

**Saving.** Press `S` and confirm to save and quit. To resume, start NetHack again with the same character name; the game loads your save and **deletes the save file in the process**. There is no reloading after a death. Copying the save file outside the game to retry one is called **save scumming**, and is cheating.

NetHack does offer an honest opt-out for learning: launch with the `-X` command-line flag (or type `#exploremode` mid-game) to enter **explore mode**. Death turns optional (a fatal blow asks "Die?", and you may decline), your save files persist so you can reload them, and the `#terrain` command reveals the whole level's map. Explore mode disables scoring and tags your end-of-game record as a "discover game" so it doesn't compete with real runs.

**Bones levels.** When a hero dies on certain levels — most ordinary Dungeons-of-Doom levels at Dlvl 4 or deeper, plus Minetown and Quest filler levels (but *not* Sokoban, Mines' End, the Castle, any level of Vlad's Tower, or the planes) — the game saves the level as a **bones file**. A future game has a flat 1-in-3 chance of loading that bones file in place of generating that level from scratch (the odds don't climb with depth; it's leaving bones behind that grows likelier deeper down). The overview records *"Final resting place for..."*. The entry message *"This place looks familiar..."* appears only when the bones came from one of your own former characters.

The bones level keeps its layout, traps, and items, with several adjustments:

- The dead hero leaves behind a *named* remnant — usually a **ghost**, but a **vampire** if killed by a vampire, a **wraith** if killed by one, a **mummy** for a mummy kill, a **green slime** for a sliming death, or a **statue** if the hero was petrified by a cockatrice. The hero's corpse stays where it fell.
- Every non-artifact item directly in the hero's inventory has an **80% chance of being cursed**. Contents of containers are untouched. Pet test or altar test anything before wearing or wielding it.
- Artifacts revert to their base items, and any *quest* artifact is stripped entirely.
- The Amulet of Yendor and the three Invocation items, if the former hero carried them, are swapped with cursed mundane doubles — a "cheap plastic imitation" amulet, a blank spellbook, a partly-used wax candle, an ordinary bell.
- Unique monsters that *should* be on the level (the Wizard, Medusa, Vlad, your quest leader and nemesis) are removed; any statues of unique monsters are silently swapped for doppelgangers in their guise.

**Bones-level dangers.** The 80% curse rate is the obvious one, but the subtler danger is that bones-level *monsters* can be far above the level's normal difficulty. Whatever killed the previous adventurer is usually still there, and often far too strong for the depth. Treat any above-depth monster on a bones level as a reason to retreat, not engage: if you aren't ready for it, leave and come back when you are.

**Opting out.** Set `OPTIONS=bones=false` in your rcfile if you want a bones-free run. That blocks both *creating* bones (your own death won't generate a file) and *loading* bones (you'll never inherit a level). The **Bonesless** conduct requires it.

---

### Ways to Die Instantly {#ways-to-die-instantly}

Some things in the Mazes kill in one move no matter how many hit points you have. Players call them instadeaths. Nearly every one gives a warning a turn or two ahead if you know what to look for.

> *The catalog of instadeaths below was inspired by Trevor Powell's Instadeath Spoiler, which drew on Dylan O'Donnell's RGRN files. Trevor defined an instadeath as "a single move death which does not involve the player's hit points dropping to zero," and that taxonomy has been the standard reference ever since.*

#### Attack Wands {#attack-wands}

Being hit by a powerful wand can mean instant death. A wand of death or finger of death kills an unprotected character outright, and ray wands of cold, fire, lightning, or magic missile can roll lethal damage too.

**Defense:** Reflection bounces rays; magic resistance blocks death and magic-missile rays. The first time most monsters zap a beam wand (death, sleep, fire, cold, lightning, magic missile) at you, the shot misses. If you can see the monster, the wand identifies itself in the same moment, so you know what was aimed at you and have a turn to react before the next zap connects. Monsters native to the Castle, Ludios, the Quest, Gehennom, Vlad's Tower, and the Planes get no warning miss.

#### Choking {#choking}

If you push past Satiated and keep eating, you can choke and die. The game prints "You're having a hard time getting all of it down" as a warning; if you have eating-confirmations turned on it'll also prompt you. Past a hard nutrition threshold only a one-in-20 escape, or being Breathless, keeps the meal from killing you instantly.

**The other path to choking is the amulet of strangulation.** Worn, it puts a short countdown on your throat and kills you when it runs out. The amulet generates cursed 90% of the time, so you usually can't just take it off: pray, or uncurse it with holy water or remove curse. [Magic resistance](#damage-resistances) doesn't help. Polymorphing into a Breathless form *does* save you.

**Defense:** Don't eat above Satiated. Be paranoid about unidentified amulets.

#### Starvation {#starvation}

That isn't technically instant, but it feels like it. If your nutrition drops to zero, you faint. If you don't eat something while fainted, you die. In the early game before you've established a food supply, starvation still needs an immediate answer.

**Defenses:** Eat corpses promptly. Pray when your god is willing and you are Weak or Fainting (prayer cures hunger). Carry food rations, tripe rations, or lembas wafers.

**Famine**, one of the three Riders in the endgame, will kill you quickly through starvation by draining 40–80 nutrition per hit, with no extrinsic to block it. Enter the Astral Plane Satiated and carry a stack of food rations through the fight, or you will be Faint soon after Famine hits.

#### Deadly Poison {#deadly-poison}

A handful of monsters (pit vipers, killer bees, cobras, some spiders) have a poison-damage branch that can deliver 10 to 30 extra HP of damage on top of the normal hit. At full HP you usually survive; at low HP it can outright kill you. The "extra-damage" roll fires about 1 in 240 per qualifying hit. Eating any Rider corpse (Death, Pestilence, *or* Famine) is instantly fatal regardless of HP.

**Defenses:** [Poison resistance](#damage-resistances) makes you immune. Most characters can get that early by eating enough appropriate corpses. It's one of the first intrinsics worth acquiring.

#### Brainlessness {#brainlessness}

Mind flayers drain Intelligence with their tentacle attacks. If your Intelligence drops to your racial minimum (3 for humans), the next drain kills you: "brainlessness." A regular mind flayer has three tentacle attacks per turn; the **master mind flayer** has *five*, plus a heavier weapon strike. A single unprepared turn next to a master mind flayer can drop your Int by up to ten. Each hit also has a 1-in-5 chance to trigger **spell amnesia**: a random number of your spells (up to all of them) drop to zero retention; re-study spellbooks to restore. Independently, each hit has another 1-in-5 chance to drain one or two of your **weapon skills** — Basic falls back to Unskilled, Expert to Skilled, and so on. Skill loss has to be earned back at training posts, so do not stand and trade blows with a mind flayer.

**Defenses:** **Wear any helmet.** Even a plain orcish helm blocks seven of every eight tentacle drains. Greasing the helmet stacks an additional slip-off roll on top, so a greased helmet is the gold standard. Better yet, kill them at range (wands, spells) so the question doesn't arise. One useful detail: a mind flayer's *mind blast* locks on every time when telepathy reveals you, but can still fire one time in ten without it. Taking off an amulet of ESP lowers the risk; it does not remove it. To recover drained Intelligence you need a *potion of restore ability* (uncursed restores one stat; blessed restores all), the spell of restore ability, or prayer when you're in good standing. In 5.0 the unicorn horn no longer restores lost attributes, so don't rely on it. Stockpile at least one restore ability before pushing into mind flayer territory.

#### Engulfment {#engulfment}

Two monsters hide in plain sight until you walk into them. The **lurker above** (`t`, gray, level 10) hides on the ceiling and drops onto whoever passes underneath; the **trapper** (`t`, green, level 12) hides on the floor and engulfs whoever steps onto it. Both look like ordinary terrain until they trigger. Their engulfment wraps and crushes rather than digesting.

Other engulfers don't hide. Purple worms digest; vortices and fog clouds engulf and batter you without digestion. Dragons do not swallow you.

**Defenses:** Searching reveals hidden monsters. *Telepathy* shows them through the deception. Wearing a *ring of warning* or a *helm of caution* tips you off before you step.

**Getting out.** Once engulfed, attack the host repeatedly; weapons still work from inside. If you have a wand of digging, zap it (no direction needed): it almost always expels you immediately, leaving the engulfer at 1 HP. A wand of opening or the knock spell forces the engulfer to release you on the spot without killing it, useful if a *tame* purple worm has swallowed you in conflict. Ranged spells and rays will tear into the host from the inside.

#### Drowning {#drowning}

Giant eels, electric eels, and krakens can grab you with their wrap attack. Once they have you, each of the monster's turns you can drown. The check uses the *monster's* tile (always water for an eel or kraken), not yours, so you can drown even while standing on adjacent dry land. Only *Swimming*, *[magical breathing](#movement-and-spatial-behavior)*, or *amphibious form* prevent the drown; encumbrance doesn't matter here. (Encumbrance only matters if you *fall* into water and need to crawl out; Stressed or worse forces emergency disrobe.) You'll meet eels and krakens at Medusa's level, in moats around the Castle, in swamp rooms, and on the Water Plane.

**Defenses:** An amulet (or spell) of *magical breathing* gives you Breathless and ends the grab-drown threat. Levitation keeps you above pools so you can't walk into them, but **does not save you from an eel's grab** once it lands. Kill sea monsters at range whenever possible; their grab attack requires adjacency.

#### Petrification (Stoning) {#petrification-stoning}

Petrification is the reason players carry a lizard corpse. Touching or eating a cockatrice without protection, kicking its corpse barefoot, or meeting Medusa's gaze kills at once; a lizard cannot help. Stepping on the corpse is safe unless Fumbling trips you onto it.

A cockatrice's hiss or a thrown egg instead starts a five-turn countdown. It announces itself with *"You are slowing down,"* *"Your limbs are stiffening,"* *"Your limbs have turned to stone"* (at which point you are **paralyzed** and can no longer act), *"You have turned to stone,"* and *"You are a statue"* (death).

**Defenses ahead of time:** wear gloves around cockatrice corpses, use reflection against Medusa, and pile up *timed* stoning resistance from acid blob corpses (each one grants 3–18 turns). For something permanent, wear yellow dragon scale mail.

**Peril in the new moon.** A cockatrice's hiss has a small chance to start stoning on any landed melee hit (roughly 1 in 30). On the real-world night of a new moon, that jumps to about 1 in 3. Hunt the nest on another night.

**Defenses while it's happening:** eat a lizard corpse (that is why you carry one), eat an acidic corpse, drink a potion of acid, pray, or cast stone-to-flesh on yourself. Keep the lizard in your **main inventory**, not in a bag: pulling it out of a bag takes a turn you can't spare. Act *before* the "Your limbs have turned to stone" message; after that you're paralyzed for three turns and the final messages kill you. Amulet of [Unchanging](#special-and-utility) does **not** interrupt stoning. If you happen to be polymorphed into a non-stone golem, wearing it during the countdown is actively harmful; it blocks the stone-golem auto-poly that would otherwise save you on death.

Out of lizards? Any acidic corpse will do: acid blob, jellies, yellow dragon, black naga, and yes, green slime works (but green slime starts a *different* countdown that turns you to slime; only reach for it as a last resort). Quaffing a potion of acid has the same curative effect.

**The other side of the coin:** a wielded cockatrice corpse (with gloves on) is one of the game's most devastating weapons. anything you hit that lacks [stoning resistance](#damage-resistances) turns to stone. The classic offense, known to veterans as the "rubber chicken," handles many demon lords. Medusa and the Riders resist stoning. The failure modes you must guard against are falling into a pit, hole, or trapdoor while carrying it, and losing the gloves. Thrown cockatrice eggs work the same way and have the same hazard if a monster throws one at you.

#### Disintegration {#disintegration}

A black dragon's breath is the only monster, spell, or wand that disintegrates you. (A deeply angered god can also call down a wide-angle disintegration beam as a follow-up to lightning; reflection won't block that one. Only disintegration resistance will. Stay on speaking terms with your god.)

**Defenses:** Disintegration resistance (from eating a black dragon corpse or wearing black dragon scale mail) gives full immunity. **Reflection** bounces the breath back, protecting you, but black dragons are themselves disintegration-resistant, so the bounce won't kill them. Magic resistance does **not** help.

**Without disintegration resistance**, your worn armor takes the breath first: the **shield** is destroyed first if you have one, then your **body armor and cloak** together; only if neither is worn do you die outright (with your cloak and shirt destroyed in the process). So an ordinary shield at least eats one breath for you before being lost. An amulet of life saving still rescues you from the fatal case, though you lose any armor it took.

#### Level Drain {#level-drain}

Certain monsters reduce your experience level on a hit, taking the HP and power gains that came with each lost level. Wraiths, barrow wights, Nazgul, vampires, vampire leaders, and Vlad himself all carry level-drain attacks. [Stormbringer](#stormbringer) in an enemy's hand does the same. Drained levels do not come back on their own. You re-earn them by killing more monsters, by drinking a potion of restore ability (a blessed one restores all lost levels at once), or by eating a wraith corpse.

(Don't confuse drain-life with *Strength* drain: a vampire bat's poisoned bite drains Str, not levels. Stat drain is a separate problem and [Enchantment Drain](#enchantment-drain) covers its cousin.)

**Defenses:** *Drain resistance* makes you immune. The classic sources are wielding [Excalibur](#excalibur-artifact) (Lawful), Stormbringer (Chaotic), or the [Staff of Aesculapius](#staff-of-aesculapius) (Healer's quest artifact). New in 5.0: wearing **black dragon scale mail** (disintegration resistance plus drain resistance, both in one slot) or a **shield of drain resistance** (random shop find, no other property).

Wraith corpses are weightless and can't be tinned (no nutrition), so eat them fresh the moment the fight ends.

#### Enchantment Drain {#enchantment-drain}

**Disenchanters** (`R`, blue) appear only in [Gehennom](#gehennom). Their claw drains worn gear; hitting one in melee drains your weapon.

Their **active** claw picks one of your worn armor pieces (cloak first, then suit, then shirt, then helm, gloves, boots, or shield by weighted chance) and shaves 1 off its enchantment. If you have no armor at all, it can instead chew a ring, amulet, or blindfold. **It can't reach your wielded weapon** with the active attack. The game does print "Your *thing* seems less effective" each time, so you'll know when it lands.

Your weapon only takes enchantment damage as a **passive** counter when you hit them in melee. Three or four melee strikes will take a +7 sword to +3; that passive drain is silent. Range-killing sidesteps both attacks at once.

**Defenses.** **Magic-cancellation armor** at MC3 mostly blocks their armor drain but doesn't stop the melee counter that drains your weapon. Rings of conflict and pets redirect them to other targets. Artifacts resist drain 9 times in 10; ordinary items only 1 in 10. **Don't eat the corpse**: it strips a random intrinsic.

#### The Touch of Death {#the-touch-of-death}

Some monsters, most notably Death (one of the Riders on the Astral Plane), can kill you with a single touch. The Finger of Death spell and the wand of death work similarly. **Do not zap a wand of death or finger of death at Death the Rider**. Death absorbs the attack and gains max HP. Magic missile is the recommended answer against all three Riders.

**Death the Rider's touch** has a 15% chance to attempt the full **8d6 + 50** blow and drain half that damage from your maximum HP. Magic resistance reduces that to the smaller drain rather than blocking it. Sixty percent of touches deliver that smaller drain directly, and 25% miss. A high-level character with many hit points can survive the high-damage hit; the permadrain still hurts.

**The wand of death and Finger of Death spell** are gated by magic resistance only when the death ray *hits you from outside*. If you misfire and self-zap, MR doesn't save you; only being **nonliving** (polymorphed into a vampire, lich, skeleton, etc.) or a demon will. The same nonliving/demon immunity also protects against incoming death rays.

An amulet of life saving will revive you once if the touch or zap kills you outright.

#### Genocide {#genocide}

Reading an uncursed scroll of genocide while confused can genocide your own role species. Check your status before reading one.

---

### Divine Relations {#divine-relations}

A happy god answers prayers, forgives transgressions, and occasionally sends gift artifacts. An angry god smites you.

#### Prayer {#prayer}

Praying (`#pray`) calls on your god for help. When conditions are right, prayer pulls you back from stoning, starvation, or near-death. When conditions are wrong, it can kill you.

> *The mechanics below were inspired by Matthew Lahut's Praying Spoiler, the long-running RGRN reference for the prayer system.*

**What prayer fixes (in priority order).** Your god fixes the most urgent trouble first:

1. Petrification in progress (stoning)
2. Sliming in progress
3. Strangulation
4. Sinking in lava
5. Illness (food poisoning, sickness)
6. Severe hunger (Weak or Fainting)
7. Standing in a stinking cloud
8. Critically low HP (≤5, or below a fraction of maxHP that scales with your experience level: 1/5 at XL 1–5, 1/6 at 6–13, 1/7 at 14–21, 1/8 at 22–29, 1/9 at XL 30+)
9. Lycanthropy
10. Stuck in a wall, collapsing under load, cursed levitation boots, unusable hands (cursed glove + cursed wielded weapon), cursed blindfold

After resolving the major troubles above, your god may also grant additional blessings: clearing minor afflictions (plain hunger, blindness, confusion, stunning, hallucination, ordinary punishment with iron ball and chain), improving your alignment, or even gifting intrinsics like [telepathy](#senses-and-perception) or speed.

**The requirements for a safe prayer.** All of the following must be true:

- Your **alignment** must be non-negative. Killing peacefuls, robbing shops, and other misdeeds reduce alignment. Sacrifice and virtuous behavior raise it.
- Your **luck** must be non-negative. Luck is affected by many things (see [Luck and Fortune](#luck-and-fortune)).
- Your god must not be **angry**. God anger is separate from alignment and accumulates from specific offenses (breaking conduct with your god, desecrating altars).
- The **prayer timeout** must have expired. After a successful prayer, you must wait before praying again. The timeout averages around 450 turns but can run much longer. In a genuine emergency (HP critical, starving), there is some forgiveness if your timeout is close to expiring.
- You must not be **polymorphed** into a demon or undead while worshipping a non-chaotic god.
- You must not be in **[Gehennom](#gehennom)** (unless you worship Moloch, which no standard role does). Your god cannot hear you there. That is one of the things that makes Gehennom so dangerous.
- If you're on an altar, it should be **co-aligned**. Praying on a cross-aligned altar directs your prayer to the wrong god.

**The short rule:** pray for a listed trouble only when your alignment and Luck are non-negative, your god has not expressed anger, and you are off another god's altar and outside Gehennom. If you have never prayed, wait until after turn 300. Afterward, allow about a thousand turns between prayers when you can; the average recovery is nearer 500, but the tail is long.

**When prayer goes wrong.** If a requirement is unmet, your god punishes instead of helping: lost alignment or luck, a longer timeout, cursed worn items, or hostile minions. Severe transgressions can trigger lightning or disintegration, both fatal.

**Practical guidance.** Pray only when you're about to die and have no other option: starvation, stoning, illness, critically low HP. First run the checklist above (alignment non-negative, timeout expired, no cross-aligned altar). If any answer is no, find another way.

**Prayer timeout tracking.** The game does not show the number. Five hundred turns is an average, not a promise; use a thousand as the safe rule when the run gives you that much room.

#### Turning Undead {#turning-undead}

**Knights** and **Priests** can `#turn` to call on their god and drive back the undead: every undead and vampire in sight (and demons, past experience level 15) within a wide radius. The tougher the creature, the higher your level must be to *destroy* it rather than merely scare it, zombies at experience level 6 but **ghosts not until 14**, liches 16. Below that, a turn only routs them, and magic-resistant undead like ghosts resist about half the time. Lawful and neutral heroes destroy what they turn; chaotic ones pacify it.

Unlike prayer, turning costs nothing with your god: no timeout and no goodwill, so use it freely, paying only a few turns of paralysis while you chant. But like prayer it **fails in [Gehennom](#gehennom)**, so it's dead weight in the Valley of the Dead. The turn undead spell is different: it fires in one direction, scares one target, and works there.

#### Sacrifice {#sacrifice}

Sacrifice trades a fresh corpse for favor. On a co-aligned altar, `#offer` first calms an angry god, then repairs alignment and prayer timeout; once those are sound it can raise Luck or produce an artifact. Holy water and crowning come from prayer on the altar, not the sacrifice itself.

The rules:

- The corpse must be fresh, killed within the last **50 turns**. A corpse older than that has zero sacrifice value (the gods simply ignore it). Acid blob corpses are the one exception and never spoil for that purpose.
- Bigger monsters make more valuable sacrifices. *"You have a feeling of inadequacy"* means your god was angry and the corpse was too small to help; the requirement does not scale with XL.
- The altar must match your alignment, or you're praying to someone else's god (which has its own consequences).
- Same-race sacrifice punishes a lawful or neutral hero (and turns a co-aligned altar chaotic). For a **chaotic** hero on a chaotic altar, though, it is a reward: a peaceful demon appears and your Luck and alignment both rise.
- Two requirements before any gift can fire: you must be experience level **3 or higher**, and your Luck must not be negative.

With enough sacrifice credit, your god may gift you an artifact weapon. The chance per qualifying sacrifice is roughly **1 in 6** for the first gift, then drops sharply for each subsequent gift. The drop depends on two things: how many gifts you have already received and how many artifacts exist in the game (yours, randomly generated, and from any bones files you have inherited). If only your first gift exists, the next chance begins around one in eight; more gifts and more existing artifacts make it worse. Don't be surprised if you get one artifact and then nothing more for thousands of turns.

The first gift is not merely biased for several roles. A Valkyrie, Wizard, Barbarian, Samurai, or Priest can receive only the role's signature artifact first, and it adopts the hero's alignment. The corpse also caps what can appear: Sting, Ogresmasher, and Trollsbane need only a value-1 offering; Vorpal Blade and Fire Brand need 5; Frost Brand needs 9; Grayswandir needs 10. Save a troll-class corpse when fishing for the strongest gifts.

#### Donating to Priests {#donating-to-priests}

A peaceful priest in their own temple accepts donations. `#chat` to them and a prompt appears: *How much will you offer (suggested: X or Y)?* The two numbers are the priest's suggested thresholds for the two reward tiers.

**What you get:**

- **Clairvoyance.** 500–999 turns per suggested amount of automatic short-range map awareness (you "see" the immediate area around you every few turns without moving). Granted if you offer in the lower tier.
- **Protection.** An intrinsic AC bonus that *stacks* across visits. Granted if you offer in the upper tier. Your **first** donation grants 2–4 points; subsequent donations add 1 each up to 9; past 9, the chance to get another point drops to 1-in-N. The bonus persists for life, unlike clairvoyance.

**The cost.** Pay enough and the benefit is yours. The priest's prompt always shows you the exact ask, which scales with your experience level and how much gold you're carrying:

- **Clairvoyance:** a randomized 150–250 zorkmids × experience level as the base ask
- **Protection:** twice that, 300 to 500 zorkmids × experience level

If you walk in carrying far more gold than the baseline, the priest scales the ask to your purse. The useful thresholds are the two numbers in the prompt: pay at least the first for clairvoyance and the larger for protection.

**The cheapskate penalty.** If you offer noticeably less than what's expected while clearly able to afford more, the priest calls you a Cheapskate and will hold a grudge: the next time you chat with that same priest, the cost will be higher. The penalty stacks if you keep doing it, and it sticks for the rest of the game. Other priests in other temples aren't affected. Refusing to donate anything at all also costs you alignment with your god.

**Practical guidance:**

- **Donate early, donate often.** Protection stacks, so 500 zm at XL 1 buys the same AC reduction as 15000 zm at XL 30. Visiting the Minetown temple every time you climb back up from [the Mines](#the-gnomish-mines) is a classic stacking ritual.
- **Count gold before chatting.** The priest's roll is sensitive to what's in your inventory; drop excess gold on the floor outside the temple before asking, then pick it back up.
- **Cross-aligned priests still accept donations** and still grant the AC and clairvoyance. You miss the alignment bonus and you can't sacrifice on their altar, but the AC ramp still works.
- **Do not start the conversation unless you are willing to pay.** A zero offer counts as a refusal: it costs alignment and marks you as a cheapskate just like a token offer.

#### Altars and Alignment {#altars-and-alignment}

To convert a cross-aligned altar, sacrifice ordinary fresh corpses on it. Each attempt either flips the altar to your god (success), costs you Luck (failure), or, if your alignment record is negative, converts *you* to the altar's alignment instead. Better odds at higher experience level. Worth the risk when you need a co-aligned altar for sacrifice gifts, holy water, or BUC testing.

Above XL 8, either result can also summon a hostile minion of the displaced god. Have an exit in reach before you make the offering.

Keep two things off every altar:

- **A corpse of your own race** (human, elf, gnome, dwarf, or orc, whichever you are). Punished on every altar — *unless* you are chaotic and the altar is chaotic, where it instead rewards you with a peaceful demon and a Luck and alignment boost.
- **A unicorn whose alignment matches the altar.** Counts as an insult to that god.

#### Crowning {#crowning}

If your alignment record reaches 20 *and* your Luck reaches 10, your god may crown you on a successful prayer. Crowning grants:

- A special title (e.g., "Hand of Elbereth" for lawful characters).
- An alignment gift, with exceptions. A Lawful crowning transforms the long sword you are wielding into [Excalibur](#excalibur-artifact), so having a +7 long sword in hand at the moment of crowning gives you a +7 Excalibur; with no long sword there is no sword. Wizards and Monks receive their spellbook instead of the weapon.
- Intrinsic [fire resistance](#damage-resistances), [cold resistance](#damage-resistances), [shock resistance](#damage-resistances), [sleep resistance](#damage-resistances), [poison resistance](#damage-resistances), and see invisible.
- Permanent skill-unrestriction on your alignment's sword slot.
- A class-specific bonus: Wizards get the *finger of death* spell; Monks get *restore ability*.

Crowning makes every later prayer add roughly 1,000 turns on top of the ordinary timeout. If you're sacrificing to fish for an artifact gift, mind your piousness, since a prayer made at high standing can crown you. A stethoscope applied to yourself reports it in words; *piously* is the top band, where a prayer could crown you.

---

### Making Friends {#making-friends}

The Mazes of Menace are dark, hostile, and full of things that want to eat you. Under those circumstances, a loyal companion is worth more than a bag of gold. Fortunately, the dungeon provides.

#### Starting Pets {#starting-pets}

Most roles begin with a faithful pet: a little dog or a kitten, depending on your role. It follows you between levels (if adjacent when you take stairs), fights alongside you, picks up items, and eats food it finds on the floor. Think of it as a self-propelled, self-feeding curse tester with teeth.

A pet that eats well and fights often will grow. A little dog becomes a dog, then a large dog. A kitten becomes a housecat, then a large cat. A grown large dog or large cat is a genuine combat asset, capable of taking on mid-dungeon threats that would give you trouble.

One more thing: your pet usually avoids cursed items when there's an uncursed alternative, which makes it a *probabilistic* curse-detector. Drop items on the ground and watch what your pet walks past versus what it walks around. If it has no choice, it will still cross the cursed square, but consistent avoidance across many turns is a strong tell. Even when it does step onto a cursed pile (chasing food, or pulled by a magic whistle), the game prints *"[pet] moves reluctantly onto …"*. That message is a giveaway.

#### Feeding and Loyalty {#feeding-and-loyalty}

Pets have an invisible tameness score that decreases when you leave them behind on another level for too many turns, drag them by a leash, or hit them yourself. Hunger affects their behavior, not tameness. (Combat damage from other monsters doesn't reduce tameness.) When tameness hits zero, the pet either goes untame-but-peaceful or turns fully hostile. Feeding is the antidote:

- **Dogs and cats** love tripe rations and most meat
- **Horses** prefer apples, carrots, and other vegetarian fare

You'll find tripe rations scattered through the dungeon. Always pick them up, even though they're revolting food for humans. Your pet will adore you for it (unless it's a horse, which prefers fruit). When you're carrying food your pet likes, it will follow you more closely.

**Is it hungry?** There's no meter, but `#chat` to the pet and the sound tells you, graded by how recently it fed:

| Pet       | Just fed | Content   | Hungry     |
|-----------|----------|-----------|------------|
| **Dog**   | yips     | barks     | whines     |
| **Cat**   | purrs    | mews      | meows      |
| **Horse** | —        | whickers  | whinnies   |

The hungry sound is your cue to feed. It doubles as the unhappy sound, so read it in a calm moment: a cat that **yowls** or a horse that **neighs** has nearly gone feral.

#### Taming New Creatures {#taming-new-creatures}

If your starting pet perishes (or you want an army), several methods of taming exist:

- **Throwing food** at a suitable creature: meat for dogs and cats, produce for horses
- **Scroll of taming** or **spell of charm monster** both route through the same handler and tame all eligible creatures within a 3×3 radius. Reading the scroll while confused widens that to 11×11 (but you can't cast the spell while confused).
- **Magic trap effects** occasionally produce taming

Taming isn't limited to small animals: with a scroll of taming or the charm monster spell, you can recruit a purple worm to swallow your enemies whole, a dragon to breathe fire at them, a titan to crush them underfoot. The exclusion list is substantial, though: no humans (priests, shopkeepers, watchmen, soldiers, kings), no covetous monsters (the Wizard, liches, masters), no demons (unless you are one), no vault guards, quest leaders, nor minions can be tamed. Unique monsters (Medusa, etc.) also resist.

#### What Pets Do for You {#what-pets-do-for-you}

A well-fed pet earns its keep in several ways:

- **Combat muscle.** A strong pet clears rooms and softens up dangerous monsters before you engage
- **Curse detection.** The drop-and-watch trick is free but probabilistic; look for repeated reluctance or the printed message
- **Shoplifting.** If your pet picks up an item inside a shop and carries it out the door, the shopkeeper blames the animal, not you. That takes patience (the pet must wander onto the item, then wander back out) but it's the cheapest way to acquire a wand of wishing from a shop
- **Sacrifice fodder.** Monsters your pet kills leave corpses you can sacrifice on altars, exactly as if you'd killed them yourself

**Training apport (fetching).** Hand-feeding your pet builds a score called apport. A pet with high apport will pick up nearby items and bring them to you. That is what makes pet-shoplifting practical: drop something at the shop counter, walk out, and trust the pet to follow with the goods. Pair it with a magic whistle (below) to yank a loaded pet to your side from anywhere on the level.

**Upgrading your pet.** Three moves matter most.

- A **magic whistle** teleports every tame creature on the level to a spot next to you each time you blow it. Distance doesn't matter; trapped pets get freed in the process.
- Tame a **warhorse** early (throw apples or carrots) and you have a fast, hard-hitting mount before mid-game.
- Late in the run, **polymorph your pet** into a stronger form. **Titan** is a popular target: level 16, speed 18, flies, throws boulders, and casts spells. Faster than anything else that strong, so it keeps up with a speed-boosted hero, and the spell-cast attack threatens at range. Balrog hits harder but is speed 5, slow enough that anything that runs gets away. Gray dragon is an alternative when you specifically want the magic-resistance intrinsic and a body that won't accidentally re-polymorph.
- If you can tame an **Archon** directly (via a scroll of taming on a hostile, magic-whistle recall of one you tamed earlier, or a conflict-ring accident), do it. The Archon is the ultimate pet: level 19, speed 16, AC −6, magic resistance, sees invisible, flies, regenerates, and a multi- attack that includes a blinding gaze and a spell-cast. You cannot polymorph a pet into an Archon: you must encounter one and tame it.

#### Keeping Your Pet Alive {#keeping-your-pet-alive}

Pets die from the same things you do: traps, poison, powerful monsters, drowning in water. Use a stethoscope to check your companion's health, and don't lead it into fights it can't win.

If you change levels and your pet isn't adjacent, it won't follow. Its loyalty ticks down while it waits, so go back for it before it forgets you were friends. A **magic whistle** warps every pet on your level to a square next to you, even on no-teleport floors. Sokoban has no special protection against loyalty decay; do not leave a pet there while you clear another branch.

If you see *"You have a sad feeling for a moment"*, that's different: a pet of yours just died offscreen on another level, usually one you left behind.

Pets can now gain resistances and return from the dead. A pet that dines on the right monsters will gain resistances: [fire resistance](#damage-resistances), cold resistance, whatever the dungeon's terrible buffet was offering. You cannot reliably engineer that, but it is a reason to let your pet eat rather than scoop up every corpse yourself.

If your companion falls in battle, stand on its corpse at a co-aligned altar and pray. That is a last resort, not a renewable strategy: prayer timeout, alignment, and luck all factor in.

---

## Part Four: Gear and Provisions {#part-four-gear-and-provisions}

Most objects in NetHack arrive disguised. Their appearance may change from game to game, but their price, weight, material, and behavior do not. That section turns those fixed clues into decisions: what to test, what to wear, what to save, and what to leave alone.

### A Practical Identification Strategy {#a-practical-identification-strategy}

Here is the central puzzle of the Mazes: you will find dozens of items, and you won't know what most of them are.

Every game, the dungeon shuffles the deck. Potions, scrolls, wands, rings, amulets, and spellbooks are all given randomized appearances. The "milky potion" in this game might be healing; in your next game it might be paralysis. The only things that stay consistent between games are the item classes themselves (a `!` is always a potion, a `?` is always a scroll) and the prices, which turn out to be the single most powerful identification tool you have.

![The identification flowchart: cheapest method first, scroll of identify last.](asset:assets/images/spoiler_flowchart_en.webp)

#### Blessed, Uncursed, Cursed (BUC) {#blessed-uncursed-cursed-buc}

Before you can worry about *what* an item is, you need to know *what condition* it's in. Every item in the Mazes is blessed, uncursed, or cursed (BUC for short). The gods have opinions about your equipment, and those opinions have consequences:

- A **blessed** scroll of identify reveals one to four items, or the whole pack one time in five. Positive Luck raises the minimum to two. An *uncursed* scroll usually identifies one item, but one time in five it gets the blessed result. A *cursed* scroll identifies only itself the first time you read one of that type, then one item per subsequent cursed read.
- A **cursed** piece of armor bonds to your skin like it has abandonment issues. You cannot remove it until you lift the curse.
- A **cursed** potion of gain level interprets "gain a level" in the most literal architectural sense: you rocket through the ceiling to the floor above, instead of gaining an experience level.

BUC status changes each object in its own way. A blessed luckstone keeps good Luck and lets bad Luck wear off; a cursed one does the reverse. A cursed or confused scroll of teleportation sends you to a random *level* instead of teleporting within the current one.

You don't see BUC status by default. Priests are the exception: they sense it as soon as they handle an object. Everyone else must test.

**Altar testing.** Drop an item on an altar:

  - An amber flash means blessed.
  - A black flash means cursed.
  - No flash means uncursed.

That is free and unlimited. If you find an altar early, use it.

**Pet testing.** A pet normally steps reluctantly onto a cursed item, so drop the object in a doorway or corridor and watch several passes. Repeatedly walking around it is strong evidence that it is cursed; walking over it once is not proof that it is safe. Food, fear, combat, and pathfinding can spoil the test. A further trap: a helm of opposite alignment or dunce cap may test uncursed and then curse itself when worn. Fumbling gloves and levitation boots do not autocurse, but they are generated cursed often enough that you should still test them.

**Holy water.** Dipping an item in blessed water (holy water) will uncurse a cursed item or bless an uncursed one. Dipping in cursed water (unholy water) curses an uncursed item or unblesses a blessed one. You make holy water by placing potions of water on a co-aligned altar and making a successful prayer there. It is precious in the early game, so save it for items you've already identified.

**Scroll of identify.** Save this for objects that the cheaper tests cannot settle. A blessed scroll identifies one to four inventory items—or everything, one time in five. Positive Luck guarantees at least two. An uncursed scroll usually identifies one item but gets the blessed result one time in five. Pick up every unidentified item before reading a blessed scroll so the all-inventory result reaches everything you own.

#### The Price Is Right {#the-price-is-right}

Every unidentified object has a fixed base price. With Charisma 11–15 and no surcharge, the shopkeeper's buy quote is that base price; the ordinary offer for an item you sell is half of it. That makes a shop an identification station as well as a market.

> *Shopkeeper pricing was first documented in detail by Gregory Bond's Shopping Spoiler, HTML-formatted by Kate Nepveu and hosted on steelypips.org. David Damerell's Object Identification Spoiler expanded the price-based identification techniques. The mechanics below draw from both.*

To quote an item without picking it up, stand on it and press **`:`**, or **`#chat`** with the shopkeeper while you are standing there. Do not throw your own object in from the doorway: you get no quote, and the shopkeeper pockets it.

Three conditions impose the same Tourist markup: wearing a *dunce cap*, playing a *Tourist below XL 15*, or showing a *T-shirt or Hawaiian shirt* with no body armor or cloak over it. Each raises buy prices by a third and cuts ordinary sell offers from one-half to one-third of base; the conditions do not stack. Charisma changes buy quotes only. Cover the shirt before doing business.

Items in the same category that share a base price are in the same **price group**. A price often narrows an object to two or three candidates. Low Charisma raises buy quotes (to twice base at Cha 5 or less); high Charisma lowers them (to half base at Cha 19 or more). The tables below do the conversion.

Two wrinkles affect unidentified merchandise. About one object in four carries a permanent one-third buy surcharge, so identical-looking stacks may receive different quotes. About one shopkeeper in four offers only three-quarters of the normal sell price for unidentified goods; that habit applies to the shopkeeper, not the object. If a quote misses the expected tier, check the neighboring tier as well.

**Angry.** Attacking a shopkeeper, zapping a wand at one, leaving with unpaid goods, or refusing to pay for shop damage makes the shopkeeper angry. Even after you settle matters, a pacified shopkeeper keeps a one-third buy surcharge. Sell prices are unaffected.

**After a fight.** If you actually attacked a shopkeeper rather than just running up a debt, they want blood, not gold. You can still buy them off. Press `p` to offer 1000 gold pieces, which you must have in hand. If you are the shop's registered customer the offer fails about one time in three, wasting the gold and leaving them furious. Otherwise they calm down, minus the usual surcharge.

**Invisible.** A shopkeeper will not do business with a customer they cannot see. Walk in invisible and you get "Invisible customers are not welcome!" and no quotes, no sales. If you are stuck invisible, wear a mummy wrapping as your cloak: it blocks the invisibility, so you appear visible again and the shopkeeper deals with you normally. Take it off on your way out if you want to vanish once more.

**The specialty is a clue too.** A shop that deals in one kind of goods stocks only items that fit its theme, so *where* you find something can name it outright. Everything on a lighting shop's shelves is light-related: every wand there is a wand of light, every potion is oil, every scroll a scroll of light, every spellbook a spellbook of light. A food shop's only potions are fruit juice, booze, and water. That is the shop's own stock talking. An item you or a monster dropped on the floor could be anything.

The price tables for each item class follow.

##### Scroll Prices {#scroll-prices}

| Price | Scrolls                                                                                                           |
| ----- | ----------------------------------------------------------------------------------------------------------------- |
|    20 | identify                                                                                                          |
|    50 | light                                                                                                             |
|    60 | blank paper, enchant weapon                                                                                       |
|    80 | enchant armor, remove curse                                                                                       |
|   100 | confuse monster, destroy armor, fire, food detection, gold detection, magic mapping, scare monster, teleportation |
|   200 | amnesia, create monster, earth, taming                                                                            |
|   300 | charging, genocide, punishment, stinking cloud                                                                    |

The $100 group is crowded, so its quote seldom settles an identity. A $20 scroll is identify. The $60 group contains blank paper and enchant weapon; $80 means enchant armor or remove curse. Those narrow groups are good places to spend a use-test once BUC is known.

A *single* scroll sealed in a one-square niche with no door—sometimes behind iron bars—is a scroll of teleportation. It is there so that a creature teleported into the niche can leave.

##### Spellbook Prices {#spellbook-prices}

Spellbooks price at 100 × the spell's level, which makes reading risk easy to gauge: a $700 book is level 7 and will probably explode in the hands of anyone who isn't a careful Wizard.

| Price | Level | Spellbooks                                                                                                                  |
| ----- | ----- | --------------------------------------------------------------------------------------------------------------------------- |
|   100 | 1     | confuse monster, detect monsters, force bolt, healing, jumping, knock, light, protection                               |
|   200 | 2     | chain lightning, create monster, cure blindness, detect food, drain life, magic missile, slow monster, wizard lock          |
|   300 | 3     | cause fear, clairvoyance, cure sickness, detect unseen, extra healing, haste self, identify, remove curse, sleep, stone to flesh |
|   400 | 4     | cone of cold, detect treasure, fireball, invisibility, levitation, restore ability                                          |
|   500 | 5     | charm monster, dig, magic mapping                                                                                           |
|   600 | 6     | create familiar, polymorph, teleport away, turn undead                                                                      |
|   700 | 7     | cancellation, finger of death                                                                                               |

##### Potion Prices {#potion-prices}

| Price | Potions                                                                     |
| ----- | --------------------------------------------------------------------------- |
|    20 | healing                                                                     |
|    50 | booze, fruit juice, see invisible, sickness                                 |
|   100 | confusion, extra healing, hallucination, restore ability, sleeping, water   |
|   150 | blindness, gain energy, invisibility, monster detection, object detection   |
|   200 | enlightenment, full healing, levitation, polymorph, speed                   |
|   250 | acid, oil                                                                   |
|   300 | gain ability, gain level, paralysis                                         |

Healing sits alone at $20, uniquely identifiable from the price tag. Water is always the "clear" potion, so if you see "clear potion" you know what it is without even checking the price. The $50 group is tricky because sickness and [see invisible](#senses-and-perception) are in there together (one very good, one very bad). The $200 group is packed with excellent potions.

##### Ring Prices {#ring-prices}

| Price | Rings                                                                                                                                                                      |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   100 | adornment, hunger, protection, protection from shape changers, stealth, sustain ability, warning                                                                           |
|   150 | aggravate monster, cold resistance, gain constitution, gain strength, increase accuracy, increase damage, invisibility, poison resistance, see invisible, shock resistance |
|   200 | fire resistance, free action, levitation, regeneration, searching, slow digestion, teleportation                                                                           |
|   300 | conflict, polymorph, polymorph control, teleport control                                                                                                                   |

Only four rings cost $300, and three of them are excellent: conflict, [polymorph control](#special-and-utility), and [teleport control](#movement-and-spatial-behavior). The fourth is polymorph, which usually generates cursed.

##### Wand Prices {#wand-prices}

| Price | Wands                                                                                                                                                          |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   100 | light, nothing                                                                                                                                                 |
|   150 | digging, enlightenment, locking, magic missile, make invisible, opening, probing, secret door detection, slow monster, speed monster, stasis, striking, undead turning |
|   175 | cold, fire, lightning, sleep                                                                                                                                   |
|   200 | cancellation, create monster, polymorph, teleportation                                                                                                         |
|   500 | death, wishing                                                                                                                                                 |

If a wand costs $500, you are having a very good day.

##### Amulet Prices {#amulet-prices}

All amulets have a base price of $150 except the cheap Amulet of Yendor imitations ($0). Price won't ID them; you'll need other methods.

#### The Engrave Test (Wands) {#the-engrave-test-wands}

The wand-identification test costs one charge and preserves the rest.

> *Procedure adapted from Kieron Dunbar's "Identifying Wands by Zapping" spoiler, originally posted to RGRN.*

1. **BUC-test the wand first.** A cursed wand has a 1-in-100 chance to explode when used for engraving. Drop it on any altar, or use another curse test, before spending a charge.
2. **Write a short message on the floor with your finger.** Engrave anything in the dust first (command `E`, then select "`-`" for fingers, then type a word or two). That matters because a few wands act on the *existing* engraving rather than producing a visible effect on bare floor: polymorph rewrites the message as a random new one, and cancellation, make-invisible, and teleportation each make it "vanish". Without a pre-written message you won't see those behaviors.
3. **Engrave again with the wand.** Use `E` and select the wand. Observe the result. The [Wand Table](#the-wand-table) lists the engrave-test result for each wand; most reveal themselves here. A wand of lightning also blinds you for up to 50 turns, so do not test one while monsters are near. A few wands share results; see [Resolving Ambiguous Engrave Results](#resolving-ambiguous-engrave-results).

**A suspected wand of wishing is safe to engrave-test.** If a $500 candidate asks *"For what do you wish?"*, the test has spent a charge and granted the wish. Make it count.

#### The Sink Test (Rings) {#the-sink-test-rings}

If you find a sink, you can drop a ring down it. Each type produces a clue, though a few messages overlap and some require sight, so that is not always formal identification. Rings of searching and [slow digestion](#special-and-utility) return immediately. Another ring has a 1-in-20 chance to come back and a 1-in-5 chance to be buried under the sink; otherwise it is gone. Use a spare ring, not your only candidate. See [Sinks](#sinks) for the message table.

#### Use-Testing (The Careful Way) {#use-testing-the-careful-way}

When you don't have access to a shop or a sink, you can sometimes figure out what an item is by using it carefully. Here's the approach for each category:

**Potions.** The safest test is to throw a potion at a monster and observe the effect. Throwing avoids the risk of drinking something lethal. If a potion heals the monster, it's some kind of healing potion. If the monster speeds up, it's speed. If the monster becomes invisible, well, you've learned something (and now have an invisible monster to deal with).

You can also dip items into potions. Dipping a stack of poisonable ammunition (arrows, crossbow bolts, darts, or shuriken) into a potion of sickness will poison it, confirming the potion's identity (it won't poison a sword or any non-missile weapon). Dipping a unicorn horn into a potion of **confusion**, **hallucination**, or **blindness** turns it into water; dipping into a potion of **sickness** turns it into fruit juice.

**Oil is the only potion you can apply.** `#apply` an unidentified potion and, if the game offers to light it, it's a potion of oil; nothing else responds.

A dip also makes a quick safety check before drinking blind. Acid corrodes a dipped arrow and sickness coats it with poison, so **if you dip a spare arrow and nothing happens, the potion is neither acid nor sickness** (nor oil, polymorph, or holy water). That won't clear paralysis or sleeping, which give no reaction but will still leave you helpless.

**Testing a $200 potion.** The $200 group (enlightenment, full healing, levitation, polymorph, speed) has good payouts but two traps. Uncursed levitation lasts 10–149 turns; blessed levitation lasts 250–299, though you can press `>` to descend early. Polymorph may put you in a form that destroys or sheds body armor. Strip to a shirt and test only when nothing is hunting you.

**Scrolls.** Reading is risky. Some scrolls (destroy armor, amnesia, punishment) are outright harmful. Safest is to price-ID first, then read from safe price groups. If you must test blind: take off your armor before reading a scroll that might be destroy armor. Read from a position where teleportation won't be disastrous.

Confused reading produces different effects for many scrolls and is sometimes useful. A confused scroll of remove curse **randomizes the BUC of your uncursed items** (about a quarter end up blessed, a quarter end up cursed, and half stay uncursed) and leaves already-cursed items cursed. A non-blessed confused scroll only touches your worn and wielded gear (plus loadstones and active leashes); a blessed confused scroll touches your whole inventory. So it's a way to get a few cheap blessings on worn items, not a curse-removal tool. Don't read it confused if you need to uncurse something.

**Rings.** First, confirm the ring is not cursed (altar or pet test). Then put it on. Many rings produce an immediate message or visible effect: you start levitating, you become invisible, you feel stronger. If nothing obvious happens, check your stats and inventory for subtle changes (protection, searching). Take it off quickly if you feel hungry faster than normal (hunger ring) or if monsters seem newly aggressive (aggravate monster).

**Amulets.** BUC-test an amulet before wearing it. Strangulation kills in six turns; remove the amulet immediately, or pray if a curse holds it on. Restful sleep can leave you helpless. An amulet of ESP reveals itself if you go blind while wearing it; reflection becomes apparent when a ray bounces from you.

**Armor.** Magical armor reveals itself when worn: speed boots make you faster, a cloak of invisibility makes you invisible. But trying on unknown armor in a shop is dangerous: if it is cursed you cannot take it off, and the shopkeeper still expects payment. A helm of opposite alignment or dunce cap can even curse itself on wear. **Verify BUC before wearing unknown armor in a shop.** Outside a shop, survival takes priority: at AC 6 or worse, wear found body armor, helms, shields, and cloaks if you cannot test them. Keep testing boots and gloves first; their bad magical variants can be immediately dangerous.

Each type of special armor has a **randomized appearance**, so the same "snow boots" that were safe levitation in your last game might be jumping or fumble boots this time. The four shuffled pools are:

- 4 magical **helms** share 4 appearances: plumed / etched / crested / visored helmet → one of helmet, helm of caution, helm of opposite alignment, helm of [telepathy](#senses-and-perception). (Helm of brilliance is always "crystal helmet"; dunce cap and cornuthaum both look like "conical hat"; that pair *is* a fixed pun.)
- 4 magical **cloaks** share 4 appearances: tattered cape / opera cloak / ornamental cope / piece of cloth → one of cloak of protection, invisibility, [magic resistance](#damage-resistances), or displacement. All excellent.
- 4 **gloves** share 4 appearances: old / padded / riding / fencing gloves → leather gloves or one of the three gauntlet types (fumbling, power, dexterity).
- 7 magical **boots** share 7 appearances: combat / jungle / hiking / mud / buckled / riding / snow boots → one of speed, water walking, jumping, elven, kicking, fumble, or levitation boots.

Prices do not shuffle. They separate the safe boots and cloaks from the cursed ones.

##### Armor Prices {#armor-prices}

| Price | Type     | Possibilities                                                    |
| ----- | -------- | ---------------------------------------------------------------- |
|    10 | Helms    | plain helmet                                                      |
|    50 | Helms    | caution, opposite alignment, or telepathy                         |
|     8 | Boots    | elven (stealth), kicking                                         |
|    30 | Boots    | fumble, levitation (both commonly cursed!)                       |
|    50 | Boots    | speed, water walking, jumping (all desirable)                    |
|     8 | Gloves   | leather gloves (only)                                            |
|    50 | Gloves   | gauntlets of fumbling, power, or dexterity                       |
|    50 | Cloaks   | cloak of protection or displacement                              |
|    60 | Cloaks   | cloak of invisibility or magic resistance                        |

A $30 pair of boots is the warning sign: both candidates are usually generated cursed. A $50 pair is desirable. A $60 cloak is either invisibility or magic resistance. Price cannot separate $8 elven boots from kicking boots, or the three kinds of $50 gauntlets; after a BUC test, wear them and watch the messages.

#### Gray Stones: Four Stones, One Lucky {#gray-stones-four-stones-one-lucky}

Gray stones range from a luckstone worth carrying all game to a loadstone you cannot put down. There are four types:

| Price | Stone                | Effect                                     |
| ----- | -------------------- | ------------------------------------------ |
|     1 | flint **or** loadstone | flint is sling ammunition; loadstone weighs 500 units, usually cursed, and won't drop once carried. Use the kick test (loadstones don't scoot). |
|    45 | touchstone           | Identifies gems when rubbed. Very useful.  |
|    60 | luckstone            | Preserves luck. Essential.                 |

Here's how to tell them apart:

**The kick test.** Kick an unidentified gray stone on the floor. If it scoots away normally, it's not a loadstone. A loadstone is abnormally heavy and resists being kicked. Take off gauntlets of power and kicking boots first, or you may overpower a real loadstone and fool yourself.

**The pick-up test.** Loadstones are cursed when they generate, and a cursed loadstone refuses to be dropped at all. The game prints "For some reason, you cannot drop the stone!" and the stone stays in your pack. If you pick up a gray stone and it weighs you down suspiciously, try to drop it. If you can't, you are stuck with a cursed loadstone until you uncurse it (holy water, scroll of remove curse, prayer). Then you can drop it.

**The price test.** At base price, $60 means a luckstone, $45 a touchstone, and $1 flint or a loadstone. The random unidentified-item surcharge can make a $45 touchstone quote at $60, so only a $45 quote is conclusive by itself.

**The rub test.** Apply (`a`) a gray stone to a gem in your pack (or `#rub` it against one). A touchstone produces a colored-streak message. If the touchstone is **blessed** (or you're an Archeologist or Gnome holding an uncursed one), the streak also identifies the gem. Other gray stones produce similar streak messages, so a streak alone doesn't prove touchstone; an *identification* result does. A cursed touchstone can shatter the gem.

**Location clue.** The luckstone at the bottom of [the Gnomish Mines](#the-gnomish-mines) is guaranteed and always uncursed, so a gray stone at Mine's End is usually it. One layout salts the level with decoys, though — four [mimics](#a-note-on-mimics) disguised as gray stones and a real cursed loadstone. Search (`s`) beside a suspect stone to expose any mimic, then price-ID the two real stones ($60 versus $1) instead of grabbing one blindly; the kick test is unreliable in these cramped niches.

Before picking up a gray stone, kick it and check BUC. A few seconds of testing can spare you a 500-unit loadstone welded to your pack.

#### Naming What You've Learned {#naming-what-youve-learned}

As you gather clues, use the `#name` command to track what you know. You can **call** an entire item class by a name you choose. For example, if you've determined that "fizzy potions" are in the $200 price group, call them "fizzy=$200" so you don't forget. If you later throw one at a monster and it speeds up, you can rename the class to "speed."

**Identification by stacking.** When you pick up an item, the game merges it into an existing slot only if the two are *identical*: same type, same enchantment, same BUC, same erodeproofing. So whether a new item stacks with one you already understand leaks information for free. When a merge actually teaches you something the game says so explicitly: *"You learn more about your items by comparing them."* That message is your cue that the merge propagated a known property (BUC, enchantment, erosion) to the previously unknown side. Two same-appearance items that *don't* merge are a different potion, a different BUC, or one side has been diluted or eroded.

#### A Practical Strategy {#a-practical-strategy}

All of these techniques combine into a workflow:

**At an altar** (priority one). Ferry unknown equipment to the altar and drop each item. Sort the pack by BUC; whether to wear, stash, or discard an object still depends on what it does.

**At a shop** (priority two). Stand on unidentified items and press `:` for quotes. Group them by price and compare them with the tables.

**Engrave-test your wands** once BUC is known and the area is safe. The test costs one charge. Gravel identifies digging; ice cubes identify cold. Be prepared for lightning blindness.

**Experiment cautiously** with the rest. Wear non-cursed rings one at a time. Throw potions at monsters. Read scrolls from safe price groups after removing your armor.

**Save your scrolls of identify** for the items that resist other methods, in roughly this order: **spellbooks first** (reading an unknown high-level book can paralyze you for many turns among whatever is nearby), **amulets** next (all the same price), then the resistance/utility rings in the $200 group, then any wands that engrave-tested ambiguously.

Use the cheapest safe method first: altar, shop, engrave test, controlled use-test, then a scroll of identify.

---

### Provisions and Dining {#provisions-and-dining}

Hunger is the dungeon's most persistent clock: every turn you spend costs nutrition, and when the tank hits empty, you start fainting. Keep fainting without eating and you eventually starve, or get killed by whatever was in the room when you keeled over.

#### How Hunger Works {#how-hunger-works}

Your nutrition starts at 900 and ticks down steadily. The rate depends on what you're doing:

- **Base consumption** costs 1 point per turn (less while sleeping).
- **[Regeneration](#combat-and-defense)** (from a ring or intrinsic) costs extra on odd turns.
- **Encumbrance** costs extra on odd turns if you're **stressed** or worse (burdened alone is free).
- **Rings** usually cost 1 extra nutrition every 20 turns. Regeneration, conflict, and hunger rings cost ten times that while active.

When nutrition drops below certain thresholds, you get warnings:

| Nutrition  | Status    | Effect                                    |
| ---------- | --------- | ----------------------------------------- |
| above 1000 | Satiated  | Overfull. Eating more risks choking.      |
| 151–1000   | Normal    | Fine.                                     |
| 51–150     | Hungry    | Warning message. Time to eat.             |
| 1–50       | Weak      | Strength penalty (-1 Str). Pray if possible. |
| 0 or below | Fainting  | Collapse at random; eat or pray at once.  |

Eat when you get the "Hungry" message; don't wait for "Weak." If you hit Fainting and have no food, pray to your god (see [Divine Relations](#divine-relations)); a willing god cures hunger. If you are merely Hungry and have no food, take the stairs down. A new floor offers corpses and provisions; searching an exhausted one does not.

#### What to Eat {#what-to-eat}

**Eat what is safe.** Unless you are keeping vegetarian conduct, much of your nutrition can come from fresh kills. Check the corpse before you save a ration; freshness alone does not make it edible.

- Eat corpses within 30 to 50 turns of the kill. Past that they risk being tainted, which means food poisoning (lethal without treatment).
- Some corpses grant intrinsic resistances ([poison resistance](#damage-resistances) from killer bees, [fire resistance](#damage-resistances) from fire giants, etc.). Eat these deliberately, even when you are not hungry. See the table below.
- Some corpses are harmful (cockatrice corpses petrify you, green slimes turn you into slime, kobold meat is poisonous). Know which corpses are safe before eating.

**Food rations** (or **gunyoki**, for Samurai) are the emergency backup. 800 nutrition, weight 20, common in shops. Carry two or three for when you don't have a fresh kill in front of you. You don't need to hoard them.

**Lembas wafers** provide 800 nutrition at only 5 weight. Elves gain a quarter more nutrition from them; orcs gain a quarter less.

**Tripe rations** aren't pleasant eating (your character retches) but pets love them. Save tripe for your pet.

**Tins** are preserved food that never spoils, but they are also a *trap if you're sloppy about where you open them*. Opening a tin is an occupation: you cannot act while you work, and a monster can wander up and attack you mid-open. A tin opener finishes in zero or one turn, a dagger in three, an axe in six, and bare hands in as many as fifty turns of helpless effort. Don't pop a tin in a corridor next to a sleeping room. Blessed tins are the one exception: they open in zero or one turn no matter the tool (instantly with a blessed tin opener). A tin of spinach increases your Strength.

**Vegetarian characters** have to live on rations, lembas, fruits, and the small set of non-meat corpses (fungi, molds, lichens, jellies, plus eggs). **Vegans** lose the eggs, so they're stricter still: rations, lembas, fruits, and plant corpses only. Plan ahead. The corpse-pile strategy doesn't work for either, so rations and fruit are the budget items to hoard.

#### Dangerous Foods {#dangerous-foods}

Before eating a corpse, ask:

1. Is it fresh—roughly under 50 turns old?
2. Is it neither a `c` corpse nor Medusa?
3. Is it not green slime?
4. Is it not my own race, unless I have the Cave Dweller or orc exemption?
5. Is it not a dog or cat, unless I accept aggravate monster?

Then check the table below for poison, acid, and unusual effects.

**Cockatrice corpse:** instant death by stoning. Never eat this.

**Acidic corpses** (acid blob, etc.): damage unless acid resistant.

**Poisonous corpses:** damage and stat drain unless poison resistant.

**Rotten corpses:** food poisoning. Pray immediately if affected.

**Cannibalism** (eating your own race): costs 2 to 5 Luck and gives the aggravate monster intrinsic. Cave Dwellers and orcs are exempt.

#### Useful Corpse Effects {#useful-corpse-effects}

Eating for intrinsics pays off through the early and mid game. Each resistance is a *chance* per eat, not a guarantee, so eat *every* one you find, not just the first. The tables below give a verdict for every monster symbol: each row's **general** ruling plus the members that differ. Eat corpses **fresh** (much over fifty turns old risks food poisoning), and a `*` marks a resistance that is only **temporary**.

**No corpse, nothing to eat:** `A` angels, `&` demons, `L` liches, `v` vortices, `y` lights, plus the exceptions named in the tables.

**Undead substitutions:** ordinary vampires, mummies, and race-based zombies leave an already-old corpse of their base race despite carrying the no-corpse generation flag. Treat it as tainted unless you have sickness resistance. Vlad, ghouls, and skeletons leave nothing edible.

**Usually plain meat:** `C` centaurs, `G` gnomes, `J` jabberwocks, `K` Kops, `o` orcs, `O` ogres, `p` piercers, `q` quadrupeds, `t` trappers, `U` umber hulks, `w` worms, `z` zruties. Cats, dogs, leprechauns, and nymphs have important effects listed below.

[]{#vegetarian-safe-corpses} **Vegetarian-safe corpses** (vegan, except the pudding globs, which are vegetarian only):

| Sym | Class | Eating verdict |
|----|-------|----------------|
| `b` | Blobs | Acid blob acidic → acid/stone res\*. Quivering blob → poison res. Gelatinous cube → fire/cold/sleep/shock res. |
| `j` | Jellies | Mostly acidic → acid/stone res\*. Blue jelly → cold/poison res. |
| `F` | Fungi & molds | Molds by color → resistances (yellow→poison, brown→cold+poison, red→fire+poison); only yellow mold is poisonous to eat, but each conveys its resistance, so poison res is a common payoff. Green mold acidic → acid/stone res\*. **Lichen: safe, never rots — carry one.** Violet fungus → hallucination. |
| `P` | Puddings & oozes | Edible **globs** (vegetarian, not vegan): gray ooze → fire/cold/poison res; brown pudding → cold/shock/poison res (acidic). Black pudding isn't vegetarian. **Green slime → never eat, turns you to slime (death).** |

**Everything else (meat):**

| Sym | Class | Eating verdict |
|----|-------|----------------|
| `a` | Ants & insects | Mostly **poisonous** → poison res. Giant ant plain; fire ant → fire res. |
| `c` | Cockatrices | **Never eat — petrifies (death).** Pyrolisk is safe → fire res. |
| `d` | Dogs & canines | Little dog through large dog grant permanent aggravate monster unless you are a Cave Dweller or orc. Hell hounds → fire res; winter wolves → cold res; were-jackal/wolf leave no corpse. |
| `e` | Eyes & spheres | Mostly no corpse. A fresh **floating eye → telepathy**; eat it when the room is safe. |
| `f` | Felines | Kitten through large cat grant permanent aggravate monster unless you are a Cave Dweller or orc. |
| `g` | Gremlins & gargoyles | Gargoyles → stone res\*. Gremlin poisonous → poison res. |
| `h` | Dwarves & humanoids | Plain, but mind flayers → **+Int** (and telepathy). |
| `i` | Imps & minor demons | Imp, homunculus, quasit, and tengu leave corpses. Homunculus is poisonous → sleep/poison res; quasit → poison res; **tengu → teleportitis or teleport control.** |
| `l` | Leprechauns | One chance in two to grant teleportitis. |
| `k` | Kobolds | **Poisonous** (no upside). |
| `m` | Mimics | Edible, but eating one briefly glues you in place. |
| `n` | Nymphs | About one chance in three to grant teleportitis. |
| `r` | Rodents | Plain, but rabid rat poisonous; wererat leaves no corpse. |
| `s` | Arachnids & centipedes | **Poisonous** → poison res (the classic early source). |
| `u` | Unicorns & horses | Plain; unicorns → poison res. |
| `x` | Xans & fantastic insects | Mostly no corpse. Xan poisonous → poison res. |
| `B` | Bats & birds | Bats → brief **stun**. Raven plain; vampire bat poisonous. |
| `D` | Dragons | Babies plain. Each **adult → its breath's resistance**: red→fire, white→cold, blue→shock, orange→sleep, black→disintegration, green→poison, yellow→acid. Green and yellow corpses are also poisonous/acidic. Gray, silver, shimmering plain. Chromatic Dragon → all. |
| `E` | Elementals | Mostly no corpse. Eat a stalker while visible for brief invisibility and stunning; eat one while already invisible for permanent invisibility and see invisible. |
| `H` | Giants & titans | Eat for **+Str**. Fire/frost/storm giants add fire/cold/shock res. |
| `N` | Nagas | Eat for poison res. Red naga also → fire res; black naga also → acid/stone res\* (acidic). |
| `Q` | Quantum mechanics | Poisonous, and eating one randomly speeds *or* slows you. Genetic engineer → random polymorph. |
| `R` | Rust monsters & disenchanters | Plain, but **disenchanter strips one of your intrinsics — never eat.** |
| `S` | Snakes | Mostly **poisonous** → poison res. Garter snake and python plain. |
| `T` | Trolls | Plain (ice troll → cold res). Trolls revive, so eat or move the corpse. |
| `W` | Wraiths | A fresh **wraith → gain a level**. Barrow wights and Nazgul leave no corpse. |
| `X` | Xorns | Eat for stone res\*. |
| `Y` | Apelike creatures | Plain; yeti → cold res. |
| `'` | Golems | Mostly no corpse; flesh golem → fire/cold/sleep/shock/poison res. |
| `@` | Humans & elves | Plain. Elves → sleep res. **Were-humans → lycanthropy.** Nurse → full heal. **Medusa → never eat, petrifies (death).** |
| `;` | Eels & sea monsters | Plain; electric eel → shock res; jellyfish poisonous → poison res. |
| `:` | Lizards | Plain. **Lizard → cures stoning, never rots — carry one.** Newt → a little Pw. Salamander poisonous → fire res. Chameleon → random polymorph. |

A gelatinous cube is the highest-density source of ascension-kit intrinsics in the game; poison resistance off any of the early corpses is the most important single intrinsic to bank.

**Sprig of wolfsbane.** Not a corpse but the same shelf. Eating one cures lycanthropy (see [A note on werecreatures](#a-note-on-werecreatures)). It weighs almost nothing, so keep any you find.

**Puddings, cubes, molds, and blobs can be useful food.** Many offer a chance at an intrinsic. Puddings and acid blobs leave **globs**; globs of one kind merge into a single meal and therefore a single resistance roll. Eat separate globs from the floor before they merge in your inventory.

#### Food Strategy {#food-strategy}

1. Eat safe, fresh corpses as your primary food source.
2. Save food rations and lembas wafers for emergencies.
3. Eat intrinsic-granting corpses deliberately (even if not hungry).
4. Go down when Hungry with no food; pray when Weak or Fainting if it is safe to pray.
5. Buy food from shops when you can afford it.
6. Don't carry more food than you need. It's heavy.

---

### The Apothecary {#the-apothecary}

Potion appearances are shuffled each game. Price and controlled tests are dependable; remembering that last game's bubbly potion was healing is not.

#### The Potion Table {#the-potion-table}

What each potion does, and the uses that aren't obvious from the label. Prices for narrowing an unidentified bottle are in [Potion Prices](#potion-prices); the standouts get fuller treatment in [Key Potions](#key-potions) below. The chance is that potion's share of the random potions you find, unchanged by depth.

| Potion | Chance | Effect and notable use |
| ------ | -----: | ---------------------- |
| **[healing](#potion-healing)** | 11.5% | Restores HP; only a blessed potion also cures blindness. |
| **[water](#potion-holy-water)** | 8% | The "clear potion." Put it on a co-aligned altar for a successful prayer to make holy water. |
| **[extra healing](#potion-healing)** | 4.5% | More HP, always cures blindness and (non-cursed) sickness; can raise max HP. |
| **[gain ability](#potion-gain-ability)** | 4% | Blessed raises *all* stats by 1, uncursed a random one. Save and bless. |
| **gain energy** | 4% | Raises maximum Pw. |
| **[speed](#potion-speed)** | 4% | One non-cursed quaff makes you permanently Fast, the real source of that intrinsic. |
| **restore ability** | 4% | Restores drained stats. Keep one against attribute drain. |
| **see invisible** | 4% | See invisible for a while; one quaff in ten makes it permanent. Shares $50 with booze, fruit juice, and sickness. |
| **invisibility** | 4% | Turns you invisible. |
| **levitation** | 4% | Float over hazards; *blessed* lets you descend at will, otherwise you float until it times out. |
| **monster detection** | 4% | Reveals every monster on the level. |
| **object detection** | 4% | Reveals every object on the level. |
| **fruit juice** | 4% | Harmless food, and what sickness or a unicorn-horn dip turns into. |
| **booze** | 4% | Small nutrition; usually leaves you confused. |
| **confusion** | 4% | Confuses you, the setup for the [confused-scroll](#confused-reading) tricks. |
| **sleeping** | 4% | Puts you to sleep (dangerous to quaff blind); better thrown at enemies. |
| **sickness** | 4% | HP loss and illness (Healers immune); dip missiles into it to poison them. |
| **paralysis** | 4% | Freezes you helpless, a lethal blind quaff; throw it at enemies instead. |
| **hallucination** | 3% | Harmless but disorienting; everything shows as nonsense. |
| **blindness** | 3% | Blinds you, but activates telepathy for the duration if you have ESP. |
| **oil** | 3% | The only potion you can `a`pply (it lights): a safe ID test, lamp fuel, throwable fire. |
| **[gain level](#potion-gain-level)** | 2% | +1 experience level; *cursed* lifts you a dungeon level through the ceiling. |
| **enlightenment** | 2% | Reports your stats and intrinsics; blessed also gives +1 Int and +1 Wis. |
| **[full healing](#potion-healing)** | 1% | Full HP, cures nearly everything, raises max HP. |
| **[polymorph](#potion-polymorph)** | 1% | Polymorphs you, or dip an item to change and ID it. |
| **acid** | 1% | Damages you if you quaff it; throw it for acid damage. |

#### Key Potions {#key-potions}

[]{#potion-healing} **Healing, extra healing, full healing.** Extra healing is the one to stockpile: it always cures blindness and (non-cursed) also cures sickness in addition to restoring HP. Non-cursed extra and full healing raise your maximum HP if the heal would otherwise overflow; blessed versions give the biggest boost. Save every non-cursed extra or full healing potion you do not need immediately for Gehennom and the ascension run.

[]{#potion-gain-ability} **Gain ability.** When blessed, raises *all* your stats by 1. Uncursed raises a random stat. That is liquid gold: save every one until you can bless it.

[]{#potion-speed} **Speed.** One non-cursed quaff grants permanent intrinsic speed; blessing only lengthens the temporary boost layered on top. A self-zapped wand of speed monster instead gives 50–74 turns of temporary speed.

[]{#potion-holy-water} **Holy water.** Put uncursed water on a co-aligned altar and make a successful prayer there; every potion of water on that square becomes holy. Holy water blesses any item you dip into it. Because a dip blesses the whole stack at once, dipping a *stack* of plain water into holy water turns it all holy for a single consumed bottle, so one holy water seeds many more.

Short on water? Make your own. Any potion but acid reduces toward plain water each time it gets wet, so two dips finish the job: the first dilutes it, the second waters it down. A dip treats a whole *stack* at once, so a pile of unwanted potions waters down together. At a fountain, every dip also rolls on the fountain's event table and has a one-in-three chance to dry the fountain. Clear the area first; unwanted potions can become holy-water feedstock, but the process is not risk-free.

[]{#potion-gain-level} **Gain level.** Raises your experience level by 1. Useful for reaching quest eligibility quickly, or converting into something better through alchemy. When cursed, it moves you up one dungeon level instead: you rise straight through the ceiling.

[]{#potion-polymorph} **Identifying a polymorph potion.** A clean test: dip a single arrow or dart into an unknown potion. If the arrow turns into a different item, the potion was polymorph and identifies itself. You spend one arrow and one potion; you save the gamble of quaffing it.

#### Alchemy {#alchemy}

Dip one potion into another and you might create something better, or you might cause an explosion. Most combinations are duds, but the useful recipes are worth memorizing:

| Dip this            | Into this           | Result               |
| ------------------- | ------------------- | -------------------- |
| Healing             | Gain energy/level   | Extra healing        |
| Extra healing       | Gain energy/level   | Full healing         |
| Full healing        | Gain energy/level   | Gain ability         |
| Fruit juice         | Gain energy/level   | See invisible        |
| Speed               | Healing             | Extra healing        |
| Booze               | Gain energy/level   | Hallucination        |
| Levitation          | Enlightenment       | Gain level (2/3)     |

The chain from healing → extra healing → full healing → gain ability via gain energy or gain level is the core alchemy sequence. A handful of common healing potions and a gain energy or two can be transmuted into the rarest potions in the game.

A useful side-loop is **Levitation + Enlightenment → Gain level (2/3 chance, or nothing 1/3)**. Both inputs are reasonably common and individually low-value, but the output is one of the catalysts that feeds the main healing chain. If you find a stack of each, that is a way to manufacture gain-level potions rather than wait for the dungeon to drop them.

**Chained alchemy climbs two at a time.** Alchemy upgrades a stack of potions into a better one, and the healing chain (healing → extra healing → full healing) is the classic run. A dip transmutes a good batch of *fresh* potions at once, up to seven or eight, but everything alchemy produces comes out *diluted*, and a diluted stack converts only two per dip. So the first step of a chain can be a big batch, while every step after works on the diluted output of the last and moves just two potions at a time. Diluted potions work fine (a home-brewed full healing heals exactly like a found one); the dilution only limits chained alchemy.

Alchemy carries an explosion risk: roughly 10% on any non-water combination. An alchemy smock (if you find one) reduces that to about 1 in 30. Do your chemistry in an isolated room, away from your stash, and never dip a cursed potion into another. The target potion is always consumed. A blast also destroys the potion you are dipping, and dipping a cursed potion detonates every time.

#### Neutralizing Ailments {#neutralizing-ailments}

A non-cursed **unicorn horn** cures blindness, deafness, confusion, stunning, hallucination, vomiting, and sickness. It may take several applications; the exact blessed and uncursed odds are in [Key Tools](#key-tools). It does not restore drained ability scores, which now require a potion of restore ability.

If you have no horn, potions cover most of the same ground:

- **Blindness** (and deafness): **blessed healing**, or any non-cursed **extra** or **full healing**. Eating a carrot works too, and temporary blindness (a cream pie, a yellow light) just wears off.
- **Hallucination**: **extra** or **full healing** clear it; plain healing does not. A potion of **sickness** snaps you out of it as well, though its other effects make you pay for it.
- **Sickness** (the food-poisoning timer that kills you): **blessed healing**, non-cursed **extra** or **full healing**, a unicorn horn, or a eucalyptus leaf. Prayer works if your god is listening.
- **Stoning**: eat a lizard or acidic corpse before the countdown ends. Keep a lizard in open inventory; it never rots.
- **Confusion and stunning**: a unicorn horn clears them. A lizard corpse cuts either timer to two turns; otherwise wait them out.

A horn also purifies bad potions by dipping:

- **Blindness, confusion, hallucination** → uncursed water
- **Sickness** → fruit juice

The water can be blessed into holy water and the fruit juice alchemized into see invisible, so nothing is wasted.

---

### The Scroll Rack {#the-scroll-rack}

Scrolls are the dungeon's single-use spells: read once (`r`), triggered, gone. They appear with absurd randomized labels ("ZELGO MER," "DAIYEN FOOELS," "PRATYAVAYAH") that stay consistent within a game but mean nothing until you identify them.

#### The Scroll Table {#the-scroll-table}

Each scroll's effect and best use. Prices for narrowing an unidentified scroll are in [Scroll Prices](#scroll-prices); the standouts get fuller treatment in [Key Scrolls](#key-scrolls) below. The chance is that scroll's share of the random scrolls you find, unchanged by depth.

| Scroll | Chance | Effect and notable use |
| ------ | -----: | ---------------------- |
| **[identify](#scroll-identify)** | 18% | Names an item, but only in your main pack, so consolidate first. Blessed can name several. |
| **light** | 9% | Lights the room, revealing dark corners; blessed lights a wider area. |
| **[enchant weapon](#scroll-enchant)** | 8% | +1 (blessed up to +3); safe to +5, risks destroying the weapon at +6 and above. |
| **[remove curse](#scroll-remove-curse)** | 6.5% | Frees cursed gear; blessed clears your whole inventory. |
| **[enchant armor](#scroll-enchant)** | 6.3% | Enchants worn armor; past +3 (+5 for elven armor or a cornuthaum), further attempts may destroy it. |
| **[teleportation](#scroll-teleportation)** | 5.5% | Teleports you, aimed with teleport control. The lone scroll in a sealed, doorless niche is teleportation. |
| **confuse monster** | 5.3% | Charges your hands so your next few melee hits confuse the target. |
| **[magic mapping](#scroll-magic-mapping)** | 4.5% | Maps the level instantly. Very nice for maze levels. |
| **destroy armor** | 4.5% | Destroys a worn piece; the confused and cursed reads behave differently. |
| **create monster** | 4.5% | Spawns a monster; cursed creates 13, while confused creates acid blobs. |
| **[scare monster](#scroll-scare-monster)** | 3.5% | Drops a fear spot stronger than [Elbereth](#elbereth). |
| **amnesia** | 3.5% | You forget your spells and some weapon skill; blessed spares the spells. Bad to read. |
| **gold detection** | 3.3% | Reveals gold; read confused, it reveals traps instead. |
| **fire** | 3% | Bursts into flame around you, burning scrolls and potions and melting ice. |
| **blank paper** | 2.8% | Nothing written; write your own scroll on it with a magic marker. |
| **food detection** | 2.5% | Reveals food on the level. |
| **earth** | 1.8% | Drops boulders around you, to trap monsters or wall yourself in. |
| **[charging](#scroll-charging)** | 1.5% | Recharges a wand or tool, even a wand of wishing (once only). |
| **[genocide](#scroll-genocide)** | 1.5% | Removes a species; blessed a whole class. Never target your own race or role. |
| **taming** | 1.5% | Tames adjacent monsters; read confused, the area widens to 11×11. |
| **punishment** | 1.5% | Chains a heavy iron ball to you; remove curse frees you. |
| **stinking cloud** | 1.5% | Places a lingering poison-gas cloud at a range you choose. |

#### Key Scrolls {#key-scrolls}

[]{#scroll-identify} **Identify.** The scroll only inspects your **main inventory**: items inside a bag or sitting on the floor are invisible to it. Pull everything out of your bag and pick up nearby unknowns before reading. A blessed scroll identifies one to four items, with a one-in-five chance to identify everything; positive Luck raises the minimum to two. An uncursed scroll gets that blessed result one time in five and otherwise names one item.

[]{#scroll-enchant} **Enchant weapon / enchant armor.** Uncursed enchant *weapon* raises by +1. Blessed raises by up to 3, less the more the weapon is already enchanted (no more than +1 once the weapon is +6 or higher). At +6 or higher, each read has a 2/3 chance of destroying the weapon outright. **Safe ceiling: +5.** Enchant *armor* raises by a small random amount that's larger when armor is unenchanted, larger again for elven or non-magic armor, and +1 extra when blessed. Once worn armor exceeds **+3** (or **+5** for elven / Wizard's Cornuthaum), each further enchant attempt can destroy the armor; the scroll "evaporates" your gear. Blessed scrolls don't bypass that cap.

[]{#scroll-remove-curse} **Remove curse.** Frees you from cursed equipment. Uncursed version works on worn and wielded items only; blessed version uncurses your entire inventory.

[]{#scroll-charging} **Charging.** Recharges wands and rechargeable tools. Save one for a wand of wishing. The risk, charge counts, and ring rules are collected under [Recharging](#recharging).

[]{#scroll-genocide} **Genocide.** Uncursed eliminates a single species; blessed wipes an entire monster class from the game forever. Liches (`L`) are the usual blessed target. **Do not blessed-genocide a class that contains your own race or role.** Dwarves are `h`, Gnomes are `G`, Elves and Humans are `@`, Orcs are `o`; a blessed scroll targeting one of those ends the game with "killed by a scroll of genocide". And `@` is lethal for *every* role, not just elves and humans, since your role-self is an `@`. (That makes the popular "wipe mind flayers" pick a Dwarf trap, since mind flayers are also `h`.) Read one while confused and you genocide your own role's species the same way. Check the symbol before answering the prompt.

[]{#scroll-reverse-genocide} **Reverse genocide.** A cursed scroll of genocide doesn't remove its target; it spawns 4 to 6 of the named species at your feet. The named species must be one that can ordinarily be created. Naming wraiths gives you a corpse pile for level recovery; naming mind flayers buys an Int-fed feast if you're polymorphed into one; naming an easy-to-tame creature gives you instant pet candidates. Don't try unique monsters (the gods refuse).

[]{#scroll-magic-mapping} **Magic mapping.** Reveals the entire level layout; blessed also shows secret doors. Invaluable in [Gehennom](#gehennom)'s maddening mazes, where mapping by hand could take a lifetime you don't have.

[]{#scroll-scare-monster} **Scare monster.** The trick: don't read it. Drop it on the floor and stand on it. It works like a permanent [Elbereth](#elbereth), frightening most monsters away. The first time you pick up an uncursed scroll, it survives but gets "stamped"; the next pickup ends with *"The scroll turns to dust as you pick it up,"* and the scroll is gone. A cursed scroll dusts on the first pickup. Drop where you want the safe spot, not where you will need to relocate.

[]{#scroll-teleportation} **Teleportation.** Uncursed teleports you randomly on the level. Cursed or confused reading sends you to a random dungeon level. With teleport control, *you* choose where you land. The game's most flexible escape hatch.

[]{#scroll-stinking-cloud} **Stinking cloud.** Reading places a poison-gas fog at a visible square within about five squares (about fifteen squares of coverage uncursed, twenty-five if blessed) that blinds anything inside and deals roughly 6–13 HP per turn to anything not poison-resistant. A clean way to clear a throne room or the Wizard's Tower from a safe corridor, as long as *you* are poison-resistant or unbreathing: the gas doesn't pick sides. Kills inside the cloud still count as yours for XP and alignment.

[]{#scroll-fire} **Fire.** Erupts in a burst of flame. Read uncursed or cursed and the explosion is centered on *you*, for only a few points of damage but enough to ignite the scrolls and potions in your pack. Blessed is a different scroll entirely: it deals five times the damage and prompts you to aim at a visible square within about five squares, making it one of the few ranged area attacks a non-spellcaster can carry. Either version burns away green slime if it catches you, so it doubles as a slime cure. Bless it and keep it; an unblessed test-read goes off in your own pack.

#### Confused Reading {#confused-reading}

Many scrolls do something completely different when read while confused. Some of these alternate effects are *better* than the normal ones:

**Confused enchant armor / enchant weapon**, *if uncursed or blessed*, erodeproofs the item instead of enchanting. That is the usual way to rustproof your gear, useful when you need protection from rust more than another +1.

**Confused destroy armor** reaches the same result by the opposite BUC: *if cursed*, it doesn't destroy anything, it erodeproofs a piece of armor. (Uncursed or blessed strips erodeproofing instead.)

**Confused remove curse** randomizes uncursed objects: one chance in four to bless, one in four to curse, and one in two to leave alone. An unblessed scroll reaches only worn and wielded gear, loadstones, and active leashes; only a blessed scroll reaches the whole main inventory. It is a gamble, not a curse-removal method.

**Confused taming** widens the scroll's reach from a 3×3 area around you to 11×11. The trick is scroll-only; confused charm monster just fizzles.

**Confused teleportation** sends you to a random *dungeon level* instead of a random spot on this floor. Useful as a panic button, dangerous if you're shallow and want to keep exploring.

**Confused gold detection** detects every trap on this level instead of gold. Far faster than searching tile by tile.

**Confused charging** restores Pw, and if you're already at full, *raises your max Pw* by 4–16 (6–24 blessed). A spellcaster's permanent buff if you can spare the scroll. Cursed reading zeroes your Pw instead.

The cleanest way to confuse yourself on purpose is a **potion of confusion**: drink one and the timer runs about 16–22 turns. A non-blessed **potion of booze** (Samurai: **sake**) will also confuse you for a few turns.

---

### Wands {#wands}

Wands are reusable magical items that produce directed effects when zapped (`z`, then a direction). They come in three types: **ray wands** fire a beam in a direction that bounces off walls, **beam wands** affect what they hit in a straight line, and **non-directional wands** affect the area around you.

A ray travels seven to thirteen squares before it fades, bouncing off walls, stone, and the edge of the map along the way. Because it keeps going after each bounce, a ray sent down a straight corridor or at a wall a few squares off can come back and hit you as hard as it would a monster. Aim so the beam spends its length heading away from you.

A wand's blessed-uncursed-cursed status doesn't change what it does when it works, but a cursed wand has a small chance, about 1 in 100, to backfire and explode in your hand each time you zap or engrave with it. The blast grows with the charges left inside, so it pays to uncurse a wand you mean to lean on, a wand of death above all.

#### The Wand Table {#the-wand-table}

Unlike scroll and potion prices, wand prices alone rarely pin down a specific wand. A $150 wand is one of thirteen possibilities. The **engrave-test result** in the rightmost column is far more useful: most wands reveal themselves in one zap. See [The Engrave Test (Wands)](#the-engrave-test-wands) for the procedure and [Resolving Ambiguous Engrave Results](#resolving-ambiguous-engrave-results) for the few shared results.

| Price | Wand | Type | Charges when found | Engrave-test result |
| --- | --- | --- | --- | --- |
|   100 | Light                                       | None  | 11–15 | room lights up         |
|   100 | Nothing                                     | BEAM  | 4–8  | no message             |
|   150 | [Digging](#wand-digging)                    | RAY   | 4–8  | gravel flies up        |
|   150 | Enlightenment                               | None  | 11–15 | you feel enlightened   |
|   150 | Magic missile                               | RAY   | 4–8  | bullet holes           |
|   150 | [Make invisible](#wand-make-invisible)      | BEAM  | 4–8  | engraving vanishes ¹   |
|   150 | Opening                                     | BEAM  | 4–8  | no message             |
|   150 | Probing                                     | BEAM  | 4–8  | no message             |
|   150 | Secret door detection                       | None  | 11–15 | doors revealed         |
|   150 | Slow monster                                | BEAM  | 4–8  | bugs slow down         |
|   150 | Speed monster                               | BEAM  | 4–8  | bugs speed up          |
|   150 | [Stasis](#wand-stasis)                      | None  | 3–6  | no message             |
|   150 | Striking                                    | BEAM  | 4–8  | wand fights you        |
|   150 | Undead turning                              | BEAM  | 4–8  | no message             |
|   150 | Locking                                     | BEAM  | 4–8  | no message             |
|   175 | [Cold](#wand-fire-cold-lightning)           | RAY   | 4–8  | ice cubes drop         |
|   175 | [Fire](#wand-fire-cold-lightning)           | RAY   | 4–8  | flames fly             |
|   175 | [Lightning](#wand-fire-cold-lightning)      | RAY   | 4–8  | lightning arcs         |
|   175 | Sleep                                       | RAY   | 4–8  | bugs stop moving ²     |
|   200 | [Cancellation](#wand-cancellation)          | BEAM  | 4–8  | engraving vanishes ¹   |
|   200 | Create monster                              | None  | 11–15 | bugs appear            |
|   200 | [Polymorph](#wand-polymorph)                | BEAM  | 4–8  | engraving rewrites     |
|   200 | [Teleportation](#wand-teleportation)        | BEAM  | 4–8  | engraving vanishes ¹   |
|   500 | [Death](#wand-death)                        | RAY   | 4–8  | bugs stop moving ²     |
|   500 | [Wishing](#wand-wishing)                    | None  | 1  | prompts for a wish     |

*¹ Shared by cancellation, make-invisible, and teleportation. ² Shared by sleep and death.*

#### Key Wands {#key-wands}

[]{#wand-wishing} **Wishing.** Each zap grants one wish. Wands of wishing generate with **1 charge**. Recharge the wand once *before* trying to wrest it, then use the eventual wrested charge last: that gives three wishes. Without a scroll of charging, the initial and wrested charges give two. Plan the wishes before you reach [the Castle](#the-castle).

[]{#wand-death} **Death.** Fires a death ray that instantly kills most things it hits. Reflected by reflection. Blocked by magic resistance. One of the strongest late-game attacks—but a bounce can kill you just as instantly if you lack reflection or magic resistance.

**Sleep.** A sleep ray can end an early run without dealing a point of damage. A bounced ray may leave you helpless for 6d25 turns; aim away from walls and do not rely on waking before the monster arrives.

[]{#wand-digging} **Digging.** Essential utility. Dig through walls to create shortcuts, dig down to escape dangerous situations, dig through rock to reach vaults and hidden areas. A downward zap drops you onto the next floor, the same direction you wanted to go anyway.

[]{#wand-teleportation} **Teleportation.** Zap a monster to send it elsewhere on the level, or zap yourself to escape. It buys distance without having to win the fight first.

[]{#wand-fire-cold-lightning} **Fire, cold, lightning.** Offensive ray wands that bounce off walls. Fire burns scrolls and spellbooks on the floor. Cold freezes water (useful for creating paths). Lightning blinds monsters.

[]{#wand-cancellation} **Cancellation.** Removes special properties from items and monsters. A cancelled monster loses most of its special attacks: a cancelled cockatrice can't petrify, a cancelled mind flayer can't suck brains, and a cancelled clay golem dissolves on the spot. Keep that wand out of a bag of holding: it destroys the bag and everything inside. Pointed at a pile of unidentified scrolls and potions, it converts them into blank scrolls and water, which feed the magic-marker and holy-water production lines.

[]{#wand-polymorph} **Polymorph.** Transforms monsters into random other monsters and items into random other items of the same class. Can be used creatively (polymorph a pile of junk armor hoping for dragon scale mail, polymorph a weak monster hoping for a useful corpse). Risky but powerful.

[]{#wand-make-invisible} **Make invisible.** A self-zap makes you invisible for 31–45 turns. A monster you zap becomes invisible permanently, which is seldom an improvement unless you can still see it. For lasting invisibility on yourself, use a ring or cloak.

[]{#wand-stasis} **Stasis.** Zap it and nothing seems to happen: no ray, no aim, no message. What it really does is seal the level against teleportation for **10–30 turns**. While the seal holds, nobody can teleport: not you, not your foes, not even the covetous monsters that normally blink across the level to reach you. The magic whistle falls silent too. Despite the name, it freezes no one in place; the monsters around you keep moving and swinging. Its use is narrow: pin a teleport-reliant enemy so it cannot flee to heal or harry you from afar, at the cost of sealing away your own escape teleport along with theirs.

**Probing.** A diagnostic wand: zap at a monster to learn its HP, max HP, level, and *what it's carrying*. Useful on shopkeepers, soldiers, and named adventurers whose inventory might be worth the trouble. A stethoscope reports HP and status but not gear; if you want to know what's in the pack, probing is the tool.

#### Resolving Ambiguous Engrave Results {#resolving-ambiguous-engrave-results}

A few engrave-test results are shared by more than one wand.

**"The engraving vanishes!"** belongs to **cancellation**, **make-invisible**, or **teleportation**. Drop a known item and zap each candidate: make-invisible hides it, teleportation sends it elsewhere on the level, cancellation dulls its magic.

**"The bugs on the floor stop moving!"** belongs to **sleep** or **death**. Death is the only $500 ray wand.

**No engrave message at all** narrows to one of six: **nothing**, **opening**, **locking**, **probing**, **undead turning**, or **stasis**. Test each at a safe target:

- **Opening** unlocks a chest or door. **Locking** locks one.
- **Probing** reveals a nearby monster's stats.
- **Undead turning** revives a fresh corpse to its original species (and animates any corpses the target was carrying).
- **Stasis** seals the level against teleportation and gives no outward sign at all, so it is the hardest of the six to pin down; if a later teleport mysteriously fails, that was the wand.
- **Nothing** does nothing.

For non-ambiguous wands, a follow-up zap at a safe target confirms what the engrave-test already suggested: **slow monster** / **speed monster** at a tame or weak monster, **striking** at a closed door, **polymorph** at a pile of junk gear. Avoid zapping unidentified wands at yourself.

#### Recharging {#recharging}

Wands can be recharged with a scroll of charging. The most prized use is on a wand of wishing, where one recharge safely turns a single wish into two. Each successive recharge raises the risk of the wand exploding. The formula is (recharges cubed) / 343, so:

- First recharge: safe, no chance of exploding.
- Second: 0.3%.
- Third: 2.3%.
- Fourth: 7.9%.
- Eighth: 100%.

Use blessed charging for the best results, except on a wand of wishing, which follows its own rules. A fresh wand of wishing has **exactly one** charge. An uncursed or blessed scroll of charging adds **one** wish; blessing does not add another, while a cursed scroll strips the wand to zero. Recharge before wrestling, because the wrested use destroys the wand. The first recharge is safe and a second is a **guaranteed explosion**. The total is two wishes without charging or three with one recharge.

Rings are chargeable too, but the explosion test uses their current enchantment: +0 is safe, +1 explodes one time in seven, +3 about 43%, +5 about 71%, and +7 always. A valuable highly enchanted ring is a poor charging target.

#### Wresting {#wresting}

When a wand has 0 charges, you can still try to zap it. There is a 1/121 chance of "wresting" one final charge from the wand before it turns to dust. That is a last resort, but it works on wands of wishing too.

#### Polymorph as a Tool {#polymorph-as-a-tool}

Self-polymorph has uses worth the risk. A wand of polymorph zapped at yourself, a potion of polymorph, the polymorph self spell, or stepping on a polymorph trap can all roll a new form for you. With **polymorph control** (the ring or intrinsic) the game lets you *choose* the form.

- **Travel where your legs can't.** A xorn phases through walls. An eel breathes underwater. A vampire becomes a bat or a fog cloud and slips under doors. A floating eye drifts past traps you can't disarm.
- **Bring your own resistances and attacks.** A red dragon form gives you fire breath. A brown mold form freezes anything that hits you in melee. A purple worm swallows your problems whole. Most monster powers are yours when you wear their shape.
- **Borrow another body.** The new form rolls its own full HP. Your ordinary HP remains underneath and returns when the form ends.
- **Escape cursed body armor.** A *bigger* form breaks out and destroys the suit. A *smaller* form drops it intact into your inventory, where you can holy-water it back to neutral.
- **Eat what you can't.** A metallivore form eats iron bars. A green dragon shrugs off poisonous corpses.

Without polymorph control, a failed Constitution check can cause system shock for up to 30 HP. Cursed polymorph objects do not strip control; the danger is transforming without it. Do not try at low HP.

A wand of polymorph zapped at a *pile* of junk items reshuffles each one into a random item of the same class. That trick is called "polypiling," because it can turn a pile of dross into a selection of stuff you need. Drop the fodder on a square far from your real pack: a misaimed zap that catches your bag of holding rolls the bag too. Max your Luck first. When polypile fails, one of the zapped items can turn into a hostile golem made from its material, and every point of Luck lowers the chance of that going wrong.

---

### Rings and Amulets {#rings-and-amulets}

You can wear two rings (one on each hand) and one amulet (around your neck). Put one on with `P` and take it off with `R`, the pair that handles rings and amulets (armor uses `W` and `T`).

#### The Ring Table {#the-ring-table}

| Price | Ring                           | Notes                          |
| ----- | ------------------------------ | ------------------------------ |
|   100 | Adornment                      | +CHA, chargeable               |
|   100 | Hunger                         | Increases hunger (auto-curse)  |
|   100 | Protection                     | +AC, chargeable                |
|   100 | Protection from shape changers | Useful against werebeasts      |
|   100 | Stealth                        | Reduces noise                  |
|   100 | Sustain ability                | Prevents stat drain            |
|   100 | Warning                        | Shows nearby monsters          |
|   150 | Aggravate monster              | Bad (auto-curse)               |
|   150 | Cold resistance                | Resist cold attacks            |
|   150 | Gain constitution              | +CON, chargeable               |
|   150 | Gain strength                  | +STR, chargeable               |
|   150 | Increase accuracy              | +hit, chargeable               |
|   150 | Increase damage                | +dmg, chargeable               |
|   150 | Invisibility                   | You become invisible           |
|   150 | Poison resistance              | Immune to poison               |
|   150 | See invisible                  | See invisible creatures        |
|   150 | Shock resistance               | Resist electric attacks        |
|   200 | Fire resistance                | Resist fire attacks            |
|   200 | [Free action](#ring-free-action) | Immune to paralysis          |
|   200 | Levitation                     | Float in the air               |
|   200 | Regeneration                   | Heal faster (costs hunger)     |
|   200 | Searching                      | Auto-search each turn          |
|   200 | [Slow digestion](#ring-slow-digestion) | Reduces hunger            |
|   200 | Teleportation                  | Random teleports (auto-curse)  |
|   300 | [Conflict](#ring-conflict)     | Monsters fight each other      |
|   300 | Polymorph                      | Random polymorphs (auto-curse) |
|   300 | Polymorph control              | Choose polymorph form          |
|   300 | [Teleport control](#ring-teleport-control) | Choose teleport destination |

Rings marked "auto-curse" generate cursed 90% of the time, and a cursed ring can't be removed until you uncurse it.

#### Key Rings {#key-rings}

[]{#ring-free-action} **Free action** prevents paralysis, a common way for a late-game monster to take enough unanswered turns to kill you.

[]{#ring-teleport-control} **Teleport control** turns random teleportation into aimed movement and makes teleportitis useful.

[]{#ring-conflict} **Conflict** makes monsters attack one another. It can dismantle a crowded room, but it also makes your pets attack you.

[]{#ring-slow-digestion} **Slow digestion** greatly reduces ordinary hunger. It does not make you immune to the extra drain from other worn rings.

**Aggravate monster** roughly doubles the effective dungeon depth for monster generation, capped at 50. That is usually disastrous. A prepared chaotic player may use it briefly to attract difficult sacrifice fodder, then remove it. Since the ring generates cursed 90% of the time, that is not an experiment to perform without a BUC test.

A blessed potion of polymorph grants you polymorph control for that specific transformation: you choose the form, no ring required. That makes the ring of polymorph control less of a critical acquisition: you no longer need to find it or wish for it just to do a single controlled polymorph. The ring remains useful for repeated transformations. Save that wish for something else.

**The hidden cost:** an ordinary worn ring costs 1 nutrition every 20 turns; conflict, regeneration, and hunger cost 1 every 2 turns. Keep situational rings in inventory and put them on when needed. Free action is the exception: protection against an unexpected paralysis is worth its modest food cost.

#### Amulets {#amulets}

Amulets are simpler in theory but harder to identify: they all cost $150, so price is no help. You'll need to wear-test or use a scroll of identify. The stakes are high, because the range runs from "saves your life" to "slowly strangles you to death":

| Amulet                 | Effect                                      |
| ---------------------- | ------------------------------------------- |
| Life saving            | Revives you once from death, then crumbles  |
| Reflection             | Reflects ray attacks                        |
| Magical breathing      | Survive underwater and without air          |
| ESP                    | Detect monsters via telepathy               |
| Unchanging             | Prevents involuntary polymorph              |
| Change                 | Changes your sex when worn, then disintegrates |
| Versus poison          | Poison resistance                           |
| Flying                 | Grants flight (new in 5.0)     |
| Guarding               | +2 AC and +2 MC (new in 5.0)   |
| Strangulation          | Slowly kills you (usually cursed)           |
| Restful sleep          | Puts you to sleep randomly (usually cursed); grants +1 HP/turn regen while asleep |

BUC-test an unknown amulet before putting it on. An amulet of strangulation starts a six-turn death timer: take it off immediately, or pray if a curse prevents removal.

#### Key Amulets {#key-amulets}

**Life saving** revives you to 50 HP plus a Constitution bonus, capped at your maximum, then crumbles and costs 1 Constitution. It cannot save death by genocide. Once identified, wear it and forget it; the danger you failed to anticipate is the one it is for.

**Reflection** is excellent if you didn't get a shield of reflection from Perseus's statue or elsewhere. Wearing it as an amulet frees up your shield slot for a small shield or two-weapon fighting.

**Guarding** provides +2 AC and +2 magic cancellation (MC). That is a new addition in 5.0 that neatly solves the MC puzzle: pair it with a cloak of magic resistance (MC1) and you reach MC3, freeing you from needing the less versatile cloak of protection.

**Magical breathing** prevents drowning. It earns its slot at Medusa's island and becomes essential on the Plane of Water.

**Flying** is the late-addition cousin of levitation: you stay in the air the same way, but you can still pick things up and choose to drop down on your turn. The bonus is that **your steed flies with you**. A flying warhorse skips over moats, pools, and [the Castle](#the-castle)'s drawbridge, and crosses Medusa's island edge to edge. Steeds cannot wear speed boots, and your speed does not add to theirs.

**Restful sleep** puts you to sleep randomly and is usually cursed, so an untested one may not come off. Wearing it while asleep grants +1 HP per turn via accelerated regeneration. In a fully secured room with the door spiked shut, that turns a near-useless item into a slow field hospital.

---

### Tools of the Trade {#tools-of-the-trade}

The `(` symbol covers the dungeon's most eclectic category: pickaxes, magic lamps, unicorn horns, musical instruments, crystal balls, and bags that eat other bags.

#### Containers {#containers}

Every adventurer eventually runs out of carrying capacity, and the bag of holding is the dungeon's most coveted answer.

| Container      | Weight | Special                                  |
| -------------- | ------ | ---------------------------------------- |
| Sack           | 15     | Basic storage                            |
| Oilskin sack   | 15     | Protects contents from water             |
| Bag of holding | 15     | Reduces weight of contents dramatically  |
| Bag of tricks  | 15     | Creates monsters when opened (not a bag) |
| Large box      | 350    | Comes with 0 to 3 items (0 to 5 if locked) |
| Chest          | 600    | Comes with 0 to 5 items (0 to 7 if locked) |
| Ice box        | 900    | Preserves corpses from rotting           |

Note the weights. Sacks are 15 (carry one). Boxes and chests are furniture, not luggage: a large box weighs 350, a chest 600, an ice box 900, comparable to your *entire* carrying capacity. Use them as floor stash, not as something to drag from level to level.

A **bag of holding** changes the effective weight of its contents: blessed quarters it, uncursed halves it, and cursed doubles it. [Sokoban](#sokoban)'s prize is a bag of holding half the time; if you receive the amulet instead, a bag is a strong wish candidate.

A warning: **never** put a wand of cancellation, another bag of holding, or a charged bag of tricks inside a bag of holding. The bag explodes for 6d6 damage, scatters its own contents, and destroys about one item in thirteen.

If you find a *cursed* bag of holding (in a bones pile, perhaps), don't open it. Drop it on the floor and zap a wand of cancellation at it. The explosion rule only fires on insertion, not on a zap, so the bag uncurses safely.

The identically-named **bag of tricks** is a different beast, and it punishes the obvious move: try to *loot* it like a container and it grows a huge set of teeth and bites you (painful, but at least a free identification). To use it, **apply** it (`a`) instead. Each charge summons a random hostile monster onto your square (rarely a small swarm). It carries nothing, but standing beside an altar it makes a tidy sacrifice-and-experience engine. Don't apply it when you're weak or cornered, since deeper down it can disgorge something dangerous.

##### Carrying capacity {#carrying-capacity}

Your carrying capacity is roughly **25 × (Strength + Constitution)
+ 50**, capped at 1000. Average human stats land you near 950; a low-Str spellcaster might start closer to 700. As you load up, the status line walks through these tiers:

| Tier         | When                                    | Cost                                                                     |
| ------------ | --------------------------------------- | ------------------------------------------------------------------------ |
| Unencumbered | weight at or below capacity             | None                                                                     |
| Burdened     | up to about 1.5× capacity               | Movement −25%; nutrition fine                                            |
| Stressed     | up to about 2× capacity                 | Movement −50%; extra hunger on odd turns; **exercises Str** (free upside)|
| Strained     | up to about 2.5× capacity               | Movement −75%; extra hunger; combat exerts you (1 HP every 3 attacks); exercises Str but abuses Dex |
| Overtaxed    | up to about 3× capacity                 | Movement −87.5%; same hunger and exertion; pass out instead of dying; abuses Dex and Con |
| Overloaded   | beyond 3× capacity                      | You cannot move                                                          |

Practical rule: stay **Unencumbered** in normal play, accept **Burdened** during loot runs, and never linger at **Stressed** or worse without a reason. A blessed bag of holding cuts the effective weight of its contents to roughly a quarter; an uncursed bag halves it, while a cursed bag doubles it.

**Running out of inventory letters.** Weight isn't the only limit. Your inventory has **52 slots** (`a-z` plus `A-Z`), and a 53rd item hits *"Your pack is too full."* Stackable items consolidate into a single slot only when the game can tell they are the same thing. Five identified scrolls of identify share one letter, but identified and unidentified scrolls of the same type stay in separate slots, and weapons of different enchantments do not merge. Clutter is usually an identification problem in disguise: the more you identify, the more your inventory consolidates.

The bag of holding solves that too. Items inside any container do not count against your 52, so a stash of twenty potions in a bag of holding costs you a single letter. The `#adjust` command lets you swap items between letters, force-merge stacks that didn't merge, or split a stack to a new letter; it is purely relabeling, with no game effect.

Intelligent monsters can loot unlocked containers and carry containers away, but they refuse to open a locked one. Lock any floor stash before leaving it unattended. The Castle residents likewise cannot empty a locked chest.

#### Unlocking Tools {#unlocking-tools}

The dungeon is full of locked things, and brute force is noisy and slow. A **skeleton key** is the most reliable ordinary tool (70%+ success on doors, 75%+ on boxes). A **lock pick** (Samurai: **osaku**) is respectable. A **credit card** is the worst but still better than kicking. Carry one of the three; they are light, and locked doors are everywhere.

Skeleton keys and lock picks can also **lock** what they can unlock, so they double as your way to relock a chest after stashing loot. Credit cards are unlock-only.

#### Light Sources {#light-sources}

**Oil lamps** and **candles** light dark corridors. A **magic lamp** burns indefinitely and can still be rubbed while lit. Rub it (`#rub`) and there's a 1-in-3 chance the djinni emerges, then a chance it grants you a wish (80% if the lamp is blessed, so ~27% wish per rub overall), less if it isn't. Try again on the same lamp until the djinni shows. Use it for light until you can bless and rub it; lighting it does not consume the wish.

The **Candelabrum of Invocation** is a unique candelabra found in [Vlad's Tower](#vlads-tower). It's one of three items needed for the invocation ritual to enter [Moloch's Sanctum](#molochs-sanctum). You'll need seven candles to fill it, so start hoarding candles when you find them.

#### Musical Instruments {#musical-instruments}

Any tonal instrument (wooden flute, magic flute, tooled horn, frost or fire horn, bugle, or harp) can play the passtune at [the Castle](#the-castle) drawbridge. The tune and its two sources are described in [The Castle](#the-castle). A **magic harp** (Samurai: **magic koto**) charms monsters into tameness; a wooden harp is just a **koto**. A **magic flute** puts them to sleep. A **drum of earthquake** creates pits around you, which is as chaotic as it sounds.

A tooled horn or leather drum wakes and scares nearby monsters; the drum also deafens you for 30–49 turns. A wooden flute produces only sound.

#### Other Notable Tools {#other-notable-tools}

| Tool               | Use                                           |
| ------------------ | --------------------------------------------- |
| Pickaxe / mattock  | Dig through walls and floors                  |
| Unicorn horn       | Cure confusion, blindness, sickness, hallucination, stunning, vomiting, deafness |
| [Stethoscope](#tool-stethoscope) | Check HP and status of a monster      |
| Tin opener         | Open tins in one turn                         |
| Tinning kit        | Preserve corpses as tins                      |
| Can of grease      | Coat armor, weapons, bags                     |
| Blindfold          | Voluntarily go blind (useful for telepathy)   |
| Towel              | Wipe cream pie from face, use as blindfold    |
| [Magic marker](#tool-magic-marker) | Write scrolls and spellbooks on blank paper |
| [Crystal ball](#tool-crystal-ball) | Name a symbol and scan the level for it |
| Bell of Opening    | Invocation item; carried by your quest nemesis, looted from their corpse |
| Leash              | Tie a pet to you so it follows through stairs |

#### Key Tools {#key-tools}

Apply a non-cursed **unicorn horn** to cure confusion, blindness, sickness, hallucination, stunning, vomiting, and deafness: most of the status ailments that matter. Carry one at all times.

Bless your horn. A blessed horn can fix up to seven ailments in a single application; an uncursed horn maxes out at three, with a 35% chance of doing nothing even when you have troubles to fix. A cursed horn will *inflict* a random ailment from the same list (including the new deafness one), so be sure of bless status before applying. Horns don't get used up, so a non-emergency test apply is free.

[]{#tool-stethoscope} The **stethoscope** reports a monster's HP and condition. Its first use on each game turn is free, so checking does not surrender your move; further uses that turn cost time.

A 5.0 caveat: the unicorn horn **no longer restores lost ability scores**. Drained Strength, Intelligence, Wisdom, and so on now require a *potion of restore ability* (or its spell) to bring back. The horn remains the universal cure for *status* problems, but not for attribute drain. Budget for restore ability separately.

[]{#tool-magic-marker} The **magic marker** is a printing press for scrolls (and, more expensively, spellbooks). A fresh marker has 30-99 charges; one non-cursed scroll of charging restores it to at least 50 (more if the scroll is blessed), but only once. The second recharge attempt always fails. Each write costs roughly half to all of the target scroll's basecost: magic mapping 4-7 charges, identify 7-13, enchant weapon / enchant armor / charging 8-15, teleportation 10-19, and **genocide 15-29**. Spellbooks cost about 10 × spell level: a level-3 book averages ~22 charges, a level-7 ~52.

To write a scroll intentionally, enter a label you have seen; that produces the scroll bearing that label even if you have not formally identified it. If charges run out mid-write, scrolls disappear entirely (paper + charges wasted); a spellbook's paper survives but the writing fades.

Blank paper is the marker's fuel, and you can make your own: **dip any unwanted scroll or spellbook in water and it washes blank.** A pool or moat does it cleanly and every time; a fountain works too but rolls the usual fountain risks on top. So spare scrolls of light or create monster aren't junk, they're feedstock for a scroll of identify or enchant weapon.

High-value writes include **genocide** (common class targets are L, &, and h, though uniquely named demon lords survive; see [Genocide](#scroll-genocide) for the race warning), **charging** (uncursed or blessed adds one wish to a wand of wishing, for 8–15 marker charges), and **enchant weapon / enchant armor**. Never recharge a wand of wishing twice.

The marker also feeds the **wraith feast**: a cursed scroll of genocide on a non-graveyard level summons four to six wraiths at your feet (see [Farming wraiths](#a-note-on-wraiths)).

The **tinning kit** turns a corpse (`a`pply, then select the corpse) into a tin: up to 50 nutrition of preserved food that keeps indefinitely. Tinning eliminates raw-corpse poison and acid damage as well as neutralizing spoilage, so a tinned killer bee or acid blob is safe to eat with no resistance, and the intrinsic grant still applies. The kit lets you seek poison resistance without taking poison damage; acid resistance from a corpse lasts only 3–18 turns, so it cannot be banked the same way. Don't tin a cockatrice, and don't eat a cockatrice tin; you petrify on the spot.

The **pickaxe** and the heavier **dwarvish mattock** dig through most walls and floors. Apply (`a`) and pick a direction for a sideways tunnel, or apply downward to chip through the floor for a quick escape. A wand of digging is faster in a straight line but burns charges. Sokoban is non-diggable; in Gehennom, the Valley floor, Sanctum, and the two towers resist digging, while the filler mazes do not. Applied to a statue, a pickaxe also breaks it (dropping any contents, or animating the sculpted monster if it is a statue trap).

[]{#tool-crystal-ball} The **crystal ball** is a one-question oracle when applied (`a`): name a map symbol, and the ball scans the whole level for that symbol. Each use consumes one charge; a scroll of charging restores a few. A spent ball still applies but shows nothing useful, just colored haze.

Intelligence determines whether each reading lands or backfires. The Int check is rolled against an "oops" threshold of 8 for a quest artifact, 16 for a blessed ball, or 20 for uncursed; rolling over the threshold triggers a misfire. Misfires range from harmless ("too much to comprehend") through confusion, blindness, and hallucination to (one outcome in five on an unblessed non-artifact ball) an explosion that hits you for about 1d30. A cursed ball misfires every time while charged. An altar reveals BUC; holy water blesses the ball.

The **can of grease** coats armor against hugs, wraps, sticky attacks, and mind-flayer tentacles. It does not stop nymph theft, Rider grabs, or weapon snatching. Greasing a bag protects its contents from water until the coating wears off.

---

### The Armory {#the-armory}

This section covers choosing your equipment; the [Weapons Tables](#weapons-tables) and [Armor Tables](#armor-tables) appendices give the full stats for every item.

#### Armor and AC {#armor-and-ac}

Armor Class is what decides how often you get hit, and it's the most important defensive number in the game. Each point you push down means more monster swings whiff past you. AC starts at 10 and drops as you add protection; lower is better. At AC −10 or below you're quite difficult to damage with physical attacks; the practical target for an ascension kit is **AC −20**, with diminishing returns past −25.

If your AC is **6 or worse**, do not wait indefinitely for an altar: ordinary body armor, helms, shields, and cloaks are usually worth the risk. Test boots, gloves, and conical hats before wearing them; their bad magical forms can trap or cripple you.

| Slot | Wear now | Look for | Use care |
| ---- | -------- | -------- | -------- |
| Body | Best suit that does not overburden you | Dragon scale mail | Monks lose 20 to-hit; metal hurts casting |
| Cloak | Any useful non-cursed cloak | Magic resistance, protection, displacement | Mummy wrapping blocks invisibility |
| Helm | Ordinary helm when AC is poor | Brilliance, caution, telepathy | Test conical hats |
| Gloves | Only after a BUC test | Power or dexterity | Fumbling gloves are usually cursed |
| Boots | Only after a BUC test | Speed, water walking, jumping | Levitation and fumble boots are usually cursed |
| Shield | If you use one hand and are not a Monk | Reflection or a resistance | Any shield blocks two-handers and penalizes casting |
| Shirt | Wear when convenient | Either kind; enchant it | A visible shirt worsens shop prices |

##### Body suits {#body-suits}

Body armor is the heaviest slot you wear and the biggest single source of AC. Monks fight best with this slot empty: **any** body suit, dragon scale mail included, costs them −20 to-hit on Martial Arts. Late game some wear dragon scale mail anyway, for the AC and intrinsic, not because it dodges the penalty.

The lowest rung of body armor is mostly leather. The **leather jacket** (1 AC, 30 zm) is the half-suit version, light enough to throw on while you sort through bags but not really a primary suit. **Leather armor** (2 AC, 150 zm) is plain heavy leather, the Cave Dweller's starter and a Wizard's mid-game default if mithril hasn't appeared yet. Both are penalty-free for casters and neither rusts. **Studded leather armor** (3 AC, 200 zm) is what the name says, leather reinforced with metal studs, still casting-safe.

Iron pieces start small and work up. **Ring mail** sews flat iron rings to a backing rather than interlocking them, lighter protection than chain at 3 AC for the plain version and 2 AC for the orcish one. **Scale mail** (4 AC, 250 zm) sews iron scales to a backing the way fish overlap their plates, the Roman lorica squamata in look. **Chain mail** (5 AC, 300 zm) is what most people picture when they say "armor": thousands of interlocking iron rings sewn to a tunic. Orcish chain mail comes in a point worse and looks like someone's first attempt.

**Dwarvish mithril-coat** gives 6 AC at only 150 weight and does not rust. The **elven mithril-coat** gives 5 AC at the same weight. Mithril is still metallic: its spellcasting penalty is the same as plate mail's, though a robe halves that penalty. For a caster, the AC may still justify the trade.

The reliable heavy armors are **splint mail** (iron strips riveted to a leather backing) and **banded mail** (overlapping horizontal iron bands wrapped around a tunic). Both come in at 6 AC, 350 to 400 zm: only one point of AC behind plate for noticeably less weight. For most non-Wizard runs, one of these two is the practical body slot until you reach dragon scales.

At the top is **plate mail**, the late-medieval European knight's full harness, articulated steel plates strapped over a padded jacket. The heaviest body suit in the dungeon (450 zm) and the strongest (7 AC). The bulk pushes Knights and Valkyries toward Burdened in a hurry, and the iron raises your spellcasting failure rate. Samurai see the same item on screen as **tanko**. **Crystal plate mail** is the same shape rendered in clear glass: no rust risk, same AC, much rarer. **Bronze plate mail** is the older Mediterranean ancestor at one point worse (6 AC), copper-class so it corrodes rather than rusts.

For dragon scales and dragon scale mail, see [Dragon Scale Mail](#dragon-scale-mail) below.

##### Shirts {#shirts}

Shirts sit *under* your body armor. They give 0 base AC, but they never penalize spellcasting and they weigh almost nothing, so a +5 enchanted shirt is doing real work. The two shirts in the dungeon are mechanically identical 5-zm cloth tops: the **Hawaiian shirt** is the Tourist starter, the **T-shirt** is the plain alternative. Both are layered first when donning armor, so getting a shirt on once you're already wearing a body suit means a full strip-down and re-armor.

##### Cloaks {#cloaks}

Cloaks layer over the body suit and contribute modest AC (0 to +3), magic cancellation, and often a useful intrinsic. They also protect the suit beneath from some attacks.

The plain regional cloaks (**orcish cloak**, **dwarvish cloak**, **leather cloak**) are all 0-1 AC at 10-15 zm and distinguished mostly by who carries them. **Elven cloak** is the standout in that group: 1 AC and grants stealth, which is more useful than the AC itself.

**Oilskin cloak** is a waxed-canvas sailor's outer layer; in the dungeon it gives 1 AC, MC2, and resistance to monster grab attacks. **Robe** is exactly what a spellcaster wears: 2 AC, MC2, and most importantly it cancels most of the metal-armor spellcasting penalty. A Wizard in chain mail and robe casts almost as well as in just leather. Monks start with a +1 robe and should keep it. **Alchemy smock** is the chemist's apron: 1 AC, MC1, plus poison resistance. It is excellent protection before you have the intrinsic.

**Mummy wrapping** is what it sounds like, with one important quirk: it blocks invisibility while worn. Most heroes who pick one up should drop it; 0 AC and MC1 from any other cloak come without the invisibility lockout.

Four magical cloaks deserve special attention:

- **Cloak of protection** contributes MC3 on its own, the highest of any single piece, and 3 AC. The late-game cloak slot for any hero who already has magic resistance from another source.
- **Cloak of magic resistance** is the simplest, lightest source of magic resistance in the dungeon and a fixture of every mid-game kit before dragon scale mail.
- **Cloak of displacement** makes monsters swing at your phantom image, complementing low AC instead of competing with it.
- **Cloak of invisibility** grants invisibility, mostly an offensive bonus since monsters miss more often.

##### Helmets {#helmets}

The helm slot covers your head and protects against the dungeon's small surprises: rolling-boulder traps, hidden falling rocks, ceiling drops from tunnel collapses. Most helmets penalize spellcasting because they're metal; Wizards do well in cloth caps.

The plain helmets (**orcish helm**, **dwarvish iron helm**, **helmet (kabuto)**, **dented pot**) are iron pieces at 1-2 AC and 10-40 zm. Serviceable for fighters, but each adds 4 points to a spell's failure calculation. **Elven leather helm** is the spellcaster's compromise: 1 AC at 3 zm, leather-class, no penalty. **Fedora** is the Archeologist's starting hat; an Archeologist wearing one gains +1 Luck.

**Cornuthaum** is the Wizard's pointy hat: 0 base AC but MC1, and grants clairvoyance to a Wizard while blocking clairvoyance for everyone else. **Dunce cap** is the cornuthaum's evil twin: auto-curses on wear, sets Int and Wis to 6, refuses to come off without remove curse. Both can be BUC-tested. Their base prices also separate them: a cornuthaum costs 80 zm and a dunce cap 1 zm.

**Helm of brilliance** adds its enchantment value to both Int and Wis while worn. A +3 helm gives +3 Int and +3 Wis, a spellcaster's mid-game goal. The **helm of caution** puts the warning intrinsic in the helm slot: nearby monsters appear as colored threat markers without your having to see them, cheap and light, the best early-game helm pickup in the game. **Helm of telepathy** detects minds within eight squares while your eyes are open; while blind, its telepathy reaches the whole level.

**Helm of opposite alignment** flips your alignment while worn (and generates cursed 9 times in 10), mostly a trap but occasionally useful on purpose: sacrifice on a cross-aligned altar, claim the opposite alignment's quest artifact, or pick a different altar on the Astral Plane.

##### Gloves {#gloves}

Gloves are the smallest armor slot (1 AC across the board) but they do critical defensive work: with gloves on you can pick up a **cockatrice corpse** safely and even wield it as a weapon. Without gloves the touch petrifies you immediately. (See [Petrification](#petrification-stoning).)

**Leather gloves** (Samurai see **yugake**) are the default at 1 AC and 10 zm, leather-class, no penalty. **Gauntlets of power** are the dungeon's strength shortcut: wearing them sets Str to 25 regardless of what it was, instantly turning a Wizard into a passable melee threat. **Gauntlets of dexterity** add their enchantment value to Dex. A +3 pair gives +3 Dex on top of any natural Dex you've trained.

**Gauntlets of fumbling** are a trap item: they generate cursed 9 times in 10 and make you fumble constantly. Altar-test an unidentified pair before putting it on. A cursed glove plus a cursed wielded weapon is the dungeon's classic deadlock: neither comes off without a scroll of remove curse, holy water, or prayer.

##### Boots {#boots}

Boots are the home of movement intrinsics (water walking, jumping, levitation, speed), so for most builds the slot is chosen for what the boots *do* rather than the AC (1-2) they add.

The plain boots come in two sizes and a few weights: **low boots** (1 AC) and **high boots** (2 AC) are light leather, the everyday default. **Iron shoes** (2 AC) and **kicking boots** (1 AC) are heavier iron variants for kickers and fighters.

The useful magical boots change how you move:

- **Speed boots** grant the very-fast intrinsic, so two of every three turns are free actions. The most-wished-for boots in the game.
- **Water walking boots** let you walk on water, critical for the Castle drawbridge moat and the upper Plane of Water. Save them for the moment.
- **Jumping boots** add the `#jump` command, so you can leap to a nearby square in combat without casting the spell.
- **Elven boots** grant stealth and are a dependable choice for Rogues and Rangers.

The **trap boots** generate cursed 9 times in 10:

- **Levitation boots** float you constantly and refuse to come off if cursed.
- **Fumble boots** trip you every 1–20 turns, costing two turns.

Altar-test boots before putting them on. A cursed pair won't come off until you break the curse, and levitation boots can leave you floating helpless over a moat.

##### Shields {#shields}

Shields contribute 1–2 AC and force a choice elsewhere in the loadout. Any shield prevents two-weapon combat and two-handed weapons. Any shield also adds a flat spellcasting penalty; one heavier than 30 weight quarters the final success chance. A Monk can wear a shield, but loses the Martial Arts to-hit bonus while doing so. Shields do not block unseen rays or arrow traps.

The plain shields (**small shield**, **elven shield**, **orcish shield**, **Uruk-hai shield**, **dwarvish roundshield**) range from 1 to 2 AC with no special properties. The **small shield** at 1 AC, along with the two 30-weight resistance shields, avoids the severe quartering of spell success. All three still impose the flat shield penalty; a dedicated caster is strongest with the slot empty.

**Large shield** and **dwarvish roundshield** are 2 AC but heavy (100 weight). Their restriction is the same as every other shield: while one is worn, you cannot wield a two-handed sword, battle-axe, or polearm.

**Shield of drain resistance** (1 AC, drain resistance) and **shield of shock resistance** (1 AC, shock resistance) grant their named resistances. Drain resistance has no non-artifact source outside that shield, and the shock version is one of the most convenient shock resistors in the game. The **shield of reflection** is silver, 2 AC, and grants reflection, the property that bounces death rays, cones of cold, and breath weapons back at the caster. It "saves" the body slot in the canonical ascension kit by providing reflection in the shield slot, leaving the body suit free for gray dragon scale mail (which gives magic resistance instead).

**Erosion, enchantment, and Protection** each get their own section below: armor rusts, burns, or corrodes (see [Erosion and Proofing](#erosion-and-proofing)); scrolls of enchant armor add enchantment with destruction risk above +3 (see [Enchantment](#enchantment)); and donating gold to a priest of your alignment buys intrinsic Protection that stacks with worn AC and can raise MC0 to MC1 (see [Donating to Priests](#donating-to-priests)).

[]{#magic-cancellation} **Magic cancellation (MC).** Worn armor contributes a hidden defense, capped at 3. MC can negate the secondary effect of level drain, poison, paralysis, sleep, slowing, confusion, stunning, lycanthropy, disease, sliming, and teleporting touch. It does not block gazes, breath weapons, cockatrice touch, or brain sucking. The chance is set by MC level:

| MC | Block chance |
|----|--------------|
|  0 | 0%           |
|  1 | 30%          |
|  2 | 60%          |
|  3 | 90%          |

Start with the highest MC value among worn armor. Extrinsic Protection adds 1, or 2 when it comes from an **amulet of guarding**; multiple extrinsic sources do not add repeatedly. Intrinsic Protection from a priest donation or spell merely raises MC0 to MC1. The total caps at
3. A cloak of protection reaches MC3 by itself; an amulet of guarding raises an MC1 suit to MC3.

**MC is not the same as the magic resistance intrinsic.** Magic resistance is a binary on/off flag that blocks specific *magical* attacks at 100%: wand-of-death rays, magic missile, the touch of death spell, polymorph beams, magic traps, and so on. MC instead blocks the listed melee status effects at a percentage rate. A helmet, not MC, usually stops a mind-flayer tentacle; cockatrice touch requires its own precautions. An ascending hero wants both defenses.

**Cloak of magic resistance vs. cloak of protection.** These two cloaks cover those two different defenses:

- The **cloak of magic resistance** grants the magic resistance intrinsic and contributes MC1. It is the simplest source of magic resistance in the game; mid-game heroes who haven't yet wished for gray dragon scale mail rely on it.
- The **cloak of protection** grants no magic resistance, but contributes MC3 on its own. It is the late-game choice once you already have magic resistance from another source.

The canonical ascension kit takes both defenses by putting **gray dragon scale mail** in the body slot (which grants magic resistance there) and then wearing the **cloak of protection** in the cloak slot (for the MC3). Before you have gray dragon scale mail, the cloak of magic resistance is doing essential work in the cloak slot, and the cloak of protection waits in your pack.

For the AC, MC, weight, cost, and granted-power numbers on every piece of armor in the game, see the [Armor Tables](#armor-tables) appendix.

#### Weapons {#weapons}

Your weapon determines its reach, damage, and the skill you train. The sections that follow group weapons by how they are used. For per-skill stat tables, see [Weapons Tables](#weapons-tables) in the appendix.

A handful of commands run through everything below: **`w`** wields a weapon; **`x`** exchanges it with the alternate weapon slot; **`t`** throws any item; **`f`** fires whatever stack you've set in your quiver; **`Q`** sets that quiver. Polearms, whips, pick-axes, and grappling hooks are also used through **`a`** (apply), the same key used for most tools.

For a first run, train the weapon your role can keep using:

| Role | Train first |
| ---- | ----------- |
| Archeologist | Whip now; move to saber or pick-axe when damage matters |
| Barbarian | Axe or two-handed sword, matching the starting weapon |
| Cave Dweller | Club |
| Healer | Knife (the scalpel skill) or quarterstaff |
| Knight | Long sword; lance if you stay mounted |
| Monk | Martial Arts |
| Priest | Mace or morning star |
| Ranger | Bow |
| Rogue | Dagger |
| Samurai | Long sword (katana), with bow as the ranged skill |
| Tourist | Dart |
| Valkyrie | Long sword |
| Wizard | Dagger or quarterstaff |

##### One-handed melee swords {#one-handed-melee-swords}

The everyday swords of Knights, Valkyries, Samurai, and most fighters. One-handed, leaving the other hand free for a shield or an off-hand weapon.

**Short sword** (Samurai see **wakizashi**) is a 60-centimeter straight blade designed for close-quarters thrusting. d6 small, d8 large. The Rogue's starter and the Samurai's off-hand.

**Scimitar and silver saber.** These are the saber-skill blades. The **scimitar** is the curved slashing sword of the Arabian Nights, an ordinary iron one-hander. The **silver saber** is its silver cousin, and its bonus damage against demons, weres, vampires, shades, and most imps makes it one of the strongest late-game one-handers. The two artifact silver sabers are **Grayswandir** (a top-tier wishable: silver, double damage on every hit, plus hallucination resistance) and **Werebane** (extra damage against lycanthropes).

**Broadsword.** A medieval European blade wider and shorter than a long sword, hilted with a cross-shaped guard. **Runesword** is the broadsword's chaotic cousin; its artifact form **Stormbringer** drains levels from enemies and may swing at peaceful targets without your asking.

**Long sword.** The dungeon's iconic blade. A long sword dipped in a fountain at experience level 5 or higher has a chance to come back as **Excalibur**: 1 in 6 for Knights, 1 in 30 for any other Lawful. Non-Lawfuls who try the dip get the sword cursed instead. Excalibur is the early-game grail: +d5 to-hit, +d10 damage, level drain resistance, and a free search every step. The long-sword class is also home to **katana** (the Samurai's curved one-hander with +1 to-hit baked in, slightly larger dice than a plain long sword) and a thicket of long-sword artifacts: **Frost Brand**, **Fire Brand**, **Giantslayer**, **Vorpal Blade**, **Sunsword**, and the katana artifact **Snickersnee**.

Keep a melee weapon in the alternate slot when using a launcher. Press `x` to exchange the current and alternate weapons when a monster closes; press it again to return to the launcher.

##### Two-handed melee {#two-handed-melee}

Heavier swings at the cost of your shield slot and off-hand. In 5.0, bimanual weapons get a **3/2 Strength damage bonus** on every melee strike (your Strength damage component is multiplied by 1.5), which puts two-handed builds back in serious competition with one-hand-plus-shield.

**Two-handed sword.** The German zweihander of the late sixteenth century, a 1.5-meter steel blade swung with both hands by Landsknecht mercenaries. d12 small, d6+2d6 large, at a crushing 150 zm weight. **Tsurugi** is the Japanese straight-edged two-hander, much lighter (60 zm) but with the highest small-target dice of any weapon in the game (d16). The artifact form is the **Tsurugi of Muramasa**, the Samurai quest artifact.

**Quarterstaff.** A simple wooden pole, bimanual at d6/d6 and only 40 weight. Weapons do not impose spellcasting penalties; a wielded quarterstaff actually gives a small casting bonus. Wizards start with one, and Healers, Priests, Cave Dwellers, and Wizards can reach Expert.

Certain two-handed weapons live in other sections because their combat role is more defining than their grip: **battle-axe** is under Axes, **dwarvish mattock** under Pick-axes, polearms under Reach, lance under Mounted, and bow and crossbow under Ranged.

##### Axes {#axes}

The axe's blade biases hard toward big targets: extra damage dice against anything large. **Axe** is the standard one-handed wood-cutting axe, d6 small / d4 large. **Battle-axe** is the two-handed long-hafted version with a wider head (often double-bitted), d8+d4 small / d6+2d4 large, two-handed (so it gets the 3/2 Strength bonus and locks out the shield). The Barbarian quest artifact **Cleaver** is a battle-axe.

##### Blunt one-handed {#blunt-one-handed}

The mace-and-club family: useful against undead (no blood spilled, in the cleric flavor sense) and effective against heavily armored targets in the historical sense (a club doesn't care that you're in plate).

**Club.** A wooden stick with a heavy end. The Caveman's starter. d6/d3, light, no special properties.

**Aklys** is an obscure ancient Greek thrown club with a leather thong tied to the haft. The thong matters in the dungeon: when you wield the aklys as your primary and throw it, the line yanks it back to your hand the way a tethered ball returns. d6/d3; it can miss the return occasionally.

**Mace.** The medieval European steel mace, a metal-headed club with a shaped striking surface. The Priest's starter. The Priest's guaranteed first sacrifice gift is **Demonbane**, a silver mace with bonus damage against demons plus a banish invoke. **Silver mace** is the plain silver version, with bonus damage against demons, weres, vampires, shades, and most imps.

**Morning star.** A spiked-ball mace, the brutal foot-soldier's weapon of the late Middle Ages. d4+d4 small / d6+1 large, the class hits hard for a one-handed weapon. The artifact **Trollsbane** is a morning star (regenerates while wielded, extra damage against trolls).

**Flail.** A weighted ball on a chain attached to a haft (Samurai see **nunchaku**, the chain-linked Okinawan sticks). d6+1 small / d4+d4 large, light at 15 zm, stacks well against larger targets. The **grappling hook** trains the same skill. Applied at two-square reach, it can pull a very small monster one square, snag an object, or drag you one step; it does not haul an ordinary foe into melee.

**War hammer.** A small one-handed warhammer with a striking head and a back spike. d4+1 small / d4 large. The Valkyrie's guaranteed sacrifice gift is **Mjollnir**, the Norse god Thor's thunder hammer; it does shock damage on hit. Only a Valkyrie with Strength 25 can throw it and have it return reliably.

##### Reach {#reach}

Reach weapons strike from a distance with `a` (apply). The class covers the polearms, the lance, and the long-sword artifact **Snickersnee**, all of which route through the same reach routine: range scales with your weapon's skill rank, from two squares away at Basic out to roughly 2.8 at Expert. Apply works in any direction including diagonals. Smoother still, the **`f`** (fire) command doubles as your reach attack: with a reach weapon wielded, `f` autotargets a monster in range and strikes it in a single keystroke, no direction prompt.

**Polearms** are long-hafted weapons with a blade or hook on the end: glaive, halberd, partisan, bardiche, voulge, fauchard, guisarme, bill-guisarme, lucern hammer, bec de corbin, ranseur, spetum. Most are fifteenth-century European battlefield weapons designed to pull a knight off his horse or open his armor at a joint. The **glaive** also goes by **naginata**, the curved blade on a long shaft used by Samurai retainers. All polearms are two-handed. If you bump a polearm into an adjacent monster the ordinary way, the strike is treated as a **bash**: damage clamps to 1d2 base, the weapon-skill bonus doesn't apply, and only Strength still adds. Reach is what makes polearms worth carrying; up-close they're worse than a dagger.

**Lance** is a long wooden shaft with a steel point, the weapon of mounted knights charging at full gallop. It has reach like any polearm, and on top of that gets the **joust**: charging into a target while mounted on a horse or pony adds +2d10 damage on contact (or +2d2 if the lance is in your off-hand). A critical joust has a 1-in-250 chance of shattering the lance. Knights reach Expert in lance and start on a saddled pony with one in hand. On horseback a Knight can both joust on contact and reach at distance, which makes the lance one of the role's most versatile weapons. Most non-Knight roles never see one.

##### Daggers and knives {#daggers-and-knives}

The small blades, the dungeon's most versatile weapon class.

**Dagger** is the basic 30-centimeter double-edged blade worn at the belt since the Bronze Age. d4/d3, +2 baked-in to-hit, light, and (critically) the entries **stack**. Daggers are the only blade you'd actively want to throw in volume: at Expert with the Rogue's class bonus, you can throw up to **four daggers per `f` keystroke**. Set the dagger stack as quiver with `Q`, fire with `f`, then walk over and pick them back up after the fight (daggers rarely break). The dagger family branches into flavor on the same chassis: **elven dagger** (the artifact form **Sting** glows blue near orcs and is the Tolkien reference), **orcish dagger** (a bit worse), **silver dagger** (bonus damage against silver-haters, a Ranger's classic off-hand). The **athame** is a ritual dagger that engraves Elbereth without dulling.

**Knife** is the kitchen blade or pocketknife, light and small. d3/d2, no special multishot. **Scalpel** is the Healer's starter, a tiny surgical blade.

**Crysknife** is the Fremen blade from Frank Herbert's *Dune*: a 20-centimeter blade carved from a sandworm's tooth. d10/d10, +3 to-hit, but it has a quirk: dropping one on the floor reverts it to a worm tooth every time unless you've erodeproofed it first, which drops the chance to about one in ten.

Daggers and knives benefit hugely from the `w` + secondary + `x` rotation pattern. A Rogue typically wields a short sword and keeps daggers in the off-hand, then `x` to swap the dagger stack into primary for throwing.

##### Whips and grappling hooks {#whips-and-grappling-hooks}

Tools that double as weapons. The **bullwhip** is the Archeologist's starter: a six-foot braided leather lash with a small popper at the tip. d2/d1, weak in combat, but `a` the bullwhip and you can disarm an adjacent monster, or yank yourself out of a pit (the popper anchors on nearby furniture, a boulder, or a large monster). The **rubber hose** is the dungeon's joke weapon: Keystone Kops sometimes carry one.

The **grappling hook** is a three-pronged iron hook on a chain. Apply it at two-square reach to snag an object, pull a very small monster one square, or drag yourself a step. It trains the flail skill.

##### Ranged {#ranged}

The structural overview lives in [Ranged Combat](#ranged-combat) in the Combat chapter; the items themselves:

**Bows and arrows.** The plain **bow**, **elven bow**, and **orcish bow** are 1.5-meter wooden bows of varying quality, all firing arrows (1 zm each). **Yumi** is the long Japanese asymmetric bow, the Samurai's launcher, paired with **ya** (bamboo arrows). The Ranger quest artifact is the **Longbow of Diana**, named for the Roman goddess of the hunt; it grants free arrows out of thin air. Wield a bow with `w`, set arrows as quiver with `Q`, fire with `f`. Rangers and Samurai reach Expert; Rogues cannot train bow.

Any bow fires any arrow, but a matched set (elven bow with elven arrows, orcish bow with orcish arrows, yumi with ya) earns the corresponding race or role an extra arrow per volley. See the [weapons tables](#weapons-tables) for the pairings.

**Crossbows and bolts.** The **crossbow** is the late-medieval mechanical bow that fires short heavy **bolts**. It hits harder per shot than a bow but reloads slowly, and full multishot needs Strength 18 (16 for gnomes). Bolts need a crossbow; no bow fires them. Rogues and Rangers reach Expert; Knights cap at Skilled.

**Sling.** A leather pocket on two cords, the simplest ranged weapon and the one David used on Goliath. The Caveman's starter. Fires rocks, flint stones, or gems.

**Throw-only weapons.** **Darts** stack big and accept poison from a sickness potion. **Shuriken** are Japanese throwing stars; Monks get the extra multishot. **Boomerang** is the Australian curved throwing club that returns to your square on a clear miss; catching it needs a Dex check. **Aklys** belongs here too: see the Blunt one-handed section above.

For all throwables, set the stack with `Q` and fire with `f`. Throwing without a quiver is `t` plus a chosen item plus a direction.

##### Two-weapon style {#two-weapon-style}

When your role can fight with a weapon in each hand, the off-hand choice matters as much as the main. Rules and the break-even math are in [Two-Weapon Combat](#two-weapon-combat) in the Combat chapter; the standard off-hand pairings:

- **Samurai:** katana primary, wakizashi off-hand. The wakizashi is a short sword (not a long sword), so it doesn't share long-sword skill with the katana. That is the price Samurai pay for the two-weapon flavor.
- **Rogue:** short sword primary, dagger stack off-hand (the daggers double as a throwing stack via `Q` + `f`). A silver dagger off-hand pairs well against silver-haters.
- **Valkyrie or Knight:** long sword primary, off-hand at Skilled with a silver dagger. Numbers usually favor a two-handed weapon over an off-hand unless you're already at high enchantment.
- **Barbarian:** caps at Basic; the to-hit penalty swallows the benefit, so a single good weapon is the better call.
- **Rangers can two-weapon, but never train it past unskilled** (a −9 to-hit penalty), so a single good weapon usually wins.

#### Enchantment {#enchantment}

Weapons and armor can be enchanted using scrolls of enchant weapon and enchant armor. An uncursed enchant-weapon scroll adds +1; an uncursed enchant-armor scroll adds 1–2, with larger gains possible on plain +0 armor. Blessed scrolls can add more. At **+6 or higher**, a weapon has a two-in-three chance to evaporate when positively enchanted. **Armor** is also at risk: above +3 each new scroll has a chance to destroy the item (above +5 for "special" armor like elven pieces, or the Wizard's cornuthaum). Blessed scrolls give more points per read but don't change the destruction threshold; cursed scrolls can subtract enchantment and shouldn't be used for enchanting at all.

#### Erosion and Proofing {#erosion-and-proofing}

Weapons and armor can be damaged by rust (iron items), fire (organic items), and corrosion (copper items). A badly damaged item provides less AC or damage.

To fix erosion, read a **non-cursed** scroll of enchant weapon while confused (for your weapon), or a non-cursed scroll of enchant armor while confused (for a random worn armor piece). That erodeproofs the item and repairs existing damage. A confused cursed scroll strips proofing instead.

You can also slow erosion without magic. Coat an armor piece with grease (apply a can of grease). The grease layer can deflect hugs, wraps, sticky attacks, and mind-flayer tentacles, but not ordinary theft or weapon snatching. Grease shields gear from water too: a greased weapon or suit takes a fountain dip, a water trap, or a wade through deep water without rusting. Each soaking has about a 50% chance of washing the grease away, so it buys a few dunks of cover, not a permanent seal.

#### Dragon Scale Mail {#dragon-scale-mail}

Dragon scales are prized for their toughness and their magical protections, and mail forged from those scales is among the best body armor in the game.

Dragons don't always drop scales, and they never drop the mail itself. A fresh kill yields scales about one time in three, and a revived dragon only one time in twenty. **Scales** can be worn as body armor just like mail and carry the color's full intrinsic property (gray gives magic resistance, silver reflection, and so on, identical to the mail). But the AC of scales is only +3 whereas fully formed scale mail is +9. Same weight.

To upgrade scales into scale mail: wear the scales and read a non-cursed scroll of enchant armor. The scales merge and harden into the corresponding dragon scale mail at +0 (or higher if blessed; a blessed scroll also blesses the result). A cursed scroll just gives the usual bad enchant effect; no merge.

---

### Curses and How to Break Them {#curses-and-how-to-break-them}

Sooner or later, you will put on something cursed. Maybe it's a ring you didn't test. Maybe it's boots from a bones level. Maybe a monster touched your inventory and you didn't notice. However it happens, you're now wearing an item that refuses to come off, and it's probably doing something terrible. You cannot remove it until you break the curse.

#### How Items Get Cursed {#how-items-get-cursed}

- **Born that way.** Some items generate cursed most of the time (rings of teleportation, rings of polymorph, amulets of strangulation; anything the dungeon thinks is funny)
- **Bones inheritance.** Items on a bones level have an 80% chance of being cursed.
- **Monster interference.** Certain monsters can curse items in your inventory
- **Confused remove curse.** Reading it confused has a chance of *cursing* items instead of uncursing them
- **Unholy water.** The evil twin of holy water

#### Effects of Cursed Items {#effects-of-cursed-items}

- **Cursed armor and rings** bond to you and can't be removed: a cursed ring of teleportation means random teleports you can't stop, and a cursed pair of levitation boots means you can never touch the ground again
- **Cursed weapons** can't be unwielded. Hope you like that -3 orcish dagger
- **Cursed potions and scrolls** have specific altered effects; some are weaker, some harmful, and a few are useful on purpose
- **Cursed tools** malfunction spectacularly. A cursed bag of holding *doubles* the weight of its contents instead of reducing it
- **Cursed food** is unpleasant but rarely fatal. Small mercies

#### Detecting Curses {#detecting-curses}

Prevention is better than cure. Test items *before* wearing them:

- **Altar test.** Drop an item on an altar. A black flash means cursed; no flash means uncursed
- **Pet test.** A pet steps reluctantly onto a cursed object. Drop it in a narrow route and watch several passes; one crossing does not prove safety
- **Scroll of identify.** Always reveals the full status

(Temple donation does *not* reveal BUC; that's a common spoiler myth. Donating to a priest grants temporary clairvoyance and a Protection bonus, but inventory BUC stays hidden.)

#### Removing Curses {#removing-curses}

When prevention fails, you have three remedies:

- **Scroll of remove curse.** Uncursed removes curses from worn and wielded items. Blessed uncurses your entire inventory
- **Holy water.** Dip a cursed item in holy water and it becomes uncursed. That is the main reason to hoard holy water
- **Prayer.** Cursed levitation, a welded weapon when you have no free hand, and a cursed blindfold count as major trouble and can be the prayer's main repair. Ordinary cursed equipment is minor trouble: with positive Luck and nothing worse to fix, a successful prayer uncurses at most one item.

Stuck in cursed body armor? Polymorphing into a form too small for the suit drops it off into your inventory (curse and all), even though it would normally refuse to come off. From there, dip in holy water and re-wear. See [Polymorph as a Tool](#polymorph-as-a-tool).

Most veterans carry holy water and a scroll of remove curse at all times.

---

## Part Five: Mastery and Endgame {#part-five-mastery-and-endgame}

By the middle game, survival depends less on what the dungeon happens to drop and more on what you build from it: trained skills, managed Luck, spells you can cast reliably, and a kit assembled for threats you have not met yet. The chapters here explain those systems before the route descends into Gehennom.

### Spellcasting {#spellcasting}

Spells are reusable abilities learned from spellbooks. Unlike scrolls (consumed on use) or wands (limited charges), spells can be cast (`Z`) repeatedly as long as you have mana (Pw, power) and the spell hasn't expired from your increasingly overtaxed brain.

#### Learning Spells {#learning-spells}

Read a spellbook (`r`, the same key that reads scrolls) to learn its spell. The book's shop price is 100 times the spell level. Reading takes several turns and can fail: the result may teleport you, take your gold, blind, confuse, poison, or injure you. A surviving book can be tried again. In 5.0, a Wizard who is not certain to succeed sees *"This spellbook is difficult to comprehend. Continue?"*; declining costs nothing.

The book's level decides which effects are on the table. A level-1 book can teleport you somewhere random when you fail to read it. A level-2 book might aggravate nearby monsters instead. Misread a level-3 book and it can blind you for 250 to 350 turns. A level-4 book can take all your gold, and level 5 can leave you confused for 16 to 22 turns. Misread a level-6 book and you may be contact-poisoned: gloves take corrosion damage, bare hands take 3 to 6 points of Strength plus 1d10 HP (just 1 to 2 Strength and 1d6 HP with poison resistance). And a level-7 book can have an exploding rune. Magic resistance blocks the explosion; without it, you take 2d10+5 damage. Practical rule: don't read books you can't afford to fail.

The chance of successfully reading a spellbook depends on the **spell level**, your **Intelligence**, and your **experience level**. The exact formula is `Int + 4 + XL/2 − 2·level` versus a roll of 1d20, so read 20 or more always succeeds, 10 is a coin flip, and anything below that is dicey. Reading a level-7 spell at Int 15, XL 2 gives a read score of 6: only a 30% chance of success. Lenses add +2. A **blessed** spellbook bypasses the check entirely and always succeeds. A **cursed** spellbook fails automatically and applies one of the failure effects above.

The formula produces a **read score**. A score of 5 succeeds 25% of the time, 10 succeeds 50%, 15 succeeds 75%, and 20 succeeds automatically. To guarantee a read without lenses, you need `Int + XL/2` of 18 for a level-1 book, then 20, 22, 24, 26, 28, or 30 for levels 2 through 7. Lenses reduce each requirement by 2.

Save your holy water for your hardest unread spellbooks.

**Wizards** are the undisputed masters of magic: they read books and cast spells more reliably, and can reach Expert in every school. A well-built Wizard can eventually learn *every* spell in the game, which is the closest the Mazes come to letting you cheat. **Monks** are the surprising second. They have access to all seven spell schools too, and their no-body-armor restriction helps casting because metal body armor adds a failure penalty; the monk-favored robe grants a bonus. Priests and Healers cast well in their own schools. Other roles can manage the occasional spell with help. A Valkyrie can sometimes read identify (level 3) if her Intelligence is boosted by gain-ability potions, but non-spellcasters are usually better off with scrolls.

[]{#wizards-identify-books} **Wizards identify books by training.** Advancing a spell school skill to each rank automatically reveals the appearances of spellbooks in that school: unskilled unlocks level-1 appearances, basic level-3, skilled level-5, expert level-7. A Wizard starts knowing all level-1 appearances and level-3 in attack and enchantment, so several books are already identifiable in their core schools.

Each spell stays in memory for about 20,000 turns, then fades and must be relearned. The spell list (`+`) shows time-remaining. You can also `a`pply a spellbook to check how worn it is: each **successful** read counts toward a fixed total of four before the book fades to blank paper. Failed reads don't add to that counter, but each failure has its own 1-in-3 chance to destroy the book outright. Carry important spellbooks if you plan to rely on their spells in the late game.

**Paperbacks.** A spellbook that appears as a *paperback* is a novel rather than a real spellbook. Read it: the first novel you pick up in a game grants 20 XP, which is exactly enough to lift a fresh character from experience level 1 to 2. (The 20 XP only fires once; subsequent paperbacks just display a quote.) Each paperback is a Terry Pratchett **Discworld** title, and reading it opens a passage from the novel.

#### Key Spells {#key-spells}

| Spell           | Level | Effect                                  |
| --------------- | ----- | --------------------------------------- |
| Force bolt      | 1     | 2d12 ranged hit; an Int/XL bonus adjusts by −3 to +3 |
| Healing         | 1     | Restore hit points                      |
| Detect monsters | 1     | Reveal monsters across the whole level |
| Identify        | 3     | Identify items (saves scrolls)          |
| Remove curse    | 3     | Uncurse worn/wielded items              |
| Chain lightning | 2     | Shock that spreads from the caster in all directions, chaining to nearby monsters |
| Magic mapping   | 5     | Reveal the level (saves scrolls)        |
| Charm monster   | 5     | Tame nearby creatures in a 3×3 area; Skilled+ acts like a blessed scroll |
| Finger of death | 7     | Kill in a beam; MR resists              |

The other 32 spells, along with their schools, types, and rank-gated upgrades, are in the [Spell Tables](#spell-tables) appendix.

For Wizards, learning **identify** and **magic mapping** as spells dramatically reduces your need for scrolls: it's like having infinite scrolls, except they cost mana instead of inventory space. **Finger of death** is the ultimate argument-ender. **Charm monster** turns your enemies into your friends, which is even better than killing them because friends carry things and absorb hits.

**Chain lightning** is a fine room-clearer. At level 2 it's within reach of any character who can cast at all. The spell auto-fires in all eight directions without a target prompt, deals 2d6 per hit, and stops dead at any peaceful or tame monster, so you can clear a hostile room without lighting up your pet or a shopkeeper down the hall. Shock-resistant hostiles eat one hit, then end that beam.

If the `+` menu shows **100% fail**, the problem is usually equipment or skill, not the spellbook. Remove a shield first, then metal body armor, helm, gloves, or boots; raise the role's casting stat and train the spell's school. A robe halves the metal-suit penalty, and wielding a quarterstaff gives a small bonus. Every shield imposes a flat penalty, and shields heavier than 30 weight quarter the final chance.

#### Mana Management {#mana-management}

Your power (Pw) pool determines how many spells you can cast before you need to sit in a corner and regenerate like a phone battery. Casting a spell costs **5 Pw per spell level** (so finger of death is 35 Pw). A failed cast still spends half.

Pw regenerates on a periodic tick that shortens as you level: every 24 turns at XL 1 (18 for a Wizard), 18 by XL 10 (14 Wizard), 12 by XL 20 (9 Wizard), and 5 by XL 30 (4 Wizard). Each tick gives 1 to **((Wis + Int) / 15) + 1** Pw, typically 1-3; magical breathing adds 2 to that ceiling. The **energy regeneration** intrinsic (from the *Eye of the Aethiopica*, among others) bypasses the tick, so you regen every turn. Stressed or worse encumbrance shuts regen off; Burdened is fine.

Carry backup wands and scrolls: a Wizard out of Pw is just a person in a bathrobe holding a stick.

---

### Luck and Fortune {#luck-and-fortune}

Luck is hidden, but four rules handle most of it:

1. Keep Luck at 0 or above so prayer remains safe.
2. Carry a blessed luckstone in open inventory once you find one.
3. Give identified gems to a unicorn of your alignment.
4. Do not kill peaceful creatures or break mirrors without a reason.

#### How Luck Works {#how-luck-works}

Luck ranges from −13 to +13 and normally starts at 0. Left alone, it drifts back toward its calendar baseline.

**Luck timeout.** Every 600 turns, Luck moves one point toward its baseline, normally 0. While you carry the Amulet or your god is angry, it moves every 300 turns.

**Luckstones.** A luckstone in open inventory (not in a bag) adds 3 to your Luck, or subtracts 3 if cursed, and changes the timeout:

| Luckstone | Luck | Good Luck | Bad Luck  |
| --------- | ---- | --------- | --------- |
| Blessed   | +3   | kept      | wears off |
| Uncursed  | +3   | kept      | kept      |
| Cursed    | −3   | wears off | kept      |

Bless it. A blessed luckstone keeps the Luck you earn and lets mistakes wear off. The Mine's End stone is uncursed, so dip it in holy water. Never carry a cursed one.

The [Heart of Ahriman](#heart-of-ahriman) (itself a luckstone), the [Tsurugi of Muramasa](#tsurugi-of-muramasa), and the [Orb of Fate](#orb-of-fate) count as luckstones. Carrying several never adds more than 3, and a cursed one weakens the rest.

**Calendar Luck.** The drift target isn't always 0:

- On a **full moon** night, baseline Luck is +1: Luck drifts toward +1 instead of 0. If you started the session on a full moon, you have +1 Luck for free.
- On **Friday the 13th**, baseline Luck is −1. Avoid stair-up runs on this day if you can; your accumulated good Luck will sap toward −1 even if you've been virtuous.

(NetHack uses the computer's real date.)

#### Gaining and Losing Luck {#gaining-and-losing-luck}

| Action                                              | Luck change          |
| --------------------------------------------------- | -------------------- |
| Throw identified real gem to co-aligned unicorn     | **+5**      |
| Throw named-but-unidentified real gem to co-aligned | +2          |
| Throw unknown real gem to co-aligned unicorn        | +1          |
| Throw fully-identified real gem to cross-aligned unicorn | −3 to +3 (random) |
| Throw unidentified real gem to cross-aligned unicorn | −1 to +1 (random)  |
| Sacrificing on your own altar (varies by corpse value) | typically +1 |
| Sitting on a throne (this result occurs only while Luck is negative) | +1 |
| Breaking a Sokoban rule (squeeze, fracture, polymorph boulder, scroll of earth) | −1 each |
| Killing a peaceful creature                         | −1 (50% chance per kill) |
| Killing a same-alignment unicorn                    | −5          |
| Killing your quest leader                           | −20 immediate (floor at −10), +7 god-anger, plus permanent −4 to baseline luck |
| Killing your pet                                    | −1 plus −15 alignment |
| Cannibalism                                         | −2 to −5    |
| Breaking a mirror                                   | −2          |

**Unicorn gem-throwing is the strongest active Luck source in the game.** Throw a properly-identified real gem (not glass) at a unicorn whose alignment matches yours and you gain +5 Luck immediately. The unicorn turns peaceful, accepts the gift, and teleports away, and will accept another later if you find it again. Identify your gems *first* (touchstone or scroll of identify); the bonus drops from +5 to +1 if you don't actually know what you're throwing. Glass gems are harmless but yield nothing; throwing them is a safe way to pacify an unwanted unicorn without spending real gems. Avoid throwing real gems at cross-aligned unicorns: the result is a random Luck change between -3 and +3. Archeologists start with a **touchstone**, which lets them verify whether a gem is real before throwing it at a unicorn.

A sacrifice can raise Luck only while the corpse's difficulty exceeds your current Luck. Kobolds are too weak to help. For later gains, use fresh corpses from tough monsters.

#### Why Luck Matters {#why-luck-matters}

At Luck +5 (or higher, with a luckstone), life is *noticeably* better:

- You hit more often in combat. Swings that would have missed connect instead.
- Your prayers are more likely to be answered. Your god likes lucky people. (Gods are fickle that way.)
- Many smaller checks tip your way as well.

Negative Luck makes prayer unsafe. At −1 or −2 Luck, if your god is not angry, the usual result is simple displeasure and a reset prayer timer rather than a curse or divine bolt. Deeper negative Luck and anger allow harsher outcomes. Luck also changes attacks and many Luck-adjusted rolls; it does not make scrolls generically backfire.

---

### Exercising Your Stats {#exercising-your-stats}

Behind the scenes, the dungeon keeps a hidden exercise counter for four of your six stats: **Str**, **Dex**, **Con**, and **Wis**. (Int and Cha don't exercise; they only change through magical sources like gain-ability potions.) Living a way that *trains* a stat slowly pushes the counter up; living a way that *abuses* it pushes the counter down. Every several hundred turns the game checks the counter and may grant a +1 or −1.

#### How Exercise Works {#how-exercise-works}

The counter is invisible. A long enough streak of exercising behavior, plus a passing random roll (with diminishing returns once you've already gained), gives you the message *"You feel agile! You must have been working on your reflexes!"*, or the matching one for the other stats. The reverse, *"You haven't been working on reflexes lately,"* fires when the abuse counter wins instead.

Exercise can lift a stat up to **18** (your innate maximum isn't bypassed; potions of gain ability still rule the top end). Abuse can drop it down to your racial minimum.

#### Actions That Exercise and Abuse {#actions-that-exercise-and-abuse}

| Stat | Exercises | Abuses |
|------|-----------|--------|
| **Str** | Carrying a heavy load (Stressed but not Overtaxed), intrinsic regeneration, throwing or pushing a boulder, throwing the heavy iron ball | Being Weak from hunger |
| **Dex** | Successful kicks (locks, sinks, doors), successful thrown weapons | Being Satiated, heavy encumbrance, Fumbling, Stunned, Wounded legs, missed kicks |
| **Con** | Staying just-Not-Hungry consistently | Fainting, Sick, Vomiting, polluted fountains, extreme encumbrance |
| **Wis** | Active Clairvoyance, successful detection (gold/monster/food), a willing prayer, a worthy sacrifice | Confusion, Hallucination, cursed enlightenment, digging up graves |

Two Monk-specific quirks: a Monk who is Weak from fasting exercises Wis, and a Satiated Monk abuses it.

#### Why Exercise Matters {#why-exercise-matters}

Stats matter for almost everything: Str for damage and carrying capacity, Dex for hit chance, Con for HP per level, and Wis for Pw regeneration. Those gradual gains add up. So do five hundred turns spent Satiated and Fumbling.

---

### Enhancing Skills {#enhancing-skills}

Most adventurers discover the skill system the first time they press `#enhance` and realize the broadsword they've been swinging for several levels is finally ready to graduate from Basic to Skilled. Weapons, fighting styles, and spell schools each track their own proficiency, and you train them one slot at a time.

Pick one weapon class early and stay with it. Skill compounds only if you stop switching, and a weapon you are Skilled with (which adds 2 to your to-hit) out-fights a higher-base one you are Unskilled with (which subtracts 4), so a shinier sword you have no training in is usually a downgrade. Chasing every better weapon you find leaves you Unskilled in all of them.

#### The Skill Ladder {#the-skill-ladder}

Practice with a weapon improves how often you hit and how hard. The game tracks that as a **skill rank**: more practice, higher rank, more deadly swings. Most skills run **Unskilled → Basic → Skilled → Expert**. **Bare hands** and **martial arts** alone reach **Master** and **Grand Master**. Each rank-up costs both **practice** (uses of the skill) and **skill slots** (a finite budget tied to your experience level).

| To reach     | Practice (cumulative) | Weapon slots | Non-weapon slots |
| ------------ | --------------------- | ------------ | ---------------- |
| Basic        | 20                    | 1            | 1                |
| Skilled      | 80                    | 2            | 1                |
| Expert       | 180                   | 3            | 2                |
| Master       | 320                   | —            | 2                |
| Grand Master | 500                   | —            | 3                |

Non-weapon skills (spell schools, riding, bare hands, martial arts) cost roughly half as many slots as melee weapons, the dungeon's quiet subsidy for magic. (Two-weapon uses the weapon column despite the name.) You start with 2 slots, gain one per experience level (29 more by XL 30), and one more if you are crowned, so the absolute ceiling is **32 slots** for an XL-30 crowned hero. Lose an experience level and you lose a slot, which can demote your most recent advancement.

Each role has a per-skill **cap** beyond which no amount of training will help. A Wizard caps at Basic with a mace and is restricted from long swords. Restricted skills don't appear on `#enhance` and stay Unskilled, except for god-given artifact weapons, which unrestrict the skill to Basic. The full role caps appear in [Per-Role Skill Caps](#per-role-skill-caps) below.

#### Training a Skill {#training-a-skill}

Practice accumulates through use:

- **Weapon skills** tick on every melee or thrown hit that does **more than 1 damage**. A pillow-soft punch for 1 point doesn't count. Spears, javelins, knives, daggers, and aklys train the same skill whether you stab with them or throw them.
- **Bare hands** counts **50%** of your hits; **martial arts** counts **75%**. The rank still applies on every hit; that just slows the climb.
- **Riding** earns one tick every **100 squares** ridden.
- **Spell schools** earn **N practice per successful cast of a level-N spell**. Every school has a level-1 option to grind. See the schools table below.

Skills your role starts at Basic come **pre-credited with 20 practice uses**, so you're already a quarter of the way to Skilled before the first turn.

When you've earned enough practice, the message names the category: **"You feel more confident in your weapon skills,"** **"spell casting skills,"** or **"fighting skills."** That is your cue to type `#enhance`. If more advancements remain after you pick one, you'll see **"You feel you could be more dangerous!"** Keep going.

#### What a Rank Buys You {#what-a-rank-buys-you}

For weapons and fighting styles, each rank shifts your to-hit and damage bonuses by a flat amount (the values replace each other, not stack):

| Rank         | Weapon  | Two-weapon | Riding | Bare hands | Martial arts |
| ------------ | ------- | ---------- | ------ | ---------- | ------------ |
| Unskilled    | −4 / −2 | −9 / −3    | −2 / 0 | +1 / 0     | +2 / +1      |
| Basic        | 0 / 0   | −7 / −1    | −1 / 0 | +1 / +1    | +3 / +3      |
| Skilled      | +2 / +1 | −5 / 0     | 0 / +1 | +2 / +1    | +4 / +4      |
| Expert       | +3 / +2 | −3 / +1    | 0 / +2 | +2 / +2    | +5 / +6      |
| Master       | —       | —          | —      | +3 / +2    | +6 / +7      |
| Grand Master | —       | —          | —      | +3 / +3    | +7 / +9      |

(Each cell is **to-hit / damage**.) Two-weapon penalties apply to **each** of the two strikes. A Basic two-weaponer hits twice but at −7 each, which is much worse than one solid swing. Bare hands and martial arts bonuses apply on every hit; only the practice counter skips the weakest hits. The Expert weapon line (+3 / +2) is the payoff for dedicating to a single weapon.

#### The Seven Spell Schools {#the-seven-spell-schools}

Every spellbook belongs to one of seven schools, and your rank in that school determines how reliably you can cast spells from it. Higher rank also unlocks some spell upgrades. Cone of cold becomes a cluster of 3×3 explosions at Skilled, identify IDs the whole stack, haste self lasts longer, and so on.

| School      | Focus                                  | L1 grind        |
| ----------- | -------------------------------------- | --------------- |
| Attack      | Direct damage (force bolt, fireball)   | Force bolt      |
| Healing     | HP restore and cure status             | Healing         |
| Divination  | Sensing, identifying, mapping          | Light           |
| Enchantment | Buffs, debuffs, charm                  | Confuse monster |
| Cleric      | Divine protection and summoning        | Protection      |
| Escape      | Mobility, evasion, levitation          | Jumping         |
| Matter      | Manipulation, transmutation, polymorph | Knock           |

#### Per-Role Skill Caps {#per-role-skill-caps}

Three tables of fixed maxima follow: weapons, fighting styles, and spell schools. Skills not listed for a role are **restricted**: the rank is locked at Unskilled, with one exception (a god-given artifact weapon unrestricts you to Basic in its skill). Key: **B**=Basic, **S**=Skilled, **E**=Expert, **M**=Master, **GM**=Grand Master, **(blank)**=restricted.

A blank cell doesn't mean the skill is unusable, just locked at Unskilled forever. A Healer can still read a spellbook of force bolt and try to cast it. A Wizard can still swing a long sword. They'll just always pay the Unskilled penalty from the [Skill Ladder](#the-skill-ladder) (−4/−2 for a weapon, −9/−3 per strike for two-weapon, the Unskilled cast-failure rate for a spell school), with no path to improvement. Role abbreviations: Arc=Archeologist, Bar=Barbarian, Cav=Caveman, Hea=Healer, Kni=Knight, Mon=Monk, Pri=Priest, Rog=Rogue, Ran=Ranger, Sam=Samurai, Tou=Tourist, Val=Valkyrie, Wiz=Wizard.

##### Weapon Skill Caps {#weapon-skill-caps}

| Weapon           | Arc | Bar | Cav | Hea | Kni | Mon | Pri | Rog | Ran | Sam | Tou | Val | Wiz |
|------------------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| dagger           | B   | B   | B   | S   | B   | —   | —   | E   | E   | B   | E   | E   | E   |
| knife            | B   | —   | S   | E   | B   | —   | —   | E   | S   | S   | S   | —   | S   |
| axe              | —   | E   | S   | —   | S   | —   | —   | —   | S   | —   | B   | E   | S   |
| pick-axe         | E   | S   | B   | —   | B   | —   | —   | —   | B   | —   | B   | S   | —   |
| short sword      | B   | E   | —   | S   | S   | —   | —   | E   | B   | E   | E   | S   | B   |
| broadsword       | —   | S   | —   | —   | S   | —   | —   | S   | —   | S   | B   | S   | —   |
| long sword       | —   | S   | —   | —   | E   | —   | —   | S   | —   | E   | B   | E   | —   |
| two-handed sword | —   | E   | —   | —   | S   | —   | —   | B   | —   | E   | B   | E   | —   |
| saber            | E   | S   | —   | B   | S   | —   | —   | S   | —   | B   | S   | B   | —   |
| club             | S   | S   | E   | S   | B   | —   | E   | S   | —   | —   | —   | —   | S   |
| mace             | —   | S   | E   | B   | S   | —   | E   | S   | —   | —   | B   | —   | B   |
| morning star     | —   | S   | B   | —   | S   | —   | E   | B   | B   | —   | B   | —   | —   |
| flail            | —   | B   | S   | —   | B   | —   | E   | B   | S   | S   | B   | —   | —   |
| hammer           | —   | E   | S   | —   | B   | —   | E   | B   | B   | —   | B   | E   | —   |
| quarterstaff     | S   | B   | E   | E   | —   | B   | E   | —   | B   | B   | B   | B   | E   |
| polearms         | —   | —   | S   | B   | S   | —   | S   | B   | S   | S   | B   | S   | S   |
| spear            | —   | S   | E   | B   | S   | B   | S   | B   | E   | S   | B   | E   | B   |
| trident          | —   | S   | S   | B   | B   | —   | S   | —   | B   | —   | B   | B   | B   |
| lance            | —   | —   | —   | —   | E   | —   | B   | —   | —   | S   | B   | S   | —   |
| bow              | —   | B   | S   | —   | B   | —   | B   | —   | E   | E   | B   | —   | —   |
| sling            | S   | —   | E   | S   | —   | —   | B   | —   | E   | —   | B   | B   | S   |
| crossbow         | —   | —   | —   | —   | S   | B   | B   | E   | E   | —   | B   | —   | —   |
| dart             | B   | —   | —   | E   | —   | —   | B   | E   | E   | —   | E   | —   | E   |
| shuriken         | —   | —   | —   | S   | —   | B   | B   | S   | S   | E   | B   | —   | B   |
| boomerang        | E   | —   | E   | —   | —   | —   | B   | —   | E   | —   | B   | —   | —   |
| whip             | E   | —   | —   | —   | —   | —   | —   | —   | B   | —   | B   | —   | —   |
| unicorn horn     | S   | —   | B   | E   | —   | —   | S   | —   | —   | —   | S   | —   | —   |

Scimitar was merged into saber in 5.0; both refer to the same skill now.

##### Fighting Style Caps {#fighting-style-caps}

| Style        | Arc | Bar | Cav | Hea | Kni | Mon | Pri | Rog | Ran | Sam | Tou | Val | Wiz |
|--------------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| bare hands   | E   | M   | M   | B   | E   | —   | B   | E   | B   | —   | S   | E   | B   |
| two-weapon   | B   | B   | —   | —   | S   | —   | —   | E   | —   | E   | S   | S   | —   |
| riding       | B   | B   | —   | —   | E   | —   | —   | B   | B   | S   | B   | S   | B   |
| martial arts | —   | —   | —   | —   | —   | GM  | —   | —   | —   | M   | —   | —   | —   |

Only Monks and Samurai have martial arts at all, and only Monks reach Grand Master.

##### Spell School Caps {#spell-school-caps}

| School      | Arc | Bar | Cav | Hea | Kni | Mon | Pri | Rog | Ran | Sam | Tou | Val | Wiz |
|-------------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| Attack      | B   | B   | B   | —   | S   | B   | —   | —   | —   | B   | —   | B   | E   |
| Healing     | B   | —   | —   | E   | S   | E   | E   | —   | B   | —   | —   | —   | S   |
| Divination  | E   | —   | —   | —   | —   | B   | E   | S   | E   | B   | B   | —   | E   |
| Enchantment | —   | —   | —   | —   | —   | B   | —   | —   | —   | —   | B   | —   | S   |
| Cleric      | —   | —   | —   | —   | S   | S   | E   | —   | —   | S   | —   | —   | S   |
| Escape      | —   | B   | —   | —   | —   | S   | —   | S   | B   | —   | S   | B   | E   |
| Matter      | B   | —   | S   | —   | —   | B   | —   | S   | —   | —   | —   | —   | E   |

Healers cap at Expert in healing but are restricted from every other school. The only role with that kind of single-school specialization. Wizards and Monks are the only roles with access to all seven schools, though only Wizards can push four of them to Expert; Monks reach Expert only in healing. Barbarians and Valkyries cap at Basic in their two available schools (attack and escape) and are restricted from the other five.

#### Spending Slots Wisely {#spending-slots-wisely}

Thirty-two slots sounds like plenty until you start counting. Expert in a single weapon costs **6 slots** (1+2+3) by itself. A Valkyrie aiming for Expert long sword, Skilled two-weapon, and Skilled riding is eleven slots deep before any spell school.

A few principles:

- **Don't enhance reflexively.** Slots are spent permanently (short of losing experience). If you're not committed to a weapon, hold the slot until you are.
- **Cap-aware investment.** Pushing a skill to its role cap is fine: the menu just stops offering further advances. You can't waste enhancements past the cap because the option never appears.
- **Wizards get two benefits from spell schools.** Each rank-up improves casting success *and* reveals more spellbook appearances in that school (the [identification payoff](#wizards-identify-books) covered in the Spellcasting chapter). Schools containing your unidentified books deserve priority. That double benefit is Wizard-only; other roles only get the casting-success benefit.
- **Wizards: daggers before schools.** A common opening pushes **Dagger to Expert** (six slots) before serious investment in spell schools. Thrown daggers carry the early game while Pw is scarce, and school ranks then come online to upgrade the late game without leaving the early game starving.
- **Riding is a skill.** Without **Basic riding** you can't pick up items, loot, dip, set or disarm traps, or engrave on the floor while mounted. Knights start at Basic. Pushing to Skilled erases the −1 to-hit penalty in the saddle and adds +1 damage.
- **Bare hands and martial arts favor Monks.** Grand Master needs **9 cumulative non-weapon slots**, which Monks reach naturally. Barbarians, Cave Dwellers, and Samurai can reach Master; other roles have lower caps.

A few spells get sharper at Skilled. Cone of cold and fireball become a cluster of 3×3 **explosions** you can place at range. Identify, remove curse, haste self, detect monsters, and several others gain the blessed-scroll effect.

---

### Wishes and Wishing {#wishes-and-wishing}

When *"For what do you wish?"* appears, the game accepts a free-form object description. Decide the object and exact wording before you answer; a typo can turn the rarest resource in the game into junk.

#### Sources of Wishes {#sources-of-wishes}

The Mazes are stingy, but there are more wish sources than most travelers realize:

- **Wand of wishing:** found in one of [the Castle](#the-castle)'s four corner towers (see [Key Wands](#key-wands) for the charge mechanics).

- **Vlad's throne:** A special throne that grants a guaranteed wish if you keep sitting. Four of thirteen outcomes are a wish (which destroys the throne); the other nine are painful but the throne survives. Keep sitting until the wish arrives.

- **The Amulet of Yendor:** Grants a wish when you first pick it up. A reward for reaching the bottom of the dungeon. You can decline this wish if your kit is already complete; some minimalist ascenders skip it entirely on principle.
- **Magic lamp:** Rubbing a blessed lamp summons the djinni 1-in-3 times; *if* it appears, it grants a wish 80% of the time, so roughly 27% wish per rub. Keep rubbing. Either a magic lamp or a magic marker is guaranteed in Orcus Town.
- **Fountain:** roughly 1 in 30 quaffs summons a water demon, and *that* demon grants a wish only about 1-in-5 times on shallow floors (less on deeper ones), so a true wish chance closer to 1 in 150 per quaff. Far more likely to produce snakes, nymphs, curses, or vomiting.
- **Throne:** Very rare chance of a wish when sitting. Also a very real chance of everything going wrong.
- **Djinni from smoky potion:** Rare (1 in 13 base probability), and even then only 20% wish chance (80% if blessed). But when it works, you feel like a genius.

The number of wishes varies widely. A sensible budget is about five, counting the Castle wand's initial, recharged, and wrested charges, Vlad's throne, and the Amulet pickup wish. Lamps, fountain demons, and smoky potions may add more.

#### What to Wish For {#what-to-wish-for}

Choose the two body-armour wishes as a pair. If you already have reflection from an amulet or shield, wish for **gray dragon scale mail** to gain magic resistance. If a cloak already supplies magic resistance and reflection is missing, wish for **silver**. Once one defense is secured outside the body slot, the other mail becomes the better first wish.

1. **Gray dragon scale mail** ([magic resistance](#damage-resistances) + AC; magic resistance is the most important protection in the game). Type `blessed greased fixed +2 gray dragon scale mail`.
2. **Silver dragon scale mail** (reflection + AC; reflection protects against wands and breath weapons). Type `blessed greased fixed +2 silver dragon scale mail`.
3. **Speed boots** (being fast gives you more actions per turn, excellent for both offense and escape). Type `blessed greased fixed +2 speed boots`.
4. **Gauntlets of power** (STR 25 if your role benefits; most roles benefit from punching harder). Type `blessed greased fixed +2 gauntlets of power`.
5. **Amulet of [life saving](#special-and-utility)** (an extra life for the Planes). Type `blessed amulet of life saving` (amulets take no enchantment or erosion).
6. **A specific artifact** ([Grayswandir](#grayswandir) is a common target; its silver hurts demons, imps, vampires, weres, and shades). Type `blessed greased fixed +2 Grayswandir`.

Don't wish for consumables (scrolls, potions) unless you're in dire straits. A wish is for permanent gear you can't otherwise get: dragon scale mail, speed boots, an artifact.

#### Wish Syntax {#wish-syntax}

When the prompt asks "For what do you wish?", be specific. Here is what each word buys you:

- "blessed greased fixed +2 gray dragon scale mail" is the standard form. `blessed` because BUC defaults to random, `greased` can deflect hugs, wraps, sticky attacks, and mind-flayer tentacles, `fixed` (or `rustproof` or `erodeproof`) locks erosion, and `+2` is the enchantment. Don't reach higher than you have to: when you name a plus on armor or a weapon, the wish secretly rolls a number from 1 to 5, and if your plus is greater than that roll the enchantment collapses to +0. So +1 always lands, +2 lands four times in five, +3 only three in five, and anything past +5 never lands at all. A +3 wish has the higher average if it lands, but ask for +2 anyway: the plus is steadier, and once you top it off with enchant scrolls it ends up a hair ahead of where a +3 wish would have left you.
- Mind your Luck before you wish. Non-negative Luck is all you need, and piling up more buys you nothing extra at the prompt. Negative Luck, though, poisons the whole wish: `blessed` comes out cursed, `fixed` fails to hold, and any plus above +2 flips to a minus. If your Luck has soured, mend it before you spend a wish on gear.
- "gray dragon scale mail" alone lets the dice pick the BUC and the enchantment, so a bare wish can land cursed. You had *one* wish; spell out the BUC and the plus. And don't forget "scale": "gray dragon mail" alone hands you a scroll of mail instead.
- Artifact wishes get *harder* as artifacts accumulate. The denial roll scales with the total artifacts in the world (yours, generated, even bones-file ones), and your artifact-wish counter ticks whether the artifact appears. Quest artifacts are absolutely blocked.
- A few targets are silently nerfed into mundane substitutes. The **Amulet of Yendor** becomes a fake amulet, the **Bell of Opening** a plain bell, the **Book of the Dead** blank paper, and the **Candelabrum** a tallow candle. A wish for a **magic lamp** also fails, handing you an ordinary oil lamp. Cruel, after all that lamp-rubbing.

---

### Artifacts {#artifacts}

Scattered throughout the Mazes are items of legend: named weapons, amulets, and tools that carry powers no ordinary gear can match. Each artifact exists only once per game. Here's how they come into your hands:

- **Fountain dipping** (Excalibur, for Lawful characters).
- **Sacrifice** on an altar (your god may gift you an aligned artifact).
- **Quest completion** (each role's unique quest artifact).
- **Wishing** (you can wish for most artifacts, but they resist if they don't match your alignment).
- **Random generation** (rare, but weapons have a small chance of being generated as an artifact).
- **Naming** (Sting and Orcrist only; see below).

#### Alignment and Blasting {#alignment-and-blasting}

Each artifact has an alignment. If you try to handle an artifact that doesn't match your alignment:

- **Intelligent artifacts** blast for 4d10 on every touch when your role or alignment is wrong (2d10 with magic resistance). The item evades your grasp only when both are wrong.
- **Other misaligned artifacts** have a 1-in-4 chance on every touch to blast for 4d4 damage (2d4 with magic resistance).

#### Wishable / random artifacts {#wishable-random-artifacts}

These are the artifacts you can find, get from a sacrifice gift, fountain-dip up (Excalibur), or wish for. Bonus damage is rolled fresh on each hit (e.g. `+d10` means roll 1d10). The "extra" column is the damage rolled *on top of* the base weapon's own damage. A weapon listed as "×2 vs X" rolls its base damage *twice* against any member of that monster class.

| Artifact               | Align    | Weapon            | Hit    | Extra damage           | Notable                                                |
|------------------------|----------|-------------------|--------|------------------------|--------------------------------------------------------|
| Excalibur         | Lawful   | long sword        | +d5    | +d10 physical               | drain resistance, automatic searching                  |
| Grayswandir       | Lawful   | silver saber      | +d5    | ×2 physical                 | hallucination resistance                               |
| Mjollnir          | your alignment | war hammer   | +d5    | +d24 shock                  | Valkyries catch it 99% of the time; STR 25 to throw    |
| Magicbane         | Neutral  | athame            | +d3    | +d4 magic (stun)            | magic resistance and curse protection while *wielded*  |
| Stormbringer      | Chaotic  | runesword         | +d5    | +d2 drain life              | drains a level and heals you; attacks peacefuls        |
| Vorpal Blade      | Neutral  | long sword        | +d5    | +d1 physical                | chance to behead on hit                                |
| Frost Brand       | any      | long sword        | +d5    | ×2 cold vs non-resistant    | cold resistance while wielded                          |
| Fire Brand        | any      | long sword        | +d5    | ×2 fire vs non-resistant    | fire resistance while wielded                          |
| Sunsword          | Lawful   | long sword        | +d5    | (base only); ×2 vs undead   | wielded light; `#invoke` fires a blinding ray any direction (camera-style; works on any monster) |
| Snickersnee       | Lawful   | katana            | —      | +d8 physical                | one free reach attack per turn (the "Shkinng!" hit) at polearm distance, on top of normal katana melee |
| Cleaver           | Neutral  | battle-axe        | +d3    | +d6 physical                | two-handed; every swing also strikes both flanks       |
| Demonbane         | Lawful   | silver mace       | +d5    | (base only); ×2 vs demons   | banishes demons; Priest's first sacrifice gift         |
| Sting             | Chaotic  | elven dagger      | +d5    | (base only); ×2 vs orcs     | warns of orcs (the dagger glows blue)                  |
| Orcrist           | Chaotic  | elven broadsword  | +d5    | (base only); ×2 vs orcs     | warns of orcs                                          |
| Grimtooth         | Chaotic  | orcish dagger     | +d2    | +d6 physical (any target)   | warns of elves; defends vs poison                      |
| Dragonbane        | any      | broadsword        | +d5    | (base only); ×2 vs dragons  | reflection while wielded                               |
| Werebane          | any      | silver saber      | +d5    | (base only); ×2 vs were-    | defends against lycanthropy                            |
| Giantslayer       | Neutral  | long sword        | +d5    | (base only); ×2 vs giants   | —                                                      |
| Ogresmasher       | any      | war hammer        | +d5    | (base only); ×2 vs ogres    | —                                                      |
| Trollsbane        | any      | morning star      | +d5    | (base only); ×2 vs trolls   | regeneration while wielded                             |

Not every entry is equally desirable. **Grayswandir** and **Magicbane** are the artifacts most players try to wish for first; **Mjollnir** is the Valkyrie's archetypal wish; **Excalibur** is usually fountain-dipped rather than wished. **Frost Brand**, **Vorpal Blade**, and **Stormbringer** are common second wishes. In 5.0, **Snickersnee** adds a free reach attack each turn, while **Sunsword** can blind on demand. The remaining entries (the bane weapons, Fire Brand, Cleaver) are usually accepted as sacrifice gifts rather than spent wishes on.

**[Excalibur]{#excalibur-artifact}** is the go-to weapon for Lawful characters; the drain resistance alone is worth carrying it, even after you have a stronger weapon. At XL 5 or higher, Knights have 1-in-6 fountain-dip odds; every other Lawful role faces 1-in-30.

**[Grayswandir]{#grayswandir}** is wishable and one of the strongest melee weapons in the dungeon. It's silver (extra damage to many monsters), doubles its physical damage on every hit, adds +d5 to-hit, and grants hallucination resistance.

**[Mjollnir]{#mjollnir}** is the Valkyrie's signature throw-and-return weapon: only Valkyries catch it back 99% of the time. Other roles can wield it in melee, but throwing it is risky because it will not return to them. Anyone can wield it; Strength 25 is required only to throw it (gauntlets of power get you there). +d24 shock damage is brutal against anything not shock-resistant.

**[Magicbane]{#magicbane}** is the Wizard's go-to athame. Its stun damage, curse protection, and magic resistance all require it to be **wielded**, not just carried. Often the first gift from a Neutral sacrifice. One nuance for two-weapon Wizards: the curse protection only applies while Magicbane is the *primary* wielded weapon. If you stash Magicbane in the off-hand to swing a heavier blade, you've also turned off its anti-curse aura.

**[Stormbringer]{#stormbringer}** is dangerous because it attacks peaceful monsters automatically, which can wreck your alignment. Each hit drains a level from the target and heals you for half the HP the victim loses; it does not grant you that experience level. Stormbringer is also *intelligent*: a Lawful or Neutral wielder takes 4d10 blast damage on touch, not the 4d4 that ordinary cross-aligned artifacts deal.

**[Cleaver]{#cleaver}** is the Barbarian quest artifact. It is a two-handed battle-axe, so it cannot be paired with a shield. Every swing strikes the primary target and the two flanking squares: useful at a corridor mouth, hazardous beside peaceful creatures.

**[Frost Brand]{#frost-and-fire-brand}** and **Fire Brand** each have an `#invoke` power the wishable table doesn't capture: Frost Brand summons a snowstorm around you (cold damage to nearby squares), Fire Brand summons a firestorm. Either one clears the room around you when you're cornered.

**[Snickersnee]{#snickersnee}** got a major buff in 5.0: once per turn you can `a` (apply) it for a reach attack at a target up to two squares away, *without* using your turn — you still get a normal melee swing on top. The free hit is announced by a distinctive "Shkinng!" That combined output (one reach + one melee per turn) puts Snickersnee ahead of a plain katana for most Samurai.

**[Sunsword]{#sunsword}** is the Lawful long sword that wants to be a tool. Wielded, it lights its current radius (handy in caves and [the Mines](#the-gnomish-mines) without costing an oil lamp). `#invoke` it for a directed *blinding ray*, mechanically a camera flash in any direction (not limited to undead). Invoking a rested artifact costs no Pw and starts a cooldown of about 100 turns. Up or down lights only your own square; invoking at yourself self-blinds you. During cooldown, Sunsword can spend 25 Pw to fire anyway.

**[Bane weapons]{#bane-weapons}** (Sunsword, Demonbane, Sting, Orcrist, Grimtooth, Dragonbane, Werebane, Giantslayer, Ogresmasher, Trollsbane) deal double base damage against their target class. Their base damage is modest, but the defensive powers often decide when to swap one in: Trollsbane regenerates while wielded, Dragonbane reflects, Werebane neutralizes lycanthropy, Grimtooth defends against poison.

**[Naming Sting and Orcrist]{#naming-sting-orcrist}.** These two elven blades are the only artifacts you can call into being just by naming them, with no wish or sacrifice required. Name a single elven dagger "Sting" or a single elven broadsword "Orcrist," and as long as that artifact has not already appeared in your game, the blade turns into the genuine article on the spot. It must be a lone blade rather than a stack, so split one off first if you are carrying several. Wielded, each glows blue when orcs are near and strikes them for double damage, part alarm and part weapon for the trip through the Gnomish Mines. Both are chaotic, so a chaotic hero carries one cleanly, while anyone else takes the occasional blast for holding a blade out of alignment.

#### Quest artifacts {#quest-artifacts}

Each role has one quest artifact, awarded for completing that role's quest. These artifacts are intelligent: a role or alignment mismatch causes a 4d10 blast on every touch, and an artifact evades you when both mismatch. Three of the nine non-weapon quest artifacts grant magic resistance merely by being carried: the Orb of Detection, Magic Mirror of Merlin, and Platinum Yendorian Express Card.

Quest artifacts cannot be wished for; they must be earned in their role's quest. The table distinguishes **carry** powers, which operate from open inventory, from **wear/wield** powers. Magic resistance is a carry power on the Orb of Detection, Magic Mirror of Merlin, and Platinum Yendorian Express Card, but requires wearing or wielding the items that grant it in the other rows.

`M-i` (or `#invoke`) activates an artifact's special power. A rested artifact costs no energy, then ignores further invocations for about 100 turns. Sunsword and Grimtooth alone may spend 25 Pw to fire their powers during that cooldown.

| Role | Artifact                            | Form           | Wear/wield                          | Carry                    | `#invoke`           |
|------|------------------------------------------|----------------|-----------------------------------|--------------------------|---------------------|
| Arc  | The Orb of Detection                    | crystal ball | —                                     | MR, ESP, ½ spell dmg     | invisibility        |
| Bar  | The Heart of Ahriman                    | luckstone    | ×2 dmg as a projectile                | stealth, +luck           | levitation          |
| Cav  | The Sceptre of Might                    | mace         | +d5 hit; ×2 vs non-lawful; MR          | —                        | conflict            |
| Hea  | The Staff of Aesculapius                | quarterstaff | drain-life on hit; drain res.; regen  | —                        | heal ½ missing HP; cure sickness, slime, blindness |
| Kni  | The Magic Mirror of Merlin              | mirror       | (speaks to you)                       | MR, ESP                  | —                   |
| Mon  | The Eyes of the Overworld               | lenses       | astral vision, magic res. (when worn) | —                        | enlightenment       |
| Pri  | The Mitre of Holiness                   | helm         | +1 prot. (brilliance base)            | fire res.                | energy boost        |
| Ran  | The Longbow of Diana                    | bow          | +d5 hit; reflection                   | ESP                      | conjure arrows      |
| Rog  | The Master Key of Thievery              | skeleton key | —                                     | warn, t-ctrl, ½ phys     | guaranteed untrap   |
| Sam  | The Tsurugi of Muramasa                 | tsurugi      | +d8 phys; chance to behead; +1 prot.  | +luck                    | —                   |
| Tou  | Platinum Yendorian Express Card         | credit card  | —                                     | MR, ESP, ½ spell dmg     | charge an item      |
| Val  | The Orb of Fate                         | crystal ball | —                                     | +luck, warn, ½ all dmg   | level teleport      |
| Wiz  | The Eye of the Aethiopica               | amulet       | MR (worn)                             | ½ spell, +energy         | portal to a visited branch |

**[The Orb of Detection]{#orb-of-detection}** (Archeologist): a crystal ball that grants ESP and magic resistance just by being carried. `#invoke` toggles invisibility. Archeologists are already exceptional at stealth, and that turns them into a ghost.

**[The Heart of Ahriman]{#heart-of-ahriman}** (Barbarian): a true luckstone (so it raises the Luck cap to +13 and counts everywhere a luckstone does), plus stealth. Barbarians can also throw it for double damage and pick it back up. `#invoke` is levitation.

**[The Sceptre of Might]{#sceptre-of-might}** (Caveman): mace base, +d5 to-hit, double damage against any monster whose alignment differs from the artifact's (the Sceptre itself is Lawful, so it deals doubled damage against chaotic, neutral, *and* unaligned monsters: most of the dungeon's hostiles once you reach [Gehennom](#gehennom)). It also grants magic resistance while *wielded*. `#invoke` toggles conflict without an energy cost when the artifact is rested.

**[The Staff of Aesculapius]{#staff-of-aesculapius}** (Healer): each hit drains life; Stormbringer is the only other drain-life weapon. Regeneration and drain resistance require the Staff to be wielded. `#invoke` heals half your missing HP and cures sickness, sliming, and blindness.

**[The Magic Mirror of Merlin]{#magic-mirror-of-merlin}** (Knight): grants ESP and magic resistance, and occasionally whispers a rumor when applied or wielded. Knights already have Excalibur for combat, so the Mirror rides along as a talking insurance policy.

**[The Eyes of the Overworld]{#eyes-of-the-overworld}** (Monk): lenses that, when worn, give astral vision—x-ray sight in a radius of three— **and** magic resistance. Both effects require them to be worn; carrying them in inventory does nothing. `#invoke` enlightens you. For a Monk who can't safely wear body armor, a powerful passive on a slot they can use.

**[The Mitre of Holiness]{#mitre-of-holiness}** (Priest): a helm of brilliance with the usual brilliance bonus to intelligence and wisdom (so spells cast more reliably), plus fire resistance while carried, plus extrinsic Protection that adds 1 MC rather than AC. `#invoke` gives an energy boost, useful for spell-heavy Priests. The Mitre does **not** deal bonus damage against undead (the artifact has no melee attack to carry the bonus), and it does not grant drain resistance.

**[The Longbow of Diana]{#longbow-of-diana}** (Ranger): a real artifact bow with +d5 to hit plus reflection while wielded, ESP while carried. `#invoke` conjures free arrows out of thin air. Combined with the Ranger's ranged specialization that is the role's centerpiece.

**[The Master Key of Thievery]{#master-key-of-thievery}** (Rogue): just carrying it grants warning, teleport control, and half physical damage taken. When applied to a lock, the Key finds traps; using `#untrap` on a door or chest then succeeds automatically. For a Rogue that works with any non-cursed Key; everyone else needs it **blessed**.

**[The Tsurugi of Muramasa]{#tsurugi-of-muramasa}** (Samurai): a katana-grade two-handed sword with +d8 damage *and* a behead chance (like Vorpal Blade) *and* a +1 protection bonus, and it acts as a luckstone. Note that Tsurugi does **not** grant magic resistance, despite the weapon's reputation. One of the strongest artifacts in the game, the Samurai's reward for a hard quest.

**[The Platinum Yendorian Express Card]{#platinum-yendorian-express-card}** (Tourist): the Tourist's get-out-of-jail card. Carrying it grants ESP, magic resistance, and half spell damage; `#invoke` charges an item (a wand, ring, or marker). It can add one charge to a wand of wishing, but that wand still survives only one recharge.

**[The Orb of Fate]{#orb-of-fate}** (Valkyrie): the most generous carried passive in the game — counts as a luckstone, grants warning, and halves both spell *and* physical damage taken. `#invoke` performs a level teleport.

**[The Eye of the Aethiopica]{#eye-of-the-aethiopica}** (Wizard): grants magic resistance when **worn**; carrying also gives half spell damage taken and *extra energy regeneration*. `#invoke` offers a menu of dungeon branches you have already visited and opens a portal to the chosen one.

---

### Into Gehennom {#into-gehennom}

#### The Castle {#the-castle}

The Castle ends the Dungeons of Doom and guards the only route into Gehennom. Clear it as a supply depot: the wand of wishing and the storerooms are the last reliable chance to repair a weak kit.

The drawbridge is the first puzzle. You can lower it four ways:

- **Play the passtune.** A five-note musical sequence played on any tonal instrument (wooden flute, magic flute, tooled horn, frost or fire horn, bugle, harp) opens the drawbridge. The notes are randomized per game. You can learn them by trying different sequences: the game tells you how many notes are correct after each attempt, like a game of Mastermind. The bridge must be in one of the eight squares around you for the tune to work. Do not stand on the span or its doorway; those are the squares that can crush you when the bridge moves. The notes are A–G; "H" is also accepted, in the German notation where it means B.
- **Wand of opening** pointed at the drawbridge.
- **Spell of knock** cast at the drawbridge.
- **Wand of striking** *destroys* the drawbridge entirely. The span drops into the moat and becomes water again. The tune is useless afterward, so bring another way across.

Once you're across, the Castle contains:

- A **throne room** with a throne and a random court of high-letter monsters (liches, nymphs, eyes, giants, and the like). Sitting on the throne is tempting but risky (see [Points of Interest](#points-of-interest)). The throne room also holds a separate **treasure chest** with random loot. That is not the wand chest, just a side prize.
- **Barracks** full of soldiers carrying decent equipment, which is to say *your* equipment once you've dealt with them.
- **Four corner-tower alcoves**. One (and only one, randomly) contains the **wand of wishing** in a locked chest. *Search them all*, or quaff a potion of object detection from the courtyard to see which tower holds the chest and skip the other three. That chest also holds a **potion of gain level**. The chest's square is protected by a burned-in [*Elbereth*](#elbereth) engraving and sealed with a cursed scroll of scare monster. Those wards keep food-eating monsters such as gelatinous cubes away from the chest. The cursed scroll is also a known gotcha: don't try to read it casually. The locked chest opens by force, by a key, or by a wand of opening.
- Four **storerooms** along the north and south walls, each guarded by a dragon (`D`-class). Don't confuse them with the corner alcoves; they hold armor, weapons, gems, and food, one class per room.
- A **central hallway lined with five trap doors**. Stepping on one drops you straight to the Valley of the Dead, which is rarely what you want at this stage. Watch the floor. The trap doors are also the *only* way down from the Castle: the level has no conventional `>` stair to [Gehennom](#gehennom), so when you are ready to descend, you do so by deliberately stepping on one.
- A **fountain** in the moat-side corridor, usable in emergencies but not worth risking the wand of wishing for.
- A **moat** surrounding the fortress, occupied by giant eels and the occasional shark.

Strategy: clear the Castle carefully. A ring of conflict turns the guards against each other: walk in, put on the ring, and let the soldiers solve your monster problem for you. Loot everything. Then use your wand of wishing to fill critical gaps in your equipment (gray dragon scale mail, silver dragon scale mail, gauntlets of power, speed boots, whatever you're missing).

The locked Castle wand chest is **safe to leave temporarily**: monsters in 5.0 can pick up and rummage through *unlocked* containers, and they can unlock doors with keys, but they cannot unlock chests. A chest that started life locked stays locked until you or a wand of opening intervene.

The Castle wand yields only two wishes on its own (its charge plus a wrested second), so plan a *small* wishlist and accept that further wishes must come from other sources: Vlad's throne, the Amulet pickup, Orcus Town's lamp, or fountain luck (see [Key Wands](#key-wands) for the full mechanics).

Once you're fully equipped, take a moment before descending. Sit down. Have a snack. Check your inventory twice. You should have **[magic resistance](#damage-resistances)**, **reflection**, **fire** and **[poison resistance](#damage-resistances)**, a **wand of digging**, a **unicorn horn**, plenty of food, holy water, scrolls of teleportation and identify, and your **quest artifact**.

---

#### Gehennom {#gehennom}

Below [the Castle](#the-castle) the dungeon changes its character. Corridors give way to mazes, ordinary monsters to demons. Worst of all, your god goes silent. Prayer fails in Gehennom, and from that point on you survive on what you packed at the Castle.

#### The Valley of the Dead {#the-valley-of-the-dead}

The first level of Gehennom, immediately below the Castle, is the **Valley of the Dead**. The arrival message reads *"You arrive at the Valley of the Dead..."* and the dungeon overview marks the level for the rest of the game. The map is a wide irregular level with three graveyards scattered across it. You arrive in the lower right; the down stair is in the upper left, while the permanent **shrine to Moloch** stands midway along the left side. The shrine sits on an unaligned high altar; do not pray here. The walls are non-diggable everywhere, so no shortcuts, and both `noteleport` and `nommap` are set, which means magic mapping will not reveal the level and teleportation does not work.

A morbid detail worth noticing. Scattered across the level are **dead bodies of every player role** the dungeon has ever seen descend: two corpses each of Archeologists, Barbarians, Cavemen, Healers, Knights, Rangers, Rogues, Samurai, Tourists, Valkyries, and Wizards. Pointedly absent: no Priests and no Monks. Moloch may have a special fate reserved for members of those classes.

#### What's Different in Gehennom {#whats-different-in-gehennom}

- **No prayer.** Your god is deaf to you in Gehennom (unless you are a Moloch worshipper, and you are not). No emergency healing, no food rescue, no curse removal via divine intervention. Pack accordingly; from here on you are on your own.
- **Fire everywhere.** Fire traps litter the corridors, and demons breathe fire as casually as you breathe air. If you do not have [fire resistance](#damage-resistances) by now, turn around.
- **Hot ground.** A potion dropped on the floor can shatter harmlessly; a fire trap is what threatens potions throughout your pack. Do not drop a valuable bottle just to rearrange inventory.
- **Lava.** Rivers of lava split some levels. Levitation or flying carries you across, and so do fireproofed water-walking boots. The neatest trick: a blast of cold (a wand of cold, the cone-of-cold spell, a frost horn, or cold breath) freezes lava permanently into ordinary floor, opening a walkway straight across. Without fire resistance, lava kills on contact. With fire resistance you sink and have about a dozen turns to levitate, teleport, or step free.
- **Demon lords on specific levels.** Asmodeus, Baalzebub, Juiblex, and Orcus hold court on private throne levels. Each fight is a major battle, several can summon reinforcements, and all of them are angry you are here. Their lairs and the bribery rules get their own section below.
- **Teleportation restrictions.** Teleportation is blocked on a demon lord's lair level while that lord still lives. Kill or banish them and the restriction lifts. In older editions, most Gehennom levels permanently blocked teleportation, which is no longer the case.
- **Mazes.** Nearly every level is a maze. A wand of digging or a pickaxe is no longer optional. Dig straight lines to the stairs and don't look back.

#### The demon-prince lairs {#the-demon-prince-lairs}

Three of Gehennom's special levels are the personal thrones of **Asmodeus** (fire-, cold-, and poison-resistant, casts cold spells, carries wands of cold and fire), **Baalzebub** (the Lord of the Flies, with a stunning gaze and a poisonous bite that drains Strength; his lair is a beetle-shaped maze), and **Juiblex** (the Faceless Lord, a slime that engulfs in melee and spits acid). They wait in their lairs until they see you; after that, they can follow you on stairs.

**Four demon princes accept bribes: Asmodeus, Baalzebub, Geryon, and Dispater.** The demand is a random fraction of the gold in your main inventory, so stash most gold in a bag and leave a small payment outside it. Approaching with no open gold makes the prince attack. All four are lawful, so a lawful visitor pays half. Juiblex, Yeenoghu, Orcus, Demogorgon, and the rest attack on sight.

Fighting Juiblex is viable late game, but he engulfs in melee, so keep your distance. Demons are immune to death rays; use an ordinary damaging attack, a banishing artifact, or another escape. A *refused* bribe converts the prince to permanent hostility, and he will not offer terms again. Bribe or fight.

**Wielding [Excalibur](#excalibur-artifact) or Demonbane closes off bribery entirely.** A prince who sees either weapon in your hand attacks at once, so sheathe it before you approach.

#### Vlad's Tower {#vlads-tower}

A three-level tower branching **upward** off Gehennom, one of the only side-branches in the lower dungeon. **Vlad the Impaler**, a unique vampire lord, guards the **Candelabrum of Invocation** at the top. Climb the tower, kill Vlad, take the Candelabrum.

The tower also contains a **special throne**, and 5.0 has made it both more rewarding and more painful. The good news: it never disintegrates from sheer use the way ordinary thrones do, so you can sit on it again and again. The bad news: you will, because the prize is rare. Each sit rolls one of thirteen effects. Four of them grant a wish (the throne *does* disintegrate after the wish, having spent its power). The other nine are bad: permanent level drain, an inventory-coating layer of grease (your weapon will slip, your shield will fall off), a stripped intrinsic, a forced level teleport to the vibrating-square level (sometimes useful, often not), three summoned demons, a confused-blessed remove curse on your gear, forced polymorph, 50+8d6 acid damage (about 78 on average) if you do not have acid resistance, or a randomized stat shuffle that will probably make several of your scores worse.

The arithmetic: only one sit in three picks an effect at all (the other two roll "you feel out of place" and do nothing), and of those that fire, 4/13 are the wish. The unconditional rate is about 1 in 10, so plan on roughly ten sits before the wish lands, with about two bad effects along the way. Stand at full HP, leave any precious gear behind (a grease hit coats your whole pack and makes your hands slippery for 100 to 200 turns, dropping items when you try to use them), and have [acid resistance](#damage-resistances) before you sit. Acid can deal up to 80 HP, and magic resistance blocks none of the throne's bad effects. If you do not want a forced wish right now (say, you have already used your Castle wish and Amulet wish and want to keep this one for the ascension kit), you can come back later. The throne stays put unless something destroys it.

#### Orcus Town {#orcus-town}

**Orcus** is a god of the underworld in Roman mythology, a chthonic figure who punishes broken oaths and devours the dead. In the Mazes he is a unique demon prince (`&`, level 66, a slow flier at speed 9), the **Prince of Undead**, who casts spells, swings a weapon, claws twice, and stings for strength drain. His weapon is an ordinary **wand of death**, not an artifact. His fingertip cantrip is also a death ray, so bring reflection or magic resistance. Orcus is a demon and ignores your own death ray; use physical damage or another attack type.

His level is a ghost town. Its abandoned shops contain random loot, not merchandise, and no shopkeepers remain to demand payment. What remains is an honor guard of liches, vampires, and ghouls. Somewhere on the level the dungeon guarantees either a **magic lamp** or a **magic marker** (50/50). Walk carefully, since fire and magic traps are everywhere; deal with the residents, and lift the lamp or marker on your way out. Either one extends the wishes you can pull from the Castle wand.

#### The Wizard's Tower {#the-wizards-tower}

A sequence of three special Gehennom levels. The portal enters at the bottom; the **Wizard of Yendor** and **Book of the Dead** wait at the top. His attacks are survivable; the problem is that he keeps coming back. He teleports to you, summons monsters, steals the Amulet, and curses your gear for the rest of the game.

Kill him cleanly the first time, grab the Book, and move on. Subsequent kills don't yield new loot (he respawns), so don't engage him voluntarily again. The "Run, don't fight" advice for the Ascension Run is mostly about him.

#### Moloch's Sanctum {#molochs-sanctum}

The bottom level of Gehennom. It is **sealed**: until the Invocation ritual is performed (see "The Heist" below), the down-stair to the Sanctum doesn't exist. Once the seal breaks, descend to find the **High Priest of Moloch** carrying the **Amulet of Yendor** near the **high altar**. The High Priest is a unique non-bribable boss who casts spells, summons minions, and punishes anyone in melee range. The standard answer is a wand of death or finger of death from a safe distance.

#### The Heist {#the-heist}

The climax of the game is a choreographed sequence: three Invocation items, one vibrating square, one final boss, and one frantic climb back to the surface. Everything up to the invocation can be done at your own pace. Afterward, covetous monsters start hunting you and delays become expensive. Have the whole kit ready before you begin. The steps:

1. **Collect the trio.** You need the **Bell of Opening** (the Quest goal, dropped by your quest nemesis), the **Candelabrum of Invocation** (the top of [Vlad's Tower](#vlads-tower)), and the **Book of the Dead** (the top of the Wizard's Tower). Missing any one means walking all the way back to fetch it; the Bell in particular is easy to leave behind on the nemesis's corpse the first time through [the Quest](#the-quest).

2. **Attach all seven candles to the Candelabrum.** Apply (`a`) each candle and select the Candelabrum. Candles spawn often enough that you'll usually have enough, but you need a source for seven: **Izchak's lighting shop in Minetown** is the clean answer, or seven are scattered on that level if the shop is absent (Orcish Town layout).

3. **Find the vibrating square.** On the Gehennom level directly above [Moloch's Sanctum](#molochs-sanctum), a single square vibrates when you step on it: *"You feel a strange vibration under your feet."* The square's position is random within the maze, so you have to search by walking. Scrolls of magic mapping help enormously.

4. **Perform the Invocation.** None of the three items may be cursed. Standing on the vibrating square, apply the Candelabrum to light it, then apply the Bell to ring it. Within four turns, read the Book of the Dead. The floor opens and a down stair appears.

5. **Swipe the Amulet from Moloch.** Descend, take down the **High Priest** (a wand of death works), then take the **Amulet of Yendor** from the body.

6. **Begin the getaway.** Take the up stair; it was usable even before you held the Amulet. You are now on the **Ascension Run**. Every covetous monster in the game has noticed, the Wizard of Yendor will keep teleporting to you to take his Amulet back, and the Mysterious Force will keep yanking you back down. Climb fast (see [The Ascension Run](#the-ascension-run) below).

#### Survival Tips {#survival-tips}

- **Bring extra food.** You will be moving fast and prayer is not a reliable refill.
- **Bring scrolls of remove curse.** Fast inventory cleanup when something goes wrong.
- **Dig, don't navigate.** Maze walls are faster to go through than around.
- **Kill the Wizard quickly.** Every turn he lives is another summoned monster, another stolen item, another cursed piece of gear. He will come back (he always comes back), but the intervals between his appearances give you breathing room.
- **The Amulet anchors you.** Level teleportation does not work while you carry it. Every step back to the surface must be climbed by foot.
- **Genocide the lich class.** A blessed scroll of genocide applied to **L** removes liches, demiliches, master liches, and arch-liches in one read. Some of the worst Gehennom threats, gone for the rest of the run.

---

### The Ascension {#the-ascension}

#### The Ascension Kit {#the-ascension-kit}

The adventurers who died deep in Gehennom carried almost exactly that kit. Assemble it, then read the next section to see how they died anyway. Slot by slot:

| Slot | Typical pick | Notes |
|--------|------------------------|---------------------------------------|
| **Body** | Dragon scale mail | Gray (magic resistance) or silver (reflection) are the popular picks; blue (shock) also works. |
| **Cloak** | Cloak of magic resistance | Or a robe for casters. Magic resistance blocks death rays and the touch-of-death spell. |
| **Helm** | Helm of brilliance or helm of telepathy | Brilliance for casters; telepathy when you might be blind. |
| **Gloves** | Gauntlets of power | Skip them only if you have a different STR strategy (e.g. a Knight with a +STR ring). |
| **Boots** | Speed boots | Extra actions help every role. |
| **Shirt** | Hawaiian shirt or T-shirt | A free body slot under everything else. Heavy enchantment (typically blessed +4 or +5) buys several extra AC at no cost. |
| **Shield** | Mostly skipped | Reflection comes from silver dragon scale mail or an amulet instead; two-weapon fighters can't use a shield anyway. |
| **Amulet** | Amulet of life saving | The "extra life" plan. |
| **Ring (L)** | Free action | The Astral Plane is packed with paralyzing attacks; you want this on every step. |
| **Ring (R)** | Slow digestion, conflict, or regeneration | Conflict is the standard Astral-Plane crowd-control choice. |
| **Weapon** | Your best trained weapon; silver backup if practical | Only four quest artifacts are weapons. Silver adds damage against demons, imps, vampires, weres, and shades. |
| **Pack** | Bag of holding, unicorn horn, luckstone, wand of death, multiple wands of teleport, seven candles, ≥5 holy water, blessed full healing, shock protection | Holy water repairs curses; full healing is a one-action panic button; shock resistance or reflection protects against the Plane of Air's lightning. Riders resist stoning, so a cockatrice corpse is not an answer to them. |
| **Required loot** | Bell of Opening, Candelabrum of Invocation, Book of the Dead, Amulet of Yendor | The Invocation chain plus the prize. |

A typical ascension AC sits in the **−25 to −40** range.

##### What killed the runners-up {#what-killed-the-runners-up}

Their gear was nearly indistinguishable from the ascenders'. Their AC was −23 to −40. They had wands of death, all three Invocation items, silver dragon scale mail. What killed them was *behavior*:

- **Inventory management mid-combat.** An Archeologist on Dlvl 35 tried to open a tin while a jabberwock, a displacer beast, and a zruty were adjacent. The tin opener prompt took the turn she didn't have.
- **Eating when not hungry.** A Tourist with AC −40 and all three Invocation items, deep in Gehennom, chose to eat a stalker corpse while satiated and choked to death. The ring of [slow digestion](#special-and-utility) on her finger does not prevent choking.
- **Out of escape consumables.** A Wizard on Dlvl 50, within sight of the Sanctum, burned the last wand-of-death charge without any further escape route, then died blind and surrounded.

Keep at least one escape consumable within reach: a scroll of teleportation, a wand of digging, or an oilskin sack with a potion of full healing.

---

#### The Ascension Run {#the-ascension-run}

You did it. You fought through [Gehennom](#gehennom), defeated the High Priest, and snatched the Amulet of Yendor from [Moloch's Sanctum](#molochs-sanctum). Now all you have to do is carry it from the absolute bottom of the dungeon, through every level of Gehennom, past every demon lord you thought you were done with, all the way back to the surface, and then through the Elemental Planes to the Astral Plane where your god awaits. Easy, right?

**A free wish on pickup.** The moment you pick up the Amulet of Yendor, your god grants you a single wish on the next turn. It fires automatically; you do not need to invoke it. Have your wish list ready *before* you reach the Sanctum: gauntlets of power, a +5 weapon of your choice, a blessed cloak of [magic resistance](#damage-resistances), or whatever you are missing for the climb. You only get that wish once. A cursed potion of gain level does move you upward, but it still provokes the Mysterious Force in Gehennom.

**Bring the authentic Amulet.** The climb out is always open. Every up-stair in the Dungeons of Doom takes you closer to the surface regardless of what you carry. On dungeon level 1, the up stair takes a bearer of the real Amulet to the Plane of Earth; without it, climbing out ends the game as an escape. Only the Amulet you took off the High Priest's body in Moloch's Sanctum counts. Bones-pile Amulets are fakes (the game converts a dead adventurer's real Amulet to a fake when their corpse becomes a bones level), and a wish for an Amulet of Yendor silently substitutes a fake too. If you didn't pick yours up off the High Priest, you don't have the real one.

##### The Gauntlet {#the-gauntlet}

The dungeon now opposes you on four fronts, all of them aimed at the Amulet in your pack:

- **The Wizard of Yendor** periodically teleports to your location, summoning monsters and reaching for the Amulet. He will not stop. Kill him each time. He always comes back. He is the world's most persistent ex.
- **The Amulet blocks teleportation.** You cannot level teleport while carrying the Amulet. Every single staircase from the bottom of Gehennom to the surface has to be climbed by foot.
- **Covetous monsters.** Demon lords and the Wizard can warp directly to your position and attack. They are specifically targeting you for the Amulet, because apparently everyone wants that thing.
- **The Mysterious Force.** While you carry the Amulet in Gehennom, each time you climb stairs there is a chance the force grabs you instead. Conditional on a force trigger, it keeps a Lawful hero on the same level one time in four, a Neutral one time in three, and a Chaotic one time in two. Otherwise it drops you **down** a level (Chaotic max), two levels (Neutral max), or even three (Lawfuls only). The worst yank is hardest on Lawfuls and gentlest on Chaotics: a Chaotic climb can never lose more than one level at a time. In 5.0 the trigger chance also **decays** as it fires. Every yank slightly reduces the chance of the next one, and deeper yanks reduce later triggers more. That decay benefits Lawful heroes most and Chaotic heroes least. The force stops the moment you climb out of Gehennom, and it never fires on the bottom four levels.
- **Consider an alignment detour.** A helm of opposite alignment flips Lawful to Chaotic and Chaotic to Lawful; a Neutral hero lands Lawful or Chaotic at random. Chaotic caps every yank at one level. The cost is that your Astral offering then goes to the Chaotic altar, since the altar check uses your *current* alignment. An optimization choice, not a free lunch.

##### Strategy {#strategy}

You are no longer an explorer. You are a running back carrying the ball through the entire opposing team. Speed is everything.

- **Run, don't fight.** Don't explore. Don't loot. Just go up. Every turn you spend fighting something optional is a turn the Wizard gets closer to stealing back his Amulet.
- **Dig.** Use your wand of digging to reach staircases quickly. Straight lines through walls beat wandering through corridors.
- **Zap problems away.** Teleportation wands move monsters out of your path. Death wands remove them permanently. Use both liberally.
- **Casters: drop the Amulet to cast.** Carrying the Amulet adds an extra 1–2× the spell's base cost on every cast, so you pay roughly 2–3× total. Drop the Amulet, cast your finger of death or magic mapping, pick it back up. The three-turn round trip is cheaper than the Pw burn.
- **Kill the Wizard fast.** When he shows up (and he will), don't try to be clever. Finger of death, wand of death, or brute force. The faster he's down, the fewer monsters he summons.
- **Don't rely on Elbereth past [the Castle](#the-castle).** Elbereth is **completely ignored** in all of Gehennom and on all four Elemental Planes plus Astral. Writing it grants no alignment, and no monster there will care. Plan your heal-and-recover breaks around corridors, scrolls of teleportation, and conflict instead.

If you packed well at the Castle and your resistances are solid, that is a sprint, not a marathon. Once you reach the top of the Dungeons of Doom, the final staircase leads to the Elemental Planes: the last obstacle between you and divinity.

---

#### The Elemental Planes {#the-elemental-planes}

Beyond the top of the Dungeons of Doom, the world dissolves into its raw elements. Four planes stand between you and the gods, each one a different flavor of hostile. There are no stairs here, only magic portals, hidden somewhere on each plane, leading to the next. Each plane is a closed world; the portal you find is the only way out of it, and it closes behind you.

**Two cheap ways to find a portal.** A scroll of gold detection read while confused marks every trap on the level, the portal included: one read, one map. And the Amulet of Yendor is itself a compass while you carry it: wielded or worn, it occasionally mutters *hot*, *very warm*, or *warm* as you get closer (within 3, 8, or 12 squares of the portal). It's a hot/cold game you can play your way across the void.

##### Plane of Earth {#plane-of-earth}

You arrive in a small cavern in the corner of the plane. The light is dim, and two figures are already there to meet you: an Elvenking and a minotaur, both hostile. The plane is a constellation of small caverns scattered through diggable rock, and the portal to the Plane of Air is hidden in another one of them. The only way through is to dig. The other caverns hold earth elementals, stone giants, rock trolls, stone golems, pit fiends, dust vortices, and an umber hulk. Teleportation is sealed, so once a fight starts you cannot escape it on a wand. A wand of digging is essential. Magic mapping shows the caverns but not an unseen portal. Read gold detection while confused, or use a crystal ball to locate the portal before digging toward it.

##### Plane of Air {#plane-of-air}

The opposite extreme: an open void with no walls, no floor you can feel, just empty sky and air elementals moving faster than thought. They attack multiple times per turn and they cannot be genocided. A ring of conflict is useful here: let them tear each other apart while you search for the portal. Magic mapping does not reveal an unseen portal; confused gold detection or a crystal ball does. The plane is divided into drifting **cloud bubbles** that move on their own each turn, and if you are standing in a bubble when it shifts, you shift with it. Walking with the drift can carry you across the plane faster than fighting against it, and a bubble may eventually drift you onto the portal square itself.

Cloud lightning strikes about one turn in eight for 8d6 damage and has a one-in-three chance to fry exposed wands and rings. Shock resistance or reflection belongs in the kit; keep spare charged items inside a bag.

The plane bars its own shortcut. Self-teleportation meets only the message *"A mysterious force prevents you from teleporting!"* A wand of teleportation still moves whatever is chasing you; it just will not move you.

##### Plane of Fire {#plane-of-fire}

Lava lakes cover the plane, fire traps lie between them, and fire elementals and hell hounds roam. With fire resistance, most of that damage disappears and the problem becomes finding the portal. Without it, every crossing and encounter can burn both you and your inventory.

##### Plane of Water {#plane-of-water}

The plane is open water crossed by drifting air bubbles. You arrive inside one. Stepping into the water beside a bubble normally leaves you scrambling back into air; the serious drowning threat is a giant eel or kraken wrapping you and pulling you under. Magical breathing removes that danger, but it is not required merely to stand on the level.

**The standard tactic on arrival: genocide class `;`.** Read a scroll of genocide, target the entire `;` class (jellyfish, piranhas, sharks, giant eels, electric eels, krakens), and the plane instantly empties of anything that can drag you under. That is the right moment for that scroll. Class `;` is almost nowhere else in the game (a kraken occasionally appears in Medusa's pool, but that is the only other relevant encounter), and on the next plane it is irrelevant. Then find the portal and push through.

##### The Astral Plane {#the-astral-plane}

You surface into the presence of the divine. Three separate temples hold the Lawful, Neutral, and Chaotic altars. You must sacrifice the Amulet of Yendor on the altar matching your alignment to ascend. **Choose wrong and the game ends on the spot**: the opposing god gains dominion over your god, and you've handed victory to the other side. There is no retrying. Pick the right altar the first time. Farlook (`;`) shows an altar's alignment only when you are *adjacent* to it. From across the room you only see "an aligned high altar," so plan to walk within one square of each in turn until one matches yours.

The plane is swarming with Angels and the three **Riders**: Death, Famine, and Pestilence. They are level 30, regenerate while you fight, [see invisible](#senses-and-perception), and shove monsters out of their path. Each one hits twice per turn with a touch attack dealing 8d8 damage.

- **Death** moves with the slow inevitability of his name. Every touch is 8d8 damage, and roughly three in twenty land the kill itself. [Magic resistance](#damage-resistances) blocks the instakill but not the baseline damage; without magic resistance you live or die at random on every swing.
- **Pestilence** starts an illness timer of 20 plus your Constitution turns. Each later touch cuts the remaining time to one third. Sick resistance prevents it; otherwise apply a unicorn horn at once.
- **Famine** kills by accumulation. Each touch is 8d8 damage and 40 to 79 turns of hunger taken straight out of you. No single swing starves you; the exact number depends on the nutrition you had before the fight.

A slight mercy new in 5.0: if Pestilence or Famine land their first attack on a turn, their second downgrades to a stun.

**The Riders cannot be permanently killed.** They revive, they pursue, they do not stop. **Eating any Rider corpse is instantly fatal.** You are not here to fight; you are here to reach one altar, make one sacrifice, and end this.

If you have to pick which Rider to engage first, **Pestilence is the one to fear most**: the sickness timer keeps killing you after you've moved away, and unicorn-horn cures sometimes lose the race. Death's instakill is blocked by magic resistance; Famine you can outrun with a stack of food.

**Defenses.** An **amulet of life saving** is the best insurance on Astral. Magic resistance stops Death's instakill. Sick resistance handles Pestilence (green dragon scale mail is a source). Carry plenty of food and a unicorn horn. All three Riders resist stoning; a cockatrice corpse will not remove them. A ring of **conflict** can turn surrounding monsters on one another, but a high-level Rider may resist it most turns. Do not put the ring on while your guardian Angel is still present: it vanishes and your god replaces it with two to four hostile Angels. Teleportation wands can clear a path through the crowds; note that **self-teleport fails on every elemental plane**, so zapping the wand at yourself does nothing. Only zapping it at others teleports them.

**Don't zap a wand of death at Death.** It heals him. Magic missile works on all three Riders; use that instead.

Offer the Amulet at the correct altar. Your god accepts the gift, the Amulet vanishes into the divine flame, and you ascend among the immortals. Few adventurers reach this moment. The book closes here. Congratulations.

---

## Appendices {#appendices}

### Advanced Controls {#advanced-controls}

The basic keys handle every situation in the Mazes; the commands below handle them faster. Once you've spent a few thousand turns hammering `s` and walking corridors one square at a time, you may find they become reflexive.

#### Command counts {#command-counts}

Type a number before any command to repeat it that many times: `10s` searches ten times, `20.` waits twenty turns, `5h` walks west five times. The sequence interrupts automatically as soon as anything interesting happens (a monster appears adjacent, your HP changes, a `--More--` prompt fires, the search turns up something). Press ESC to cancel early.

Counts up to 32,767 are accepted (five digits), but the useful limit is "however long you'll watch the screen update without losing patience." `99s` is plenty for any real searching job.

#### Repeat last command (Ctrl+A) {#repeat-last-command-ctrla}

`Ctrl+A` runs whatever you just ran, with the same count if you used one. After your first `10s` of searching, every subsequent search is one keystroke. It remembers the *last command that actually executed*, not attempts that were canceled or bumped against a wall.

#### Movement prefixes {#movement-prefixes}

A handful of prefix keys modify the next command and then clear. Use them to attack a suspected monster, move without attacking, or choose how a long walk should stop.

- **`F`** then a direction is **force attack** into that square, even if no monster is visible there. Use it on suspected invisible monsters, on a displaced creature whose image is one square off from its real position, or to break your own [Elbereth](#elbereth). Double-tap `F` to cancel without acting.
- **`G`** then a direction runs until you approach an item, trap, branch, or closed door. **`g`** is more cautious and also stops at corridor forks. Capital-letter directions (`H`, `J`, `K`, `L`, and `Y`, `U`, `B`, `N`) use the fast run mode instead: they pass items, doors, and traps unless another stopping condition intervenes.
- **`m`** then a direction is **move without attacking and without picking up**. Walk past your pet without striking it ("Pardon me, Fido"), step past an autopickup heap, or step *into* a known pool or lava square on purpose: the prefix overrides the safety stop that would otherwise keep you out. Before `e`, the prefix skips the offer to eat food from the floor; before `a`, it has no special effect. `m,` forces a menu for a floor pile.

#### Travel {#travel}

The underscore key (`_`) is the "travel" command, a speedy autopilot. Press `_`, point at a destination you've already explored, then `.` to confirm, and your character walks the shortest path there. The walk stops on any interruption, including closed doors, which travel walks up to but doesn't open (press a direction to step through them, or `o` first). After `_`, you can type a background symbol to jump the cursor to the next one of that kind: `_<.` walks to the up-staircase, `_>.` walks to the down-staircase, `__.` walks to a known altar.

#### Forcing locked chests {#forcing-locked-chests}

`#force` (or `#f`) pries a locked chest open with your wielded weapon when you don't have a lockpick or key. Bladed weapons risk breaking the blade on the lock; blunt weapons risk destroying the chest's contents.

#### Message history and redraw {#message-history-and-redraw}

`Ctrl+P` walks backward through the message history one message at a time. A monster's special-attack warning, a shopkeeper's price quote, or a status onset is preserved long enough to read it twice. The default buffer holds 20 messages; older messages roll off silently.

`Ctrl+R` redraws the screen, a useful reflex when the terminal gets garbled or when something doesn't look right.

#### Dungeon overview and event journal {#dungeon-overview-and-event-journal}

`Ctrl+O` (or `#overview`) lists the interesting levels you've visited (including altars, thrones, fountains, sinks, shops, temples, graves, trees, annotations, bones, branch stairs, the deepest level in each branch, and [the Castle](#the-castle)'s tune once you learn it). Prefix with `m` to see *all* visited levels in a menu and add or edit annotations from there; `#annotate` does the same for the level you're standing on. The classic use is labeling stash floors so you remember which one held the bag.

`v` (or `#chronicle`) opens the **chronicle**, a chronological journal of major events from this run: your first kill, conduct breaks, artifact gifts and crownings, the first prayer, level milestones, and entries into major branches. Mainly for end-of-run storytelling; for current conduct state use `#conduct`.

---

### Customization {#options-worth-knowing-about}

NetHack's defaults are sensible, but five options prevent common input mistakes and make danger easier to see. Flip them in-session with `mO` for the full in-session options menu, or persist them in your rcfile: `~/.nethackrc` on macOS/Linux, `%USERPROFILE%\NetHack\.nethackrc` on Windows, or the `NETHACKOPTIONS` environment variable.

If you change only five things, make them these:

1. **HP and hunger colors**, so danger reaches your eye before the numbers do.
2. **`paranoid_confirmation:+attack quit`**, to stop fatal typos.
3. **`autopickup` with `pickup_types:$?!=/`**, to collect the useful light items without swallowing every rock and suit of armor.
4. **`pickup_burden:unencumbered`**, to keep loot from silently stealing your speed.
5. **Red menu text for cursed items**, so a dangerous choice looks dangerous.

One more option changes character creation rather than the interface. `OPTIONS=reroll` lets you reject the first starting attributes and inventory for another shuffle. It is pleasant if you enjoy choosing an opening hand, but no roll matters as much as the decisions after it.

#### Status display {#status-display}

**`hilite_status`** colorizes the bottom status line—HP, hunger, AC, and other fields can each carry threshold rules. Defining a rule turns highlighting on. Put each complete rule on its own line:

```
OPTIONS=statushilites
OPTIONS=hilite_status:hitpoints/<66%/yellow/<50%/orange/<33%/red&bold/<15%/red&inverse
OPTIONS=hilite_status:hunger/Satiated/yellow/Hungry/orange/Weak/red&bold/Fainting/red&inverse/Fainted/red&inverse+blink
```

Do not split one rule with a trailing backslash: the parser inserts a space, and later fields are rejected as separate options.

**`menucolors`** colorizes menu entries by pattern. The two most-useful rules are the BUC tags, so anything cursed jumps out red and anything pre-blessed reads as cyan:

```
MENUCOLOR=" cursed "=red
MENUCOLOR=" blessed "=cyan
```

The leading and trailing spaces matter: they keep `" cursed "` from matching the middle of `"uncursed"`.

**`force_invmenu`** opens a pop-up menu of the eligible items whenever a command asks you to pick from inventory (read, drop, wield, and so on), instead of the default *"What do you want to read? [j-k or ?*]"* single-letter prompt. You see the candidates laid out and pick with one keystroke; no need to press `?` first or to remember which letter is which.

**`pile_limit:5`** is the default. At five or more object stacks, the game prints a summary instead of listing the pile; `pile_limit:0` always lists every object.

#### Safety {#safety}

**`paranoid_confirmation:+attack quit`** adds full-word confirmation for attacking peacefuls and quitting without clearing the safety defaults. `pray` is already included by default; `Remove` means choosing which worn item to remove, not confirming removal.

#### Pickup {#pickup}

**`autopickup`** picks items up as you walk over them, filtered by **`pickup_types`** (e.g. `pickup_types:$?!=/` for gold, scrolls, potions, rings, and wands). The `m` prefix on movement suppresses autopickup for one step. Press `@` any time to toggle autopickup on or off for the rest of the session.

**`autopickup_exception`** layers per-pattern rules on top: `autopickup_exception:">rock"` skips rocks even when the type filter would grab them; `autopickup_exception:"<holy water"` always grabs holy water.

**`pickup_burden:unencumbered`** asks before any pickup—manual or automatic—that would push you past Unencumbered. The default `S` waits until a pickup would exceed Stressed; setting `U` keeps you nimble.

#### Movement {#movement}

**`number_pad`** turns the numeric keypad into movement keys (1–9 for directions). Off by default; enabling it changes digit-prefix behavior so you press `n` first to enter a count.

**`runmode`** sets how often the screen redraws during a run or travel: `walk` redraws every step (so you can watch), `run` (the default) every few steps, and `teleport` jumps straight to where you stop. It changes what you *see* mid-run, not what halts you.

#### Verbosity {#verbosity}

**`verbose`** turns on extra descriptive messages. Turn it off if the message log feels noisy.

**A starter rcfile.** A few lines that cover most of the above:

```
OPTIONS=statushilites
OPTIONS=hilite_status:hitpoints/<66%/yellow/<50%/orange/<33%/red&bold/<15%/red&inverse
OPTIONS=hilite_status:hunger/Satiated/yellow/Hungry/orange/Weak/red&bold/Fainting/red&inverse/Fainted/red&inverse+blink
MENUCOLOR=" cursed "=red
MENUCOLOR=" blessed "=cyan
OPTIONS=force_invmenu,pile_limit:5
OPTIONS=paranoid_confirmation:+attack quit
OPTIONS=autopickup,pickup_types:$?!=/
OPTIONS=pickup_burden:unencumbered
```

**Curses for a paneled UI.** A bigger interface shift requires a NetHack binary built with the **curses** window interface; the standard 5.0 terminal build may not include it. When it is available, curses draws a properly paneled UI inside the terminal. Set `windowtype:curses`, `align_message:right`, `align_status:bottom`, `perm_invent`, and `windowborders` in your rc, open a 120×40 terminal, and you get a permanent inventory column, a multi-line message panel, and bordered status and map regions. Plain tty NetHack pins the message line at row 0 no matter what you set.

---

### Sokoban Solutions {#sokoban-solutions}

Sokoban is a four-level boulder puzzle branch that goes *up* from its entrance. Each level has two possible layouts, chosen randomly. You push boulders onto pits to fill them and create a path to the next staircase. The penalty for cheating (squeezing past or stepping onto a boulder instead of pushing it, destroying boulders with a wand, force bolt, or pick-axe, or reading a scroll of earth in Sokoban) is a −1 Luck penalty per infraction, and it stacks. Digging walls doesn't work in Sokoban: the rock is too hard. Flying and levitation don't help either: *"Air currents pull you down…"* if you try to fly over an unfilled pit. Play fair.

> *Solutions originally compiled by Boudewijn Waijers, with contributions by Jukka Lahtinen and others, for the steelypips.org NetHack archive maintained by Kate Nepveu. Adapted for 5.0 and reformatted for this guide.*

In the maps below, boulders are labeled A through T so the solutions can reference them. The `^` symbols mark pits on Level 1 and holes on Levels 2–4; a hole drops you one level even if you are flying. `<` marks the upstairs. Your starting position is marked `@`. Coordinates are written **(column, row)**. "Finish X" means push boulder X to the trap row and then along that row into the nearest unfilled pit or hole, following the listed order. "Finish C like G" means reuse G's route for C.

The arrows mark rolling boulder traps. In sokoban, a boulder pushed onto one keeps rolling in the direction you pushed until it falls into a hole or hits something.

After solving a level, push leftover boulders into corners so they can't block you if you return later. Items sometimes hide under boulders.

**A note on mirroring.** The level is fully mapped when you arrive. Match its outline to the printed version; if it is flipped, swap left and right (or up and down) in every step and count columns from the opposite edge. The web edition's flip buttons do this visually.

#### Level 1, Version A {.sokoban-level data-width=14 data-height=13} {#level-1-version-a-sokoban-level-data-width14-data-height13}

```
            11111
   12345678901234
 1 ┌────┐  ┌───┐
 2 │····│  │···│
 3 │·A··└──┘·B·│
 4 │·C······D··│
 5 │··┌─┐@┌─┐E·│
 6 ├──┴─┴─┼─┘·─┴┐
 7 │·^·^·<│·····│
 8 │·^┌───┤F····│
 9 └┐^│   │·G···│
10  │↑└───┘·H···│
11  │^^^^^←I·J··│
12  │··┌────────┘
13  └──┘
```

1. Push A right one square.
2. Push C up one square.
3. Push D right one square.
4. Push D left to (4,4).
5. Push E down to (11,8).

The map now looks like this:

```
            11111
   12345678901234
 1 ┌────┐  ┌───┐
 2 │····│  │···│
 3 │·CA·└──┘·B·│
 4 │··D········│
 5 │··┌─┐>┌─┐··│
 6 ├──┴─┴─┼─┘·─┴┐
 7 │·^·^·<│··@··│
 8 │·^┌───┤F·E··│
 9 └┐^│   │·G···│
10  │↑└───┘·H···│
11  │^^^^^←I·J··│
12  │··┌────────┘
13  └──┘
```

6. Push H left one square.
7. Finish I, J, E, G, H, F, B, D, and C.

One boulder (A) remains. The scrolls at (3,12) and (4,12) are scrolls of earth.

#### Level 1, Version B {.sokoban-level data-width=15 data-height=11} {#level-1-version-b-sokoban-level-data-width15-data-height11}

```
            111111
   123456789012345
 1 ┌─┬────┐ ┌────┐
 2 │<│@···└─┘····│
 3 │^├┐·AB····C··│
 4 │^││··DE│·F·G·│
 5 │^││····│·····│
 6 │^├┴───┬┘H────┤
 7 │^│    │······│
 8 │↑└────┘······│
 9 │^^^^^←IJKL···│
10 │··┌───┐······│
11 └──┘   └──────┘
```

1. Push A down one square.
2. Push B right to (11,3).
3. Push H down to (10,8).
4. Push J up one square.
5. Finish I.
6. Push L up one square.
7. Finish K, J, H, and L.

The map now looks like this:

```
            111111
   123456789012345
 1 ┌─┬────┐ ┌────┐
 2 │<│>···└─┘····│
 3 │^├┐······BC··│
 4 │^││·ADE│·F·G·│
 5 │^││····│·····│
 6 │^├┴───┬┘·────┤
 7 │^│    │······│
 8 │↑└────┘······│
 9 │@····←·······│
10 │··┌───┐······│
11 └──┘   └──────┘
```

8. Push C down one square.
9. Push B left to (6,3).
10. Push G down one square, then left to (10,5).
11. Finish G.
12. Finish C and F like G.
13. Move B right to (11,3), then down two squares, then left to (10,5).
14. Finish B.
15. Move A up one square.
16. Finish A like B.

Two boulders (D and E) remain. The scrolls at (2,10) and (3,10) are scrolls of earth.

#### Level 2, Version A {.sokoban-level data-width=29 data-height=12} {#level-2-version-a-sokoban-level-data-width29-data-height12}

```
            11111111112222222222
   12345678901234567890123456789
 1 ┌────┬────┐       ┌─────────┐
 2 │····│····└─┐     │·········│
 3 │··AB│CD···@│     │·········│
 4 │·····E···┌─┘     │·········│
 5 │····│····│       │····<····│
 6 ├─·──┼────┴┐      │·········│
 7 │··F·│·····│      │·········│
 8 │·GH·│I·J·K│      │·········│
 9 │··L·····M·│      │·········│
10 │·NOP│Q··R·└──────┴────────+┤
11 │····│··S·T→^^^^^^^^^^^^^^^·│
12 └────┴──────────────────────┘
```

1. Push E left to (3,4).
2. Push L right to (9,9).
3. Push R right one square.
4. Finish T, S, M, R, K, J, and L.
5. Finish N, O, P, G, and E.
6. Push F left one square.
7. Finish H.
8. Push F up to (3,4).
9. Finish F and A.

Five boulders (B, C, D, I, and Q) remain.

#### Level 2, Version B {.sokoban-level data-width=26 data-height=14} {#level-2-version-b-sokoban-level-data-width26-data-height14}

```
            11111111112222222
   12345678901234567890123456
 1  ┌──┐          ┌─────────┐
 2 ┌┘·@└──────┐   │·········│
 3 │··········│   │·········│
 4 │·A┌───┐B─·│   │·········│
 5 │··│···│·C·│   │····<····│
 6 │·D·E····F─┤   │·········│
 7 │·G··H··│··│   │·········│
 8 │·────I·└┐·│   │·········│
 9 │··J···K·│·└┐  │·········│
10 │·──┐L─···M·└──┴────────+┤
11 │···│··N─·O→^^^^^^^^^^^^·│
12 │··P······┌──────────────┘
13 └───┐··│··│
14     └──┴──┘
```

1. Push B down two squares.
2. Push C left one square.
3. Push P right three squares, then up one square, to (7,11).
4. Finish O.
5. Push N down one square, then left to (3,12).
6. Push M left one square.
7. Push F up one square.
8. Push B left two squares.
9. Push K down two squares.

The map now looks like this:

```
            11111111112222222
   12345678901234567890123456
 1  ┌──┐          ┌─────────┐
 2 ┌┘·>└──────┐   │·········│
 3 │··········│   │·········│
 4 │·A┌───┐·─·│   │·········│
 5 │··│···│CF·│   │····<····│
 6 │·D·E·B···─┤   │·········│
 7 │·G··H··│··│   │·········│
 8 │·────I·└┐·│   │·········│
 9 │··J·····│·└┐  │·········│
10 │·──┐L─@·M··└──┴────────+┤
11 │···│·PK─··→·^^^^^^^^^^^·│
12 │·N·······┌──────────────┘
13 └───┐··│··│
14     └──┴──┘
```

10. Push M right one square, then down to (11,11). Finish M.
11. Push N right to (10,12), then up to (10,10). Finish N like M.
12. Push K down one square, then left to (3,12). Finish K like N.
13. Push P right one square, then down one square. Finish P like N.
14. Push L down two squares, then left to (3,12). Finish L like N.
15. Push I down one square, then right one square, then down to (8,12). Finish I like N.
16. Push J right to (8,9), then down to (8,12). Finish J like N.

The map now looks like this:

```
            11111111112222222
   12345678901234567890123456
 1  ┌──┐          ┌─────────┐
 2 ┌┘·>└──────┐   │·········│
 3 │··········│   │·········│
 4 │·A┌───┐·─·│   │·········│
 5 │··│···│CF·│   │····<····│
 6 │·D·E·B···─┤   │·········│
 7 │·G··H··│··│   │·········│
 8 │·────··└┐·│   │·········│
 9 │········│·└┐  │·········│
10 │·──┐·─·····└──┴────────+┤
11 │···│···─@·→········^^^^·│
12 │·········┌──────────────┘
13 └───┐··│··│
14     └──┴──┘
```

17. Push H left one square.
18. Push B down one square, then right one square, then down to (8,12). Finish B.
19. Push C down one square, then left two squares, to (7,6). Finish C like B.
20. Push F left one square, then down one square, then left to (7,6). Finish F like C.
21. Push G right one square. Push D up one square.
22. Push E right two squares, to (7,6). Finish E like F.

Four boulders (A, D, G, and H) remain.

#### Level 3, Version A {.sokoban-level data-width=20 data-height=12} {#level-3-version-a-sokoban-level-data-width20-data-height12}

```
            11111111112
   12345678901234567890
 1 ┌────────┬───┬─────┐
 2 │········│···│·····│
 3 │·AB··─CD│·─·│·····│
 4 │··│·E·F·│GH·│·····│
 5 ├─·│··─··│·─·│··<··│
 6 │···┌─·······│·····│
 7 │···│·I·─···─┤·····│
 8 │·J·│K·│···──┤·····│
 9 ├─L·│··└─────┴────+┤
10 │··M···→^^^^^^^^^^·│
11 │···│·@┌───────────┘
12 └───┴──┘
```

1. Push M left one square. Finish M.
2. Push J right one square.
3. Finish L, J, A, and B.
4. Push D down to (9,6).
5. Finish I.
6. Push K down two squares, then left to (3,10). Finish K.
7. Push E up one square.
8. Push F right one square, then up one square, to (9,3).
9. Push E down one square, then left one square, to (5,4).
10. Push E up one square, then left two squares. Finish E.
11. Push C down one square, then left three squares, to (5,4). Finish C like E.
12. Push D right two squares, then left to (8,6).
13. Push D up two squares, then left to (5,4). Finish D like E.

Three boulders (F, G, and H) remain.

#### Level 3, Version B {.sokoban-level data-width=22 data-height=13} {#level-3-version-b-sokoban-level-data-width22-data-height13}

```
            1111111111222
   1234567890123456789012
 1   ┌─┬────┐  
 2 ┌─┘·│····│  
 3 │···A····├─┬───────┐  
 4 │·─·BC─DE│·│·······│  
 5 │·FG─······│·······│  
 6 │·─··H·│···│·······│  
 7 │····─I└─J─┤···<···│  
 8 │··KL··M···│·······│  
 9 │·──···│···│·······├─┐
10 │····─N├───┤·······+·│
11 └─┐··O·└───┴───────┤·│
12   │··P@→^^^^^^^^^^^+·│
13   └────────────────┴─┘
```

1. Push O left two squares, to (4,11).
2. Finish P and N.
3. Push L down one square, to (5,9).
4. Push O up one square, to (4,10).
5. Finish L.
6. Push K right one square, to (5,8). Finish K.
7. Push O right one square, to (5,10). Finish O.

The map now looks like this:

```
            1111111111222
   1234567890123456789012
 1   ┌─┬────┐  
 2 ┌─┘·│····│  
 3 │···A····├─┬───────┐  
 4 │·─·BC─DE│·│·······│  
 5 │·FG─······│·······│  
 6 │·─··H·│···│·······│  
 7 │····─I└─J─┤···<···│  
 8 │······M···│·······│  
 9 │·──···│···│·······├─┐
10 │····─·├───┤·······+·│
11 └─┐····└───┴───────┤·│
12   │··@>→····^^^^^^·+·│
13   └────────────────┴─┘
```

8. Push G down to (4,8), then one square right, to (5,8). Finish G.
9. Push F one square right. Finish F like G.
10. Push M two squares right, to (10,8), then left to (5,8). Finish M.
11. Push J up two squares, to (10,5).
12. Finish I.
13. Push H right one square. Finish H.
14. Push A right two squares, to (7,3).
15. Push C down two squares, to (6,6). Finish C like H.

Five boulders (A, B, D, E, and J) remain.

#### Level 4, Version A {.sokoban-level data-width=26 data-height=18} {#level-4-version-a-sokoban-level-data-width26-data-height18}

The prize on this version is usually a bag of holding, with a 1 in 4 chance of being an amulet of reflection instead.

```
            11111111112222222
   12345678901234567890123456
 1 ┌────────────────────────┐
 2 │@·····^→^^^^^^^^^^^^^^^·│
 3 │·······┌──────────────┐·│
 4 └┬─────·└────┐         │·│
 5  │···········│         │·│
 6  │·A·B·C·D·E·│         │·│
 7 ┌┴──────·────┤         │·│
 8 │···F·G··H·I·│         │·│
 9 │···J········│         │·│
10 └┬───·──────┬┘   ┌─────┤·│
11  │··K·L·M···│  ┌─┤·····│·│
12  │·····N····│  │·+·····│·│
13  │·O·P···Q·┌┘  ├─┤·····│·│
14 ┌┴─────·─┬─┘   │·+·····+·│
15 │··R·····│     ├─┤·····├─┘
16 │········│     │·+·····│
17 │···┌────┘     └─┤·····│
18 └───┘            └─────┘
```

1. Push A left one square.
2. Push B left one square.
3. Push C left one square.
4. Push E right one square.
5. Push D right one square.
6. Push G to (9,8), then up three squares, then left one square. Finish G.
7. Finish H and I like G.
8. Push J left two squares, to (3,9).
9. Finish F like G.
10. Push N right three squares, to (11,12).
11. Push L to (6,11), then up three squares. Finish L.
12. Finish M and K like L.
13. Push N left three squares, then up one square, to (8,11). Finish N like L.

The map now looks like this:

```
            11111111112222222
   12345678901234567890123456
 1 ┌────────────────────────┐
 2 │>·····@→·······^^^^^^^^·│
 3 │·······┌──────────────┐·│
 4 └┬─────·└────┐         │·│
 5  │···········│         │·│
 6  │A·B·C···D·E│         │·│
 7 ┌┴──────·────┤         │·│
 8 │············│         │·│
 9 │·J··········│         │·│
10 └┬───·──────┬┘   ┌─────┤·│
11  │··········│  ┌─┤·····│·│
12  │··········│  │·+·····│·│
13  │·O·P···Q·┌┘  ├─┤·····│·│
14 ┌┴─────·─┬─┘   │·+·····+·│
15 │··R·····│     ├─┤·····├─┘
16 │········│     │·+·····│
17 │···┌────┘     └─┤·····│
18 └───┘            └─────┘
```

14. Push R to (8,15), then up four squares. Finish R like L.
15. Push Q to (8,13), then down three squares, then left to (3,16). Push Q up one square. Finish Q like R.
16. Finish P and O like Q.
17. Push J to (6,9), then down three squares. Finish J like L.
18. Push C to (9,6), then down three squares. Finish C like J.
19. Finish B and D like C.

Two boulders (A and E) remain. The bag-or-amulet prize is in one of the small chambers ((17,12), (17,14), or (17,16)) next to the treasure zoo.

#### Level 4, Version B {.sokoban-level data-width=26 data-height=17} {#level-4-version-b-sokoban-level-data-width26-data-height17}

The prize on this version is usually an amulet of reflection, with a 1 in 4 chance of being a bag of holding instead.

```
            11111111112222222
   12345678901234567890123456
 1   ┌──────────────────────┐
 2   │··→^^^^^^^^^^^^^^^^^^·│
 3   │··┌─────────────────┐·│
 4 ┌─┴┐·│    ┌───┐        │·│
 5 │··│A└┐  ┌┘···│        │·│
 6 │·····├──┤·N··│        │·│
 7 │·BC··│··│··O·│        │·│
 8 └┐··DE│···PQ·┌┘        │·│
 9  │F··G···│R··│   ┌─────┤·│
10  │·HI·│··│··S│ ┌─┤·····│·│
11  │·J·K└──┤·T·│ │·+·····│·│
12  │·······│··┌┘ ├─┤·····│·│
13  └──┐·L··│·┌┘  │·+·····+·│
14     └┬─·─┘·│   ├─┤·····├─┘
15      │·M···│   │·+·····│
16      │@·│··│   └─┤·····│
17      └──┴──┘     └─────┘
```

1. Push M right three squares, then up four squares to (11, 11).
2. Push T up one square.
3. Push S up two squares.
4. Push Q up one square.
5. Push P left three squares to (8, 8).
6. Push G left two squares.
7. Push D up two squares, then left one square.
8. Finish A.
9. Push B up one square.
10. Push C right one square. Finish C.
11. Push B down one square.

The map now looks like this:

```
            11111111112222222
   12345678901234567890123456
 1   ┌──────────────────────┐
 2   │··→·^^^^^^^^^^^^^^^^··│
 3   │··┌─────────────────┐·│
 4 ┌─┴┐·│    ┌───┐        │·│
 5 │··│·└┐  ┌┘···│        │·│
 6 │·@D··├──┤·N··│        │·│
 7 │·B···│··│·QO·│        │·│
 8 └┐···E│P····S┌┘        │·│
 9  │FG·····│R··│   ┌─────┤·│
10  │·HI·│··│·T·│ ┌─┤·····│·│
11  │·J·K└──┤M··│ │·+·····│·│
12  │·······│··┌┘ ├─┤·····│·│
13  └──┐·L··│·┌┘  │·+·····+·│
14     └┬─·─┘·│   ├─┤·····├─┘
15      │·····│   │·+·····│
16      │>·│··│   └─┤·····│
17      └──┴──┘     └─────┘
```

12. Push D right one square. Finish D.
13. Push B right two squares. Finish B.
14. Finish I.
15. Push E down one square, then left one square. Finish E.
16. Push F up three squares, then right two squares. Finish F.

The map now looks like this:

```
            11111111112222222
   12345678901234567890123456
 1   ┌──────────────────────┐
 2   │·@→······^^^^^^^^^^^··│
 3   │··┌─────────────────┐·│
 4 ┌─┴┐·│    ┌───┐        │·│
 5 │··│·└┐  ┌┘···│        │·│
 6 │·····├──┤·N··│        │·│
 7 │·····│··│·QO·│        │·│
 8 └┐····│P····S┌┘        │·│
 9  │·G·····│R··│   ┌─────┤·│
10  │·H··│··│·T·│ ┌─┤·····│·│
11  │·J·K└──┤M··│ │·+·····│·│
12  │·······│··┌┘ ├─┤·····│·│
13  └──┐·L··│·┌┘  │·+·····+·│
14     └┬─·─┘·│   ├─┤·····├─┘
15      │·····│   │·+·····│
16      │>·│··│   └─┤·····│
17      └──┴──┘     └─────┘
```

17. Push G right one square. Finish G.
18. Finish H and J like G.
19. Push P down one square, then left three squares, to (5,9). Finish P.
20. Push K to (6,9), then left one square. Finish K.
21. Push L right one square, then up one square, then left two squares. Finish L like K.

The map now looks like this:

```
            11111111112222222
   12345678901234567890123456
 1   ┌──────────────────────┐
 2   │·@→············^^^^^··│
 3   │··┌─────────────────┐·│
 4 ┌─┴┐·│    ┌───┐        │·│
 5 │··│·└┐  ┌┘···│        │·│
 6 │·····├──┤·N··│        │·│
 7 │·····│··│·QO·│        │·│
 8 └┐····│·····S┌┘        │·│
 9  │·······│R··│   ┌─────┤·│
10  │····│··│·T·│ ┌─┤·····│·│
11  │····└──┤M··│ │·+·····│·│
12  │·······│··┌┘ ├─┤·····│·│
13  └──┐····│·┌┘  │·+·····+·│
14     └┬─·─┘·│   ├─┤·····├─┘
15      │·····│   │·+·····│
16      │>·│··│   └─┤·····│
17      └──┴──┘     └─────┘
```

22. Push T down one square.
23. Push R to (11,8), then left three squares. Finish R like P.
24. Finish M like R.
25. Push T left one square. Finish T like R.
26. Push N right one square.
27. Push Q down to (12,9), then left one square. Finish Q like R.
28. Push N left one square. Finish N like Q.

Two boulders (O and S) remain. The amulet-or-bag prize is in one of the small chambers ((17,11), (17,13), or (17,15)) next to the treasure zoo.

---

### Voluntary Challenges {#voluntary-challenges}

The game tracks a set of optional self-imposed restrictions called **conducts**. You can check which ones you've maintained at any time with `#conduct`. When you die or ascend, the end-of-game summary lists every conduct you kept. No conduct is required for victory; they exist for players who want a harder game or a more impressive ascension.

> *The conduct system was documented in Dion Nicolaas's Conduct Spoiler, originally posted to RGRN and archived at steelypips.org. The information below has been updated for 5.0 of the Mazes.*

Conducts are not declared in advance. The game simply watches your actions and records whether you've broken each restriction. If you eat a corpse on turn 1, you've broken foodless, vegan, and vegetarian for the rest of the run. There's no going back.

Here is the short version. “Start option” means the conduct has to be chosen before the first turn; the others are watched automatically.

| Conduct | What breaks it | How it begins |
|---------|----------------|---------------|
| Vegetarian | Eating meat or another forbidden animal food | Automatic |
| Vegan | Eating any animal product | Automatic |
| Foodless | Eating anything, including chewing through a wall | Automatic |
| Atheist | Praying, sacrificing, turning undead, chatting with a priest, or altar-testing an item | Automatic |
| Weaponless | Hitting with a wielded weapon or weapon-tool | Automatic |
| Pacifist | A kill credited to you, including pushing a pet into a fatal trap | Automatic |
| Illiterate | Reading, or engraving anything beyond a single `x` | Automatic |
| Genocideless | Genociding a species or class | Automatic |
| Polyselfless | Changing your own form | Automatic |
| Polypileless | Polymorphing an object | Automatic |
| Wishless | Making a wish | Automatic |
| Artifact-wishless | Asking for an artifact, even if the wish is denied | Automatic |
| Nudist | Wearing armor | `OPTIONS=nudist` |
| Blind (Zen) | —; blindness lasts for the whole game | `OPTIONS=blind` |
| Pauper | —; starting empty is the whole conduct | `OPTIONS=pauper` |
| Petless | Making any monster tame | `OPTIONS=pettype:none` |
| Permadeaf | —; deafness lasts for the whole game | `OPTIONS=permadeaf` |
| Sokoban | Violating its boulder rules after entering | Automatic on entering |
| Bonesless | —; bones stay disabled for the whole game | `OPTIONS=!bones` |
| Unrerolled | Rejecting the first character offered | Accept the first character |

#### The Food Conducts {#the-food-conducts}

These form a hierarchy: foodless is stricter than vegan, which is stricter than vegetarian.

**Vegetarian.** Don't eat meat. Specifically, don't eat the corpses of non-vegetarian monsters, and avoid items made from animal products (meat sticks, eggs from carnivorous creatures). In practice, that means living on permissible corpses and globs. Lichens, jellies, fungi and molds, and gray ooze or brown pudding globs are all safe. Fortune cookies, lembas wafers, and whatever vegetable food you find on the ground also work. Green slime is technically vegetarian, not vegan, but eating its glob slimes you. The vegetarian monster list is broad: all `b` (blobs), all `j` (jellies), all `F` (fungi and molds), all `v` (vortices), all `y` (lights), all `E` (elementals) except stalkers, and all `'` (golems) except flesh and leather golems. Many [vegetarian corpses grant useful intrinsics](#vegetarian-safe-corpses). Vegetarian-safe is not the same as safe. Yellow mold corpses poison, violet fungus causes hallucination, and acid blobs sting going down. Monks are a good role to play vegetarian; they already pay an alignment penalty for meat.

**Vegan.** Follow all vegetarian restrictions, plus avoid eating eggs, pancakes, lumps of royal jelly, cream pies, candy bars, *and* fortune cookies. (Yes, fortune cookies are vegetarian-safe but not vegan-safe. They contain eggs.) The conduct fires only on *eating*: carrying or using animal-derived items is fine, so vegans can still light the Candelabrum with wax or tallow candles, wear leather armor, and apply bone horns. Vegan also excludes puddings.

**Foodless.** Don't eat anything at all. Your practical answers are prayer (which cures hunger from Hungry status onward, not just Weak/Fainting) and a ring of slow digestion (which stops ordinary hunger). Stone to flesh can make meatballs, but eating one breaks the conduct. Most foodless runs rely on finding a ring of slow digestion early or praying through hunger until one appears. Wishing for the ring is the usual plan if a wand of wishing or magic lamp turns up. Chewing through walls also breaks this conduct (it counts as eating rock).

#### Atheist {#atheist}

Don't interact with the divine. Specifically: don't `#pray`, don't `#offer` corpses at altars, don't `#turn` undead, and don't `#chat` with priests. The altar BUC flash also counts: any non-coin item you drop on an altar increments the conduct counter, so the original identification trick is off-limits too. That removes your safety net for starvation, stoning, illness, and cursed items.

Without prayer to cure hunger, you need reliable food sources. Without sacrifice or altar BUC, identification is harder and you'll get no artifact gifts. The final Amulet offering for ascension is exempt, so a clean atheist ascension is mechanically possible.

#### Weaponless {#weaponless}

Never hit a monster with a wielded weapon or weapon-tool. You can throw weapons, fire them from bows and crossbows, and use wands and spells. You can also fight bare-handed or with martial arts (Monks excel here). What you cannot do is swing a sword, axe, mace, aklys, pick-axe, unicorn horn, or any other weapon-class or weapon-tool item in melee while it's in your `w`ielded slot. The one ranged exception that *does* break the conduct: using a wielded polearm at range via `a` (apply).

That is less restrictive than it sounds. Monks start with strong martial arts and get better. Other classes can rely on spells, wands, and thrown daggers. A wielded cockatrice corpse still works (it's not a weapon). The main sacrifice is giving up the damage output of late-game artifact weapons.

#### Pacifist {#pacifist}

Do not kill a monster yourself. Pet kills and monsters killed through conflict do not break the conduct; displacing a pet into a fatal trap does. A pacifist run uses pets for fighting, conflict for crowds, and [Elbereth](#elbereth) to keep monsters at bay.

Pacifist ascensions are possible but require deep knowledge of the dungeon's rules. The canonical late-game plan is a **figurine of an Archon** (wished, broken, then re-tamed if it turns hostile) as your champion fighter, the spell of *charm monster* for crowd pacification, and a ring of conflict for fights you can't talk your way out of.

#### Illiterate {#illiterate}

Don't read anything. No scrolls, no spellbooks, no fortune cookies, no T-shirts. You also can't engrave anything more than a single "x" or "X" (the traditional illiterate's signature). You don't lose the conduct if you read blank scrolls or spellbooks, or Hawaiian shirts, the Book of the Dead, or messages already engraved on the floor.

Without scrolls, you lose access to identify, enchant weapon/armor, teleportation, remove curse, and genocide in their most common forms. Without spellbooks, you can't learn new spells or refresh old ones, so any starting spell you have will eventually fade. That forces extreme reliance on wands, potions, and creative workarounds. The standard workarounds are **pet-step BUC testing** (does the dog walk over it?) and **price-ID** (looking at a shopkeeper's quote doesn't count as reading), which together cover most of the ID table that scroll of identify would have handled.

#### No Genocide {#no-genocide}

Never genocide any monster. Genocide is prompted by reading a **scroll of genocide** (uncursed picks one species; blessed wipes the whole class) and by **sitting on a throne**: one outcome in the throne-effect table (case 8 of 13) prompts you to genocide a single species. To preserve the conduct, type **"none"** at the prompt. Pressing Enter merely asks again. A cursed scroll summons monsters based on whatever name you give it, but that summoning does not itself break genocideless conduct.

That means you'll face the full bestiary throughout the game, including master and arch-liches, mind flayers, cockatrices, and everything else that experienced players routinely eliminate. You'll also have to cross the **Plane of Water** the hard way: the standard tactic of genociding class `;` to clear out the eels and krakens is off-limits, so bring magical breathing and pay attention to where the sea monsters can reach you.

That is one of the milder conducts: many players ascend without genociding anything because they never find the scroll and never roll case 8 on a throne.

#### Polymorph Restrictions {#polymorph-restrictions}

Two related conducts track polymorphing:

**No polymorph.** Never let your form change. Obvious sources: potion or ring of polymorph, wand or spell of polymorph (zapped at you), and polymorph traps. Less obvious: a genetic engineer's claw; eating a chameleon, doppelganger, or mimic corpse; and failing to cure slimedness (turns you into a green slime). The Amulet of Unchanging blocks every path. A failed system shock does *not* break the conduct. Keeping that conduct forgoes the advantages of powerful monster forms (master mind flayer, xorn, various dragons).

**No polymorph objects.** Never polymorph items. Don't zap items with a wand of polymorph, don't dip items in potions of polymorph, and avoid other means of transforming objects. This eliminates a powerful item-generation strategy (polypiling).

#### Wishing Restrictions {#wishing-restrictions}

Two related conducts:

**Wishless.** Never make a wish. Refuse wishes from wands, fountains, smoky potion djinn, thrones, and all other sources. **Picking up the Amulet of Yendor also triggers a wish prompt**: wish for "nothing" (the literal string) and the counter doesn't tick. Wishing for "nothing" is the standard escape hatch for any forced wish. That is extremely challenging because wishes are the primary way to obtain critical items (silver dragon scale mail, speed boots, a bag of holding) when the dungeon doesn't provide them.

**No wishing for artifacts.** Make wishes, but never wish for an artifact. That prevents the most efficient wish strategy (wishing for [Grayswandir](#grayswandir), the [Eye of the Aethiopica](#eye-of-the-aethiopica), or similar powerful artifacts) while still allowing wishes for mundane necessities. The counter ticks even for *denied* artifact wishes (when the game gives you "something in your hand" instead), so be sure you can get the artifact before asking.

#### Combining Conducts {#combining-conducts}

Combining conducts is where the difficulty climbs. A vegetarian atheist run is substantially harder than either alone. A pacifist illiterate vegan foodless atheist weaponless run is the stuff of legends (and has been done). For scale: on the public NAO server, about one in nine ascensions is wishless, and only one in eighty is foodless.

Recent editions of the Mazes have added several more tracked conducts:

**Nudist.** Never wear any armor, shirt, cloak, gloves, boots, helmet, or shield. Set the `nudist` option at game start. You fight the entire dungeon in your underwear. Officially tracked since 3.6.

**Blind (Zen).** Play the entire game without sight. Set the `blind` option at game start. You'll need telepathy and other senses to navigate. Officially tracked since 3.6.

Mazes 5.0 added six more tracked conducts: Pauper, Petless, Permadeaf, [Sokoban](#sokoban), Bonesless, and Unrerolled. Pauper, Permadeaf, Petless, and Bonesless are start-of-game options (you opt in or out before play). Sokoban is tracked automatically based on what you do during the run; Unrerolled records that you accepted the first character the game offered.

#### Pauper (new in 5.0) {#pauper-new-in-50}

Start with absolutely nothing: no gold, no inventory, no armor, no starting weapon. Set `OPTIONS=pauper` in your rcfile (rcfile or `NETHACKOPTIONS` env only; the in-game `O` menu cannot toggle it). Pauper implicitly sets nudist. It is a permanent conduct you never lose: it does not forbid acquiring or spending gold later, just starting empty.

To keep the start from being impossible, you get a few compensations: two unspent weapon-skill slots, and your role knows one signature spell or item. Wizard knows force bolt; Healer knows healing; Priest, Knight, and Monk all know protection (Priest also knows water); Archeologist knows touchstone; Cave Dweller knows flint; Rogue and Tourist know sack; Samurai knows gunyoki rations. The [supply chests](#supply-containers) on early levels can provide much of your first kit.

#### Petless (new in 5.0) {#petless-new-in-50}

Never have a pet. Set `OPTIONS=pettype:none` in your rcfile to skip the starting companion entirely (that overrides per-role defaults). After that, you lose the conduct the moment anything becomes tame. The game won't stop you. Scrolls of taming, the charm monster spell, food thrown at hostile dogs and cats, and magic-trap accidents all still work; each one just breaks Petless on the spot.

#### Permadeaf (new in 5.0) {#permadeaf-new-in-50}

Never hear anything. Set `OPTIONS=permadeaf` (or `OPTIONS=deaf`) in your rcfile. That option is set-in-config only; the in-game `O` menu cannot toggle it. (Don't confuse `permadeaf` with the unrelated `acoustics` flavor toggle, which doesn't earn the conduct.) The game then runs as if you had the Deaf intrinsic from turn one and never recovered: all the "you hear water falling", "you hear someone counting money", "you hear a door open" messages and the ambient monster sounds ("you hear a slurp" and friends) are suppressed.

Only the *messages* are suppressed. A shrieker still shrieks and still summons monsters and aggravates the level; you just don't get the warning that it happened. Treat empty silence near a `F`-class monster as the same threat as the usual "shrieks" message.

Permadeaf navigates by sight and logic alone.

#### Sokoban (new in 5.0) {#sokoban-new-in-50}

Enter Sokoban without breaking its rules. You need not finish the branch for the conduct to appear at the end of the game. Each cheating action costs **1 point of Luck** and increments the conduct counter: **squeezing past** a boulder via a small or empty-handed form, **fracturing** a boulder with force bolt, a pick-axe, or a wand of striking, **polymorphing** a boulder, reading a **scroll of earth**, or **dismounting** onto a boulder. The game tracks violations automatically.

#### Bonesless (new in 5.0) {#bonesless-new-in-50}

Never inherit from another player's grave. Set `OPTIONS=!bones` (see [Saving and Bones](#saving-and-bones)); a run that just happens to find no bones doesn't count.

---

### Shops: Credit, Debt, and Trouble {#shopping-and-shopkeeper-pricing}

Shops do more than sell: their pricing system is your most powerful identification tool. You can find full mechanics and interactive price tables in Part Four, [The Price Is Right](#the-price-is-right). What follows here is the rest: credit, debt, combat, and non-obvious rules.

First, the rule that prevents the most expensive mistake: **do not cross the shop door with anything marked unpaid.** The shopkeeper turns hostile, blocks your return, and calls the Keystone Kops. Check the bill with `I`, then `u`, and pay before you leave. Paying later dismisses every Kop still hunting you.

#### Credit and Debt {#credit-and-debt}

Each shopkeeper keeps a per-customer ledger with three numbers: credit, debit, and loan.

**How you get credit.** There are two ordinary routes:

1. **Sell to a shopkeeper who has no gold.** Instead of paying cash, the shopkeeper may offer credit worth nine-tenths of the normal sale offer. The prompt reads: "Shopkeeper cannot pay you at present. Will you accept *N* zorkmids in credit for that?" A shopkeeper with gold simply pays cash; a shortage does not turn the unpaid balance into credit.
2. **You drop gold on a shop floor square.** Any gold you drop or throw inside the shop is added to your credit balance (after paying off any existing debt first). That turns portable gold into a shop-specific balance that leprechauns cannot steal.

**How credit gets used.** When you buy something, the shopkeeper applies your credit against the purchase price first ("the price is deducted from your credit"). Any remainder comes out of your gold. Credit is per-shop and per-shopkeeper, and cannot be withdrawn back to gold.

**Is paying from credit better or worse than paying in gold?** The price itself is identical: credit is deducted from the *post- Charisma, post-Tourist, post-angry* cost at a strict 1:1 ratio, with no markup or discount either way. The differences are about how *safe* and *liquid* your money is, not how far it stretches:

- **Better** in that leprechauns cannot steal it and it adds no carry weight. A shop you'll come back to can serve as a bank.
- **Worse** in that credit is locked to one shopkeeper. If you over-accumulate at a shop that doesn't have items you want (or the shopkeeper dies, or you anger them and they go hostile), the credit evaporates. You also can't tip altar donations, can't pay shrine fees, and can't bribe a demon out of credit.

Practical balance: park spare gold as credit at a shop you intend to keep visiting ([the Gnomish Mines](#the-gnomish-mines) general store is a popular choice), but don't deposit more than you expect to spend there.

(There is an old piece of shop cheese called *credit cloning*: drop a bag containing gold in the shop, then have your pet carry the bag outside. The shop keeps the credit while you recover the same coins.)

**Debit** is the inverse: it accrues when you *use* an unpaid item inside the shop (read a scroll, quaff a potion, zap a wand) and you haven't completed the purchase. You're charged a fraction of the item's price as a usage fee; future gold drops or sales pay it down before any new credit accumulates.

**Loan** is the game's name for gold belonging to the shopkeeper that you picked up from the shop floor. Dropping gold in the shop repays the loan before it adds to your credit.

#### Shopkeeper Behavior {#shopkeeper-behavior}

A shopkeeper is one of the toughest NPCs in the game: high HP, good AC, hits hard, and unfazed by Elbereth or by the kind of clever escape that works on other monsters. They also see everything: they track every item you pick up or that enters the shop, even when you are invisible.

| Problem | Shopkeeper's response | Safest fix |
|---------|-----------------------|------------|
| Try to leave owing money | Blocks the door; escape brings Kops | Check `I`, then `u`, and pay first |
| Break or use an unpaid item | Adds the damage or use fee to your bill | Pay before leaving |
| Kick down a locked shop door | Demands 400 zm; refusal starts a fight | Pick the lock or use opening |
| Dig through a shop wall | Demands 10 zm per point of Strength | Pay, or leave the wall alone |
| Dig down while you owe | Takes your entire pack | Clear the bill before digging |
| Attack the shopkeeper | Turns hostile | `#chat` and pay the 1,000 zm buy-off |
| Arrive invisible or holding a pick-axe | Refuses entry | Become visible and put the pick-axe away |

Artifact items are priced at four times their base value: from 800 zm for Giantslayer to 32,000 zm for Stormbringer or Grayswandir. An unidentified long sword with a five-figure quote deserves a second look.

A shopkeeper *can* be killed for the entire stock plus the till (1,000–4,000 zm and a skeleton key on death), but they're a tough fight. Killing one does not itself summon Keystone Kops; the Kops respond when you leave a shop owing money. It does cost alignment; non-chaotic characters also lose 2 Luck and telepathy. **Polymorphing the shopkeeper first** (via wand or trap) means killing them no longer counts as murder, which is the preferred approach for Lawful and Neutral characters. Strong late-game players sometimes clear shops, but it is not a casual mid-game move.

Three habits prevent most shop mistakes:

- **Check the bill directly.** Use `I`, then `u`, to list unpaid inventory. Nothing sells on the door square, so the old trick of dropping everything there tells you less than the inventory command.
- **Sell, then deposit.** A normal sale pays gold. Drop that gold on the shop floor if you want to turn it into credit.
- **Bones-shop gotcha.** When you find a shop in someone's bones file, all the items inside still belong to the dead adventurer's ghost shopkeeper; pick up anything and you owe the new shopkeeper full price. The shop floor is not free loot.
- **"Closed for inventory" engraving on a door.** That marks a shop whose door spawned **locked**, not an abandoned one. The shopkeeper is still inside, and the stock is still unpaid. Pick the lock or use a wand of opening. (Orcus Town is a ghost town with no shopkeepers, so its shop items really are ownerless.)

#### Gem Identification Through Selling {#gem-identification-through-selling}

Selling unidentified gems is **not** a reliable price-ID method. Shopkeepers offer 3 to 8 zm for any unidentified gem, real or glass alike, and the exact amount varies by both the gem's true identity and the shopkeeper. Real diamonds and worthless glass diamonds both quote in the same 3-8 zm range; you cannot tell them apart by price. Selling the same gem at two different shops gives different prices for *any* unidentified gem, not just glass.

Use a **touchstone** (gray stone, base price 45, occasionally found in the Mines and elsewhere). Rubbing an unidentified gem against a **blessed** touchstone names the gem outright; with a merely uncursed touchstone you only get a streak color. (Archeologists and Gnomes get the full name from a non-cursed stone, a racial perk.) Hardness doesn't matter; every gem works. Once identified, real gems sell for their real value (often hundreds of zm each) while glass sells for almost nothing.

##### Real-gem prices {#real-gem-prices}

Once you know what a gem is, its type determines its base price. Every gem weighs 1, and gems of the same identified type stack into a single inventory slot regardless of count, so the only cost of hoarding a heap of identified rubies is one slot's worth of clutter.

Every real gem, with its base value. An ordinary sale offer starts at about half that figure, before Charisma and other modifiers.

The Mohs column is real-world mineral hardness on the Mohs scale (talc 1, diamond 10), and the game uses it in two places. Gems of Mohs 8 or higher count as **"hard"**, and hard gems do two things softer gems and glass can't: they can be used as a stylus to *engrave* [Elbereth](#elbereth) and other messages permanently into the dungeon floor (instead of the temporary dust scratch a finger or soft gem leaves). If a thrown gem hits, a hard gem survives two times in three; a softer gem or piece of glass survives one time in three. Hardness doesn't affect touchstoning: every gem can be identified by a blessed touchstone regardless.

| Price | Gem                   | Color           | Mohs | Notes                          |
|------:|-----------------------|-----------------|-----:|--------------------------------|
|  4500 | Dilithium crystal     | white           |    5 | rarest white gem               |
|  4000 | Diamond               | white           |   10 | hardest material in the game   |
|  3500 | Ruby                  | red             |    9 |                                |
|  3250 | Jacinth               | orange          |    9 | one of two orange gems         |
|  3000 | Sapphire              | blue            |    9 |                                |
|  2500 | Black opal            | black           |    8 |                                |
|  2500 | Emerald               | green           |    8 |                                |
|  2000 | Turquoise             | green           |    6 |                                |
|  1500 | Citrine               | yellow          |    6 |                                |
|  1500 | Aquamarine            | green           |    8 |                                |
|  1000 | Amber                 | yellowish brown |    2 | softest gem; only dust-writes  |
|   900 | Topaz                 | yellowish brown |    8 |                                |
|   850 | Jet                   | black           |    7 |                                |
|   800 | Opal                  | white           |    6 |                                |
|   700 | Chrysoberyl           | yellow          |    5 |                                |
|   700 | Garnet                | red             |    7 |                                |
|   600 | Amethyst              | violet          |    7 |                                  |
|   500 | Jasper                | red             |    7 |                                |
|   400 | Fluorite              | violet          |    4 |                                |
|   300 | Jade                  | green           |    6 |                                |
|   200 | Obsidian              | black           |    6 |                                |
|   200 | Agate                 | orange          |    6 |                                |
|     0 | (worthless glass)     | any color       |    5 | sells for 3–8 zm unidentified  |

The decision is rarely "carry or drop"; it's "if I'm slot-pressed and have to thin the heap, which colors do I drop first." Black opals, emeralds, and rubies are usually keepers; agate and obsidian first to go.

A few rules of thumb:

- **Every real gem is equally good for unicorn luck.** A 200 zm agate thrown to a co-aligned unicorn gives the same +5 Luck as a 3250 zm jacinth. Don't sell off your "junk" gems before you've found an alignment-matching unicorn to feed them to.
- **The price column matters when selling and in your final score.**
- **If you must drop some gems** (you're in a Mine's End slot-crunch, or you're consolidating before a stash), drop *duplicates of the cheap colors first*. Keep at least one of every identified type, because the touchstone work is already done.
- **Top tier** (≥ 2500: dilithium, diamond, ruby, jacinth, sapphire, black opal, emerald) are worth selling individually. At ordinary rates their offers begin at half base value—a diamond brings 2,000 zm—and a shop that does not deal in gems will not buy them at all.
- **Worthless glass never costs luck.** Glass thrown at a unicorn is either rejected ("not interested in your junk") or accepted accepted. The Luck risk only fires on *real* gems thrown to a **wrong-alignment** unicorn (random −3 to +3). Watch the wording: a unicorn accepts a real gem that raised your Luck *gratefully*, worthless glass that did nothing *graciously*.

---

### Weapons Tables {#weapons-tables}

Damage is shown as **vs small / vs large**, the dice rolled before enchantment and excluding silver/material bonuses. **Wt** is unit weight; **Cost** is the unenchanted shop base price in zorkmids. **Hit** is the to-hit bonus baked into the weapon itself (most are 0). Two-handed weapons that prevent shield use and two-weapon combat are flagged in the notes. Weapons are grouped by skill; consult the [per-role skill caps](#per-role-skill-caps) before investing slots. Samurai-language names for a handful of weapons are shown in parentheses (a Samurai sees them on screen by those names; same underlying item).

#### Dagger {#dagger}

Throw or stab. Daggers stack and rarely break, and Rogues get a multishot bonus on thrown daggers (up to four per turn at Expert).

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| dagger | 1d4 / 1d3 | 10 | 4 | +2 | iron | Stackable; Expert-skill Rogues can multishot up to four in a single throw. |
| elven dagger | 1d5 / 1d3 | 10 | 4 | +2 | wood | Stackable. Sting is the artifact form. |
| orcish dagger | 1d3 / 1d3 | 10 | 4 | +2 | iron | Stackable. |
| silver dagger | 1d4 / 1d3 | 12 | 40 | +2 | silver | Stackable. Silver damage to demons, vampires, lycanthropes, shades, and imps. Common Rogue/Ranger off-hand. |
| athame | 1d4 / 1d3 | 10 | 4 | +2 | iron | Stackable. Engraving with an athame **doesn't dull the blade**. |

#### Knife {#knife}

Mostly melee. Knives stack and can be thrown, but no role gets a thrown-knife multishot bonus.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| scalpel | 1d3 / 1d3 | 5 | 6 | +2 | metal | The Healer's starter. |
| knife (shito) | 1d3 / 1d2 | 5 | 4 | — | iron |  |
| stiletto | 1d3 / 1d2 | 5 | 4 | — | iron |  |
| worm tooth | 1d2 / 1d2 | 20 | 2 | — | bone |  |
| crysknife | 1d10 / 1d10 | 20 | 100 | +3 | bone | Reverts to a worm tooth when dropped or thrown. An erodeproof one reverts only about 10% of the time. |

#### Short sword {#short-sword}

One-handed melee. Wakizashi and short sword are the same weapon under different role names.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| short sword (wakizashi) | 1d6 / 1d8 | 30 | 10 | — | iron | The Rogue's starter. |
| elven short sword | 1d8 / 1d8 | 30 | 10 | — | wood |  |
| orcish short sword | 1d5 / 1d8 | 30 | 10 | — | iron |  |
| dwarvish short sword | 1d7 / 1d8 | 30 | 10 | — | iron |  |

#### Saber {#saber}

One-handed melee. The silver saber's artifact forms (Grayswandir, Werebane) are some of the strongest one-handers in the game.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| scimitar | 1d8 / 1d8 | 40 | 15 | — | iron |  |
| silver saber | 1d8 / 1d8 | 40 | 75 | — | silver | Silver does bonus damage to demons/weres/vampires/imps. Artifact forms: **Grayswandir** and **Werebane** (see [Artifacts](#artifacts)). |

#### Broadsword {#broadsword}

One-handed melee.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| broadsword (ninja-to) | 1d4+1d4 / 1d6+1 | 70 | 10 | — | iron |  |
| elven broadsword | 1d6+1d4 / 1d6+1 | 70 | 10 | — | wood |  |
| runesword | 1d4+1d4 / 1d6+1 | 40 | 300 | — | iron | Stormbringer is the chaotic artifact form. |

#### Long sword {#long-sword}

One-handed melee. The Lawful long sword carries the Excalibur fountain-dip path, the highest single-weapon return in the early game.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| long sword | 1d8 / 1d12 | 40 | 15 | — | iron | At XL 5+, dipping in a fountain rolls 1-in-30. Knights get 1-in-6. On a hit, Lawfuls get **Excalibur**. Others get the sword cursed. Artifact forms: Excalibur, Frost Brand, Fire Brand, Giantslayer, Vorpal Blade, Sunsword. |
| katana | 1d10 / 1d12 | 40 | 80 | +1 | iron | +1 to-hit baked in. Snickersnee is the artifact form. |

#### Two-handed sword {#two-handed-sword}

Two-handed weapons get a **3/2 Strength damage bonus** in 5.0: your Strength damage is multiplied by 1.5. Combined with the high base dice below, that is much of why two-handed swords rival one-hand-plus-shield despite forfeiting the shield slot. The same bonus applies to the battle-axe, dwarvish mattock, bardiche, and any other bimanual weapon.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| two-handed sword | 1d12 / 1d6+2d6 | 150 | 50 | — | iron | Two-handed (no shield, no off-hand weapon). |
| tsurugi | 1d16 / 1d8+2d6 | 60 | 500 | +2 | metal | Two-handed. The Tsurugi of Muramasa is the artifact form. |

#### Axe {#axe}

Melee. The regular axe is one-handed; the battle-axe is two-handed (gets the 3/2 Strength damage bonus).

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| axe | 1d6 / 1d4 | 60 | 8 | — | iron |  |
| battle-axe | 1d8+1d4 / 1d6+2d4 | 120 | 40 | — | iron | Two-handed (gets the 5.0 3/2 Str damage bonus). +1d4 small, +2d4 large. The Barbarian quest artifact **Cleaver** is a battle-axe. |

#### Pick-axe {#pick-axe}

Melee weapon and digging tool. `a` (apply) to dig in any direction. The mattock does the same and is two-handed.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| pick-axe | 1d6 / 1d3 | 100 | 50 | — | iron | Weapon-tool. Apply to dig through walls or down through floors (creates pit, then hole). Same `pick-axe` skill as the mattock. |
| dwarvish mattock | 1d12 / 1d8+2d6 | 120 | 50 | −1 | iron | Two-handed (3/2 Str damage bonus). Digs through walls like a pick-axe. Slight to-hit penalty (−1). |

#### Club {#club}

Blunt one-handed melee. The aklys is tethered: thrown while wielded as your primary, it returns to your hand.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| club | 1d6 / 1d3 | 30 | 3 | — | wood | Caveman starter. |
| aklys | 1d6 / 1d3 | 15 | 4 | — | iron | Returns when thrown if wielded as your primary weapon (it's tethered); occasional misfire. |

#### Mace {#mace}

One-handed blunt melee.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| mace | 1d6+1 / 1d6 | 30 | 5 | — | iron | The Priest's guaranteed first sacrifice gift, Demonbane: a silver mace with +1d5 to-hit and double damage versus demons, plus a banish invoke. |
| silver mace | 1d6+1 / 1d6 | 36 | 60 | — | silver | +1d20 versus demons, weres, vampires, shades, and most imps. |

#### Morning star {#morning-star}

One-handed blunt melee.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| morning star | 1d4+1d4 / 1d6+1 | 120 | 10 | — | iron | +1d4 small, +1 large; solid damage for a one-handed weapon. |

#### Flail {#flail}

One-handed blunt melee, plus the grappling hook as a utility tool that trains the same skill.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| flail (nunchaku) | 1d6+1 / 1d4+1d4 | 15 | 4 | — | iron | +1 small, +1d4 large; one-handed. |
| grappling hook | 1d2 / 1d6 | 30 | 50 | — | iron | Trains flail. Apply at two-square reach to snag objects, pull very small monsters, or drag yourself a step. |

#### Hammer {#hammer}

One-handed blunt melee. Mjollnir, the Valkyrie artifact war hammer, returns when thrown.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| war hammer | 1d4+1 / 1d4 | 50 | 5 | — | iron | Mjollnir is the artifact form (Valkyrie sacrifice gift; its alignment will match the player's). |

#### Quarterstaff {#quarterstaff}

Two-handed melee. Gets the 3/2 Strength damage bonus despite the modest base dice.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| quarterstaff | 1d6 / 1d6 | 40 | 5 | — | wood | Two-handed but light; the Wizard's starting weapon. |

#### Polearms {#polearms}

All polearms are two-handed. To strike at range, `#apply` the weapon (not wield-and-attack): you can hit at distance 2 orthogonally at Basic skill, with extra positions opening up at Skilled. You can still hit an adjacent monster the normal way with a polearm in hand, but the attack is treated as bashing — damage clamps to 1d2 base before bonuses and the weapon-skill bonus doesn't apply (Strength still does). Reach is what makes polearms worth carrying. Notes below describe each entry's extra damage.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| partisan | 1d6 / 1d6+1 | 80 | 10 | — | iron | Reach. |
| ranseur | 1d4+1d4 / 1d4+1d4 | 50 | 6 | — | iron | +1d4 small, +1d4 large. |
| spetum | 1d6+1 / 1d6+1d6 | 50 | 5 | — | iron | +1 small, +1d6 large. |
| glaive (naginata) | 1d6 / 1d10 | 75 | 6 | — | iron | Reach. |
| halberd | 1d10 / 1d6+1d6 | 150 | 10 | — | iron | +1d6 large. |
| bardiche | 1d4+1d4 / 1d4+2d4 | 120 | 7 | — | iron | +1d4 small, +2d4 large. |
| voulge | 1d4+1d4 / 1d4+1d4 | 125 | 5 | — | iron | +1d4 small, +1d4 large. |
| fauchard | 1d6 / 1d8 | 60 | 5 | — | iron | Reach. |
| guisarme | 1d4+1d4 / 1d8 | 80 | 5 | — | iron | +1d4 small. |
| bill-guisarme | 1d4+1d4 / 1d10 | 120 | 7 | — | iron | +1d4 small. |
| lucern hammer | 1d4+1d4 / 1d6 | 150 | 7 | — | iron | +1d4 small. |
| bec de corbin | 1d8 / 1d6 | 100 | 8 | — | iron | Reach. |

#### Spear {#spear}

All spears share the same skill; the trident uses a different one (see below). The Valkyrie starts with one and can train to Expert. The **Caveman** is the actual spear-multishot specialist: Cavemen get +1 multishot on any thrown spear (regular, silver, javelin alike), so a stack of javelins becomes a strong ranged option for them.

Spears get a **+2 to-hit bonus** when used against the big monsters (xorns, dragons, jabberwocks, nagas, and giants): the kebab bonus.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| spear | 1d6 / 1d8 | 30 | 3 | — | iron | Throwable. Valkyrie's starting weapon. |
| elven spear | 1d7 / 1d8 | 30 | 3 | — | wood |  |
| orcish spear | 1d5 / 1d8 | 30 | 3 | — | iron |  |
| dwarvish spear | 1d8 / 1d8 | 35 | 3 | — | iron |  |
| silver spear | 1d6 / 1d8 | 36 | 40 | — | silver | Silver damage to demons and weres. |
| javelin | 1d6 / 1d6 | 20 | 3 | — | iron | Stackable thrown weapon; Cavemen can ranged-spam them. |

#### Trident {#trident}

One-handed melee, separate skill from spears. The signature bonus comes out when you're fighting in water.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| trident | 1d6+1 / 1d4+2d4 | 25 | 5 | — | iron | One-handed. **+4 to-hit vs swimmers in water, +2 vs eels and snakes**: the trident's signature bonus. Outside water it's an ordinary side-arm. |

#### Lance {#lance}

Melee built for mounted combat. Any hit from horseback has a chance to joust for heavy extra damage. On foot it remains a useful reach weapon: apply it to attack from two squares away.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| lance | 1d6 / 1d8 | 180 | 10 | — | iron | One-handed. A mounted hit can joust for +2d10 primary-weapon damage (+2d2 off-hand); about one successful joust in 250 shatters the lance. On foot it keeps polearm reach but gets no joust bonus. |

#### Whip {#whip}

Light one-handed melee plus a utility tool. `#apply` the bullwhip to disarm an adjacent monster or yank yourself out of a pit.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| rubber hose | 1d4 / 1d3 | 20 | 3 | — | plastic | Joke weapon; never spawns randomly. Sometimes carried by Keystone Kops. |
| bullwhip | 1d2 / 1 | 20 | 4 | — | leather | Archeologist's starter. Apply to disarm an adjacent monster (only when the target is wielding a weapon), or to yank yourself out of a pit (anchors on a nearby boulder, furniture, or big monster). |

#### Bow {#bow}

One-handed launcher. Wield a bow and fire arrows from your quiver with `f`. Expert wielders multishot; Ranger and Samurai are the specialists. A bow prevents two-weapon combat but leaves your shield available.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| arrow | 1d6 / 1d6 | 1 | 2 | — | iron | Any bow. |
| elven arrow | 1d7 / 1d6 | 1 | 2 | — | wood | Best from an elven bow (elf volley bonus). |
| orcish arrow | 1d5 / 1d6 | 1 | 2 | — | iron | Best from an orcish bow (orc volley bonus). |
| silver arrow | 1d6 / 1d6 | 1 | 5 | — | silver | Any bow. Silver damage to demons and weres. |
| ya | 1d7 / 1d7 | 1 | 4 | +1 | metal | Best from a yumi (Samurai volley bonus). |
| bow | — | 30 | 60 | — | wood | Fires any arrow. |
| elven bow | — | 30 | 60 | — | wood | Best with elven arrows. |
| orcish bow | — | 30 | 60 | — | wood | Best with orcish arrows. |
| yumi | — | 30 | 60 | — | wood | The Samurai's bow; best with ya. |

#### Crossbow {#crossbow}

One-handed launcher. Hits harder per shot than the bow but reloads more slowly, and full multishot needs Str 18 (Str 16 for gnomes). Like a bow, it prevents two-weapon combat but not shield use.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| crossbow bolt | 1d4+1 / 1d6+1 | 1 | 2 | — | iron | Stackable. |
| crossbow | — | 50 | 40 | — | wood | Bolts pierce. At **Str 18** (16 for gnomes), multishot uses the normal roll; below that, the game rolls twice and takes the smaller volley. Gnomes also get +1 multishot. Rogues and Rangers reach Expert, Knights Skilled. |

#### Sling {#sling}

One-handed launcher. Ammo is whatever stones or gems you find on the floor (or carry), so cost of fire is essentially nil.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| sling | — | 3 | 20 | — | leather | Launches rocks, flint stones, and gems. Caveman starting weapon. |

#### Dart {#dart}

Throw-only. Stack big, weigh almost nothing, and can be coated with the poison from a potion of sickness.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| dart | 1d3 / 1d2 | 1 | 2 | — | iron | Poisonable. Tourist starts with a stack of ~21–40 at +2. |

#### Shuriken {#shuriken}

Throw-only. Monks get +1 multishot on shuriken.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| shuriken | 1d8 / 1d6 | 1 | 5 | +2 | iron |  |

#### Boomerang {#boomerang}

Throw-only. Curves along an arc and returns to you if the path stays clear; catching the return needs a Dex check.

| Weapon | Damage (S/L) | Wt | Cost | Hit | Material | Notes |
|--------------------|--------------|----|------|-----|--------------|----------------------------------------------------------------|
| boomerang | 1d9 / 1d9 | 5 | 20 | — | wood | Curves back on a clear path; stops on a monster, wall, door, or sink. Low Dex or Fumbling means you catch it in the face. |

---

### Armor Tables {#armor-tables}

**AC** is the armor-class bonus the piece provides (higher number = more protection; the number is subtracted from your displayed AC). **MC** is the magic-cancellation level (1-3) — higher MC reduces the chance of magic attacks landing. **Wt** is weight; **Cost** is shop base price. The **Notes** column folds in the intrinsic property granted while the piece is worn, and tactical caveats. Armor is grouped by slot. Dragon scale mail is listed separately because of its sheer importance to the endgame. Samurai-language names for a few pieces are shown in parentheses (same underlying item).

#### Body armor (suits) {#body-armor-suits}

| Armor | AC | MC | Wt | Cost | Material | Notes |
|--------------------------|----|----|----|------|----------|--------------------------------------------------------------------|
| plate mail (tanko) | +7 | 2 | 450 | 600 | iron | Spellcasting penalty. |
| crystal plate mail | +7 | 2 | 415 | 820 | glass | Never rusts. Spellcasting penalty. |
| bronze plate mail | +6 | 1 | 450 | 400 | copper |  |
| splint mail | +6 | 1 | 400 | 80 | iron |  |
| banded mail | +6 | 1 | 350 | 90 | iron |  |
| dwarvish mithril-coat | +6 | 2 | 150 | 240 | mithril | Light, but metallic: the suit penalty to casting is the same as plate mail's. |
| elven mithril-coat | +5 | 2 | 150 | 240 | mithril | Light, but metallic: the suit penalty to casting is the same as plate mail's. |
| chain mail | +5 | 1 | 300 | 75 | iron |  |
| orcish chain mail | +4 | 1 | 300 | 75 | iron |  |
| scale mail | +4 | 1 | 250 | 45 | iron |  |
| studded leather armor | +3 | 1 | 200 | 15 | leather | No spellcasting penalty. |
| ring mail | +3 | 1 | 250 | 100 | iron |  |
| orcish ring mail | +2 | 1 | 250 | 80 | iron |  |
| leather armor | +2 | 1 | 150 | 5 | leather |  |
| leather jacket | +1 | — | 30 | 10 | leather |  |
| gray dragon scale mail | +9 | — | 40 | 1200 | hide | Magic resistance. Endgame body-armor goal. |
| silver dragon scale mail | +9 | — | 40 | 1200 | hide | Reflection. |
| black dragon scale mail | +9 | — | 40 | 1200 | hide | Disintegration resistance + drain resistance. |
| yellow dragon scale mail | +9 | — | 40 | 900 | hide | Acid resistance + stoning resistance. |
| orange dragon scale mail | +9 | — | 40 | 900 | hide | Sleep resistance + free action. |
| white dragon scale mail | +9 | — | 40 | 900 | hide | Cold resistance + slow digestion. |
| red dragon scale mail | +9 | — | 40 | 900 | hide | Fire resistance + infravision. |
| green dragon scale mail | +9 | — | 40 | 900 | hide | Poison resistance + sickness resistance. |
| blue dragon scale mail | +9 | — | 40 | 900 | hide | Shock resistance + speed, same tier as speed boots. |
| gold dragon scale mail | +9 | — | 40 | 900 | hide | Hallucination resistance + permanent light (only body-slot light source). |

#### Dragon scales {#dragon-scales}

| Armor | AC | MC | Wt | Cost | Material | Notes |
|--------------------------|----|----|----|------|----------|--------------------------------------------------------------------|
| gray dragon scales | +3 | — | 40 | 700 | hide | Magic resistance. Make-into upgrade to scale mail. |
| silver dragon scales | +3 | — | 40 | 700 | hide | Reflection. |
| black dragon scales | +3 | — | 40 | 700 | hide | Disintegration resistance + drain resistance. |
| yellow dragon scales | +3 | — | 40 | 500 | hide | Acid resistance + stoning resistance. |
| orange dragon scales | +3 | — | 40 | 500 | hide | Sleep resistance + free action. |
| white dragon scales | +3 | — | 40 | 500 | hide | Cold resistance + slow digestion. |
| red dragon scales | +3 | — | 40 | 500 | hide | Fire resistance + infravision. |
| green dragon scales | +3 | — | 40 | 500 | hide | Poison resistance + sickness resistance. |
| blue dragon scales | +3 | — | 40 | 500 | hide | Shock resistance + speed, same tier as speed boots. |
| gold dragon scales | +3 | — | 40 | 500 | hide | Hallucination resistance + permanent light. |

#### Shirts {#shirts}

| Armor | AC | MC | Wt | Cost | Material | Notes |
|--------------------------|----|----|----|------|----------|--------------------------------------------------------------------|
| Hawaiian shirt | +0 | — | 5 | 3 | cloth | Tourist starter. Worn under body armor. |
| T-shirt | +0 | — | 5 | 2 | cloth | Worn under body armor. |

#### Cloaks {#cloaks}

| Armor | AC | MC | Wt | Cost | Material | Notes |
|--------------------------|----|----|----|------|----------|--------------------------------------------------------------------|
| mummy wrapping | +0 | 1 | 3 | 2 | cloth | Blocks invisibility while worn. |
| elven cloak | +1 | 1 | 10 | 60 | cloth | Stealth. |
| orcish cloak | +0 | 1 | 10 | 40 | cloth |  |
| dwarvish cloak | +0 | 1 | 10 | 50 | cloth |  |
| oilskin cloak | +1 | 2 | 10 | 50 | cloth | Resists grab attacks. |
| robe | +2 | 2 | 15 | 50 | cloth | Casting bonus. Cancels most of the metal-armor penalty. |
| alchemy smock | +1 | 1 | 10 | 50 | cloth | Poison resistance. |
| leather cloak | +1 | 1 | 15 | 40 | leather |  |
| cloak of protection | +3 | 3 | 10 | 50 | cloth | Highest MC of any cloak. |
| cloak of invisibility | +1 | 1 | 10 | 60 | cloth | Invisibility. |
| cloak of magic resistance | +1 | 1 | 10 | 60 | cloth | Magic resistance. The lightest source. |
| cloak of displacement | +1 | 1 | 10 | 50 | cloth | Displacement. |

#### Helmets {#helmets}

| Armor | AC | MC | Wt | Cost | Material | Notes |
|--------------------------|----|----|----|------|----------|--------------------------------------------------------------------|
| elven leather helm | +1 | — | 3 | 8 | leather |  |
| orcish helm | +1 | — | 30 | 10 | iron |  |
| dwarvish iron helm | +2 | — | 40 | 20 | iron |  |
| fedora | +0 | — | 3 | 1 | cloth | Archeologist starter; grants that role +1 Luck. |
| cornuthaum | +0 | 1 | 4 | 80 | cloth | Clairvoyance. Wizards only; blocks other clairvoyance for non-Wizards. |
| dunce cap | +0 | — | 4 | 1 | cloth | Int/Wis → 6. Auto-curses on wear. Needs remove curse to take off. |
| dented pot | +1 | — | 10 | 8 | iron |  |
| helm of brilliance | +1 | — | 40 | 50 | glass | Adds enchantment value to both Int and Wis while worn (a +3 helm gives +3 Int and +3 Wis). |
| helmet (kabuto) | +1 | — | 30 | 10 | iron |  |
| helm of caution | +1 | — | 50 | 50 | iron | Warning. |
| helm of opposite alignment | +1 | — | 50 | 50 | iron | Flips your alignment while worn. Cursed 90%. |
| helm of telepathy | +1 | — | 50 | 50 | iron | Telepathy within 8 squares while sighted; whole level while blind. |

The helm of opposite alignment is mostly a trap, but the alignment flip is sometimes useful on purpose: sacrifice on a cross-aligned altar, claim the opposite alignment's quest artifact, or, on the Astral Plane, change which altar accepts the Amulet.

#### Gloves {#gloves}

| Armor | AC | MC | Wt | Cost | Material | Notes |
|--------------------------|----|----|----|------|----------|--------------------------------------------------------------------|
| leather gloves (yugake) \* | +1 | — | 10 | 8 | leather |  |
| gauntlets of fumbling \* | +1 | — | 10 | 50 | leather | Causes frequent fumbling. Generated cursed 9 times in 10. Avoid. |
| gauntlets of power \* | +1 | — | 30 | 50 | iron | Sets Strength to 25. |
| gauntlets of dexterity \* | +1 | — | 10 | 50 | leather | Adds enchantment value to Dex while worn (a +3 pair gives +3 Dex). |

Items marked \* appear under one of four randomized descriptions until identified: *old gloves*, *padded gloves*, *riding gloves*, *fencing gloves* (plain leather gloves included).

#### Boots {#boots}

| Armor | AC | MC | Wt | Cost | Material | Notes |
|--------------------------|----|----|----|------|----------|--------------------------------------------------------------------|
| low boots | +1 | — | 10 | 8 | leather |  |
| iron shoes | +2 | — | 50 | 16 | iron |  |
| high boots | +2 | — | 20 | 12 | leather |  |
| speed boots \* | +1 | — | 20 | 50 | leather | Very fast. Free extra action on 2/3 of turns. |
| water walking boots \* | +1 | — | 15 | 50 | leather | Cross water and ice; a fireproof pair plus fire resistance can cross lava. |
| jumping boots \* | +1 | — | 20 | 50 | leather | Use `#jump` to leap to a chosen nearby square. |
| elven boots \* | +1 | — | 15 | 8 | leather | Stealth. |
| kicking boots \* | +1 | — | 50 | 8 | iron |  |
| fumble boots \* | +1 | — | 20 | 30 | leather | Causes frequent fumbling. Generated cursed 9 times in 10. Avoid. |
| levitation boots \* | +1 | — | 15 | 30 | leather | Levitation. Generated cursed 9 times in 10. Cursed boots can't be taken off, so that is a trap item. |

Items marked \* appear under one of seven randomized descriptions until identified: *combat boots*, *jungle boots*, *hiking boots*, *mud boots*, *buckled boots*, *riding boots*, *snow boots*.

#### Shields {#shields}

| Armor | AC | MC | Wt | Cost | Material | Notes |
|--------------------------|----|----|----|------|----------|--------------------------------------------------------------------|
| small shield | +1 | — | 30 | 3 | wood |  |
| shield of drain resistance | +1 | — | 30 | 50 | wood | Drain resistance. |
| shield of shock resistance | +1 | — | 30 | 50 | wood | Shock resistance. |
| elven shield | +2 | — | 40 | 7 | wood |  |
| Uruk-hai shield | +1 | — | 50 | 7 | iron |  |
| orcish shield | +1 | — | 50 | 7 | iron |  |
| large shield | +2 | — | 100 | 10 | iron | Like every shield, blocks two-handed weapons and two-weapon combat. |
| dwarvish roundshield | +2 | — | 100 | 10 | iron |  |
| shield of reflection | +2 | — | 50 | 50 | silver | Reflection. Saves the body-armor slot. |

---

### Spell Tables {#spell-tables}

The complete spellbook catalog, sorted by school then level. **Lvl** is the spell level; **Pw cost** is always 5×level. **Type** distinguishes how the spell targets:

- **aimed.** You pick a direction; the spell hits one square at that vector.
- **ray.** A beam from the caster through every square in a line until it stops.
- **untargeted.** No direction needed; the effect is on you, the level, or a fixed area.

**Upgrade** is the behavior change at **Skilled** rank or above in that school (except for protection, which upgrades at Expert, and jumping, which scales continuously).

| Spell           | School      | Lvl | Type       | Effect                              | Upgrade                       |
|-----------------|-------------|-----|------------|-------------------------------------|-------------------------------|
| force bolt      | Attack      | 1   | aimed      | 2d12 magical hit                    | —                             |
| chain lightning | Attack      | 2   | untargeted | Shock damage to nearby monsters     | —                             |
| drain life      | Attack      | 2   | aimed      | Drains an XP level from target      | —                             |
| magic missile   | Attack      | 2   | ray        | (XL÷2 + 1)d6 force ray, rounding XL÷2 down; magic resistance blocks it | —             |
| cone of cold    | Attack      | 4   | ray        | (XL÷2 + 1)d6 cold ray, rounding XL÷2 down | Aimed explosion          |
| fireball        | Attack      | 4   | ray        | (XL÷2 + 1)d6 fire ray, rounding XL÷2 down | Aimed explosion          |
| finger of death | Attack      | 7   | ray        | Death ray; magic resistance blocks it when incoming, though self-zapping bypasses that check | — |
| healing         | Healing     | 1   | aimed      | Restore hit points                  | Also cures blindness          |
| cure blindness  | Healing     | 2   | untargeted | Removes blindness                   | —                             |
| cure sickness   | Healing     | 3   | untargeted | Cures food poisoning and illness    | —                             |
| extra healing   | Healing     | 3   | aimed      | Heals more HP                       | —                             |
| stone to flesh  | Healing     | 3   | aimed      | Animates a statue as a live monster; cures stoning | —                 |
| restore ability | Healing     | 4   | untargeted | Restores one drained stat           | Restores all drained stats    |
| detect monsters | Divination  | 1   | untargeted | Reveals monsters on level           | Longer duration               |
| light           | Divination  | 1   | untargeted | Lights the current room             | —                             |
| detect food     | Divination  | 2   | untargeted | Reveals food on level               | Warns before a harmful meal   |
| clairvoyance    | Divination  | 3   | untargeted | Periodic glimpses of nearby map     | Skilled: also detects nearby monsters during each pulse |
| detect unseen   | Divination  | 3   | untargeted | Reveals invisible monsters and traps | —                            |
| identify        | Divination  | 3   | untargeted | Identifies one inventory item       | Identifies multiple items     |
| detect treasure | Divination  | 4   | untargeted | Reveals every object on the level   | Identifies detected object types |
| magic mapping   | Divination  | 5   | untargeted | Reveals the entire level            | —                             |
| confuse monster | Enchant.    | 1   | untargeted | Next melee hit confuses target      | Charges several hits          |
| slow monster    | Enchant.    | 2   | aimed      | Slows target's speed                | —                             |
| cause fear      | Enchant.    | 3   | untargeted | Visible monsters flee               | —                             |
| sleep           | Enchant.    | 3   | ray        | Puts targets in line to sleep       | —                             |
| charm monster   | Enchant.    | 5   | untargeted | Tames monsters in a 3×3 area        | —                             |
| protection      | Cleric      | 1   | untargeted | Temporary AC bonus paid from Pw     | **Expert**: 2× duration       |
| create monster  | Cleric      | 2   | untargeted | Summons a random monster nearby     | —                             |
| remove curse    | Cleric      | 3   | untargeted | Uncurses worn/wielded items         | Uncurses all carried items    |
| create familiar | Cleric      | 6   | untargeted | Creates a tame companion            | —                             |
| turn undead     | Cleric      | 6   | aimed      | Damages/turns undead and demons     | —                             |
| jumping         | Escape      | 1   | untargeted | Jump to a chosen nearby square      | Range scales with rank        |
| haste self      | Escape      | 3   | untargeted | Temporary fast movement             | Longer duration               |
| invisibility    | Escape      | 4   | untargeted | Become invisible                    | —                             |
| levitation      | Escape      | 4   | untargeted | Float over pits and water           | Can end at will with `>`      |
| teleport away   | Escape      | 6   | aimed      | Teleports target away               | —                             |
| knock           | Matter      | 1   | aimed      | Opens doors, picks locks            | —                             |
| wizard lock     | Matter      | 2   | aimed      | Closes and locks a door             | —                             |
| dig             | Matter      | 5   | ray        | Digs through walls, rock, floor     | —                             |
| polymorph       | Matter      | 6   | aimed      | Polymorphs target                   | —                             |
| cancellation    | Matter      | 7   | aimed      | Removes magical properties          | —                             |

The to-hit chance of most rays (sleep, magic missile, finger of death, and the unskilled forms of cone of cold and fireball) also scales with rank.

---

### Bestiary Tables {#bestiary-tables}

Every monster you might meet, grouped by map symbol. **Lvl** is base monster level. **Spd** is movement rate (12 is normal player speed). **AC** is armor class (lower is better). **MR** is the percentage chance the monster resists your spells and magic attacks. **Attacks** lists each mode, damage roll, and side effect; attacks separated by `·` can all occur in one turn. **Notes** lists traits that change the fight, such as flight, seeing invisible, regeneration, or a poisonous corpse.

#### Ants and insects `a` {#ants-and-insects-a}

Insects, often in groups. The soldier ant's poison sting drains Strength; killer bees swarm; the queen bee in a beehive room is tough on her own.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| giant ant | brown | 2 | 18 | 3 | 0 | bite 1d4 |  |
| killer bee | yellow | 1 | 18 | -1 | 0 | sting 1d3 poison | flies, poisonous-corpse, pois-res. Stings carry poison. |
| soldier ant | blue | 3 | 18 | 3 | 0 | bite 2d4 · sting 3d4 poison | poisonous-corpse, pois-res. Poison sting. |
| fire ant | red | 3 | 18 | 3 | 10 | bite 2d4 · bite 2d4 fire | fire-res. |
| giant beetle | black | 5 | 6 | 4 | 0 | bite 3d6 | poisonous-corpse, pois-res. |
| queen bee | magenta | 9 | 24 | -4 | 0 | sting 1d8 poison | flies, poisonous-corpse, pois-res. |

#### Blobs `b` {#blobs-b}

Slow and mindless. Don't melee an acid blob with bare hands or a metal weapon you care about: the passive acid corrodes both. Gelatinous cubes paralyse on touch.

All blobs are mindless, sleep-resistant, and poison-resistant.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| acid blob | green | 1 | 3 | 8 | 0 | passive 1d8 acid | amorphous, acid-res, ston-res. Passive acid damage; punching one corrodes your gloves. |
| quivering blob | white | 5 | 1 | 8 | 0 | touch 1d8 |  |
| gelatinous cube | cyan | 6 | 6 | 8 | 0 | touch 2d4 paralyse · passive 1d4 paralyse | fire-res, cold-res, shock-res, acid-res, ston-res. Slow but paralyses on touch. Don't melee without free-action. |

#### Cockatrices `c` {#cockatrices-c}

Medieval bestiary creature: a chicken with a serpent's tail whose touch turns flesh to stone. Carry a lizard corpse and fight gloved. No role resists stoning by default, and wielding a cockatrice corpse bare-handed kills you immediately. See [Petrification](#petrification-stoning).

All cockatrices are poison-resistant.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| chickatrice | brown | 4 | 4 | 8 | 30 | bite 1d2 · touch petrify · passive petrify | ston-res. A small cockatrice. Same petrify rules apply. |
| cockatrice | yellow | 5 | 6 | 6 | 30 | bite 1d3 · touch petrify · passive petrify | ston-res. Touch petrifies. Always carry a lizard corpse. |
| pyrolisk | red | 6 | 6 | 6 | 30 | gaze 2d6 fire · bite 1d6 | fire-res. |

#### Dogs and canines `d` {#dogs-and-canines-d}

Wild canines hunt in packs. Domestic ones can be tamed by feeding (see [Making Friends](#making-friends)). Werejackals and werewolves can give lycanthropy.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| jackal | brown | 0 | 12 | 7 | 0 | bite 1d2 | The first thing that ever killed you. |
| fox | red | 0 | 15 | 7 | 0 | bite 1d3 |  |
| coyote | brown | 1 | 12 | 7 | 0 | bite 1d4 |  |
| werejackal | brown | 2 | 12 | 7 | 10 | bite 1d4 lyc | regenerates, pois-res. No corpse. |
| little dog | white | 2 | 18 | 6 | 0 | bite 1d6 | tameable. Guaranteed Caveman/Ranger/Samurai starting pet. |
| dingo | yellow | 4 | 16 | 5 | 0 | bite 1d6 |  |
| dog | white | 4 | 16 | 5 | 0 | bite 1d6 | tameable. |
| large dog | white | 6 | 15 | 4 | 0 | bite 2d4 | tameable. |
| wolf | gray | 5 | 12 | 4 | 0 | bite 2d4 |  |
| werewolf | gray | 5 | 12 | 4 | 20 | bite 2d6 lyc | regenerates, pois-res. No corpse. |
| winter wolf cub | cyan | 5 | 12 | 4 | 0 | bite 1d8 · breath 1d6 cold | cold-res. |
| warg | black | 7 | 12 | 4 | 0 | bite 2d6 |  |
| winter wolf | cyan | 7 | 12 | 4 | 20 | bite 2d6 · breath 2d6 cold | cold-res. |
| hell hound pup | red | 7 | 12 | 4 | 20 | bite 2d6 · breath 2d6 fire | fire-res. |
| hell hound | red | 12 | 14 | 2 | 20 | bite 3d6 · breath 3d6 fire | fire-res. |

#### Eyes and spheres `e` {#eyes-and-spheres-e}

The floating eye's passive paralysis gaze is the most famous early-game death in the dungeon: never melee one without free action, blindness, or a ranged attack. Once it's dead, eat the corpse: it grants intrinsic telepathy.

All eyes and spheres fly. All except *floating eye* also are mindless.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| gas spore | gray | 1 | 3 | 10 | 0 | death-burst 4d6 |  |
| floating eye | blue | 2 | 1 | 9 | 10 | passive 3d70 paralyse | amphibious. Passive gaze paralyses on melee if you and the eye can both see each other. Use ranged, or wear a blindfold or towel to break sight. Corpse always grants telepathy. |
| freezing sphere | white | 6 | 13 | 4 | 0 | explode 4d6 cold | cold-res. |
| flaming sphere | red | 6 | 13 | 4 | 0 | explode 4d6 fire | fire-res. |
| shocking sphere | bright-blue | 6 | 13 | 4 | 0 | explode 4d6 shock | shock-res. |

#### Felines `f` {#felines-f}

Wild felines are fast and hostile; a tiger or displacer beast can turn an ordinary corridor into a bad fight. Wizards always start with a kitten, while roles without a fixed pet roll evenly between a kitten and a little dog.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| kitten | white | 2 | 18 | 6 | 0 | bite 1d6 | tameable. Common pet. |
| housecat | white | 4 | 16 | 5 | 0 | bite 1d6 | tameable. |
| jaguar | brown | 4 | 15 | 6 | 0 | claw 1d4 ×2 · bite 1d8 |  |
| lynx | cyan | 5 | 15 | 6 | 0 | claw 1d4 ×2 · bite 1d10 |  |
| panther | black | 5 | 15 | 6 | 0 | claw 1d6 ×2 · bite 1d10 |  |
| large cat | white | 6 | 15 | 4 | 0 | bite 2d4 | tameable. |
| tiger | yellow | 6 | 12 | 6 | 0 | claw 2d4 ×2 · bite 1d10 |  |
| displacer beast | blue | 12 | 12 | -10 | 0 | claw 4d4 ×2 · bite 2d10 |  |

#### Gremlins `g` {#gremlins-g}

At night, their touch strips a random intrinsic (fire resistance, telepathy, etc.). In water or fountains they split into more gremlins. Kill them on dry land, ideally during daylight.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| gremlin | green | 5 | 12 | 2 | 25 | claw 1d6 ×2 · bite 1d4 · claw curse | swims, poisonous-corpse, follows stairs, pois-res. |
| gargoyle | brown | 6 | 10 | -4 | 0 | claw 2d6 ×2 · bite 2d4 | ston-res. |
| winged gargoyle | magenta | 9 | 15 | -2 | 0 | claw 3d6 ×2 · bite 3d4 | flies, ston-res. |

#### Humanoids `h` {#humanoids-h}

Dwarves carry better-than-average loot (weapons, armor, and pick-axes), but that same equipment makes them dangerous to an unarmored explorer.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| hobbit | green | 1 | 9 | 10 | 0 | weapon 1d6 |  |
| dwarf | red | 2 | 6 | 10 | 10 | weapon 1d8 | tunnels. |
| bugbear | brown | 3 | 9 | 5 | 0 | weapon 2d4 |  |
| dwarf lord | blue | 4 | 6 | 10 | 10 | weapon 2d4 ×2 | tunnels. |
| dwarf king | magenta | 6 | 6 | 10 | 20 | weapon 2d6 ×2 | tunnels. |
| mind flayer | bright-magenta | 9 | 12 | 5 | 90 | weapon 1d4 · tentacle 2d1 drain-Int ×3 | flies, sees-invis. Tentacles drain Int; once it reaches 3, the next tentacle that lands kills you. Any helmet blocks 7/8 of tentacles. |
| master mind flayer | bright-magenta | 13 | 12 | 0 | 90 | weapon 1d8 · tentacle 2d1 drain-Int ×5 | flies, sees-invis. Five tentacles per turn. Any helmet blocks 7/8 of tentacles. |

#### Imps and minor demons `i` {#imps-and-minor-demons-i}

Mostly annoying small fry. Imps insult you and miss; quasits drain Dexterity. A homunculus's bite can put you to sleep. Without sleep resistance, fight at range.

All imps and minor demons follow you up and down stairs. All except *imp* are poison-resistant.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| manes | red | 1 | 3 | 7 | 0 | claw 1d3 ×2 · bite 1d4 | sleep-res. No corpse. |
| homunculus | green | 2 | 12 | 6 | 10 | bite 1d3 sleep | flies, poisonous-corpse, sleep-res. |
| imp | red | 3 | 12 | 2 | 20 | claw 1d4 | regenerates. |
| lemure | brown | 3 | 3 | 7 | 0 | claw 1d3 | Gehennom-only, regenerates, sleep-res. No corpse. |
| quasit | blue | 3 | 15 | 2 | 20 | claw 1d2 drain-Dx ×2 · bite 1d4 | regenerates. |
| tengu | cyan | 6 | 13 | 5 | 30 | bite 1d7 | teleports, teleport-control. |

#### Jellies `j` {#jellies-j}

Stationary or near-stationary. The blue jelly's passive cold and the spotted jelly's passive acid bite even when you hit them.

All jellies are amorphous and mindless.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| blue jelly | blue | 4 | 0 | 8 | 10 | passive 5d6 cold | corpse: cold + poison resistance. |
| spotted jelly | green | 5 | 0 | 8 | 10 | passive 6d6 acid | corpse: temp acid + stone resistance. |
| ochre jelly | brown | 6 | 3 | 8 | 20 | engulf 3d6 acid · passive 3d6 acid | corpse: temp acid + stone resistance. |

#### Kobolds `k` {#kobolds-k}

Weak early-game fodder. Every kobold corpse is poisonous; leave them alone unless you have poison resistance.

All kobolds have poisonous corpses and are poison-resistant.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| kobold | brown | 0 | 6 | 10 | 0 | weapon 1d4 |  |
| large kobold | red | 1 | 6 | 10 | 0 | weapon 1d6 |  |
| kobold lord | magenta | 2 | 6 | 10 | 0 | weapon 2d4 |  |
| kobold shaman | bright-blue | 2 | 6 | 6 | 10 | cast spell |  |

#### Leprechauns `l` {#leprechauns-l}

Steals gold and teleports away. The fix is to carry no gold near them, or to kill from range. The corpse drops any gold it still carries.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| leprechaun | green | 5 | 15 | 8 | 20 | claw 1d2 steal-gold | teleports. Steals gold and teleports away. Carry no gold near them. |

#### Mimics `m` {#mimics-m}

Disguised as items, walls, or fountains. Common in shops and zoos. The giveaway is the wrong object on the wrong square.

All mimics are amorphous, hide, and are acid-resistant.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| small mimic | brown | 7 | 3 | 7 | 0 | claw 3d4 |  |
| large mimic | red | 8 | 3 | 7 | 10 | claw 3d4 sticky |  |
| giant mimic | magenta | 9 | 3 | 7 | 20 | claw 3d6 sticky ×2 |  |

#### Nymphs `n` {#nymphs-n}

Steals one item and teleports to a random spot on the same level. Engage from range, block her path with pets, or engrave Elbereth. If she gets a hit in and you want the item back, you'll need to sweep the level to find and kill her; she drops what she stole when she dies.

All nymphs teleport.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| wood nymph | green | 3 | 12 | 9 | 20 | claw steal-item · claw seduce |  |
| water nymph | blue | 3 | 12 | 9 | 20 | claw steal-item · claw seduce | swims. |
| mountain nymph | brown | 3 | 12 | 9 | 20 | claw steal-item · claw seduce |  |

#### Orcs `o` {#orcs-o}

Pack hunters with mediocre loot, but they swarm; find a chokepoint in [the Mines](#the-gnomish-mines).

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| goblin | gray | 0 | 6 | 10 | 0 | weapon 1d4 |  |
| hobgoblin | brown | 1 | 9 | 10 | 0 | weapon 1d6 |  |
| orc | red | 1 | 9 | 10 | 0 | weapon 1d8 | pois-res. |
| hill orc | yellow | 2 | 9 | 10 | 0 | weapon 1d6 | pois-res. |
| Mordor orc | blue | 3 | 5 | 10 | 0 | weapon 1d6 | pois-res. |
| Uruk-hai | black | 3 | 7 | 10 | 0 | weapon 1d8 | pois-res. |
| orc shaman | bright-blue | 3 | 9 | 5 | 10 | cast | pois-res. |
| orc-captain | magenta | 5 | 5 | 10 | 0 | weapon 2d4 ×2 | pois-res. Hits hard. Drops decent loot. |

#### Piercers `p` {#piercers-p}

Clings to the ceiling and drops for a flat 4d6 when you walk under. A hard helmet makes the blow glance off; otherwise good AC can still win the dodge roll. Flying or a level without a ceiling prevents the ambush entirely.

All piercers hide.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| rock piercer | gray | 3 | 1 | 3 | 0 | bite 2d6 |  |
| iron piercer | cyan | 5 | 1 | 0 | 0 | bite 3d6 |  |
| glass piercer | white | 7 | 1 | 0 | 0 | bite 4d6 | acid-res. |

#### Quadrupeds `q` {#quadrupeds-q}

Rothes are early-game wreckers (three attacks per turn). Mumakil are slow but hit for 4d12.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| rothe | brown | 2 | 9 | 7 | 0 | claw 1d3 · bite 1d3 · bite 1d8 |  |
| mumak | gray | 5 | 9 | 0 | 0 | butt 4d12 · bite 2d6 |  |
| leocrotta | red | 6 | 18 | 4 | 10 | claw 2d6 · bite 2d6 · claw 2d6 |  |
| wumpus | cyan | 8 | 3 | 2 | 10 | bite 3d6 | clings. |
| titanothere | gray | 12 | 12 | 6 | 0 | claw 2d8 |  |
| baluchitherium | gray | 14 | 12 | 5 | 0 | claw 5d4 ×2 |  |
| mastodon | black | 20 | 12 | 5 | 0 | butt 4d8 ×2 |  |

#### Rodents `r` {#rodents-r}

Mostly nuisance fodder. Giant rats are common in the early dungeon; their corpses are safe food. Don't eat wererats.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| sewer rat | brown | 0 | 12 | 7 | 0 | bite 1d3 |  |
| giant rat | brown | 1 | 10 | 7 | 0 | bite 1d3 |  |
| rabid rat | brown | 2 | 12 | 6 | 0 | bite 2d4 drain-Co | poisonous-corpse, pois-res. |
| wererat | brown | 2 | 12 | 6 | 10 | bite 1d4 lyc | regenerates, pois-res. No corpse. |
| rock mole | gray | 3 | 3 | 0 | 20 | bite 1d6 | tunnels, eats metal objects left on the floor. |
| woodchuck | brown | 3 | 3 | 0 | 20 | bite 1d6 | swims, tunnels. |

#### Arachnids and centipedes `s` {#arachnids-and-centipedes-s}

Includes scorpions and centipedes. Giant spider and scorpion corpses are poisonous; cave spider and centipede corpses are safe. Do not confuse corpse poison with food poisoning from old food.

All arachnids and centipedes are poison-resistant.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| cave spider | gray | 1 | 12 | 3 | 0 | bite 1d2 | hides. |
| centipede | yellow | 2 | 4 | 3 | 0 | bite 1d3 poison | hides. |
| giant spider | magenta | 5 | 15 | 4 | 0 | bite 2d4 poison | poisonous-corpse. |
| scorpion | red | 5 | 15 | 3 | 0 | claw 1d2 ×2 · sting 1d4 poison | hides, poisonous-corpse. |
| Scorpius | magenta | 15 | 12 | 10 | 0 | claw 2d6 · claw 2d6 steal-amulet · sting 1d4 disease | poisonous-corpse, follows stairs, ston-res. |

#### Trappers and lurkers `t` {#trappers-and-lurkers-t}

Stationary engulfers that hide as part of the dungeon. Farlook cannot show a hidden lurker. Search beside a suspicious square to reveal one before stepping onto it.

All trappers and lurkers hide and follow you up and down stairs.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| lurker above | gray | 10 | 3 | 3 | 0 | engulf 1d6 wrap · engulf 2d6 | flies. |
| trapper | green | 12 | 3 | 3 | 0 | engulf 1d8 wrap · engulf 2d8 |  |

#### Unicorns and horses `u` {#unicorns-and-horses-u}

There are two equine `u`-class creatures. **Horses** (pony, horse, warhorse) spawn hostile in the wild but can be tamed, saddled, and ridden; the Knight starts on a saddled pony.

**Unicorns** (white, gray, black for Lawful, Neutral, Chaotic) are powerful kickers, peaceful when your alignment matches theirs and hostile otherwise. Killing a co-aligned unicorn is a −5 Luck penalty (you see "You feel guilty..."). Killing a cross-aligned one has no Luck consequence either way. If you don't want the fight, throw any gem (even worthless glass) to pacify a hostile unicorn at no cost; throwing real gems also adjusts your Luck (see [Luck and Fortune](#luck-and-fortune)). A killed unicorn drops its horn.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| pony | brown | 3 | 16 | 6 | 0 | kick 1d6 · bite 1d2 | tameable. Knight's starting steed. |
| white unicorn | white | 4 | 24 | 2 | 70 | butt 1d12 · kick 1d6 | pois-res. |
| gray unicorn | gray | 4 | 24 | 2 | 70 | butt 1d12 · kick 1d6 | pois-res. |
| black unicorn | black | 4 | 24 | 2 | 70 | butt 1d12 · kick 1d6 | pois-res. |
| horse | brown | 5 | 20 | 5 | 0 | kick 1d8 · bite 1d3 | tameable. |
| warhorse | brown | 7 | 24 | 4 | 0 | kick 1d10 · bite 1d4 | tameable. |

#### Vortices `v` {#vortices-v}

Engulfing elemental clouds. Different colors deal different damage types: blinding sand, cold, shock (which also drains Pw), and fire. Only the fog cloud is slow; the rest move at speed 20-22 and will close on you.

All vortices fly, are mindless, and leave no corpse.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| fog cloud | gray | 3 | 1 | 0 | 0 | engulf 1d6 | amorphous. |
| dust vortex | brown | 4 | 20 | 2 | 30 | engulf 2d8 blind |  |
| ice vortex | cyan | 5 | 20 | 2 | 30 | engulf 1d6 cold |  |
| energy vortex | bright-blue | 6 | 20 | 2 | 30 | engulf 1d6 shock · engulf 2d6 drain-Pw · passive 7d4 shock |  |
| steam vortex | blue | 7 | 22 | 2 | 30 | engulf 1d8 fire |  |
| fire vortex | yellow | 8 | 22 | 2 | 30 | engulf 1d10 fire · passive 9d4 fire |  |

#### Worms `w` {#worms-w}

Long worms become a maze of tail segments as they grow. Purple worms swallow you whole and digest. Fight them in the open so you can retreat before the swallow.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| baby long worm | brown | 5 | 3 | 5 | 0 | bite 1d4 |  |
| baby purple worm | magenta | 8 | 3 | 5 | 0 | bite 1d6 |  |
| long worm | brown | 9 | 3 | 5 | 10 | bite 2d4 | drops a worm tooth. |
| purple worm | magenta | 15 | 9 | 6 | 20 | bite 2d8 · engulf 1d10 digest |  |

#### Xans and fantastic insects `x` {#xans-and-fantastic-insects-x}

Grid bugs are trivial; xans, the bigger relatives, sting your legs and cut your carrying capacity.

All xans and fantastic insects are poison-resistant.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| grid bug | magenta | 0 | 12 | 9 | 0 | bite 1d1 shock | shock-res. |
| xan | red | 7 | 18 | -4 | 0 | sting 1d4 leg-wound | flies, poisonous-corpse. |

#### Lights `y` {#lights-y}

Yellow light bursts on contact and blinds you for 10d20 turns. Black light bursts and hallucinates you for 10d12 turns. See [Light Bursts](#light-bursts).

All lights fly and are amorphous and mindless.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| yellow light | yellow | 3 | 15 | 0 | 0 | explode 10d20 blind |  |
| black light | black | 5 | 15 | 0 | 0 | explode 10d12 hallu | sees-invis. |

#### Zruties `z` {#zruties-z}

A zruty is a nasty mid-game brute with two claws and a heavy bite, but worth good experience if you can take the flurry. The name comes from the hairy wild man of Slavic folklore.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| zruty | brown | 9 | 8 | 3 | 0 | claw 3d4 ×2 · bite 3d6 |  |

#### Angelic beings `A` {#angelic-beings-a}

Powerful late-game spellcasters with weapons. Astral-Plane Angels guard each High Priest. See [The Ascension Run](#the-ascension-run).

All angelic beings follow you up and down stairs, and none leaves a corpse. All except *Aleax* also fly. All except *couatl* also see invisible.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| couatl | green | 8 | 10 | 5 | 30 | bite 2d4 poison · bite 1d3 · hug 2d4 wrap | pois-res. |
| Aleax | yellow | 10 | 8 | 0 | 30 | weapon 1d6 ×2 · kick 1d4 |  |
| Angel | white | 14 | 10 | -4 | 55 | weapon 1d6 ×2 · claw 1d4 · cast 2d6 magic |  |
| ki-rin | yellow | 16 | 18 | -5 | 90 | kick 2d4 ×2 · butt 3d6 · cast 2d6 spell |  |
| Archon | magenta | 19 | 16 | -6 | 80 | weapon 2d4 ×2 · gaze 2d6 blind · claw 1d8 · cast 4d6 spell | regenerates. |

#### Bats and birds `B` {#bats-and-birds-b}

Erratic flyers, mostly nuisance. Vampire bats drain Strength with a poisoned bite (poison resistance blocks it).

All bats and birds fly.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| bat | brown | 0 | 22 | 8 | 0 | bite 1d4 |  |
| giant bat | red | 2 | 22 | 7 | 0 | bite 1d6 |  |
| raven | black | 4 | 20 | 6 | 0 | bite 1d6 · claw 1d6 blind |  |
| vampire bat | black | 5 | 20 | 6 | 0 | bite 1d6 · bite drain-Str | regenerates, poisonous-corpse, sleep-res, pois-res. |

#### Centaurs `C` {#centaurs-c}

Half-horse archers with strong physical attacks. Forest centaurs wield bows; plains and mountain centaurs wield crossbows. They shoot at range.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| plains centaur | brown | 4 | 18 | 4 | 0 | weapon 1d6 · kick 1d6 |  |
| forest centaur | green | 5 | 18 | 3 | 10 | weapon 1d8 · kick 1d6 |  |
| mountain centaur | cyan | 6 | 20 | 2 | 10 | weapon 1d10 · kick 1d6 ×2 |  |

#### Dragons `D` {#dragons-d}

Each adult dragon breathes its element type. Reflection bounces the ranged breath back. **Babies don't breathe**; they're just biters until they grow up. Adults are the source of dragon scale mail. See [Dragon Scale Mail](#armor-tables).

All except *Chromatic Dragon* also fly.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| baby gray dragon | gray | 12 | 9 | 2 | 10 | bite 2d6 |  |
| baby gold dragon | yellow | 12 | 9 | 2 | 10 | bite 2d6 |  |
| baby silver dragon | bright-cyan | 12 | 9 | 2 | 10 | bite 2d6 |  |
| baby red dragon | red | 12 | 9 | 2 | 10 | bite 2d6 |  |
| baby white dragon | white | 12 | 9 | 2 | 10 | bite 2d6 |  |
| baby orange dragon | orange | 12 | 9 | 2 | 10 | bite 2d6 |  |
| baby black dragon | black | 12 | 9 | 2 | 10 | bite 2d6 |  |
| baby blue dragon | blue | 12 | 9 | 2 | 10 | bite 2d6 |  |
| baby green dragon | green | 12 | 9 | 2 | 10 | bite 2d6 | poisonous-corpse. |
| baby yellow dragon | yellow | 12 | 9 | 2 | 10 | bite 2d6 |  |
| gray dragon | gray | 15 | 9 | -1 | 20 | breath 4d6 magic · bite 3d8 · claw 1d4 ×2 | sees-invis. Anti-magic breath. Magic resistance helps; reflection doesn't. |
| gold dragon | yellow | 15 | 9 | -1 | 20 | breath 4d6 fire · bite 3d8 · claw 1d4 ×2 | sees-invis. Fire breath. Drops gold-colored scales (light source). |
| silver dragon | bright-cyan | 15 | 9 | -1 | 20 | breath 4d6 cold · bite 3d8 · claw 1d4 ×2 | sees-invis. Cold breath plus reflection scales: your reflection target. |
| red dragon | red | 15 | 9 | -1 | 20 | breath 6d6 fire · bite 3d8 · claw 1d4 ×2 | sees-invis. Cone of fire. Get fire resistance before you meet one. |
| white dragon | white | 15 | 9 | -1 | 20 | breath 4d6 cold · bite 3d8 · claw 1d4 ×2 | sees-invis. Cone of cold. Cold resistance. |
| orange dragon | orange | 15 | 9 | -1 | 20 | breath 4d25 sleep · bite 3d8 · claw 1d4 ×2 | sees-invis. Sleep ray. Sleep resistance trivialises. |
| black dragon | black | 15 | 9 | -1 | 20 | breath 1d255 disint · bite 3d8 · claw 1d4 ×2 | sees-invis. Disintegration breath. Disint resistance OR reflection. |
| blue dragon | blue | 15 | 9 | -1 | 20 | breath 4d6 shock · bite 3d8 · claw 1d4 ×2 | sees-invis. Cone of lightning. Shock resistance. |
| green dragon | green | 15 | 9 | -1 | 20 | breath 4d6 poison · bite 3d8 · claw 1d4 ×2 | sees-invis, poisonous-corpse. Poison breath; poison resistance is enough. |
| yellow dragon | yellow | 15 | 9 | -1 | 20 | breath 4d6 acid · bite 3d8 · claw 1d4 ×2 | sees-invis. Acid breath. |
| Chromatic Dragon | magenta | 16 | 12 | 0 | 30 | breath 6d6 rnd-breath · cast spell · claw 2d8 steal-amulet · bite 4d8 ×2 · sting 1d6 | sees-invis, poisonous-corpse, follows stairs. |
| Ixoth | red | 15 | 12 | -1 | 20 | breath 8d6 fire · bite 4d8 · cast spell · claw 2d4 · claw 2d4 steal-amulet | sees-invis, follows stairs. |

#### Elementals `E` {#elementals-e}

Air elementals engulf and batter you with debris; fire elementals burn; water elementals strike once for 5d6 but do not drown you; earth elementals are slow and tough.

All except *stalker* also are mindless.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| stalker | white | 8 | 12 | 3 | 0 | claw 4d4 | flies, sees-invis, follows stairs. |
| air elemental | cyan | 8 | 36 | 2 | 30 | engulf 1d10 | flies. |
| fire elemental | yellow | 8 | 12 | 2 | 30 | claw 3d6 fire · passive 9d4 fire | flies. |
| earth elemental | brown | 8 | 6 | 2 | 30 | claw 4d6 | fire-res, cold-res, pois-res, ston-res. |
| water elemental | blue | 8 | 5 | 2 | 30 | claw 5d6 | swims, amphibious, pois-res, ston-res. |

#### Fungi and molds `F` {#fungi-and-molds-f}

Stationary. Lichen corpses never rot; keep one in your pack as iron rations. Brown, green, and red molds bite back on melee with elemental passive damage (cold, acid, fire). Yellow mold stuns on passive contact; violet fungus has an active touch attack with sticking.

All fungi and molds are mindless.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| lichen | bright-green | 0 | 1 | 9 | 0 | touch sticky |  |
| brown mold | brown | 1 | 0 | 9 | 0 | passive 2d6 cold | cold-res, pois-res. |
| yellow mold | yellow | 1 | 0 | 9 | 0 | passive 2d4 stun | poisonous-corpse, pois-res. |
| green mold | green | 1 | 0 | 9 | 0 | passive 2d4 acid | acid-res, ston-res. |
| red mold | red | 1 | 0 | 9 | 0 | passive 2d4 fire | fire-res, pois-res. |
| shrieker | magenta | 3 | 1 | 7 | 0 | — | pois-res. |
| violet fungus | magenta | 3 | 1 | 7 | 0 | touch 1d4 · touch sticky | pois-res. |

#### Gnomes `G` {#gnomes-g}

Gnomish PCs find most Mines residents peaceful. A gnome lord hits harder than its ordinary kin, and a gnomish wizard attacks only with spells; do not mistake either for harmless company.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| gnome | brown | 1 | 6 | 10 | 4 | weapon 1d6 |  |
| gnome lord | blue | 3 | 8 | 10 | 4 | weapon 1d8 |  |
| gnomish wizard | bright-blue | 3 | 10 | 4 | 10 | cast spell |  |
| gnome king | magenta | 5 | 10 | 10 | 20 | weapon 2d6 |  |

#### Giant humanoids `H` {#giant-humanoids-h}

Boulder throwers. Fire, frost, and storm giants deal their named element and their corpses can grant the matching resistance; titans cast spells. Eating a true giant's corpse raises Strength; the ettin and minotaur don't count as giants for that purpose.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| giant | red | 6 | 6 | 0 | 0 | weapon 2d10 |  |
| stone giant | gray | 6 | 6 | 0 | 0 | weapon 2d10 |  |
| hill giant | cyan | 8 | 10 | 6 | 0 | weapon 2d8 |  |
| fire giant | yellow | 9 | 12 | 4 | 5 | weapon 2d10 | fire-res. Throws boulders. |
| frost giant | white | 10 | 12 | 3 | 10 | weapon 2d12 | cold-res. Throws boulders. |
| ettin | brown | 10 | 12 | 3 | 0 | weapon 2d8 · weapon 3d6 |  |
| storm giant | blue | 16 | 12 | 3 | 10 | weapon 2d12 | shock-res. Throws boulders for big damage. |
| titan | magenta | 16 | 18 | -3 | 70 | weapon 2d8 · cast spell | flies. Tough humanoid with magic missiles. Casts spells. |
| minotaur | brown | 15 | 15 | 6 | 0 | claw 3d10 ×2 · butt 2d8 | Two claws plus a butt. Heavy hitter; roams the Gehennom mazes. |
| Cyclops | gray | 18 | 12 | 0 | 0 | weapon 4d8 ×2 · claw 2d6 steal-amulet | follows stairs, ston-res. Healer quest nemesis. Throws boulders. |
| Lord Surtur | magenta | 15 | 12 | 2 | 50 | weapon 2d10 ×2 · claw 2d6 steal-amulet | follows stairs, fire-res, ston-res. Valkyrie quest nemesis. |

#### Jabberwocks `J` {#jabberwocks-j}

The monster from Lewis Carroll's *Jabberwocky* ("O frabjous day! Callooh! Callay!") moves at player baseline speed and makes four 2d10 attacks. Decide early whether you can stand and trade blows. Vorpal Blade beheads it automatically.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| jabberwock | orange | 15 | 12 | -2 | 50 | bite 2d10 ×2 · claw 2d10 ×2 | flies. Four heavy attacks; baseline speed. |

#### Keystone Kops `K` {#keystone-kops-k}

Police force triggered by stealing from shops or hurting shopkeepers. Mostly weak individually but they swarm, and dead Kops respawn: each fallen Kop has a 1-in-5 chance to return near the down-stairs and a 1-in-5 chance to return elsewhere. Paying what you owe dismisses every Kop. Otherwise escape or genocide them instead of grinding through the force.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| Keystone Kop | blue | 1 | 6 | 10 | 10 | weapon 1d4 |  |
| Kop Sergeant | blue | 2 | 8 | 10 | 10 | weapon 1d6 |  |
| Kop Lieutenant | cyan | 3 | 10 | 10 | 20 | weapon 1d8 |  |
| Kop Kaptain | magenta | 4 | 12 | 10 | 20 | weapon 2d6 |  |

#### Liches `L` {#liches-l}

Skeletal spellcasters. The arch-lich can cast touch of death; master and arch-liches both require magic resistance to survive their spell barrages.

All liches regenerate, leave no corpse, and are undead, cold-resistant, sleep-resistant, and poison-resistant.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| lich | brown | 11 | 6 | 0 | 30 | touch 1d10 cold · cast spell |  |
| demilich | red | 14 | 9 | -2 | 60 | touch 3d4 cold · cast spell |  |
| master lich | magenta | 17 | 9 | -4 | 90 | touch 3d6 cold · cast spell | fire-res. Casts wizard spells. Kill from afar. |
| arch-lich | magenta | 25 | 9 | -6 | 90 | touch 5d6 cold · cast spell | fire-res, shock-res. Casts touch of death; magic resistance mandatory. |

#### Mummies `M` {#mummies-m}

Mindless undead. A wand or spell of undead turning deals 1d8 and makes a mummy flee. There is no scroll of undead turning. On death, a mummy leaves the already-old corpse of its base race; eating it without sickness resistance risks food poisoning, not magical aging.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| kobold mummy | brown | 3 | 8 | 6 | 20 | claw 1d4 | cold-res, sleep-res, pois-res. Drops an old kobold corpse. |
| gnome mummy | red | 4 | 10 | 6 | 20 | claw 1d6 | cold-res, sleep-res, pois-res. Drops an old gnome corpse. |
| orc mummy | gray | 5 | 10 | 5 | 20 | claw 1d6 | cold-res, sleep-res, pois-res. Drops an old orc corpse. |
| dwarf mummy | red | 5 | 10 | 5 | 20 | claw 1d6 | cold-res, sleep-res, pois-res. Drops an old dwarf corpse. |
| elf mummy | green | 6 | 12 | 4 | 30 | claw 2d4 | cold-res, sleep-res, pois-res. Drops an old elf corpse. |
| human mummy | gray | 6 | 12 | 4 | 30 | claw 2d4 ×2 | cold-res, sleep-res, pois-res. Drops an old human corpse. |
| ettin mummy | blue | 7 | 12 | 4 | 30 | claw 2d6 ×2 | cold-res, sleep-res, pois-res. Drops an old ettin corpse. |
| giant mummy | cyan | 8 | 14 | 3 | 30 | claw 3d4 ×2 | cold-res, sleep-res, pois-res. Drops an old giant corpse. |

#### Nagas `N` {#nagas-n}

Long serpentine bodies with ranged attacks. All nagas are poison-resistant. A black naga corpse can grant permanent poison resistance; its acid and stoning resistance last only a few turns.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| red naga hatchling | red | 3 | 10 | 6 | 0 | bite 1d4 | fire-res. |
| black naga hatchling | black | 3 | 10 | 6 | 0 | bite 1d4 | acid-res, ston-res. |
| golden naga hatchling | yellow | 3 | 10 | 6 | 0 | bite 1d4 |  |
| guardian naga hatchling | green | 3 | 10 | 6 | 0 | bite 1d4 |  |
| red naga | red | 6 | 12 | 4 | 0 | bite 2d4 · breath 2d6 fire | fire-res. |
| black naga | black | 8 | 14 | 2 | 10 | bite 2d6 · spit acid | acid-res, ston-res. |
| golden naga | yellow | 10 | 14 | 2 | 70 | bite 2d6 · cast spell 4d6 |  |
| guardian naga | green | 12 | 16 | 0 | 50 | spit 1d6 poison · bite 1d6 paralyse · touch · hug 2d4 wrap | poisonous-corpse. Lawful PCs may find them peaceful. |

#### Ogres `O` {#ogres-o}

Big melee brutes. They carry a club and sometimes a battle-axe, but no armor.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| ogre | brown | 5 | 10 | 5 | 0 | weapon 2d5 |  |
| ogre lord | red | 7 | 12 | 3 | 30 | weapon 2d6 |  |
| ogre king | magenta | 9 | 14 | 4 | 60 | weapon 3d5 |  |

#### Puddings and oozes `P` {#puddings-and-oozes-p}

**Brown and black puddings split** when you hit them with an iron or metal melee weapon. Brown puddings **rot** your wood/leather/cloth/bone armor on bite; black puddings **corrode** your metal armor on bite *and* corrode your wielded metal weapon on the passive return-hit. Gray ooze **rusts** metal armor but doesn't split. Fire-kill puddings so they don't multiply, or pick a chokepoint.

**Green slime** is a [Gehennom](#gehennom)-only exception: doesn't split, leaves a glob, and one touch starts a 10-turn countdown to becoming one yourself. Fight at range, burn yourself with fire to clear it, or wear an **amulet of unchanging** (blocks and aborts the transformation). Prayer doesn't work in Gehennom, so don't rely on it. See *Delayed Deaths* for the full cure list.

All puddings and oozes are amorphous, mindless, cold-resistant, poison-resistant, acid-resistant, and petrification-resistant. All except *gray ooze* also are shock-resistant.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| gray ooze | gray | 3 | 1 | 8 | 0 | bite 2d8 rust | fire-res. |
| brown pudding | brown | 5 | 3 | 8 | 0 | bite decay |  |
| green slime | green | 6 | 6 | 6 | 0 | touch 1d4 slime · passive slime | No corpse. |
| black pudding | black | 10 | 6 | 6 | 0 | bite 3d8 corrode · passive corrode |  |

#### Quantum mechanics `Q` {#quantum-mechanics-q}

The `Q` class is two creatures, both with random claw effects. The **quantum mechanic** teleports you on a hit: the annoyance is the lost position more than the damage. The **genetic engineer** polymorphs you: unless you have *Unchanging* or magic resistance, one claw and you become something else.

Both species also teleport themselves at random, and both leave poisonous corpses.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| quantum mechanic | cyan | 7 | 12 | 3 | 10 | claw 1d4 teleport | Self-teleports. Corpse toggles intrinsic Fast. |
| genetic engineer | green | 12 | 12 | 3 | 10 | claw 1d4 polymorph | Self-teleports. Corpse triggers polyself. |

#### Rust monsters and disenchanters `R` {#rust-monsters-and-disenchanters-r}

Rust monsters rust iron equipment on touch. Disenchanters drain enchantment from your armor when they hit you, and drain enchantment from your weapon when you hit them (passive counterattack). Either way, strip irreplaceable kit before engaging, and switch to silver or non-iron weapons against the rust monster.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| rust monster | brown | 5 | 18 | 2 | 0 | touch rust ×2 · passive rust | swims. Touch rusts iron. Strip armor before engaging or use silver. |
| disenchanter | blue | 12 | 12 | -10 | 0 | claw 4d4 disenchant · passive disenchant | Gehennom-only. Active drains armor; passive drains weapon when you melee it. |

#### Snakes `S` {#snakes-s}

Mostly poisonous. The pit viper and the cobra are the dangerous ones; garter snakes are fodder.

All snakes swim. All except *python* also hide.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| garter snake | green | 1 | 8 | 8 | 0 | bite 1d2 |  |
| snake | brown | 4 | 15 | 3 | 0 | bite 1d6 poison | poisonous-corpse, pois-res. |
| water moccasin | red | 4 | 15 | 3 | 0 | bite 1d6 poison | poisonous-corpse, pois-res. |
| python | magenta | 6 | 3 | 5 | 0 | bite 1d4 · touch · hug 1d4 wrap · hug 2d4 |  |
| pit viper | blue | 6 | 15 | 2 | 0 | bite 1d4 poison ×2 | poisonous-corpse, pois-res. |
| cobra | blue | 6 | 18 | 2 | 0 | bite 2d4 poison · spit blind | poisonous-corpse, pois-res. |

#### Trolls `T` {#trolls-t}

Regenerates from corpses on a timer. Three reliable ways to keep a troll dead: **eat the corpse** before it revives; **kill it with Trollsbane wielded** (the artifact disables the revive timer); or **stone it** so it leaves a statue instead of a corpse. A corpse left behind revives about three times in four, so an old level is likely to have its troll back on its feet.

All trolls regenerate and follow you up and down stairs.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| troll | brown | 7 | 12 | 4 | 0 | weapon 4d2 · claw 4d2 · bite 2d6 |  |
| ice troll | white | 9 | 10 | 2 | 20 | weapon 2d6 · claw 2d6 cold · bite 2d6 | cold-res. |
| rock troll | cyan | 9 | 12 | 0 | 0 | weapon 3d6 · claw 2d8 · bite 2d6 |  |
| water troll | blue | 11 | 14 | 4 | 40 | weapon 2d8 · claw 2d8 · bite 2d6 | swims. |
| Olog-hai | magenta | 13 | 12 | -4 | 0 | weapon 3d6 · claw 2d8 · bite 2d6 |  |

#### Umber hulks `U` {#umber-hulks-u}

Confusion gaze. Don't melee without some way to dodge the gaze. Blindness defeats it (the gaze requires mutual sight); free action does *not* (it covers paralysis, holding, and sleep, never confusion). The confusion stacks and wrecks navigation, and confused spellbook study garbles the spell.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| umber hulk | brown | 9 | 6 | 2 | 25 | claw 3d4 ×2 · bite 2d5 · gaze confuse | tunnels. Confusion gaze. Hard to navigate around. Hits hard too. |

#### Vampires `V` {#vampires-v}

Drains XL on bite. Shapeshifts to bat or cloud. An ordinary vampire or vampire lord leaves an already-old human corpse; Vlad leaves none. Vlad the Impaler is the boss of [Vlad's Tower](#vlads-tower).

All vampires fly, regenerate, are undead, follow you up and down stairs, and shapeshift.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| vampire | red | 10 | 12 | 1 | 25 | claw 1d6 · bite 1d6 drain-XL | Drops an old human corpse. |
| vampire lord | blue | 12 | 14 | 0 | 50 | claw 1d8 · bite 1d8 drain-XL | Drops an old human corpse. |
| Vlad the Impaler | magenta | 28 | 26 | -6 | 80 | weapon 2d10 · bite 1d12 drain-XL | Vampire boss in Vlad's Tower. Has the Candelabrum. |

#### Wraiths `W` {#wraiths-w}

A wraith drains an experience level on touch. A fresh plain wraith corpse repays the danger by granting an experience level when eaten; barrow wights and Nazgul leave no corpse.

All wraiths are undead and follow you up and down stairs.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| barrow wight | gray | 3 | 12 | 5 | 5 | weapon drain-XL · cast spell · claw 1d4 · touch 1d4 cold | cold-res, sleep-res, pois-res. |
| wraith | black | 6 | 12 | 4 | 15 | touch 1d6 drain-XL | flies. |
| Nazgul | magenta | 13 | 12 | 0 | 25 | weapon 1d4 drain-XL · breath 2d25 sleep | sees-invis. |

#### Xorns `X` {#xorns-x}

D&D's three-armed, three-eyed creatures from the Elemental Plane of Earth. They **phase through walls** (no rubble, no dig) and eat metal items off the floor. Their claws and bite are physical only, so worn armor and wielded weapons aren't directly at risk, but they hit hard for their level. The corpse grants temporary stoning resistance.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| xorn | brown | 8 | 9 | -2 | 20 | claw 1d3 ×3 · bite 4d6 | fire-res, cold-res, ston-res. |

#### Apelike creatures `Y` {#apelike-creatures-y}

Apes and great apes mostly; sasquatches are fast. Carnivore corpses are safe food.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| monkey | gray | 2 | 12 | 6 | 0 | claw steal-item · bite 1d3 |  |
| ape | brown | 4 | 12 | 6 | 0 | claw 1d3 ×2 · bite 1d6 |  |
| owlbear | brown | 5 | 12 | 5 | 0 | claw 1d6 ×2 · hug 2d8 |  |
| yeti | white | 5 | 15 | 6 | 0 | claw 1d6 ×2 · bite 1d4 | cold-res. |
| carnivorous ape | black | 6 | 12 | 6 | 0 | claw 1d4 ×2 · hug 1d8 |  |
| sasquatch | gray | 7 | 15 | 6 | 0 | claw 1d6 ×2 · kick 1d8 | sees-invis. |

#### Zombies `Z` {#zombies-z}

Slow undead. Easy to kite. Race-based zombies leave an already-old corpse of their base race, so eating one without sickness resistance risks food poisoning. A wand or spell of undead turning deals 1d8 and makes them flee; there is no corresponding scroll. The **skeleton** doesn't generate randomly: it appears in Orcus Town or when summoned by a bone devil. Big zombie populations live in morgues.

All zombies are mindless and undead.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| kobold zombie | brown | 0 | 6 | 10 | 0 | claw 1d4 | follows stairs, cold-res, sleep-res, pois-res. Drops an old kobold corpse. |
| gnome zombie | brown | 1 | 6 | 10 | 0 | claw 1d5 | follows stairs, cold-res, sleep-res, pois-res. Drops an old gnome corpse. |
| orc zombie | gray | 2 | 6 | 9 | 0 | claw 1d6 | follows stairs, cold-res, sleep-res, pois-res. Drops an old orc corpse. |
| dwarf zombie | red | 2 | 6 | 9 | 0 | claw 1d6 | follows stairs, cold-res, sleep-res, pois-res. Drops an old dwarf corpse. |
| elf zombie | green | 3 | 6 | 9 | 0 | claw 1d7 | follows stairs. Drops an old elf corpse. |
| human zombie | white | 4 | 6 | 8 | 0 | claw 1d8 | follows stairs. Drops an old human corpse. |
| ettin zombie | blue | 6 | 8 | 6 | 0 | claw 1d10 ×2 | follows stairs, cold-res, sleep-res, pois-res. Drops an old ettin corpse. |
| ghoul | black | 3 | 6 | 10 | 0 | claw 1d2 paralyse · claw 1d3 | cold-res, sleep-res, pois-res. No corpse. |
| giant zombie | cyan | 8 | 8 | 6 | 0 | claw 2d8 ×2 | follows stairs, cold-res, sleep-res, pois-res. Drops an old giant corpse. |
| skeleton | white | 12 | 8 | 4 | 0 | weapon 2d6 · touch 1d6 slow | cold-res, sleep-res, pois-res, ston-res. |

#### Humans and elves `@` {#humans-and-elves}

Never make assumptions from an `@` alone. It can be a peaceful shopkeeper, priest, watchman, or quest leader; or Medusa, a role nemesis, Croesus, or the Wizard of Yendor. Check the name before you move; that class also contains soldiers, ninja, doppelgangers, weres, adventurers, and the player.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| human | white | 0 | 12 | 10 | 0 | weapon 1d6 |  |
| wererat | brown | 2 | 12 | 10 | 10 | weapon 2d4 | regenerates. No corpse. |
| werejackal | red | 2 | 12 | 10 | 10 | weapon 2d4 | regenerates. No corpse. |
| werewolf | orange | 5 | 12 | 10 | 20 | weapon 2d4 | regenerates. No corpse. |
| elf | white | 0 | 12 | 10 | 2 | weapon 1d8 | sees-invis. |
| Woodland-elf | green | 4 | 12 | 10 | 10 | weapon 2d4 | sees-invis. |
| Green-elf | bright-green | 5 | 12 | 10 | 10 | weapon 2d4 | sees-invis. |
| Grey-elf | gray | 6 | 12 | 10 | 10 | weapon 2d4 | sees-invis. |
| elf-lord | bright-blue | 8 | 12 | 10 | 20 | weapon 2d4 ×2 | sees-invis. |
| Elvenking | magenta | 9 | 12 | 10 | 25 | weapon 2d4 ×2 | sees-invis. |
| doppelganger | white | 9 | 12 | 5 | 20 | weapon 1d12 | shapeshifter. |
| shopkeeper | white | 12 | 16 | 0 | 50 | weapon 4d4 ×2 | starts peaceful. Don't anger one. |
| guard | blue | 12 | 12 | 10 | 40 | weapon 4d10 | starts peaceful. |
| prisoner | white | 12 | 12 | 10 | 0 | weapon 1d6 | starts peaceful. |
| Oracle | bright-blue | 12 | 0 | 0 | 50 | passive 13d4 magic | starts peaceful. |
| priest | white | 12 | 12 | 10 | 50 | weapon 4d10 · kick 1d4 · cast cleric | starts peaceful. Temple defenders. Convert their altars or sacrifice on them. |
| high priest | white | 25 | 15 | 7 | 70 | weapon 4d10 · kick 2d8 · cast 2d8 cleric ×2 | sees-invis. Endgame altar guardian. Don't fight one head-on. |
| soldier | gray | 6 | 10 | 10 | 0 | weapon 1d8 | follows stairs. |
| sergeant | red | 8 | 10 | 10 | 5 | weapon 2d6 | follows stairs. |
| nurse | white | 11 | 6 | 0 | 0 | claw 2d6 heal |  |
| lieutenant | green | 10 | 10 | 10 | 15 | weapon 3d4 ×2 | follows stairs. |
| captain | blue | 12 | 10 | 10 | 15 | weapon 4d4 ×2 | follows stairs. |
| watchman | gray | 6 | 10 | 10 | 0 | weapon 1d8 | follows stairs, starts peaceful. |
| watch captain | green | 10 | 10 | 10 | 15 | weapon 3d4 ×2 | follows stairs, starts peaceful. |
| Medusa | bright-green | 20 | 12 | 2 | 50 | weapon 2d4 · claw 1d8 · gaze petrify · bite 1d6 poison | flies, swims, amphibious, poisonous-corpse. |
| Wizard of Yendor | bright-magenta | 30 | 12 | -8 | 100 | claw 2d12 steal-amulet · cast spell | flies, regenerates, sees-invis, fire-res, poison-res. Covetous: teleports to you in late Gehennom and on the planes. The final boss. |
| Croesus | magenta | 20 | 15 | 0 | 40 | weapon 4d10 | sees-invis, follows stairs. Vault guardian on Fort Ludios. Wields a two-handed sword and hoards gold, gems, and magic items off the floor. |
| archeologist | white | 10 | 12 | 10 | 1 | weapon 1d6 ×2 | tunnels. |
| barbarian | white | 10 | 12 | 10 | 1 | weapon 1d6 ×2 |  |
| caveman | white | 10 | 12 | 10 | 0 | weapon 2d4 |  |
| healer | white | 10 | 12 | 10 | 1 | weapon 1d6 |  |
| knight | white | 10 | 12 | 10 | 1 | weapon 1d6 ×2 |  |
| monk | white | 10 | 12 | 10 | 2 | claw 1d8 · kick 1d8 |  |
| priest | white | 10 | 12 | 10 | 2 | weapon 1d6 · cast cleric | Temple defenders. Convert their altars or sacrifice on them. |
| ranger | white | 10 | 12 | 10 | 2 | weapon 1d4 |  |
| rogue | white | 10 | 12 | 10 | 1 | weapon 1d6 ×2 |  |
| samurai | white | 10 | 12 | 10 | 1 | weapon 1d8 ×2 |  |
| tourist | white | 10 | 12 | 10 | 1 | weapon 1d6 ×2 |  |
| valkyrie | white | 10 | 12 | 10 | 1 | weapon 1d8 ×2 |  |
| wizard | white | 10 | 12 | 10 | 3 | weapon 1d6 · cast spell |  |
| Lord Carnarvon | magenta | 20 | 15 | 0 | 90 | weapon 4d10 · cast 4d8 spell | tunnels, starts peaceful. Archeologist quest leader. |
| Pelias | magenta | 20 | 15 | 0 | 90 | weapon 4d10 ×2 | starts peaceful. Barbarian quest leader. |
| Shaman Karnov | magenta | 20 | 15 | 0 | 90 | weapon 4d10 · cast 2d8 cleric | starts peaceful. Cave Dweller quest leader. |
| Hippocrates | magenta | 20 | 15 | 0 | 90 | weapon 1d6 · cast 3d8 cleric ×2 | starts peaceful. Healer quest leader. |
| King Arthur | magenta | 20 | 15 | 0 | 90 | weapon 4d10 ×2 | starts peaceful. Knight quest leader. Holds Excalibur if you didn't get it. |
| Grand Master | black | 25 | 15 | 0 | 90 | claw 4d10 · kick 2d8 · cast 2d8 cleric ×2 | sees-invis, starts peaceful. Monk quest leader. |
| Arch Priest | white | 25 | 15 | 7 | 90 | weapon 4d10 · kick 2d8 · cast 2d8 cleric ×2 | sees-invis, starts peaceful. Priest quest leader. |
| Orion | magenta | 20 | 15 | 0 | 90 | weapon 4d10 · cast 4d8 spell | swims, amphibious, sees-invis, starts peaceful. Ranger quest leader. Bow user. |
| Master of Thieves | magenta | 20 | 15 | 0 | 90 | weapon 4d10 · weapon 2d6 · claw 2d4 steal-amulet | starts peaceful. Rogue quest leader; also Tourist quest nemesis. |
| Lord Sato | magenta | 20 | 15 | 0 | 90 | weapon 4d10 ×2 | starts peaceful. Samurai quest leader. |
| Twoflower | white | 20 | 15 | 10 | 90 | weapon 4d10 | starts peaceful. Tourist quest leader. |
| Norn | magenta | 20 | 15 | 0 | 90 | weapon 4d10 ×2 | starts peaceful, cold-res. Valkyrie quest leader. |
| Neferet the Green | green | 20 | 15 | 0 | 90 | weapon 4d10 · cast 2d8 spell ×2 | starts peaceful. Wizard quest leader. |
| Thoth Amon | magenta | 16 | 12 | 0 | 10 | weapon 1d6 · cast spell ×2 · claw 1d4 steal-amulet | follows stairs. Barbarian quest nemesis. |
| Master Kaen | magenta | 25 | 12 | -10 | 10 | claw 16d2 ×2 · cast cleric · claw 1d4 steal-amulet | sees-invis, follows stairs. Monk quest nemesis. |
| Master Assassin | magenta | 15 | 12 | 0 | 30 | weapon 2d6 poison · weapon 2d8 · claw 2d6 steal-amulet | follows stairs. Rogue quest nemesis. |
| Ashikaga Takauji | magenta | 15 | 12 | 0 | 40 | weapon 2d6 ×2 · claw 2d6 steal-amulet | follows stairs. Samurai quest nemesis. |
| Dark One | black | 15 | 12 | 0 | 80 | weapon 1d6 ×2 · claw 1d4 steal-amulet · cast spell | follows stairs. Wizard quest nemesis. |
| student | white | 5 | 12 | 10 | 10 | weapon 1d6 | tunnels, starts peaceful. |
| chieftain | white | 5 | 12 | 10 | 10 | weapon 1d6 | starts peaceful. |
| neanderthal | white | 5 | 12 | 10 | 10 | weapon 2d4 | starts peaceful. |
| attendant | white | 5 | 12 | 10 | 10 | weapon 1d6 | starts peaceful. |
| page | white | 5 | 12 | 10 | 10 | weapon 1d6 ×2 | starts peaceful. |
| abbot | white | 5 | 12 | 10 | 20 | claw 8d2 · kick 3d2 stun · cast cleric | starts peaceful. |
| acolyte | white | 5 | 12 | 10 | 20 | weapon 1d6 · cast cleric | starts peaceful. |
| hunter | white | 5 | 12 | 10 | 10 | weapon 1d4 | sees-invis, starts peaceful. |
| thug | white | 5 | 12 | 10 | 10 | weapon 1d6 ×2 | starts peaceful. |
| ninja | white | 5 | 12 | 10 | 10 | weapon 1d8 ×2 |  |
| roshi | white | 5 | 12 | 10 | 10 | weapon 1d8 ×2 | starts peaceful. |
| guide | white | 5 | 12 | 10 | 20 | weapon 1d6 · cast spell | starts peaceful. |
| warrior | white | 5 | 12 | 10 | 10 | weapon 1d8 ×2 | starts peaceful. |
| apprentice | white | 5 | 12 | 10 | 30 | weapon 1d6 · cast spell | starts peaceful. |

#### Major demons `&` {#major-demons}

Major demons. Most can gate in reinforcements (a single barbed devil in your face can become five). Silver weapons and Demonbane do extra damage. Only Geryon, Dispater, Baalzebub, and Asmodeus accept bribes, and none will bargain while you wield Excalibur or Demonbane.

They all follow you up and down stairs.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| water demon | blue | 8 | 12 | -4 | 30 | weapon 1d3 · claw 1d3 · bite 1d3 | swims, demonic. |
| [amorous demon](#seduction) | gray | 6 | 12 | 0 | 70 | seduction (see Seduction) | flies, demonic. Displays as succubus or incubus by the demon's own randomly-assigned gender. |
| horned devil | brown | 6 | 9 | -5 | 50 | weapon 1d4 · claw 1d4 · bite 2d3 · sting 1d3 | demonic. |
| erinys | red | 7 | 12 | 2 | 30 | weapon 2d4 Str-drain | fire-res, pois-res. Grows stronger as your alignment record falls, gaining harder blows, flight, regeneration, and a second attack. |
| barbed devil | red | 8 | 12 | 0 | 35 | claw 2d4 · claw 2d4 sticky · sting 3d4 | demonic. |
| marilith | red | 7 | 12 | -6 | 80 | weapon 2d4 ×2 · claw 2d4 ×4 | sees-invis, demonic. |
| vrock | green | 8 | 12 | 0 | 50 | claw 1d4 ×2 · claw 1d8 ×2 · bite 1d6 | demonic. |
| hezrou | green | 9 | 6 | -2 | 55 | claw 1d3 ×2 · bite 4d4 | demonic. |
| bone devil | gray | 9 | 15 | -1 | 40 | weapon 3d4 · sting 2d4 drain-Str | demonic. |
| ice devil | white | 11 | 6 | -4 | 55 | claw 1d4 ×2 · bite 2d4 · sting 3d4 cold · touch 1d1 slow | sees-invis, demonic. |
| nalfeshnee | red | 11 | 9 | -1 | 65 | claw 1d4 ×2 · bite 2d4 · cast spell | demonic. |
| pit fiend | red | 13 | 6 | -3 | 65 | weapon 4d2 ×2 · hug 2d4 | sees-invis, demonic. |
| sandestin | gray | 13 | 12 | 4 | 60 | weapon 2d6 ×2 | shapeshifter, ston-res. |
| balrog | red | 16 | 5 | -2 | 75 | weapon 8d4 · weapon 4d6 | flies, sees-invis, demonic. |
| Juiblex | bright-green | 50 | 3 | -7 | 65 | engulf 4d10 disease · spit 3d6 acid | flies, amphibious, amorphous, sees-invis, demonic, fire-res, pois-res, acid-res, ston-res. |
| Yeenoghu | magenta | 56 | 18 | -5 | 80 | weapon 3d6 · weapon 2d8 confuse · claw 1d6 paralyse · cast 2d6 magic | flies, sees-invis, demonic, fire-res, pois-res. |
| Orcus | magenta | 66 | 9 | -6 | 85 | weapon 3d6 · claw 3d4 ×2 · cast 8d6 spell · sting 2d4 drain-Str | flies, sees-invis, demonic, fire-res, pois-res. |
| Geryon | magenta | 72 | 3 | -3 | 75 | claw 3d6 ×2 · sting 2d4 drain-Str | flies, sees-invis, demonic, fire-res, pois-res. |
| Dispater | magenta | 78 | 15 | -2 | 80 | weapon 4d6 · cast 6d6 spell | flies, sees-invis, demonic, fire-res, pois-res. |
| Baalzebub | magenta | 89 | 9 | -5 | 85 | bite 2d6 drain-Str · gaze 2d6 stun | flies, sees-invis, demonic, fire-res, pois-res. |
| Asmodeus | magenta | 105 | 12 | -7 | 90 | claw 4d4 · cast 6d6 cold | flies, sees-invis, demonic, fire-res, cold-res, pois-res. |
| Demogorgon | magenta | 106 | 15 | -8 | 95 | cast 8d6 spell · sting 1d4 drain-XL · claw 1d6 disease ×2 | flies, sees-invis, demonic, fire-res, pois-res. |
| Death | bright-magenta | 30 | 12 | -5 | 100 | touch 8d8 death ×2 | flies, regenerates, sees-invis, teleport-control. Rider of the Apocalypse. Vanquish three to ascend. |
| Pestilence | bright-magenta | 30 | 12 | -5 | 100 | touch 8d8 pestilence ×2 | flies, regenerates, sees-invis, teleport-control. Rider; spreads disease. |
| Famine | bright-magenta | 30 | 12 | -5 | 100 | touch 8d8 famine ×2 | flies, regenerates, sees-invis, teleport-control. Rider; drains nutrition to starvation. |
| mail daemon | bright-blue | 56 | 24 | 10 | 127 | — | flies, swims, sees-invis, starts peaceful, fire-res, cold-res, sleep-res, shock-res, pois-res, ston-res. Appears only to deliver in-game mail, then leaves. |
| djinni | yellow | 7 | 12 | 4 | 30 | weapon 2d8 | flies, pois-res, ston-res. |
| Minion of Huhetotl | orange | 16 | 12 | -2 | 75 | weapon 8d4 · weapon 4d6 · cast spell · claw 2d6 steal-amulet | flies, sees-invis, demonic. |
| Nalzok | orange | 16 | 12 | -2 | 85 | weapon 8d4 · weapon 4d6 · cast spell · claw 2d6 steal-amulet | flies, sees-invis, demonic. |

#### Golems `'` {#golems}

Iron, stone, and clay golems are dangerous; wood and leather golems are early-game fodder. A rare gold golem is a walking treasure pile.

All golems are mindless, sleep-resistant, and poison-resistant.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| straw golem | yellow | 3 | 12 | 10 | 0 | claw 1d2 ×2 | cold-res. |
| paper golem | white | 3 | 12 | 10 | 0 | claw 1d3 | cold-res. |
| rope golem | brown | 4 | 9 | 8 | 0 | claw 1d4 ×2 · hug 6d1 |  |
| gold golem | yellow | 5 | 9 | 6 | 0 | claw 2d3 ×2 | acid-res. |
| leather golem | brown | 6 | 6 | 6 | 0 | claw 1d6 ×2 |  |
| wood golem | brown | 7 | 3 | 4 | 0 | claw 3d4 | cold-res. |
| flesh golem | red | 9 | 8 | 9 | 30 | claw 2d8 ×2 | fire-res, cold-res, shock-res. |
| clay golem | brown | 11 | 7 | 7 | 40 | claw 3d10 |  |
| stone golem | gray | 14 | 6 | 5 | 50 | claw 3d8 | ston-res. |
| glass golem | cyan | 16 | 6 | 1 | 50 | claw 2d8 ×2 | acid-res. |
| iron golem | cyan | 18 | 6 | 3 | 60 | weapon 4d10 · breath 4d6 poison | no corpse. fire-res, cold-res, shock-res. |

#### Sea monsters `;` {#sea-monsters}

Live in water. Eels and the kraken wrap you and drag you under to drown: instadeath without magical breathing. Stay off the water-adjacent square unless you have it.

All sea monsters swim and are amphibious.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| jellyfish | blue | 3 | 3 | 6 | 0 | sting 3d3 drain-Str | poisonous-corpse, pois-res. |
| piranha | red | 5 | 18 | 4 | 0 | bite 2d6 ×2 |  |
| shark | gray | 7 | 12 | 2 | 0 | bite 5d6 |  |
| giant eel | cyan | 5 | 9 | -1 | 0 | bite 3d6 · touch wrap |  |
| electric eel | bright-blue | 7 | 10 | -3 | 0 | bite 4d6 shock · touch wrap | shock-res. |
| kraken | red | 20 | 3 | 6 | 0 | claw 2d4 ×2 · hug 2d6 wrap · bite 5d4 |  |

#### Lizards `:` {#lizards}

Mostly harmless. **Lizard corpses cure petrification and never rot.** Carry one for cockatrices. Medusa's gaze kills at once, so a lizard corpse cannot save you from it.

| Name | Color | Lvl | Spd | AC | MR | Attacks | Notes |
|----------------|-------|-----|-----|----|-----| -------------------------------------------- |--------------------------------------------------------|
| newt | yellow | 0 | 6 | 8 | 0 | bite 1d2 | swims, amphibious. |
| gecko | green | 1 | 6 | 8 | 0 | bite 1d3 |  |
| iguana | brown | 2 | 6 | 7 | 0 | bite 1d4 |  |
| baby crocodile | brown | 3 | 6 | 7 | 0 | bite 1d4 | swims, amphibious. |
| lizard | green | 5 | 6 | 6 | 10 | bite 1d6 | ston-res. |
| chameleon | brown | 6 | 5 | 6 | 10 | bite 4d2 | shapeshifter. |
| crocodile | brown | 6 | 9 | 5 | 0 | bite 4d2 · claw 1d12 | swims, amphibious. |
| salamander | orange | 8 | 12 | -1 | 0 | weapon 2d8 · touch 1d6 fire · hug 2d6 · hug 3d6 fire | poisonous-corpse, follows stairs, fire-res, sleep-res. |

---

### Intrinsic and Extrinsic Tables {#intrinsic-and-extrinsic-tables}

NetHack tracks 68 properties on the player. The ones you actively want to attain fall into five families: damage resistances, senses and perception, movement and spatial behavior, combat and defense, and special utility. The tables below list each property, what it does, and every reliable source — broken into **intrinsic** (gained from corpses, role progression, race, or prayer) and **extrinsic** (granted by an item you carry, wear, or wield).

Before the tables, four patterns are useful:

- **Corpse odds usually rise with the monster's level.** A floating eye always grants telepathy; acid and stoning resistance use more generous rolls than the standard resistance check. Those useful exceptions are called out below.
- **Intrinsic + extrinsic don't stack.** A property from two sources is no stronger than the same property from one. But having both is **redundancy**: take the cloak off and the intrinsic still protects you.
- **The Monk has the broadest resistance ladder of any role.** Eleven intrinsics gained across levels 1–17, more than any other role.
- **Dragon scale mail covers more of these properties than any other item.** Each color maps to one base resistance; several also grant a *secondary* effect on top (black gives disintegration *and* drain res, blue gives shock *and* fast, etc.). See the table for the full mapping.

#### Damage resistances {#damage-resistances}

The widest, most-used family. Most are gettable from corpses early. Magic resistance has the fewest sources, so most ascension kits reserve an armor, weapon, or artifact slot for it.

| Property | What it does | Intrinsic sources | Extrinsic sources |
|---|---|---|---|
| **Fire resistance** | Negates fire damage from traps, breath, and attacks (you can still drown in lava). | Monk XL 11; Priest XL 20; red dragon, fire ant, fire giant, hell hound, salamander, or red mold corpses; prayer rescue from lava. | Ring of fire resistance; red dragon scales / scale mail. |
| **Cold resistance** | Negates cold damage from breath and attacks. | Valkyrie XL 1; Monk XL 13; white dragon, frost giant, winter wolf, brown mold, or blue jelly corpses. | Ring of cold resistance; white dragon scales / scale mail. |
| **Sleep resistance** | Immune to sleep gas, sleep rays, monster sleep attacks. | Monk XL 1; Elf XL 4; any elf or homunculus corpse; prayer-rescue. | Orange dragon scales / scale mail. |
| **Disintegration resistance** | Makes black dragon breath harmless. | Black dragon corpse. | Black dragon scales / scale mail. |
| **Shock resistance** | Negates electrical damage, including lightning breath. | Monk XL 15; blue dragon or electric eel corpses. | Ring of shock resistance; blue dragon scales / scale mail; shield of shock resistance (new in 5.0). |
| **Poison resistance** | Protects against poison stings, poisonous corpses, poison breath, and Strength-draining poison attacks. | Barbarian XL 1, Healer XL 1, Orc XL 1, Tourist XL 20, Monk XL 3; killer bee and scorpion corpses use unusually favorable odds; green dragon, naga, quasit, and other poisonous corpses. | Ring of poison resistance; amulet versus poison; alchemy smock (cloak); green dragon scales / scale mail. |
| **Acid resistance** | Negates acid damage. Corpse-granted resistance is timed and resets on a level change. | Acid blob, brown pudding, yellow dragon corpses (unusually favorable odds; timed). | Yellow dragon scales / scale mail (permanent while worn). |
| **Stoning resistance** | Immunity to petrification. Corpse-granted resistance is timed; yellow dragon armor lasts while worn. | Acid blob and lizard corpses (favorable odds; timed). | Yellow dragon scales / scale mail. |
| **Drain resistance** | Blocks level drain from wraiths, vampires, and drain-life weapons such as [Stormbringer](#stormbringer). | None from corpses; vampire / lich polyforms confer it. | Black dragon scales / scale mail; shield of drain resistance (new in 5.0); wielding [Excalibur](#excalibur-artifact), Stormbringer, or [Staff of Aesculapius](#staff-of-aesculapius). |
| **Sickness resistance** | Blocks deadly disease, food poisoning. | None from corpses. | Green dragon scales / scale mail. |
| **Magic resistance** | Blocks death rays, magic missile, polymorph beams, and the touch-of-death spell. Magic traps do not check it. *Not* the same as [MC](#magic-cancellation). | No role grants it intrinsically; some polyforms have it. | Cloak of magic resistance; gray dragon scales / scale mail; wielding [Magicbane](#magicbane). |
| **Hallucination resistance** | Blocks hallucination from black lights and hallucinogenic potions. | Polyform-only, from a form with a hallucination attack such as a black light. | Gold dragon scales / scale mail; wielding [Grayswandir](#grayswandir). |
| **Blindness resistance** | Blocks light-flash blindness from yellow lights. | Polyform-only, from a form whose attack blinds. | Wielding [Sunsword](#sunsword). |

#### Senses and perception {#senses-and-perception}

Telepathy and warning show you monsters before they reach you.

| Property | What it does | Intrinsic sources | Extrinsic sources |
|---|---|---|---|
| **Telepathy** (ESP) | Senses minded monsters anywhere on the level when you are blind (and within a limited radius while sighted). | Floating eye (always grants), mind flayer, master mind flayer corpses. | Amulet of ESP; helm of telepathy; [Eye of the Aethiopica](#eye-of-the-aethiopica) (carried); [Orb of Detection](#orb-of-detection) (carried); [Platinum Yendorian Express Card](#platinum-yendorian-express-card) (carried); [Longbow of Diana](#longbow-of-diana) (carried); [Magicbane](#magicbane) (wielded). |
| **See invisible** | See invisible creatures and yourself when invisible. | Monk XL 1; Ranger XL 15. No corpse path. | Ring of see invisible. |
| **Warning** | Marks any hostile monster of level 4 or higher within about ten squares; the digit is its level divided by four. | Cave Dweller XL 15; Healer XL 15; Monk XL 7; Priest XL 15; Wizard XL 15; prayer rescue. | Ring of warning; helm of caution; [Master Key of Thievery](#master-key-of-thievery), [Orb of Fate](#orb-of-fate), [Orcrist](#bane-weapons), [Sting](#bane-weapons), [Grimtooth](#bane-weapons) (all carried). |
| **Warning of specific class** | The same indicator, restricted to one monster type. | None as intrinsic. | Orcrist / Sting (warn of orcs); Grimtooth (warns of elves); other class-specific artifacts. |
| **Searching** | Performs an automatic search roughly once every 85 turns, revealing nearby hidden doors, passages, and traps. | Archeologist XL 1; Monk XL 9; Ranger XL 1; Rogue XL 10; Tourist XL 10. | Ring of searching; carrying [Excalibur](#excalibur-artifact). |
| **Clairvoyance** | Periodic magical-eye view of the surrounding dungeon. | None as intrinsic. | Cornuthaum (Wizards only). |
| **Infravision** | See heat signatures in the dark. | Dwarf, Elf, Gnome, Orc races at XL 1. | Red dragon scales / scale mail. |

#### Movement and spatial behavior {#movement-and-spatial-behavior}

| Property | What it does | Intrinsic sources | Extrinsic sources |
|---|---|---|---|
| **[Fast](#speed)** (intrinsic speed) | Each movement allocation has a ~1/3 chance of a +12 bonus. Raises effective speed from 12 to about 16. | Monk XL 1; Samurai XL 1; Valkyrie XL 7; Archeologist XL 10; Barbarian XL 7; Cave Dweller XL 7; Knight XL 7. Prayer rescue. | Speed boots (grant **Very Fast**, ~2/3 chance, effective ~20); blue dragon scales / scale mail (Very Fast). |
| **Jumping** | The `#jump` extended command — short controlled hop. | Knight XL 1. | Jumping boots; spell of jumping. |
| **Teleport** (uncontrolled) | Random teleport every few hundred turns. Useful when paired with control. | Tengu corpse. | Ring of teleportation. |
| **Teleport control** | Lets you choose your destination when you teleport. | Monk XL 17; Wizard XL 17; tengu corpse. | Ring of teleport control; carrying [Master Key of Thievery](#master-key-of-thievery). (Carrying the Amulet of Yendor *blocks* controlled teleport.) |
| **Levitation** | Constantly floating. Crosses water, lava, ice; can't descend stairs; can't pick up items. | None. | Ring of levitation; levitation boots (cursed = stuck on); carrying the [Heart of Ahriman](#heart-of-ahriman). |
| **Flying** | Like levitation but you can descend, pick up, and land voluntarily. | Polyform into a flying monster. | Amulet of flying. |
| **Water walking** | Cross water and ice as if it were floor. Plain water-walking boots are leather and burn off in lava, but fireproofed boots cross lava too (and unharmed if you also resist fire). | Polyform into the right form (some undead). | Water-walking boots. |
| **Magical breathing** | Don't drown when grabbed by an eel or kraken; survive a stinking cloud. | None as intrinsic. | Amulet of magical breathing. |

#### Combat and defense {#combat-and-defense}

Layered defenses for the ascension kit: AC, reflection, free action, regen.

| Property | What it does | Intrinsic sources | Extrinsic sources |
|---|---|---|---|
| **Protection** | Adds to your AC (lower is better). Also adds +1 [MC](#magic-cancellation) per worn extrinsic source (+2 for amulet of guarding). | A qualifying large donation to any peaceful priest; the required amount is randomized. | Ring of protection; cloak of protection (also MC3); amulet of guarding (also MC2); carrying [Sceptre of Might](#sceptre-of-might), [Mitre of Holiness](#mitre-of-holiness), or [Tsurugi of Muramasa](#tsurugi-of-muramasa). |
| **Reflection** | Bounces ranged magic (rays, breath) back at the attacker. | None as intrinsic. | Amulet of reflection; silver dragon scales / scale mail; shield of reflection; wielding [Dragonbane](#bane-weapons) or [Longbow of Diana](#longbow-of-diana). |
| **Regeneration** | Heals 1 HP every turn, in addition to natural healing. | Troll and other regenerating polyforms. | Ring of regeneration; wielding [Trollsbane](#bane-weapons) or [Staff of Aesculapius](#staff-of-aesculapius). |
| **Energy regeneration** | Spell points regenerate faster. | None as intrinsic. | Carrying [Eye of the Aethiopica](#eye-of-the-aethiopica). |
| **Half spell damage** | Halves damage from monster-cast spells. | None as intrinsic. | Carrying [Orb of Detection](#orb-of-detection), [Master Key of Thievery](#master-key-of-thievery), [Platinum Yendorian Express Card](#platinum-yendorian-express-card), or [Orb of Fate](#orb-of-fate). |
| **Half physical damage** | Halves damage from melee and physical ranged attacks. | None as intrinsic. | Carrying Master Key of Thievery or Orb of Fate. |
| **Free action** | Blocks paralysis from floating eyes, gelatinous cubes, ghouls, and monster-cast paralysis. It does not stop slowing. | Certain polyforms. | Ring of free action; orange dragon scales / scale mail. |
| **Stealth** | Monsters don't wake when you walk near sleeping ones; you can sneak past. | Archeologist XL 5; Barbarian XL 15; Monk XL 5; Ranger XL 7; Rogue XL 1; Samurai XL 15; Valkyrie XL 3; prayer rescue. | Ring of stealth; elven boots; elven cloak; carrying [Heart of Ahriman](#heart-of-ahriman). |
| **Invisibility** | Monsters without see invisible guess your square, so their attacks are less reliable; attacking reveals your position. | Stalker polyform; potion of invisibility (timed). | Ring of invisibility; cloak of invisibility; carrying Orb of Detection. |
| **Displacement** | Monsters see you in a wrong nearby square; ranged attacks miss often. | None as intrinsic. | Cloak of displacement. |

#### Special and utility {#special-and-utility}

These properties change hunger, polymorph, survival, and crowd control.

| Property | What it does | Intrinsic sources | Extrinsic sources |
|---|---|---|---|
| **Slow digestion** | Stops ordinary hunger entirely; unusual direct nutrition drains can still starve you. | None. | Ring of slow digestion; white dragon scales / scale mail. |
| **Polymorph control** | When you polymorph (from a trap, ring, potion, wand, or spell), you choose the form. | None. | Ring of polymorph control. |
| **Unchanging** | Locks your current form. Blocks polymorph (any source) and *also blocks the green-slime countdown*. The standard answer to "I just got slimed." | None. | Amulet of unchanging. |
| **Sustain ability** | Your six stats (Str, Dex, Con, Int, Wis, Cha) do not change through exercise, abuse, potions, or attribute-draining attacks such as poison. | None. | Ring of sustain ability. |
| **Protection from shape changers** | Nearby shape-changers (chameleon, doppelganger, amorous demon) cannot polymorph. | None. | Ring of protection from shape changers. |
| **Conflict** | Nearby monsters attack one another. A shopkeeper caught in it attacks you. | None. | Ring of conflict; carrying [Sceptre of Might](#sceptre-of-might). |
| **Life saving** | When you would die, the amulet is destroyed and restores `50 + 10 × (Con ÷ 2)` HP, capped at your maximum. | None. | Amulet of life saving. |
| **Adornment** | Adds the ring's enchantment to Charisma. Most useful for shopping and seduction. | None. | Ring of adornment. |

A few properties are essentially **polyform-only**: *swimming* and *passes walls* (xorn, earth elemental, ghost). *Detect monsters* is otherwise available only as a one-shot pulse from a wand or scroll.

---

### What Changed Since Last Time {#what-changed-since-last-time}

NetHack 5.0.0 was released on May 2, 2026. If you remember 3.6.x, start with the first group below: these are the changes most likely to punish an old reflex.

#### Habits to Relearn {#new-dangers}

- **Unicorn horns no longer restore drained attributes.** Carry a potion of restore ability for that job.
- **A self-zapped wand of speed monster no longer grants permanent speed.** Potions of speed do.
- **Diluted alchemy products convert only two potions per dip.** A fresh stack may still convert as a batch. The ordinary blast chance is 10%; an alchemy smock lowers it to about 1 in 30.
- **Gehennom's hot ground usually shatters a potion you drop.** It also blocks within-level teleportation while a demon lord or prince is alive on the level.
- **Monsters loot unlocked containers and can animate suitable corpse piles.** Lock a stash before leaving it.
- **Cursed wands can explode during an engrave-test.** Identify BUC before testing a valuable-looking wand when you can.
- **Weak sacrifices no longer grind Luck.** If your Luck is already above the corpse's difficulty, the sacrifice adds none; a luckstone handles maintenance.
- **Valkyries start with a spear, not a long sword.** Knights still have a 1-in-6 Excalibur dip at XL 5 or higher; every other Lawful role gets 1 in 30.
- **The touch-of-death spell no longer uses the old instant-death result.** Without magic resistance it deals 50+8d6 damage and drains half that amount from maximum HP; magic resistance still blocks it completely.

#### New Tools and Opportunities {#new-tools-and-opportunities}

- **Dragon armor carries more secondary effects.** Black adds drain resistance, green adds sickness resistance, blue adds speed, orange adds free action, white adds slow digestion, red adds infravision, and gold adds hallucination resistance and radius-3 light.
- **The helm of caution** grants warning. The **amulet of flying** grants flight to you and your steed, and the **amulet of guarding** supplies +2 AC and +2 MC.
- **Several artifacts gained active uses.** Snickersnee adds one free polearm-style reach attack each turn. Sunsword spends 25 Pw to blind a target. Trollsbane regenerates while wielded. Demonbane is now the Priest's guaranteed first gift and takes the form of a silver mace.
- **There are new wish sources.** Vlad's throne eventually grants one, the Amulet grants one when first picked up, and Orcus Town guarantees either a magic lamp or a magic marker.
- **A blessed potion of polymorph grants control for that one change.** A polymorphed vampire can use `#monster` to cycle among vampire, bat, and fog-cloud forms.
- **Loadstones prevent knockback while you are grounded, even when cursed.** The burden is still severe, but the property now has a use.
- **Supply chests** appear on levels above the Oracle about two times in three, holding early healing, enchantment, and other supplies.
- **Pets can gain corpse resistances.** A dead pet can also be revived by praying at a co-aligned altar while standing on its corpse.
- **Sink-dipping a potion identifies it by message.** The potion is consumed, but no identify scroll is needed.
- **Chain lightning** is a new level-2 attack spell that jumps through nearby monsters. New **themed rooms** populate ordinary levels, and four new species appear: displacer beast, genetic engineer, gold dragon, and baby gold dragon.

#### Other Changes Worth Knowing {#other-changes-worth-knowing}

- *Charm monster* is now level 5, *sleep* level 3, and *confuse monster* level 1. Apply a spellbook to check how worn it is.
- Mind-flayer tentacles no longer erase the map or identifications. They still drain Intelligence and can erase memorized spells and weapon-skill experience.
- A bag-of-holding explosion scatters its contents instead of deleting everything; about one item in thirteen is still lost.
- Priest donation prices are randomized. For protection, offer at least twice but less than three times the amount named. More earns only thanks, while conspicuous underpayment can raise that priest's future prices.
- Special levels can be mirrored, so a memorized map may appear flipped. New conducts track pauper, petless, permadeaf, Sokoban, bonesless, and unrerolled games.
- Two-handed weapons receive 150% of the Strength damage bonus. Natural HP regeneration now rolls `(XL + Constitution)%` each turn, while the regeneration property heals 1 HP every turn in addition.
- Covetous monsters may flee to either staircase. The Castle no longer places master or arch-liches at level creation.
- Crystal plate mail cracks in stages and can be made crackproof. Candle radius now grows by a square-root rule rather than linearly.
- Intrinsic-granting corpses, tins, and eggs cost more in shops. Monsters no longer produce unrelated food as random death drops.
- Shopkeepers remove nearby pits and webs, and walking into a peaceful shopkeeper automatically settles debt before the inventory prompt.

---

*You descend the stairs...*

---

### Acknowledgements {#acknowledgements}

NetHack has been played, cursed at, loved, and documented since
1987. The game itself is the work of the NetHack DevTeam, a loose collective of developers who have maintained one of the longest-running open source projects in existence. But the documentation, the strategy, the collected wisdom about how to actually survive the thing, that came from the players.

In the early days, knowledge spread through Usenet, on the newsgroup **RGRN** (more formally, rec.games.roguelike.nethack). Thousands of players posted questions, argued about strategy, and slowly assembled a shared body of knowledge about a game that refused to explain itself. That was before wikis, before Reddit, before Discord. If you wanted to know whether a cockatrice corpse could be wielded as a weapon, you searched the RGRN archives and hoped someone had asked before you. Someone usually had.

RGRN gave the community its vocabulary. A **YASD** (*Yet Another Stupid Death*) is the post you make after dying to something you should have known better than to do. A **YAFAP** (*Yet Another First Ascension Post*) is the post you make when you finally win. Both traditions persist today, in the wiki, on Reddit, in Discord.

Out of those conversations came the first spoiler files: plain-text catalogs of every item, every monster, every interaction. Written by hand, cross-referenced against the source code, and shared freely.

That guide stands on their work. Specifically:

**Kevin Hugo** compiled the first comprehensive spoiler set for NetHack 3.2.2, covering every item class, monster stat, spell formula, and score calculation in methodical detail. **Dylan O'Donnell** updated the entire set for 3.4.3, correcting, expanding, and maintaining the files over several years. Together, the Hugo/O'Donnell spoilers became the definitive reference: 38 files covering potions, scrolls, wands, rings, amulets, tools, weapons, armor, artifacts, food, monsters, spells, and more. The item data tables throughout Parts Four and Five of this guide are verified against their work. Published under BSD-like terms.

**Paul Waterman** wrote the WCST NetHack Spoilers (at Wheaton College in 1991), a single sprawling document that covered the entire game in a conversational, opinionated voice. Where Hugo and O'Donnell wrote reference manuals, the WCST was a travel guide. It told you not just what things did but what to do about them. It was the original inspiration for the tone and structure of that guide, though no text has been copied from it.

**Kate Nepveu** maintained steelypips.org, the web archive that preserved the Hugo/O'Donnell spoilers, the RGRN community articles, and her own excellent guides (including the Elbereth FAQ cited in our traps chapter). Without Kate's patient archival work, much of that material might have disappeared when Usenet faded.

The following **RGRN community authors** contributed articles, FAQs, and guides that informed specific sections of this guide:

**David Damerell** wrote the Object Identification FAQ. **Kieron Dunbar** wrote the wand identification guide. **Trevor Powell** compiled the Instadeath Spoiler. **Arien Malec** wrote the Medusa guide. **Matthew Lahut** wrote the prayer guide. **Boudewijn Waijers** mapped all eight [Sokoban](#sokoban) variants. **Steven Bush** calculated spellbook reading success rates. **Gregory Bond** documented shopkeeper pricing formulas. **Dion Nicolaas** cataloged the conducts. **David Goldfarb** wrote the air elemental FAQ. **Hojita Discordia** documented XP value calculations.

And many others: Ray Chason, Pat Rankin, Geoduck, Topi Linkala, Geoffrey Eadon, Roger Broadbent, Sebastian Haas, Jukka Lahtinen, and the countless anonymous posters on the newsgroup who asked "has anyone tried..." and then reported back.

**The [NetHack Wiki](https://nethackwiki.com/)** has been an indispensable reference for this guide. Founded as "WikiHack" by Sgeo in 2005, it migrated to its own domain in 2010 and now contains over five thousand articles documenting every corner of the game. Its creators and maintainers include Pasi Kallinen, Drew Streib, Alex Smith, Shawn Moore, George Koehler, Tjr, ZeroOne, and Ray Chason. The wiki's [NetHack 5.0.0 page](https://nethackwiki.com/wiki/NetHack_5.0.0) is the community's living changelog and was a major reference for the 5.0 update of this guide.

**The public servers** where most NetHack is played today are [nethack.alt.org](https://alt.org/nethack/) (the longest-running public NetHack server, run by M. Drew Streib and Pasi Kallinen) and [Hardfought](https://hardfought.org/) (run by K2, which also hosts the major variants). Both are free to play and log every ascension; the cause-of-death and ascension statistics cited throughout this guide come from their public records (see NAO's [top types of deaths](https://alt.org/nethack/topdeaths.html)).

**The [r/nethack](https://www.reddit.com/r/nethack/) community** on Reddit has kept NetHack discussion alive for a new generation of players. Its moderators over the years have maintained a welcoming space where veterans and newcomers trade advice, share ascension stories, and argue about optimal wish choices. The community's collective knowledge, passed along in thousands of threads, has informed the practical advice throughout this guide.

Above all, this guide exists because the game itself exists. **[NetHack](https://www.nethack.org/)** has been developed since 1987 by the NetHack DevTeam, founded by Mike Stephenson, Izchak Miller, and Janet Walz. Izchak Miller passed away in 1994; the shopkeeper who bears his name in [the Mines](#the-gnomish-mines) is a small measure of how much his work meant. The source lives at [github.com/NetHack](https://github.com/NetHack/NetHack).

The game itself descends from earlier roguelikes. **Hack** was written by Jay Fenlason in 1982 as a class project at Lincoln-Sudbury Regional High School, drawing on Toy and Wichman's *Rogue* (1980), and extended by Andries Brouwer through the mid-1980s. NetHack forked from Brouwer's Hack in 1987. Many of the most distinctive NetHack monsters, including the **grid bug**, the orthogonal-only critter whose name puns on both "insect" and "software bug" living on a character-cell grid (with a likely nod to the bugs in the 1982 film *Tron*), are inherited from Fenlason's original Hack. The dungeon is older than the game.

The development was not always continuous. After version 3.4.3 in December 2003, the DevTeam went quiet for twelve years: silent to the public, working in private. The running community joke during the gap was *The DevTeam is THINKING.* The dungeon was frozen. New players descended into the same unchanging corridors that had been killing people since 2003, writing new spoilers about a fixed game, dying in the same newly-documented ways. The accumulated community wisdom from those twelve silent years remained useful, and the game was deep enough to sustain a decade of fresh analysis without a single new line of code. Version 3.6 arrived in December 2015, and active development has continued since.

The current team, including Michael Allison, Ken Arromdee, David Cohrs, Jessie Collet, Kevin Hugo, Pasi Kallinen, Ken Lorber, Dean Luick, Patric Mueller, Pat Rankin, Derek S. Ray, Alex Smith, Mike Stephenson, Janet Walz, Paul Winner, Bart House, and Warwick Allison, has maintained and extended the game across nearly four decades. Everything in these pages is downstream of their work.

All data in this guide has been verified against the current game source code. Any errors are ours alone.

---

*A Traveler's Companion to the Mazes of Menace 5.0 Launch Edition,*<br> *compiled by David Bau, using Claude 4.8 Opus to collate and check facts.*

*This work is licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).*
