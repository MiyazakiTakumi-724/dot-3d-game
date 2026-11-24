extends GutTest
## 装備の品物の一覧（2026-11-24 決定：ランクは10まで。杖の魔法の数はランクで決まる範囲に入る）。

func test_items_have_valid_rank_and_slot():
	for id in ItemCatalog.ITEMS:
		var r := ItemCatalog.rank(id)
		assert_between(r, Equipment.MIN_RANK, Equipment.MAX_RANK, id)
		assert_true(Equipment.NAMES.has(ItemCatalog.slot(id)), id)
		assert_ne(ItemCatalog.name_of(id), "", id)

## 杖の魔法の数：ランク1は1つ、2〜3は1つか2つ、4〜6は2つ、7〜8は2つか3つ、9〜10は3つ
func test_spell_count_by_rank():
	assert_eq(ItemCatalog.spell_range(1), Vector2i(1, 1))
	assert_eq(ItemCatalog.spell_range(2), Vector2i(1, 2))
	assert_eq(ItemCatalog.spell_range(3), Vector2i(1, 2))
	assert_eq(ItemCatalog.spell_range(5), Vector2i(2, 2))
	assert_eq(ItemCatalog.spell_range(8), Vector2i(2, 3))
	assert_eq(ItemCatalog.spell_range(10), Vector2i(3, 3))

func test_every_staff_follows_spell_count_rule():
	for id in ItemCatalog.ITEMS:
		if ItemCatalog.slot(id) != Equipment.Slot.STAFF:
			continue
		var n := ItemCatalog.spells(id).size()
		var range := ItemCatalog.spell_range(ItemCatalog.rank(id))
		assert_between(n, range.x, range.y, id)

func test_none_staff_and_fire_staffs():
	assert_eq(ItemCatalog.spells("staff_none_1"), [Magic.Spell.NULL_BOLT])
	assert_eq(ItemCatalog.name_of("staff_none_1"), "無の杖")
	assert_eq(ItemCatalog.spells("staff_fire_3"), [Magic.Spell.FIREBALL, Magic.Spell.FIRE_PILLAR])
	assert_eq(ItemCatalog.spells("staff_fire_9").size(), 3)

## ステータスの魔法の数まで、杖の魔法を前から使える
func test_usable_spells():
	assert_eq(ItemCatalog.usable_spells("staff_fire_9", 1), [Magic.Spell.FIREBALL])
	assert_eq(ItemCatalog.usable_spells("staff_fire_9", 3).size(), 3)
	assert_eq(ItemCatalog.usable_spells("staff_fire_3", 3).size(), 2)
	assert_eq(ItemCatalog.usable_spells("", 3), [])

func test_label():
	assert_eq(ItemCatalog.label("sword_1"), "剣")
	assert_eq(ItemCatalog.label("staff_fire_3"), "炎の杖★3")
