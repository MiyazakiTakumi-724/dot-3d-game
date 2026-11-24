extends GutTest
## 武器と防具の持ち物と装備（design.md 7章のランク、10章の死んだときの扱い、11章のインベントリ）。

var eq: Equipment

func before_each():
	eq = Equipment.new()

func test_starts_with_rank1_ball_only():
	assert_true(eq.has(Equipment.Slot.BALL, 1))
	assert_eq(eq.effective(Equipment.Slot.BALL), 1)
	assert_eq(eq.effective(Equipment.Slot.SWORD), 0)
	assert_eq(eq.ranks(Equipment.Slot.SWORD), [])

func test_gain_and_equip_higher_rank():
	assert_false(eq.equip(Equipment.Slot.BALL, 2))
	eq.gain(Equipment.Slot.BALL, 2)
	assert_eq(eq.ranks(Equipment.Slot.BALL), [1, 2])
	assert_eq(eq.effective(Equipment.Slot.BALL), 1)  # 拾っただけでは替えない
	assert_true(eq.equip(Equipment.Slot.BALL, 2))
	assert_eq(eq.effective(Equipment.Slot.BALL), 2)

func test_first_weapon_of_a_kind_is_equipped():
	eq.gain(Equipment.Slot.SWORD, 1)
	assert_eq(eq.effective(Equipment.Slot.SWORD), 1)

func test_attack_bonus_by_rank():
	assert_eq(Equipment.rank_attack(0), 0)
	assert_eq(Equipment.rank_attack(1), 0)
	assert_eq(Equipment.rank_attack(2), Equipment.ATTACK_PER_RANK)
	assert_eq(Equipment.rank_attack(3), Equipment.ATTACK_PER_RANK * 2)

## 死ぬと最低ランク（ランク1）以外は墓石へ。装備の好みは残り、取り返すと元に戻る
func test_death_keeps_rank1_and_grave_returns_the_rest():
	eq.gain(Equipment.Slot.BALL, 2)
	eq.equip(Equipment.Slot.BALL, 2)
	eq.gain(Equipment.Slot.SWORD, 1)
	eq.gain(Equipment.Slot.SWORD, 3)
	var taken := eq.take_for_grave()
	assert_eq(eq.ranks(Equipment.Slot.BALL), [1])
	assert_eq(eq.ranks(Equipment.Slot.SWORD), [1])
	assert_eq(eq.effective(Equipment.Slot.BALL), 1)
	eq.restore(taken)
	assert_eq(eq.ranks(Equipment.Slot.SWORD), [1, 3])
	assert_eq(eq.effective(Equipment.Slot.BALL), 2)

func test_without_rank1_nothing_is_kept():
	eq.gain(Equipment.Slot.BOW, 2)
	eq.take_for_grave()
	assert_eq(eq.ranks(Equipment.Slot.BOW), [])
	assert_eq(eq.effective(Equipment.Slot.BOW), 0)

func test_gain_same_rank_twice_is_one():
	eq.gain(Equipment.Slot.SWORD, 1)
	eq.gain(Equipment.Slot.SWORD, 1)
	assert_eq(eq.ranks(Equipment.Slot.SWORD), [1])

## 防具は1つの枠だけ（頭・体・足に分けない）。最大いのちに、ランク1つにつき HP_PER_ARMOR_RANK 足される【提案】
func test_armor_adds_hp():
	assert_eq(Equipment.ARMOR, [Equipment.Slot.ARMOR])
	assert_eq(eq.armor_hp(), 0)
	eq.gain(Equipment.Slot.ARMOR, 1)
	eq.gain(Equipment.Slot.ARMOR, 2)
	assert_eq(eq.armor_hp(), Equipment.HP_PER_ARMOR_RANK * 1)
	eq.equip(Equipment.Slot.ARMOR, 2)
	assert_eq(eq.armor_hp(), Equipment.HP_PER_ARMOR_RANK * 2)

## 杖：最初から無の杖（ランク1）を持っている。手に持つ杖は種類で選ぶ
func test_staffs():
	assert_eq(eq.effective(Equipment.Slot.STAFF_NONE), 1)
	assert_eq(eq.staff_slot(), Equipment.Slot.STAFF_NONE)
	eq.gain(Equipment.Slot.STAFF_FIRE, 3)
	assert_eq(eq.staff_slot(), Equipment.Slot.STAFF_NONE)  # 拾っただけでは持ち替えない
	assert_true(eq.choose_staff(Equipment.Slot.STAFF_FIRE))
	assert_eq(eq.staff_slot(), Equipment.Slot.STAFF_FIRE)
	assert_false(eq.choose_staff(Equipment.Slot.SWORD))
	# 炎の杖（ランク3）が墓石に入ると、無の杖に戻る
	var taken := eq.take_for_grave()
	assert_eq(taken[Equipment.Slot.STAFF_FIRE], [3])
	assert_eq(eq.staff_slot(), Equipment.Slot.STAFF_NONE)
	eq.restore(taken)
	assert_eq(eq.staff_slot(), Equipment.Slot.STAFF_FIRE)
