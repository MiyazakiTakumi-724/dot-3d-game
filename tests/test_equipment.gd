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
