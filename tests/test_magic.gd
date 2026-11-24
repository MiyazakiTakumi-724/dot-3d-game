extends GutTest
## 魔法（2026-11-24 決定）：装備する杖で使える魔法が決まる。杖のランク1は1つ、2は2つ、3以上は3つ。
## 無の杖はランク1だけで、無の弾の1つ。ステータスの「魔法」で、同時に使える数（1〜3）が決まる。

func test_none_staff_has_one_spell():
	assert_eq(Magic.staff_spells(Equipment.Slot.STAFF_NONE, 1), [Magic.Spell.NULL_BOLT])

func test_fire_staff_spells_grow_with_rank():
	var s := Equipment.Slot.STAFF_FIRE
	assert_eq(Magic.staff_spells(s, 1), [Magic.Spell.FIREBALL])
	assert_eq(Magic.staff_spells(s, 2), [Magic.Spell.FIREBALL, Magic.Spell.FIRE_PILLAR])
	assert_eq(Magic.staff_spells(s, 3).size(), 3)
	assert_eq(Magic.staff_spells(s, 6).size(), 3)
	assert_eq(Magic.staff_spells(s, 0), [])

## 杖に魔法が3つあっても、ステータスで使える数までしか使えない
func test_usable_limited_by_spell_slots():
	var s := Equipment.Slot.STAFF_FIRE
	assert_eq(Magic.usable(s, 3, 1), [Magic.Spell.FIREBALL])
	assert_eq(Magic.usable(s, 3, 2).size(), 2)
	assert_eq(Magic.usable(s, 1, 3), [Magic.Spell.FIREBALL])

## 炎の雨は、高い所から使うほど広い
func test_rain_radius_grows_with_height():
	assert_eq(Magic.rain_radius(2, 2), Magic.RAIN_BASE_RADIUS)
	assert_eq(Magic.rain_radius(4, 2), Magic.RAIN_BASE_RADIUS + 2 * Magic.RAIN_RADIUS_PER_LEVEL)
	assert_eq(Magic.rain_radius(0, 2), Magic.RAIN_BASE_RADIUS)

## 魔法ごとに待ち時間がある。ほかの魔法は（少しの間をおけば）使える
func test_spell_cooldown():
	var m := Magic.new()
	var mana := Mana.new()
	mana.max_value = 200
	mana.value = 200.0
	assert_true(m.try_cast(Magic.Spell.FIREBALL, mana))
	m.update(Magic.INTERVAL)
	assert_false(m.try_cast(Magic.Spell.FIREBALL, mana))
	assert_gt(m.remaining(Magic.Spell.FIREBALL), 0.0)
	assert_true(m.try_cast(Magic.Spell.FIRE_PILLAR, mana))
	m.update(Magic.COOLDOWN[Magic.Spell.FIREBALL])
	assert_eq(m.remaining(Magic.Spell.FIREBALL), 0.0)
	assert_true(m.try_cast(Magic.Spell.FIREBALL, mana))

## マナの燃費は悪い：満タン（50）から無の弾は5発、炎の雨は1回まで【提案】
func test_mana_costs_are_high():
	assert_eq(Mana.BASE_MAX / Magic.COST[Magic.Spell.NULL_BOLT], 5)
	assert_eq(Mana.BASE_MAX / Magic.COST[Magic.Spell.FIRE_RAIN], 1)

## 使うとマナが減り、少しの間は次を使えない。マナが足りなければ使えない
func test_cast_spends_mana_and_waits():
	var m := Magic.new()
	var mana := Mana.new()
	assert_true(m.try_cast(Magic.Spell.FIRE_RAIN, mana))
	assert_eq(mana.value, Mana.BASE_MAX - Magic.COST[Magic.Spell.FIRE_RAIN])
	assert_false(m.try_cast(Magic.Spell.NULL_BOLT, mana))
	m.update(100.0)
	mana.value = 3.0
	assert_false(m.try_cast(Magic.Spell.NULL_BOLT, mana))
	assert_eq(mana.value, 3.0)

## ホイールで、使える魔法の中から選ぶ（端は回り込む）
func test_select_cycles_spells():
	var m := Magic.new()
	var list := [Magic.Spell.FIREBALL, Magic.Spell.FIRE_PILLAR]
	assert_eq(m.current(list), Magic.Spell.FIREBALL)
	m.cycle(1, list)
	assert_eq(m.current(list), Magic.Spell.FIRE_PILLAR)
	m.cycle(1, list)
	assert_eq(m.current(list), Magic.Spell.FIREBALL)
	m.cycle(-1, list)
	assert_eq(m.current(list), Magic.Spell.FIRE_PILLAR)
	# 使える数が減ったら、範囲の中に戻す
	assert_eq(m.current([Magic.Spell.FIREBALL]), Magic.Spell.FIREBALL)
