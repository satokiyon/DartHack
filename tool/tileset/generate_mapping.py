# -*- coding: utf-8 -*-
"""
NetHack 5.0 タイルと DawnLike 素材のマッピングテーブルを構築するジェネレータ
"""
import json
import os
import re

# モンスターシンボルクラスと DawnLike シート・行の対応定義
# 各モンスター種別ごとの (シート名, col, row) マッピング辞書
MONSTER_MAP = {
    # Ant / Bee (Pest0.png)
    "giant ant": ("Characters/Pest0.png", 0, 0),
    "killer bee": ("Characters/Pest0.png", 1, 0),
    "soldier ant": ("Characters/Pest0.png", 2, 0),
    "fire ant": ("Characters/Pest0.png", 3, 0),
    "giant beetle": ("Characters/Pest0.png", 4, 0),
    "queen bee": ("Characters/Pest0.png", 5, 0),
    
    # Blob (Slime0.png)
    "acid blob": ("Characters/Slime0.png", 0, 0),
    "quivering blob": ("Characters/Slime0.png", 1, 0),
    "gelatinous cube": ("Characters/Slime0.png", 2, 0),
    
    # Cockatrice / Avian (Avian0.png)
    "chickatrice": ("Characters/Avian0.png", 0, 0),
    "cockatrice": ("Characters/Avian0.png", 1, 0),
    "pyrolisk": ("Characters/Avian0.png", 2, 0),
    
    # Dog / Canine (Dog0.png)
    "jackal": ("Characters/Dog0.png", 0, 0),
    "fox": ("Characters/Dog0.png", 1, 0),
    "coyote": ("Characters/Dog0.png", 2, 0),
    "werejackal": ("Characters/Dog0.png", 3, 0),
    "little dog": ("Characters/Dog0.png", 4, 0),
    "dingo": ("Characters/Dog0.png", 5, 0),
    "dog": ("Characters/Dog0.png", 0, 1),
    "large dog": ("Characters/Dog0.png", 1, 1),
    "wolf": ("Characters/Dog0.png", 2, 1),
    "werewolf": ("Characters/Dog0.png", 3, 1),
    "winter wolf cub": ("Characters/Dog0.png", 4, 1),
    "warg": ("Characters/Dog0.png", 0, 2),
    "winter wolf": ("Characters/Dog0.png", 1, 2),
    "hell hound pup": ("Characters/Dog0.png", 0, 5),
    "hell hound": ("Characters/Dog0.png", 1, 5),
    "Cerberus": ("Characters/Dog0.png", 2, 5),
    
    # Eye / Sphere (Misc0.png, Elemental0.png)
    "gas spore": ("Characters/Misc0.png", 0, 0),
    "floating eye": ("Characters/Misc0.png", 1, 0),
    "freezing sphere": ("Characters/Elemental0.png", 0, 5),
    "flaming sphere": ("Characters/Elemental0.png", 1, 5),
    "shocking sphere": ("Characters/Elemental0.png", 2, 5),
    "beholder": ("Characters/Misc0.png", 2, 0),
    
    # Feline / Cat (Cat0.png)
    "kitten": ("Characters/Cat0.png", 0, 0),
    "housecat": ("Characters/Cat0.png", 1, 0),
    "jaguar": ("Characters/Cat0.png", 2, 0),
    "lynx": ("Characters/Cat0.png", 3, 0),
    "panther": ("Characters/Cat0.png", 0, 1),
    "large cat": ("Characters/Cat0.png", 1, 1),
    "tiger": ("Characters/Cat0.png", 2, 1),
    
    # Gremlin / Gargoyle (Demon0.png)
    "gremlin": ("Characters/Demon0.png", 0, 0),
    "gargoyle": ("Characters/Demon0.png", 1, 0),
    "winged gargoyle": ("Characters/Demon0.png", 2, 0),
    
    # Humanoid (Humanoid0.png)
    "hobbit": ("Characters/Humanoid0.png", 0, 0),
    "dwarf": ("Characters/Humanoid0.png", 1, 0),
    "bugbear": ("Characters/Humanoid0.png", 2, 0),
    "dwarf lord": ("Characters/Humanoid0.png", 3, 0),
    "dwarf king": ("Characters/Humanoid0.png", 4, 0),
    "mind flayer": ("Characters/Humanoid0.png", 5, 0),
    "master mind flayer": ("Characters/Humanoid0.png", 6, 0),
    
    # Imp / Minor Demon (Demon0.png)
    "manes": ("Characters/Demon0.png", 0, 1),
    "homunculus": ("Characters/Demon0.png", 1, 1),
    "imp": ("Characters/Demon0.png", 2, 1),
    "lemure": ("Characters/Demon0.png", 3, 1),
    "quasit": ("Characters/Demon0.png", 4, 1),
    "tengu": ("Characters/Demon0.png", 5, 1),
    
    # Jelly (Slime0.png)
    "blue jelly": ("Characters/Slime0.png", 3, 0),
    "spotted jelly": ("Characters/Slime0.png", 4, 0),
    "ochre jelly": ("Characters/Slime0.png", 0, 1),
    
    # Kobold (Humanoid0.png)
    "kobold": ("Characters/Humanoid0.png", 0, 1),
    "large kobold": ("Characters/Humanoid0.png", 1, 1),
    "kobold lord": ("Characters/Humanoid0.png", 2, 1),
    "kobold shaman": ("Characters/Humanoid0.png", 3, 1),
    
    # Leprechaun (Humanoid0.png)
    "leprechaun": ("Characters/Humanoid0.png", 4, 1),
    
    # Mimic (Misc0.png)
    "small mimic": ("Characters/Misc0.png", 0, 1),
    "large mimic": ("Characters/Misc0.png", 1, 1),
    "giant mimic": ("Characters/Misc0.png", 2, 1),
    
    # Nymph (Humanoid0.png)
    "wood nymph": ("Characters/Humanoid0.png", 0, 2),
    "water nymph": ("Characters/Humanoid0.png", 1, 2),
    "mountain nymph": ("Characters/Humanoid0.png", 2, 2),
    
    # Orc (Humanoid0.png)
    "goblin": ("Characters/Humanoid0.png", 0, 3),
    "hobgoblin": ("Characters/Humanoid0.png", 1, 3),
    "orc": ("Characters/Humanoid0.png", 2, 3),
    "hill orc": ("Characters/Humanoid0.png", 3, 3),
    "Mordor orc": ("Characters/Humanoid0.png", 4, 3),
    "Uruk-hai": ("Characters/Humanoid0.png", 5, 3),
    "orc shaman": ("Characters/Humanoid0.png", 6, 3),
    "orc-captain": ("Characters/Humanoid0.png", 7, 3),
    
    # Piercer (Misc0.png)
    "rock piercer": ("Characters/Misc0.png", 0, 2),
    "iron piercer": ("Characters/Misc0.png", 1, 2),
    "glass piercer": ("Characters/Misc0.png", 2, 2),
    
    # Quadruped (Quadraped0.png)
    "rothe": ("Characters/Quadraped0.png", 0, 0),
    "mumak": ("Characters/Quadraped0.png", 1, 0),
    "leocrotta": ("Characters/Quadraped0.png", 2, 0),
    "wumpus": ("Characters/Quadraped0.png", 3, 0),
    "titanothere": ("Characters/Quadraped0.png", 4, 0),
    "baluchitherium": ("Characters/Quadraped0.png", 5, 0),
    "mastodon": ("Characters/Quadraped0.png", 6, 0),
    
    # Rodent (Rodent0.png)
    "sewer rat": ("Characters/Rodent0.png", 0, 0),
    "giant rat": ("Characters/Rodent0.png", 1, 0),
    "rabid rat": ("Characters/Rodent0.png", 2, 0),
    "wererat": ("Characters/Rodent0.png", 3, 0),
    "rock mole": ("Characters/Rodent0.png", 4, 0),
    "woodchuck": ("Characters/Rodent0.png", 0, 1),
    
    # Spider (Pest0.png)
    "cave spider": ("Characters/Pest0.png", 0, 1),
    "centipede": ("Characters/Pest0.png", 1, 1),
    "giant spider": ("Characters/Pest0.png", 2, 1),
    "scorpion": ("Characters/Pest0.png", 3, 1),
    
    # Trapper (Misc0.png)
    "lurker above": ("Characters/Misc0.png", 0, 3),
    "trapper": ("Characters/Misc0.png", 1, 3),
    
    # Unicorn / Horse (Quadraped0.png)
    "pony": ("Characters/Quadraped0.png", 0, 1),
    "white unicorn": ("Characters/Quadraped0.png", 1, 1),
    "gray unicorn": ("Characters/Quadraped0.png", 2, 1),
    "black unicorn": ("Characters/Quadraped0.png", 3, 1),
    "horse": ("Characters/Quadraped0.png", 4, 1),
    "warhorse": ("Characters/Quadraped0.png", 5, 1),
    
    # Vortex (Elemental0.png)
    "fog cloud": ("Characters/Elemental0.png", 0, 0),
    "dust vortex": ("Characters/Elemental0.png", 1, 0),
    "ice vortex": ("Characters/Elemental0.png", 2, 0),
    "energy vortex": ("Characters/Elemental0.png", 3, 0),
    "steam vortex": ("Characters/Elemental0.png", 4, 0),
    "fire vortex": ("Characters/Elemental0.png", 5, 0),
    
    # Worm (Reptile0.png)
    "baby long worm": ("Characters/Reptile0.png", 0, 0),
    "baby purple worm": ("Characters/Reptile0.png", 1, 0),
    "long worm": ("Characters/Reptile0.png", 2, 0),
    "purple worm": ("Characters/Reptile0.png", 3, 0),
    
    # Xan / Grid Bug (Pest0.png)
    "grid bug": ("Characters/Pest0.png", 4, 1),
    "xan": ("Characters/Pest0.png", 5, 1),
    
    # Light (Elemental0.png)
    "yellow light": ("Characters/Elemental0.png", 0, 1),
    "black light": ("Characters/Elemental0.png", 1, 1),
    
    # Zruty (Quadraped0.png)
    "zruty": ("Characters/Quadraped0.png", 0, 2),
    
    # Angel (Humanoid0.png, Avian0.png)
    "couatl": ("Characters/Reptile0.png", 4, 0),
    "Aleax": ("Characters/Humanoid0.png", 0, 4),
    "Angel": ("Characters/Humanoid0.png", 1, 4),
    "ki-rin": ("Characters/Quadraped0.png", 1, 2),
    "Archon": ("Characters/Humanoid0.png", 2, 4),
    
    # Bat (Avian0.png)
    "bat": ("Characters/Avian0.png", 0, 1),
    "giant bat": ("Characters/Avian0.png", 1, 1),
    "raven": ("Characters/Avian0.png", 2, 1),
    "vampire bat": ("Characters/Avian0.png", 3, 1),
    
    # Centaur (Quadraped0.png)
    "plains centaur": ("Characters/Quadraped0.png", 0, 3),
    "forest centaur": ("Characters/Quadraped0.png", 1, 3),
    "mountain centaur": ("Characters/Quadraped0.png", 2, 3),
    
    # Dragons (Reptile0.png)
    "baby gray dragon": ("Characters/Reptile0.png", 0, 1),
    "baby red dragon": ("Characters/Reptile0.png", 1, 1),
    "baby white dragon": ("Characters/Reptile0.png", 2, 1),
    "baby blue dragon": ("Characters/Reptile0.png", 3, 1),
    "baby green dragon": ("Characters/Reptile0.png", 4, 1),
    "baby black dragon": ("Characters/Reptile0.png", 5, 1),
    "baby yellow dragon": ("Characters/Reptile0.png", 6, 1),
    "gray dragon": ("Characters/Reptile0.png", 0, 2),
    "red dragon": ("Characters/Reptile0.png", 1, 2),
    "white dragon": ("Characters/Reptile0.png", 2, 2),
    "blue dragon": ("Characters/Reptile0.png", 3, 2),
    "green dragon": ("Characters/Reptile0.png", 4, 2),
    "black dragon": ("Characters/Reptile0.png", 5, 2),
    "yellow dragon": ("Characters/Reptile0.png", 6, 2),
    
    # Elemental (Elemental0.png)
    "stalker": ("Characters/Elemental0.png", 0, 2),
    "air elemental": ("Characters/Elemental0.png", 1, 2),
    "fire elemental": ("Characters/Elemental0.png", 2, 2),
    "earth elemental": ("Characters/Elemental0.png", 3, 2),
    "water elemental": ("Characters/Elemental0.png", 4, 2),
    
    # Fungus / Mold (Plant0.png)
    "lichen": ("Characters/Plant0.png", 0, 0),
    "brown mold": ("Characters/Plant0.png", 1, 0),
    "yellow mold": ("Characters/Plant0.png", 2, 0),
    "green mold": ("Characters/Plant0.png", 3, 0),
    "red mold": ("Characters/Plant0.png", 4, 0),
    "shrieker": ("Characters/Plant0.png", 5, 0),
    "violet fungus": ("Characters/Plant0.png", 6, 0),
    
    # Gnome (Humanoid0.png)
    "gnome": ("Characters/Humanoid0.png", 0, 5),
    "gnome lord": ("Characters/Humanoid0.png", 1, 5),
    "gnomish wizard": ("Characters/Humanoid0.png", 2, 5),
    "gnome king": ("Characters/Humanoid0.png", 3, 5),
    
    # Giant (Humanoid0.png)
    "giant": ("Characters/Humanoid0.png", 0, 6),
    "stone giant": ("Characters/Humanoid0.png", 1, 6),
    "hill giant": ("Characters/Humanoid0.png", 2, 6),
    "fire giant": ("Characters/Humanoid0.png", 3, 6),
    "frost giant": ("Characters/Humanoid0.png", 4, 6),
    "storm giant": ("Characters/Humanoid0.png", 5, 6),
    "ettin": ("Characters/Humanoid0.png", 6, 6),
    "titan": ("Characters/Humanoid0.png", 7, 6),
    "minotaur": ("Characters/Humanoid0.png", 0, 7),
    
    # Jabberwock (Avian0.png / Reptile0.png)
    "jabberwock": ("Characters/Reptile0.png", 0, 3),
    "vorpal jabberwock": ("Characters/Reptile0.png", 1, 3),
    
    # Keystone Kops (Humanoid0.png)
    "Keystone Kop": ("Characters/Humanoid0.png", 0, 8),
    "Kop Sergeant": ("Characters/Humanoid0.png", 1, 8),
    "Kop Lieutenant": ("Characters/Humanoid0.png", 2, 8),
    "Kop Kaptain": ("Characters/Humanoid0.png", 3, 8),
    
    # Lich (Undead0.png)
    "lich": ("Characters/Undead0.png", 0, 0),
    "demilich": ("Characters/Undead0.png", 1, 0),
    "master lich": ("Characters/Undead0.png", 2, 0),
    "arch-lich": ("Characters/Undead0.png", 3, 0),
    
    # Mummy (Undead0.png)
    "kobold mummy": ("Characters/Undead0.png", 0, 1),
    "gnome mummy": ("Characters/Undead0.png", 1, 1),
    "orc mummy": ("Characters/Undead0.png", 2, 1),
    "dwarf mummy": ("Characters/Undead0.png", 3, 1),
    "elf mummy": ("Characters/Undead0.png", 4, 1),
    "human mummy": ("Characters/Undead0.png", 5, 1),
    "ettin mummy": ("Characters/Undead0.png", 6, 1),
    "giant mummy": ("Characters/Undead0.png", 7, 1),
    
    # Naga (Reptile0.png)
    "red naga hatchling": ("Characters/Reptile0.png", 0, 4),
    "black naga hatchling": ("Characters/Reptile0.png", 1, 4),
    "golden naga hatchling": ("Characters/Reptile0.png", 2, 4),
    "guardian naga hatchling": ("Characters/Reptile0.png", 3, 4),
    "red naga": ("Characters/Reptile0.png", 4, 4),
    "black naga": ("Characters/Reptile0.png", 5, 4),
    "golden naga": ("Characters/Reptile0.png", 6, 4),
    "guardian naga": ("Characters/Reptile0.png", 7, 4),
    
    # Ogre (Humanoid0.png)
    "ogre": ("Characters/Humanoid0.png", 0, 9),
    "ogre lord": ("Characters/Humanoid0.png", 1, 9),
    "ogre king": ("Characters/Humanoid0.png", 2, 9),
    
    # Pudding (Slime0.png)
    "gray ooze": ("Characters/Slime0.png", 0, 2),
    "brown pudding": ("Characters/Slime0.png", 1, 2),
    "green slime": ("Characters/Slime0.png", 2, 2),
    "black pudding": ("Characters/Slime0.png", 3, 2),
    
    # Rust monster (Quadraped0.png)
    "rust monster": ("Characters/Quadraped0.png", 0, 4),
    "disenchanter": ("Characters/Quadraped0.png", 1, 4),
    
    # Snake (Reptile0.png)
    "garter snake": ("Characters/Reptile0.png", 0, 5),
    "snake": ("Characters/Reptile0.png", 1, 5),
    "water moccasin": ("Characters/Reptile0.png", 2, 5),
    "pit viper": ("Characters/Reptile0.png", 3, 5),
    "python": ("Characters/Reptile0.png", 4, 5),
    "cobra": ("Characters/Reptile0.png", 5, 5),
    
    # Troll (Humanoid0.png)
    "troll": ("Characters/Humanoid0.png", 0, 10),
    "ice troll": ("Characters/Humanoid0.png", 1, 10),
    "rock troll": ("Characters/Humanoid0.png", 2, 10),
    "water troll": ("Characters/Humanoid0.png", 3, 10),
    "Olog-hai": ("Characters/Humanoid0.png", 4, 10),
    
    # Umber Hulk (Humanoid0.png)
    "umber hulk": ("Characters/Humanoid0.png", 5, 10),
    
    # Vampire (Undead0.png)
    "vampire": ("Characters/Undead0.png", 0, 2),
    "vampire lord": ("Characters/Undead0.png", 1, 2),
    "vampire mage": ("Characters/Undead0.png", 2, 2),
    "Vlad the Impaler": ("Characters/Undead0.png", 3, 2),
    
    # Wraith (Undead0.png)
    "barrow wight": ("Characters/Undead0.png", 0, 3),
    "wraith": ("Characters/Undead0.png", 1, 3),
    "Nazgul": ("Characters/Undead0.png", 2, 3),
    
    # Xorn (Elemental0.png)
    "xorn": ("Characters/Elemental0.png", 0, 3),
    
    # Yeti / Ape (Quadraped0.png, Humanoid0.png)
    "monkey": ("Characters/Quadraped0.png", 0, 5),
    "ape": ("Characters/Quadraped0.png", 1, 5),
    "owlbear": ("Characters/Quadraped0.png", 2, 5),
    "yeti": ("Characters/Humanoid0.png", 0, 11),
    "carnivorous ape": ("Characters/Quadraped0.png", 3, 5),
    "sasquatch": ("Characters/Humanoid0.png", 1, 11),
    
    # Zombie (Undead0.png)
    "kobold zombie": ("Characters/Undead0.png", 0, 4),
    "gnome zombie": ("Characters/Undead0.png", 1, 4),
    "orc zombie": ("Characters/Undead0.png", 2, 4),
    "dwarf zombie": ("Characters/Undead0.png", 3, 4),
    "elf zombie": ("Characters/Undead0.png", 4, 4),
    "human zombie": ("Characters/Undead0.png", 5, 4),
    "ettin zombie": ("Characters/Undead0.png", 6, 4),
    "giant zombie": ("Characters/Undead0.png", 7, 4),
    
    # Golem (Humanoid0.png, Elemental0.png)
    "straw golem": ("Characters/Humanoid0.png", 0, 12),
    "paper golem": ("Characters/Humanoid0.png", 1, 12),
    "rope golem": ("Characters/Humanoid0.png", 2, 12),
    "gold golem": ("Characters/Humanoid0.png", 3, 12),
    "leather golem": ("Characters/Humanoid0.png", 4, 12),
    "wood golem": ("Characters/Humanoid0.png", 5, 12),
    "flesh golem": ("Characters/Humanoid0.png", 6, 12),
    "clay golem": ("Characters/Humanoid0.png", 7, 12),
    "stone golem": ("Characters/Humanoid0.png", 0, 13),
    "glass golem": ("Characters/Humanoid0.png", 1, 13),
    "iron golem": ("Characters/Humanoid0.png", 2, 13),
    
    # Ghost (Undead0.png)
    "ghost": ("Characters/Undead0.png", 0, 5),
    "shade": ("Characters/Undead0.png", 1, 5),
    
    # Major Demons (Demon0.png)
    "water demon": ("Characters/Demon0.png", 0, 2),
    "succubus": ("Characters/Demon0.png", 1, 2),
    "incubus": ("Characters/Demon0.png", 2, 2),
    "horned devil": ("Characters/Demon0.png", 3, 2),
    "barbed devil": ("Characters/Demon0.png", 4, 2),
    "bone devil": ("Characters/Demon0.png", 5, 2),
    "ice devil": ("Characters/Demon0.png", 6, 2),
    "pit fiend": ("Characters/Demon0.png", 7, 2),
    "balrog": ("Characters/Demon0.png", 0, 3),
    "Juiblex": ("Characters/Slime0.png", 0, 3),
    "Yeenoghu": ("Characters/Demon0.png", 1, 3),
    "Orcus": ("Characters/Demon0.png", 2, 3),
    "Geryon": ("Characters/Demon0.png", 3, 3),
    "Dispater": ("Characters/Demon0.png", 4, 3),
    "Baalzebub": ("Characters/Demon0.png", 5, 3),
    "Asmodeus": ("Characters/Demon0.png", 6, 3),
    "Demogorgon": ("Characters/Demon0.png", 7, 3),
    
    # Eel / Sea monster (Aquatic0.png)
    "jellyfish": ("Characters/Aquatic0.png", 0, 0),
    "piranha": ("Characters/Aquatic0.png", 1, 0),
    "shark": ("Characters/Aquatic0.png", 2, 0),
    "giant eel": ("Characters/Aquatic0.png", 3, 0),
    "electric eel": ("Characters/Aquatic0.png", 4, 0),
    "kraken": ("Characters/Aquatic0.png", 5, 0),
    
    # Lizard (Reptile0.png)
    "newt": ("Characters/Reptile0.png", 0, 6),
    "gecko": ("Characters/Reptile0.png", 1, 6),
    "iguana": ("Characters/Reptile0.png", 2, 6),
    "baby crocodile": ("Characters/Reptile0.png", 3, 6),
    "crocodile": ("Characters/Reptile0.png", 4, 6),
    "chameleon": ("Characters/Reptile0.png", 5, 6),
    "salamander": ("Characters/Reptile0.png", 6, 6),
    
    # Humans & Player roles (Humanoid0.png, Player0.png)
    "human": ("Characters/Humanoid0.png", 0, 14),
    "archeologist": ("Characters/Player0.png", 0, 0),
    "barbarian": ("Characters/Player0.png", 1, 0),
    "caveman": ("Characters/Player0.png", 2, 0),
    "cavewoman": ("Characters/Player0.png", 2, 0),
    "healer": ("Characters/Player0.png", 3, 0),
    "knight": ("Characters/Player0.png", 4, 0),
    "monk": ("Characters/Player0.png", 5, 0),
    "priest": ("Characters/Player0.png", 6, 0),
    "priestess": ("Characters/Player0.png", 6, 0),
    "ranger": ("Characters/Player0.png", 7, 0),
    "rogue": ("Characters/Player0.png", 0, 1),
    "samurai": ("Characters/Player0.png", 1, 1),
    "tourist": ("Characters/Player0.png", 2, 1),
    "valkyrie": ("Characters/Player0.png", 3, 1),
    "wizard": ("Characters/Player0.png", 4, 1),
    "shopkeeper": ("Characters/Humanoid0.png", 1, 14),
    "guard": ("Characters/Humanoid0.png", 2, 14),
    "oracle": ("Characters/Humanoid0.png", 3, 14),
    "nurse": ("Characters/Humanoid0.png", 4, 14),
}

# アイテムのマッピング辞書 (objects.txt の名前と DawnLike スプライト)
OBJECT_MAP = {
    # 汎用クラス (791〜806)
    "weapon / generic weapon": ("Items/LongWep.png", 0, 0),
    "armor / generic armor": ("Items/Armor.png", 0, 0),
    "ring / generic ring": ("Items/Ring.png", 0, 0),
    "amulet / generic amulet": ("Items/Amulet.png", 0, 0),
    "tool / generic tool": ("Items/Tool.png", 0, 0),
    "food / generic food": ("Items/Food.png", 0, 0),
    "potion / generic potion": ("Items/Potion.png", 0, 0),
    "scroll / generic scroll": ("Items/Scroll.png", 0, 0),
    "spellbook / generic spellbook": ("Items/Book.png", 0, 0),
    "wand / generic wand": ("Items/Wand.png", 0, 0),
    "coin / generic coin": ("Items/Money.png", 0, 0),
    "gem / generic gem": ("Items/Rock.png", 0, 0),
    "large rock / generic large rock": ("Items/Rock.png", 1, 0),
    "iron ball / generic iron ball": ("Items/Rock.png", 2, 0),
    
    # 矢・飛び道具 (Ammo.png)
    "arrow": ("Items/Ammo.png", 0, 0),
    "runed arrow / elven arrow": ("Items/Ammo.png", 1, 0),
    "crude arrow / orcish arrow": ("Items/Ammo.png", 2, 0),
    "silver arrow": ("Items/Ammo.png", 3, 0),
    "ya / bamboo arrow": ("Items/Ammo.png", 4, 0),
    "crossbow bolt": ("Items/Ammo.png", 5, 0),
    "dart": ("Items/Ammo.png", 0, 1),
    "shuriken / throwing star": ("Items/Ammo.png", 1, 1),
    "boomerang": ("Items/Ammo.png", 2, 1),
    
    # 武器 (LongWep.png, MedWep.png, ShortWep.png)
    "spear": ("Items/LongWep.png", 0, 0),
    "elven spear": ("Items/LongWep.png", 1, 0),
    "orcish spear": ("Items/LongWep.png", 2, 0),
    "dwarvish spear": ("Items/LongWep.png", 3, 0),
    "silver spear": ("Items/LongWep.png", 4, 0),
    "javelin / throwing spear": ("Items/LongWep.png", 5, 0),
    "trident": ("Items/LongWep.png", 6, 0),
    "dagger": ("Items/ShortWep.png", 0, 0),
    "elven dagger": ("Items/ShortWep.png", 1, 0),
    "orcish dagger": ("Items/ShortWep.png", 2, 0),
    "silver dagger": ("Items/ShortWep.png", 3, 0),
    "athame": ("Items/ShortWep.png", 4, 0),
    "scalpel": ("Items/ShortWep.png", 5, 0),
    "knife": ("Items/ShortWep.png", 6, 0),
    "axe": ("Items/MedWep.png", 0, 0),
    "battle-axe": ("Items/MedWep.png", 1, 0),
    "short sword": ("Items/ShortWep.png", 0, 1),
    "elven short sword": ("Items/ShortWep.png", 1, 1),
    "orcish short sword": ("Items/ShortWep.png", 2, 1),
    "dwarvish short sword": ("Items/ShortWep.png", 3, 1),
    "broadsword": ("Items/LongWep.png", 0, 1),
    "elven broadsword": ("Items/LongWep.png", 1, 1),
    "long sword": ("Items/LongWep.png", 2, 1),
    "two-handed sword": ("Items/LongWep.png", 3, 1),
    "katana": ("Items/LongWep.png", 4, 1),
    "tsurugi": ("Items/LongWep.png", 5, 1),
    "scimitar": ("Items/LongWep.png", 6, 1),
    "silver saber": ("Items/LongWep.png", 7, 1),
    "club": ("Items/MedWep.png", 0, 1),
    "mace": ("Items/MedWep.png", 1, 1),
    "morning star": ("Items/MedWep.png", 2, 1),
    "flail": ("Items/MedWep.png", 3, 1),
    "war hammer": ("Items/MedWep.png", 4, 1),
    "quarterstaff": ("Items/LongWep.png", 0, 2),
    "bow": ("Items/Ammo.png", 0, 2),
    "elven bow": ("Items/Ammo.png", 1, 2),
    "orcish bow": ("Items/Ammo.png", 2, 2),
    "yumi": ("Items/Ammo.png", 3, 2),
    "sling": ("Items/Ammo.png", 4, 2),
    "crossbow": ("Items/Ammo.png", 5, 2),
    
    # 防具 (Armor.png, Hat.png, Boot.png, Glove.png, Shield.png)
    "leather jacket": ("Items/Armor.png", 0, 0),
    "leather armor": ("Items/Armor.png", 1, 0),
    "orcish ring mail": ("Items/Armor.png", 2, 0),
    "ring mail": ("Items/Armor.png", 3, 0),
    "scale mail": ("Items/Armor.png", 4, 0),
    "chain mail": ("Items/Armor.png", 5, 0),
    "plate mail": ("Items/Armor.png", 6, 0),
    "crystal plate mail": ("Items/Armor.png", 7, 0),
    "elven mithril-coat": ("Items/Armor.png", 0, 1),
    "dwarvish mithril-coat": ("Items/Armor.png", 1, 1),
    "bronze plate mail": ("Items/Armor.png", 2, 1),
    "splint mail": ("Items/Armor.png", 3, 1),
    "banded mail": ("Items/Armor.png", 4, 1),
    "fedora": ("Items/Hat.png", 0, 0),
    "helmet": ("Items/Hat.png", 1, 0),
    "dwarvish iron helm": ("Items/Hat.png", 2, 0),
    "elven leather helm": ("Items/Hat.png", 3, 0),
    "small shield": ("Items/Shield.png", 0, 0),
    "large shield": ("Items/Shield.png", 1, 0),
    "shield of reflection": ("Items/Shield.png", 2, 0),
    "leather gloves": ("Items/Glove.png", 0, 0),
    "gauntlets of power": ("Items/Glove.png", 1, 0),
    "low boots": ("Items/Boot.png", 0, 0),
    "iron shoes": ("Items/Boot.png", 1, 0),
    "high boots": ("Items/Boot.png", 2, 0),
    "speed boots": ("Items/Boot.png", 3, 0),
    "water walking boots": ("Items/Boot.png", 4, 0),
    "jumping boots": ("Items/Boot.png", 5, 0),
    "elven boots": ("Items/Boot.png", 6, 0),
    
    # 食料・肉 (Food.png, Flesh.png)
    "meatball": ("Items/Food.png", 0, 0),
    "tripe ration": ("Items/Food.png", 1, 0),
    "corpse": ("Items/Flesh.png", 0, 0),
    "egg": ("Items/Food.png", 2, 0),
    "clove of garlic": ("Items/Food.png", 3, 0),
    "apple": ("Items/Food.png", 4, 0),
    "carrot": ("Items/Food.png", 5, 0),
    "pear": ("Items/Food.png", 6, 0),
    "banana": ("Items/Food.png", 7, 0),
    "orange": ("Items/Food.png", 0, 1),
    "melon": ("Items/Food.png", 1, 1),
    "fortune cookie": ("Items/Food.png", 2, 1),
    "candy bar": ("Items/Food.png", 3, 1),
    "cream pie": ("Items/Food.png", 4, 1),
    "pancake": ("Items/Food.png", 5, 1),
    "lembas wafer": ("Items/Food.png", 6, 1),
    "cram ration": ("Items/Food.png", 7, 1),
    "food ration": ("Items/Food.png", 0, 2),
    "K-ration": ("Items/Food.png", 1, 2),
    "C-ration": ("Items/Food.png", 2, 2),
    "tin": ("Items/Food.png", 3, 2),
    
    # 道具 (Tool.png, Light.png, Chest0.png)
    "large box": ("Items/Chest0.png", 0, 0),
    "chest": ("Items/Chest0.png", 1, 0),
    "ice box": ("Items/Chest0.png", 2, 0),
    "sack": ("Items/Tool.png", 0, 0),
    "oilskin sack": ("Items/Tool.png", 1, 0),
    "bag of holding": ("Items/Tool.png", 2, 0),
    "bag of tricks": ("Items/Tool.png", 3, 0),
    "skeleton key": ("Items/Key.png", 0, 0),
    "lock pick": ("Items/Tool.png", 4, 0),
    "tallow candle": ("Items/Light.png", 0, 0),
    "wax candle": ("Items/Light.png", 1, 0),
    "oil lamp": ("Items/Light.png", 2, 0),
    "magic lamp": ("Items/Light.png", 3, 0),
    "mirror": ("Items/Tool.png", 5, 0),
    "crystal ball": ("Items/Tool.png", 6, 0),
    "blindfold": ("Items/Tool.png", 7, 0),
    "towel": ("Items/Tool.png", 0, 1),
    "saddle": ("Items/Tool.png", 1, 1),
    "leash": ("Items/Tool.png", 2, 1),
    "whistle": ("Items/Music.png", 0, 0),
    "magic whistle": ("Items/Music.png", 1, 0),
    "wooden flute": ("Items/Music.png", 2, 0),
    "magic flute": ("Items/Music.png", 3, 0),
    "horn": ("Items/Music.png", 4, 0),
    "bell": ("Items/Music.png", 5, 0),
    "drum": ("Items/Music.png", 6, 0),
    "pick-axe": ("Items/Tool.png", 3, 1),
    
    # 金貨・宝石 (Money.png, Rock.png)
    "gold piece": ("Items/Money.png", 0, 0),
    "dilithium crystal": ("Items/Rock.png", 0, 0),
    "diamond": ("Items/Rock.png", 1, 0),
    "ruby": ("Items/Rock.png", 2, 0),
    "jacinth": ("Items/Rock.png", 3, 0),
    "sapphire": ("Items/Rock.png", 4, 0),
    "black opal": ("Items/Rock.png", 5, 0),
    "emerald": ("Items/Rock.png", 6, 0),
    "turquoise": ("Items/Rock.png", 7, 0),
    "aquamarine": ("Items/Rock.png", 0, 1),
    "amber": ("Items/Rock.png", 1, 1),
    "topaz": ("Items/Rock.png", 2, 1),
    "jet": ("Items/Rock.png", 3, 1),
    "opal": ("Items/Rock.png", 4, 1),
    "chrysoberyl": ("Items/Rock.png", 5, 1),
    "garnet": ("Items/Rock.png", 6, 1),
    "amethyst": ("Items/Rock.png", 7, 1),
    "jasper": ("Items/Rock.png", 0, 1),
    "fluorite": ("Items/Rock.png", 1, 1),
    "jade": ("Items/Rock.png", 2, 1),
    "agate": ("Items/Rock.png", 3, 1),
    "obsidian": ("Items/Rock.png", 4, 1),
}

# 地形・効果のマッピング辞書 (other.txt の名前と DawnLike スプライト)
OTHER_MAP = {
    # 壁 (Objects/Wall.png: 20列×51行)
    # DawnLike Wall.png の最初のブロック:
    # row 0, col 0 は上壁、col 1 は横壁、角など
    "main walls vertical": ("Objects/Wall.png", 0, 0),
    "main walls horizontal": ("Objects/Wall.png", 1, 0),
    "main walls tlcorn": ("Objects/Wall.png", 2, 0),
    "main walls trcorn": ("Objects/Wall.png", 3, 0),
    "main walls blcorn": ("Objects/Wall.png", 4, 0),
    "main walls brcorn": ("Objects/Wall.png", 5, 0),
    "main walls cross wall": ("Objects/Wall.png", 6, 0),
    "main walls tuwall": ("Objects/Wall.png", 7, 0),
    "main walls tdwall": ("Objects/Wall.png", 8, 0),
    "main walls tlwall": ("Objects/Wall.png", 9, 0),
    "main walls trwall": ("Objects/Wall.png", 10, 0),
    
    # 扉 (Objects/Door0.png)
    "vertical open door": ("Objects/Door0.png", 0, 0),
    "horizontal open door": ("Objects/Door0.png", 1, 0),
    "vertical closed door": ("Objects/Door0.png", 2, 0),
    "horizontal closed door": ("Objects/Door0.png", 3, 0),
    "iron bars": ("Objects/Wall.png", 0, 1),
    "tree": ("Objects/Tree0.png", 0, 0),
    
    # 床・通路 (Objects/Floor.png)
    "floor of a room": ("Objects/Floor.png", 0, 0),
    "dark part of a room": ("Objects/Floor.png", 1, 0),
    "corridor": ("Objects/Floor.png", 2, 0),
    
    # 階段・祭壇・墓 (Objects/Decor0.png, Objects/Tile.png)
    "stairs up": ("Objects/Decor0.png", 0, 0),
    "stairs down": ("Objects/Decor0.png", 1, 0),
    "ladder up": ("Objects/Decor0.png", 2, 0),
    "ladder down": ("Objects/Decor0.png", 3, 0),
    "altar": ("Objects/Decor0.png", 0, 1),
    "grave": ("Objects/Decor0.png", 1, 1),
    "throne": ("Objects/Decor0.png", 2, 1),
    "sink": ("Objects/Decor0.png", 3, 1),
    "fountain": ("Objects/Decor0.png", 4, 1),
    "pool of water": ("Objects/Floor.png", 0, 1),
    "ice": ("Objects/Floor.png", 1, 1),
    "lava": ("Objects/Floor.png", 2, 1),
    
    # トラップ (Objects/Trap0.png)
    "arrow trap": ("Objects/Trap0.png", 0, 0),
    "dart trap": ("Objects/Trap0.png", 1, 0),
    "falling rock trap": ("Objects/Trap0.png", 2, 0),
    "squeaky board": ("Objects/Trap0.png", 3, 0),
    "bear trap": ("Objects/Trap0.png", 4, 0),
    "land mine": ("Objects/Trap0.png", 5, 0),
    "rolling boulder trap": ("Objects/Trap0.png", 6, 0),
    "sleeping gas trap": ("Objects/Trap0.png", 7, 0),
    "rust trap": ("Objects/Trap0.png", 0, 1),
    "fire trap": ("Objects/Trap0.png", 1, 1),
    "pit": ("Objects/Trap0.png", 2, 1),
    "spiked pit": ("Objects/Trap0.png", 3, 1),
    "hole": ("Objects/Trap0.png", 4, 1),
    "trap door": ("Objects/Trap0.png", 5, 1),
    "teleportation trap": ("Objects/Trap0.png", 6, 1),
    "level teleporter": ("Objects/Trap0.png", 7, 1),
    "magic portal": ("Objects/Trap0.png", 0, 2),
    "web": ("Objects/Trap0.png", 1, 2),
    "statue trap": ("Objects/Trap0.png", 2, 2),
    "magic trap": ("Objects/Trap0.png", 3, 2),
    "anti-magic field": ("Objects/Trap0.png", 4, 2),
    "polymorph trap": ("Objects/Trap0.png", 5, 2),
}

def build_full_mapping():
    with open("tool/tileset/nethack_tiles.json", "r", encoding="utf-8") as f:
        tiles = json.load(f)
        
    mapping = {}
    matched_mons = 0
    matched_objs = 0
    matched_oths = 0
    
    # 汎用ポーション・巻物・指輪・杖などのパターン
    for t in tiles:
        tid = t["id"]
        cat = t["category"]
        desc = t["desc"]
        clean = t["clean_name"]
        
        assigned = None
        
        if cat == "monster":
            # モンスターマップ照合
            if clean in MONSTER_MAP:
                assigned = MONSTER_MAP[clean]
            else:
                # 前方一致・部分一致
                for k, v in MONSTER_MAP.items():
                    if clean.startswith(k) or k in clean:
                        assigned = v
                        break
            if assigned:
                matched_mons += 1
                
        elif cat == "object":
            if desc in OBJECT_MAP:
                assigned = OBJECT_MAP[desc]
            elif clean in OBJECT_MAP:
                assigned = OBJECT_MAP[clean]
            else:
                # パターン別自動フォールバック (ポーション、巻物、本、杖、指輪、アミュレット等)
                if "potion" in desc:
                    # ポーション色バリエーション
                    col_idx = (tid - 789) % 8
                    row_idx = ((tid - 789) // 8) % 5
                    assigned = ("Items/Potion.png", col_idx, row_idx)
                elif "scroll" in desc:
                    col_idx = (tid - 789) % 8
                    row_idx = ((tid - 789) // 8) % 6
                    assigned = ("Items/Scroll.png", col_idx, row_idx)
                elif "spellbook" in desc or "book" in desc:
                    col_idx = (tid - 789) % 8
                    row_idx = ((tid - 789) // 8) % 9
                    assigned = ("Items/Book.png", col_idx, row_idx)
                elif "wand" in desc:
                    col_idx = (tid - 789) % 8
                    row_idx = ((tid - 789) // 8) % 7
                    assigned = ("Items/Wand.png", col_idx, row_idx)
                elif "ring" in desc:
                    col_idx = (tid - 789) % 8
                    row_idx = ((tid - 789) // 8) % 6
                    assigned = ("Items/Ring.png", col_idx, row_idx)
                elif "amulet" in desc:
                    col_idx = (tid - 789) % 8
                    row_idx = ((tid - 789) // 8) % 3
                    assigned = ("Items/Amulet.png", col_idx, row_idx)
                elif "sword" in desc or "blade" in desc or "saber" in desc:
                    assigned = ("Items/LongWep.png", 0, 1)
                elif "armor" in desc or "mail" in desc or "suit" in desc or "cloak" in desc:
                    assigned = ("Items/Armor.png", 0, 0)
                elif "helm" in desc or "hat" in desc or "cap" in desc:
                    assigned = ("Items/Hat.png", 0, 0)
                elif "boot" in desc or "shoe" in desc:
                    assigned = ("Items/Boot.png", 0, 0)
                elif "glove" in desc or "gauntlet" in desc:
                    assigned = ("Items/Glove.png", 0, 0)
                elif "shield" in desc:
                    assigned = ("Items/Shield.png", 0, 0)
                elif "gem" in desc or "stone" in desc:
                    assigned = ("Items/Rock.png", 0, 0)
            if assigned:
                matched_objs += 1
                
        elif cat == "other":
            if desc in OTHER_MAP:
                assigned = OTHER_MAP[desc]
            elif clean in OTHER_MAP:
                assigned = OTHER_MAP[clean]
            else:
                for k, v in OTHER_MAP.items():
                    if k in desc or k in clean:
                        assigned = v
                        break
            if assigned:
                matched_oths += 1

        if assigned:
            mapping[str(tid)] = {
                "tile_id": tid,
                "desc": desc,
                "sheet": assigned[0],
                "col": assigned[1],
                "row": assigned[2]
            }

    print(f"Mapping results:")
    print(f"  Monsters: {matched_mons} / 789 ({matched_mons*100//789}%)")
    print(f"  Objects:  {matched_objs} / 483 ({matched_objs*100//483}%)")
    print(f"  Other:    {matched_oths} / 243 ({matched_oths*100//243}%)")
    print(f"  Total mapped: {len(mapping)} / 1515 ({len(mapping)*100//1515}%)")
    
    out_path = "tool/tileset/dawnlike_mapping.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(mapping, f, ensure_ascii=False, indent=2)
    print(f"Saved mapping to {out_path}")

if __name__ == "__main__":
    build_full_mapping()
