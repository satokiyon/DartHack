-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-11-02.
-- Tests for #adjust command (doorganize)

nh.parse_config("OPTIONS=fixinv")
nh.parse_config("OPTIONS=!timed_delay")
nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true })

local function meta(key)
    return string.char(0x80 | string.byte(key))
end

local function get_inv_map()
    local map = {}
    local count = 0
    local o = u.inventory
    while o do
        local tbl = o:totable()
        if tbl.NO_OBJ == 1 then
            break
        end
        if tbl.invlet and tbl.invlet ~= "" then
            map[tbl.invlet] = tbl
            count = count + 1
        end
        o = o:next()
    end
    return map, count
end

local function find_item_by_name(name)
    local inv = get_inv_map()
    for let, item in pairs(inv) do
        if item.otyp_name == name then
            return item
        end
    end
    return nil
end

local function find_free_slot()
    local inv = get_inv_map()
    for b = string.byte("a"), string.byte("z") do
        local let = string.char(b)
        if not inv[let] then
            return let
        end
    end
    for b = string.byte("A"), string.byte("Z") do
        local let = string.char(b)
        if not inv[let] then
            return let
        end
    end
    return nil
end

local function adjust(from_slot, to_slot, count)
    local keys = meta("a")
    if count then
        keys = keys .. tostring(count) .. from_slot
    else
        keys = keys .. from_slot
    end
    keys = keys .. to_slot
    nh.pushkey(keys)
    nh.doturn(true)
end

local function adjust_cancel(from_slot, count)
    local keys = meta("a")
    if count then
        keys = keys .. tostring(count) .. from_slot
    else
        keys = keys .. from_slot
    end
    keys = keys .. "\027" -- ESC
    nh.pushkey(keys)
    nh.doturn(true)
end

-- -------------------------------------------------------------
-- Case 1: 空きスロットへの単一アイテム移動 (Move to empty slot)
-- -------------------------------------------------------------
u.clear_inventory()
u.giveobj(obj.new("rock"))
local rock = find_item_by_name("rock")
if not rock then
    error("Case 1 Setup failed: rock not found")
end
local from_let = rock.invlet
local to_let = find_free_slot()
if not to_let then
    error("Case 1 Setup failed: no free slot")
end

adjust(from_let, to_let)
local inv = get_inv_map()
if inv[from_let] ~= nil then
    error("Case 1 Failed: slot '" .. from_let .. "' should be empty after move")
end
if not inv[to_let] or inv[to_let].otyp_name ~= "rock" or inv[to_let].quan ~= 1 then
    error("Case 1 Failed: rock not moved to slot '" .. to_let .. "'")
end

-- -------------------------------------------------------------
-- Case 2: 異なるアイテム同士のスワップ (Swap two distinct items)
-- -------------------------------------------------------------
u.clear_inventory()
u.giveobj(obj.new("rock"))
u.giveobj(obj.new("dagger"))
local rock2 = find_item_by_name("rock")
local dagger2 = find_item_by_name("dagger")
if not rock2 or not dagger2 then
    error("Case 2 Setup failed: expected rock and dagger")
end
local r_let = rock2.invlet
local d_let = dagger2.invlet

adjust(r_let, d_let)
inv = get_inv_map()
if not inv[r_let] or inv[r_let].otyp_name ~= "dagger" then
    error("Case 2 Failed: dagger should now be at slot '" .. r_let .. "'")
end
if not inv[d_let] or inv[d_let].otyp_name ~= "rock" then
    error("Case 2 Failed: rock should now be at slot '" .. d_let .. "'")
end

-- -------------------------------------------------------------
-- Case 3: スタックの一部分割 (Split stack)
-- -------------------------------------------------------------
u.clear_inventory()
u.giveobj(obj.new("20 darts"))
local darts = find_item_by_name("dart")
if not darts or darts.quan ~= 20 then
    error("Case 3 Setup failed: expected 20 darts")
end
local dart_from = darts.invlet
local dart_to = find_free_slot()

adjust(dart_from, dart_to, 5)
inv = get_inv_map()
if not inv[dart_from] or inv[dart_from].quan ~= 15 then
    error("Case 3 Failed: remaining darts should be 15 at '" .. dart_from .. "'")
end
if not inv[dart_to] or inv[dart_to].quan ~= 5 then
    error("Case 3 Failed: split darts should be 5 at '" .. dart_to .. "'")
end

-- -------------------------------------------------------------
-- Case 4: 同種スタックの統合 (Merge compatible stacks)
-- -------------------------------------------------------------
-- Now dart_from has 15 darts, dart_to has 5 darts.
adjust(dart_to, dart_from)
inv = get_inv_map()
if inv[dart_to] ~= nil then
    error("Case 4 Failed: slot '" .. dart_to .. "' should be empty after merge")
end
if not inv[dart_from] or inv[dart_from].quan ~= 20 then
    error("Case 4 Failed: slot '" .. dart_from .. "' should have 20 darts after merge")
end

-- -------------------------------------------------------------
-- Case 5: 同一スロット指定による集約 (Collect into same slot)
-- -------------------------------------------------------------
local split_target = find_free_slot()
adjust(dart_from, split_target, 8)
inv = get_inv_map()
if not inv[dart_from] or inv[dart_from].quan ~= 12 or not inv[split_target] or inv[split_target].quan ~= 8 then
    error("Case 5 Setup failed: split before collect failed")
end

-- Adjust dart_from to dart_from (collects compatible stacks into dart_from)
adjust(dart_from, dart_from)
inv = get_inv_map()
if inv[split_target] ~= nil then
    error("Case 5 Failed: slot '" .. split_target .. "' should be emptied into '" .. dart_from .. "' by collect")
end
if not inv[dart_from] or inv[dart_from].quan ~= 20 then
    error("Case 5 Failed: slot '" .. dart_from .. "' should have 20 darts after collect")
end

-- -------------------------------------------------------------
-- Case 6: 占有枠への分割と既存アイテムの追い出し (Split into occupied slot bumping occupant)
-- -------------------------------------------------------------
u.clear_inventory()
u.giveobj(obj.new("20 darts"))
u.giveobj(obj.new("rock"))
darts = find_item_by_name("dart")
local bump_rock = find_item_by_name("rock")
if not darts or not bump_rock then
    error("Case 6 Setup failed: expected darts and rock")
end
local d_from = darts.invlet
local r_dest = bump_rock.invlet

-- Split 6 darts from d_from into occupied slot r_dest
adjust(d_from, r_dest, 6)
inv = get_inv_map()
if not inv[d_from] or inv[d_from].quan ~= 14 then
    error("Case 6 Failed: darts from-slot should have 14 darts")
end
if not inv[r_dest] or inv[r_dest].otyp_name ~= "dart" or inv[r_dest].quan ~= 6 then
    error("Case 6 Failed: destination slot should now have 6 darts")
end
-- Rock must have been bumped to an open slot
local rock_bumped = find_item_by_name("rock")
if not rock_bumped or rock_bumped.invlet == d_from or rock_bumped.invlet == r_dest then
    error("Case 6 Failed: rock was not bumped to a new open slot")
end

-- -------------------------------------------------------------
-- Case 7: 名前付きアイテムの統合条件 (Named item merge behavior)
-- -------------------------------------------------------------
u.clear_inventory()
u.giveobj(obj.new("10 arrows named silver"))
u.giveobj(obj.new("5 arrows"))
inv = get_inv_map()
local named_arrows, unnamed_arrows
for let, item in pairs(inv) do
    if item.otyp_name == "arrow" then
        if item.oname == "silver" then
            named_arrows = item
        else
            unnamed_arrows = item
        end
    end
end
if not named_arrows or not unnamed_arrows then
    error("Case 7 Setup failed: expected named and unnamed arrows")
end

-- Unnamed 'from' collecting into unnamed: should NOT collect named candidate
adjust(unnamed_arrows.invlet, unnamed_arrows.invlet)
inv = get_inv_map()
if not inv[named_arrows.invlet] or not inv[unnamed_arrows.invlet] then
    error("Case 7 Failed: unnamed collect should not merge named arrows")
end

-- Named 'from' collecting into named: collects unnamed candidate!
adjust(named_arrows.invlet, named_arrows.invlet)
inv = get_inv_map()
if inv[unnamed_arrows.invlet] ~= nil then
    error("Case 7 Failed: unnamed arrows should be merged into named arrows")
end
local final_named = inv[named_arrows.invlet]
if not final_named or final_named.quan ~= 15 or final_named.oname ~= "silver" then
    error("Case 7 Failed: final arrows quan should be 15 named silver")
end

-- -------------------------------------------------------------
-- Case 8: 金貨スロット制約 (Gold constraint)
-- -------------------------------------------------------------
u.clear_inventory()
u.giveobj(obj.new("rock"))
rock = find_item_by_name("rock")
if not rock then
    error("Case 8 Setup failed: rock not found")
end
local rock_slot = rock.invlet

-- Attempt to adjust rock to '$' slot
adjust(rock_slot, "$")
inv = get_inv_map()
if not inv[rock_slot] or inv[rock_slot].otyp_name ~= "rock" then
    error("Case 8 Failed: rock should still be at original slot after rejected gold move")
end
if inv["$"] ~= nil then
    error("Case 8 Failed: non-gold item should never be placed in '$' slot")
end

-- -------------------------------------------------------------
-- Case 9: キャンセル操作 (Cancel / ESC restores state)
-- -------------------------------------------------------------
u.clear_inventory()
u.giveobj(obj.new("20 darts"))
darts = find_item_by_name("dart")
if not darts or darts.quan ~= 20 then
    error("Case 9 Setup failed: expected 20 darts")
end

-- Start splitting 5 darts, but press ESC at destination prompt
adjust_cancel(darts.invlet, 5)
inv = get_inv_map()
local darts_canceled = inv[darts.invlet]
if not darts_canceled or darts_canceled.quan ~= 20 then
    error("Case 9 Failed: ESC should abort split and preserve 20 darts")
end

-- -------------------------------------------------------------
-- Case 10: インベントリ満杯時の分割失敗処理 (Knapsack full handling)
-- -------------------------------------------------------------
u.clear_inventory()
-- Fill slots with 52 items
u.giveobj(obj.new("20 darts"))
darts = find_item_by_name("dart")
for i = 2, 52 do
    u.giveobj(obj.new("rock named r" .. tostring(i)))
end

local total_items
inv, total_items = get_inv_map()
if total_items ~= 52 then
    error("Case 10 Setup failed: expected 52 inventory items, got " .. tostring(total_items))
end

-- Pick any rock slot
local target_rock
for let, item in pairs(inv) do
    if item.otyp_name == "rock" then
        target_rock = item
        break
    end
end
if not target_rock then
    error("Case 10 Setup failed: rock not found")
end

-- Split darts into occupied rock slot when knapsack is full
adjust(darts.invlet, target_rock.invlet, 5)
inv, total_items = get_inv_map()
if total_after ~= nil and total_items ~= 52 then
    error("Case 10 Failed: inventory count changed after failed split")
end
local darts_full = inv[darts.invlet]
if not darts_full or darts_full.quan ~= 20 then
    error("Case 10 Failed: darts not preserved at 20 after failed split")
end

-- -------------------------------------------------------------
-- All tests completed successfully!
-- -------------------------------------------------------------
u.clear_inventory()
nh.debug_flags({ prevent_pline = false })
nh.impossible(">>> TEST_ADJUST_LUA_ALL_10_TESTS_PASSED <<<")
pline("test_adjust: ALL 10 TESTS PASSED SUCCESSFULLY!")
