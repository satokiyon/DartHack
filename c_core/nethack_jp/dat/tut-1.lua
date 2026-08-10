-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-19.

local tut_ctrl_key = nil;
local tut_alt_key = nil;

function tut_key(command)
   local s = nh.eckey(command);
   local m = s:match("^^([A-Z])$"); -- ^X is Ctrl-X
   if (m ~= nil) then
      tut_ctrl_key = m;
      return "Ctrl-" .. m;
   end

   m = s:match("^M%-([A-Z])$"); -- M-X is Alt-X
   if (m ~= nil) then
      tut_alt_key = m;
      return "Alt-" .. m;
   end

   return s;
end

function tut_key_help(x, y)
   if (tut_ctrl_key ~= nil) then
      des.engraving({ coord = { x,y }, type = "engrave", text = "注: チュートリアルの外では Ctrl キーの組み合わせは '^" .. tut_ctrl_key .. "' のように ^ 付きで表示される", degrade = false });
      tut_ctrl_key = nil;
   end
end

des.level_init({ style = "solidfill", fg = " " });
des.level_flags("mazelevel", "noflip",
                "nomongen", "nodeathdrops", "noautosearch");

des.map([[
---------------------------------------------------------------------------
|-.--|.......|......|..S....|.F.......|.............|.......|.............|
|.-..........|......|--|....|.F.....|.|S-------.....|.....................|
||.--|.......|..T......|....|.F.....|.|.......|.....|.......|.............|
||.|.|.......|......|-.|....|.F.....|.|.......|.....|--------.............|
||.|.|.......|......||.|-.-----------.-.......|-S----.....................|
|-+-S---------..---.||........................|...|.......................|
|......|          |.-------------------.......|...|....--S----............|
|......|  ######  |.........|      |..S.......|...|....|.....|............|
|----.-| -+-   #  |.....---.|######+..|.......S...|....|.....|............|
|----+----.----+---.|.--|.|.|#     ------------...|....|.....F............|
|........|.|......|.|...F...|#  ........|.....+...|....|.....|............|
|.P......-S|......|------.---# .........|.....|...|....-------........----|
|..........|......+.|...|.|.S# ..--S-----.....|LLL|..................|..| |
|.W......---......|.|.|.|.|.|# ..|......|.....|LLL|..................|..--|
|....Z.L.S.F......|.|.|.|.---#   |......+.....|...|..................|..|.|
|........|--......|...|.....|####+......|.....|...+..................||...|
---------------------------------------------------------------------------
]]);


des.region(selection.area(01,01, 73, 16), "lit");

des.non_diggable();

des.teleport_region({ region = { 9,3, 9,3 } });

-- TODO:
--  - save (more of) hero state when entering
--  - quit-command should maybe exit the tutorial?

-- turn on some newbie-friendly options
nh.parse_config("OPTIONS=mention_walls");
nh.parse_config("OPTIONS=mention_decor");
nh.parse_config("OPTIONS=lit_corridor");

local movekeys = tut_key("movewest") .. " " ..
   tut_key("movesouth") .. " " ..
   tut_key("movenorth") .. " " ..
   tut_key("moveeast");

local diagmovekeys = tut_key("movesouthwest") .. " " ..
   tut_key("movenortheast") .. " " ..
   tut_key("movesoutheast") .. " " ..
   tut_key("movenorthwest");

des.engraving({ coord = { 9,3 }, type = "engrave", text = "移動は " .. movekeys .. " を使う", degrade = false });
des.engraving({ coord = { 5,2 }, type = "engrave", text = "斜め移動は " .. diagmovekeys .. " を使う", degrade = false });

if (u.role == "Knight") then
   des.engraving({ coord = { 12,1 }, type = "engrave", text = "騎士は '" .. tut_key("jump") .. "' で跳躍できる", degrade = false });
end

--

des.engraving({ coord = { 2,4 }, type = "engrave", text = "行動によっては成功まで何度か試す必要がある", degrade = false });
des.engraving({ coord = { 2,5 }, type = "engrave", text = "扉に向かって進むと開けられる", degrade = false });
des.door({ coord = { 2,6 }, state = "closed" });

des.engraving({ coord = { 2,7 }, type = "engrave", text = "扉を閉めるには '" .. tut_key("close") .. "' を使う", degrade = false });


--

des.engraving({ coord = { 4,5 }, type = "engrave", text = "魔法のポータルからチュートリアルを出られる.", degrade = false });
des.trap({ type = "magic portal", coord = { 4,4 }, seen = true });

--

des.engraving({ coord = { 5,9 }, type = "engrave", text = "この扉は施錠されている. '" .. tut_key("kick") .. "' で蹴れ", degrade = false });
des.door({ coord = { 5,10 }, state = "locked" });

-- by default, kick is the first command that can be a ctrl-key combo
tut_key_help(6, 8);


des.engraving({ coord = { 5,12 }, type = "engrave", text = "'" .. tut_key("glance") .. "' でマップを見回せる. 終わったら ESC を押す", degrade = false });

--

des.engraving({ coord = { 10,13 }, type = "engrave", text = "隠し扉を探すには '" .. tut_key("search") .. "' を使う", degrade = false });

des.engraving({ coord = { 10,15 }, type = "engrave", text = "外れだ", degrade = false });

--

des.engraving({ coord = { 10,10 }, type = "engrave", text = "この扉の先は暗い通路だ", degrade = false });
des.door({ coord = { 10,9 }, state = percent(50) and "locked" or "closed" });
des.region(selection.match("#"), "unlit");
des.region(selection.match(" "), "unlit");
des.door({ coord = { 15,10 }, state = percent(50) and "locked" or "closed" });

--

des.engraving({ coord = { 15,11 }, type = "engrave", text = "すぐ近くに罠が 4 つある! 探してみよう.", degrade = false });
local locs = { {14,11}, {14,12}, {15,12}, {16,12}, {16,11} };
shuffle(locs);
for i = 1, 4 do
   des.trap({ type = percent(50) and "sleep gas" or "board",
              coord = locs[i], victim = false });
end

des.engraving({ coord = { 15,15 }, type = "engrave", text = "罠によっては '" .. tut_key("untrap") .. "' で解除できる", degrade = false });
des.trap({ coord = { 15,16 }, type = "web", spider_on_web = false });

--

des.door({ coord = { 18,13 }, state = "closed" });

des.engraving({ coord = { 19,13 }, type = "engrave", text = "アイテムを拾うには '" .. tut_key("pickup") .. "' を使う", degrade = false });

local armor = (u.role == "Monk") and "leather gloves" or "leather armor";

des.object({ id = armor, spe = 0, buc = "cursed", coord = { 19,14} });

des.engraving({ coord = { 19,15 }, type = "engrave", text = "防具を着るには '" .. tut_key("wear") .. "' を使う", degrade = false });

des.object({ id = "dagger", spe = 0, buc = "not-cursed", coord = { 21,15} });

des.engraving({ coord = { 21,14 }, type = "engrave", text = "武器を装備するには '" .. tut_key("wield") .. "' を使う", degrade = false });


des.engraving({ coord = { 22,13 }, type = "engrave", text = "怪物には体当たりして攻撃する.", degrade = false });

des.monster({ id = "lichen", coord = { 23,15 }, waiting = true, countbirth = false });

--

des.engraving({ coord = { 24,16 }, type = "engrave", text = "これで基本は覚えた. 魔法のポータルからチュートリアルを出られる.", degrade = false });

des.engraving({ coord = { 26,16 }, type = "engrave", text = "チュートリアルを終えるにはこのポータルに入る", degrade = false });
des.trap({ type = "magic portal", coord = { 27,16 }, seen = true });

--

des.engraving({ coord = { 25,13 }, type = "engrave", text = "巨大な岩は押して動かせる", degrade = false });
des.object({ id = "boulder", coord = {25,12} });

--

des.engraving({ coord = { 27,9 }, type = "engrave", text = "防具を脱ぐには '" .. tut_key("takeoff") .. "' を使う", degrade = false });

--

des.object({ class = "?", id = "remove curse", buc = "blessed", coord = {23,11} })
des.engraving({ coord = { 22,11 }, type = "engrave", text = "アイテムの見た目はゲームごとに変わることがある", degrade = false });
des.engraving({ coord = { 23,11 }, type = "engrave", text = "この巻物を拾い、'" .. tut_key("read") .. "' で読んでからもう一度防具を脱いでみよう", degrade = false });

--

des.engraving({ coord = { 19,10 }, type = "engrave", text = "ここにもチュートリアルを出るための魔法のポータルがある", degrade = false });
des.trap({ type = "magic portal", coord = { 19,11 }, seen = true });

--

-- rock fall
des.object({ coord = {14, 5}, id = "rock", quantity = math.random(50,99) });
des.object({ coord = {15, 5}, id = "rock", quantity = math.random(10,30) });
des.object({ coord = {14, 4}, id = "rock", quantity = math.random(10,30) });
des.object({ coord = {15, 6}, id = "rock", quantity = math.random(30,60) });
des.object({ coord = {14, 6}, id = "rock", quantity = math.random(30,60) });
des.object({ coord = {14, 6}, id = "boulder" });

des.door({ coord = { 20,3 }, state = percent(50) and "open" or "closed" });

des.engraving({ coord = { 21,3 }, type = "engrave", text = "荷物が重いと動きが遅くなる", degrade = false });
des.engraving({ coord = { 22,3 }, type = "engrave", text = "アイテムを落とすには '" .. tut_key("drop") .. "' を使う", degrade = false });
des.engraving({ coord = { 22,4 }, type = "engrave", text = "数字を付けて選ぶと束の一部だけ落とせる", degrade = false });

--

des.monster({ id = "yellow mold", coord = { 26,2 }, waiting = true, countbirth = false });

des.engraving({ coord = { 25,5 }, type = "engrave", text = "アイテムを投げるには '" .. tut_key("throw") .. "' を使う", degrade = false });

des.trap({ type = "magic portal", coord = { 21,1 }, seen = true });

--

des.monster({ id = "wolf", coord = { 29,2 }, peaceful = 0, waiting = true, countbirth = false });

des.engraving({ coord = { 37,4 }, type = "engrave", text = "石のような飛び道具は対応する発射具で撃つと強い", degrade = false });

des.object({ coord = { 37,3 }, id = "sling", buc = "not-cursed", spe = 9 });
des.engraving({ coord = { 37,3 }, type = "engrave", text = "スリングを装備しよう", degrade = false });
des.engraving({ coord = { 36,1 }, type = "engrave", text = "装備中の発射具で飛び道具を撃つには '" .. tut_key("fire") .. "' を使う", degrade = false });

des.engraving({ coord = { 35,4 }, type = "engrave", text = "射撃では矢筒の弾を使う. 入れるには '" .. tut_key("quiver") .. "' を使う", degrade = false });

des.engraving({ coord = { 33,4 }, type = "engrave", text = "1 ターン待つには '" .. tut_key("wait") .. "' を使う", degrade = false });


--

des.door({ coord = { 38,6 }, state = "closed" });

des.engraving({ coord = { 39,6 }, type = "engrave", text = "容器をあさるには '" .. tut_key("loot") .. "' を使う", degrade = false });

des.object({ coord = { 41,6 }, id = "large box", broken = true, trapped = false,
             contents = function(obj)
                des.object({ id = "secret door detection", class = "/", spe = 30 }); end
});
des.engraving({ coord = { 42,6 }, type = "engrave", text = "容器は '" .. tut_key("tip") .. "' でひっくり返して空にもできる", degrade = false });

des.engraving({ coord = { 45,6 }, type = "engrave", text = "魔法の杖は '" .. tut_key("zap") .. "' で使う", degrade = false });

--

des.door({ coord = { 35,9 }, state = "nodoor" });
des.engraving({ coord = { 34,9 }, type = "engrave", text = "移動キーの前に '" .. tut_key("run") .. "' を付けると走れる", degrade = false });

--

des.door({ coord = { 33,16 }, state = "nodoor" });
des.engraving({ coord = { 35,15 }, type = "engrave", text = "フロアを横断移動するには '" .. tut_key("travel") .. "' を使う", degrade = false });

--

des.trap({ type = "magic portal", coord = { 27,14 }, seen = true });

--

des.engraving({ coord = { 48,1 }, type = "burn", text = "食べられる物は '" .. tut_key("eat") .. "' で食べる", degrade = false });

des.object({ coord = { 50,3 }, id = "apple", buc = "not-cursed"  });
des.object({ coord = { 50,3 }, id = "candy bar", buc = "not-cursed"  });

des.object({ coord = { 50,3 }, id = "corpse", montype = "lichen", buc = "not-cursed" });

--

des.door({ coord = { 46,11 }, state = "closed" });

des.engraving({ coord = { 43,11 }, type = "burn", text = "二刀流は '" .. tut_key("twoweapon") .. "' で切り替える", degrade = false });
des.object({ coord = { 43,13 }, id = "knife", buc = "uncursed" });
des.object({ coord = { 43,14 }, id = "dagger", buc = "blessed" });

des.engraving({ coord = { 43,16 }, type = "burn", text = "武器の素早い持ち替えは '" .. tut_key("swap") .. "' を使う", degrade = false });

des.door({ coord = { 40,15 }, state = "random" });

--

des.object({ coord = { 48,7 }, id = "ring of levitation", buc = "not-cursed" });

des.engraving({ coord = { 48,10 }, type = "burn", text = "装飾品を身に着けるには '" .. tut_key("puton") .. "' を使う", degrade = false });

des.engraving({ coord = { 48,16 }, type = "burn", text = "装飾品を外すには '" .. tut_key("remove") .. "' を使う", degrade = false });

des.door({ coord = { 50,16 }, state = "closed" });


--

des.engraving({ coord = { 58,9 }, type = "burn", text = "階段を下りるには '" .. tut_key("down") .. "' を使う", degrade = false });
des.stair({ dir = "down", coord = { 58,10 } });

--

-- one more ctrl-key help, if needed
tut_key_help(64, 4);

des.engraving({ coord = { 65,3 }, type = "burn", text = "工事中", degrade = false });

des.trap({ type = "magic portal", coord = { 66,2 }, seen = true });

--

-- squeezing through small gaps

des.engraving({ coord = { 69,12 }, type = "burn", text = "通れない? 荷物を持ちすぎている.", degrade = false });

-- try to squeeze over boulders, find a trap door

des.object({ id = "boulder", coord = {71,16} });
des.object({ id = "boulder", coord = {72,16} });
des.object({ id = "boulder", coord = {73,16} });
des.trap({ type = "trap door", coord = { 73,15 } });

--

des.engraving({ coord = { 60,2 }, type = "engrave", text = "呪文の詠唱", degrade = false });
if (u.uenmax < 5) then
   -- TODO: make sure hero has enough Pw to cast the spell (5 pw) instead?
   -- TODO: ensure the first cast of this spell succeeds?
   des.engraving({ coord = { 59,2 }, type = "engrave", text = "残念ながら呪文を唱えるだけの魔力がない.", degrade = false });
end
des.engraving({ coord = { 57,2 }, type = "engrave", text = "呪文書を拾うには '" .. tut_key("pickup") .. "' を使う", degrade = false });
des.object({ coord = { 57,2 }, id = "spellbook of light", buc = "blessed" });
des.engraving({ coord = { 55,2 }, type = "engrave", text = "呪文書を読むには '" .. tut_key("read") .. "' を使う", degrade = false });
des.engraving({ coord = { 53,2 }, type = "engrave", text = "呪文を唱えるには '" .. tut_key("cast") .. "' を使う", degrade = false });
des.region(selection.area(53,01, 59, 3), "unlit");

--

des.engraving({ coord = { 72,2 }, type = "engrave", text = "薬は '" .. tut_key("quaff") .. "' で飲む", degrade = false });
des.object({ coord = { 72,2 }, id = "potion of object detection", buc = "blessed" });


----------------

-- entering and leaving tutorial _branch_ now handled by core
-- // nh.callback("cmd_before", "tutorial_cmd_before");
-- // nh.callback("level_enter", "tutorial_enter");
-- // nh.callback("level_leave", "tutorial_leave");
-- // nh.callback("end_turn", "tutorial_turn");

----------------

-- temporary stuff here
-- des.trap({ type = "magic portal", coord = { 9,5 }, seen = true });
-- des.trap({ type = "magic portal", coord = { 9,1 }, seen = true });
-- des.object({ id = "leather armor", spe = 0, coord = { 9,2} });


