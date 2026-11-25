extends GutTest
## 武器と防具の持ち物と装備（design.md 7章のランク、10章の死んだときの扱い、11章のインベントリ）。
## 装備は「品物」（ItemCatalog の id）で持つ。同じ種類・同じランクでも、効果の違う品物を持てる（2026-11-24 決定）。

var eq: Equipment

func before_each():
	eq = Equipment.new()

## 最初は鉄球だけ（2026-11-25）
func test_starts_with_only_the_ball():
	assert_true(eq.has("ball_1"))
	assert_eq(eq.effective(Equipment.Slot.BALL), 1)
	assert_eq(eq.current(Equipment.Slot.STAFF), "")
	assert_eq(eq.effective(Equipment.Slot.ARMOR), 0)
	assert_eq(eq.effective(Equipment.Slot.SWORD), 0)
	assert_eq(eq.items(Equipment.Slot.SWORD), [])

func test_gain_and_equip_higher_rank():
	assert_false(eq.equip("ball_heavy"))
	assert_true(eq.gain("ball_heavy"))
	assert_eq(eq.items(Equipment.Slot.BALL), ["ball_1", "ball_heavy"])
	assert_eq(eq.effective(Equipment.Slot.BALL), 1)  # 拾っただけでは替えない
	assert_true(eq.equip("ball_heavy"))
	assert_eq(eq.effective(Equipment.Slot.BALL), 2)

func test_unknown_item_is_ignored():
	assert_false(eq.gain("no_such_item"))

func test_first_weapon_of_a_kind_is_equipped():
	eq.gain("sword_1")
	assert_eq(eq.effective(Equipment.Slot.SWORD), 1)

func test_attack_bonus_by_rank():
	assert_eq(Equipment.rank_attack(0), 0)
	assert_eq(Equipment.rank_attack(1), 0)
	assert_eq(Equipment.rank_attack(2), Equipment.ATTACK_PER_RANK)
	assert_eq(Equipment.rank_attack(3), Equipment.ATTACK_PER_RANK * 2)

## 死ぬと最低ランク（ランク1）以外は墓石へ。装備の好みは残り、取り返すと元に戻る
func test_death_keeps_rank1_and_grave_returns_the_rest():
	eq.gain("ball_heavy")
	eq.equip("ball_heavy")
	eq.gain("sword_1")
	eq.gain("staff_none_1")
	eq.gain("staff_fire_3")
	eq.equip("staff_fire_3")
	var taken := eq.take_for_grave()
	assert_eq(taken, ["ball_heavy", "staff_fire_3"])
	assert_eq(eq.items(Equipment.Slot.BALL), ["ball_1"])
	assert_eq(eq.effective(Equipment.Slot.BALL), 1)
	assert_eq(eq.current(Equipment.Slot.STAFF), "staff_none_1")  # 無の杖に戻る
	assert_eq(eq.items(Equipment.Slot.SWORD), ["sword_1"])
	eq.restore(taken)
	assert_eq(eq.effective(Equipment.Slot.BALL), 2)
	assert_eq(eq.current(Equipment.Slot.STAFF), "staff_fire_3")

func test_same_item_twice_is_kept_once():
	eq.gain("sword_1")
	assert_false(eq.gain("sword_1"))
	assert_eq(eq.items(Equipment.Slot.SWORD), ["sword_1"])

## 防具は1つの枠だけ（頭・体・足に分けない）。最大いのちに、ランク1つにつき HP_PER_ARMOR_RANK 足される【提案】
func test_armor_adds_hp():
	assert_eq(Equipment.ARMOR, [Equipment.Slot.ARMOR])
	assert_eq(eq.armor_hp(), 0)
	eq.gain("armor_1")
	assert_eq(eq.armor_hp(), Equipment.HP_PER_ARMOR_RANK)
	eq.gain("armor_dragon")
	eq.equip("armor_dragon")
	assert_eq(eq.armor_hp(), Equipment.HP_PER_ARMOR_RANK * 5 + 10)
	assert_eq(eq.armor_bonus("def"), 3.0)
	assert_eq(eq.trait_of(Equipment.Slot.ARMOR, "regen"), 1)

## 杖は1つの枠で、持っている杖（無の杖・炎の杖…）から選ぶ
func test_staffs_share_one_slot():
	assert_eq(Equipment.WEAPONS, [Equipment.Slot.BALL, Equipment.Slot.SWORD, Equipment.Slot.BOW, Equipment.Slot.STAFF])
	eq.gain("staff_none_1")
	eq.gain("staff_fire_3")
	assert_eq(eq.current(Equipment.Slot.STAFF), "staff_none_1")  # 拾っただけでは持ち替えない
	assert_eq(eq.items(Equipment.Slot.STAFF), ["staff_none_1", "staff_fire_3"])
	assert_true(eq.equip("staff_fire_3"))
	assert_eq(eq.effective(Equipment.Slot.STAFF), 3)

## 並びはランクの低い順。同じランクなら品物の一覧の順（無の杖が先）
func test_items_sorted_by_rank_then_catalog():
	eq.gain("staff_star")
	eq.gain("staff_ice_2")
	eq.gain("staff_fire_2")
	eq.gain("staff_none_1")
	assert_eq(eq.items(Equipment.Slot.STAFF), ["staff_none_1", "staff_fire_2", "staff_ice_2", "staff_star"])

## 2026-11-25 夜（2回目の直し）：装備のレベル制限はやめた。持っていればどれでも装備できる
## （強い装備は、強い敵だけが落とす素材がないと作れない。Loot.LEVEL_MATERIALS）
func test_no_level_gate_on_equipping():
	var eq := Equipment.new()
	assert_true(eq.gain("sword_1"))
	assert_true(eq.gain("sword_flame"))
	assert_true(eq.equip("sword_flame"))
	assert_eq(eq.current(Equipment.Slot.SWORD), "sword_flame")
	var eq2 := Equipment.new()
	eq2.gain("bow_wind")
	assert_eq(eq2.current(Equipment.Slot.BOW), "bow_wind", "はじめて手に入れたランク4もすぐ装備する")
