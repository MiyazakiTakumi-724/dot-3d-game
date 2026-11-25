extends GutTest
## 品物の一覧（2026-11-25 ユーザーの指示：ランク5まで、1つのランクに複数の種類、それぞれに特色、ランク1は1種類で特色なし、
## ボスの落とし物はランク4、宝箱だけの装備はない、ランク5は作るだけ、最初は鉄球だけ、素材と道具もいろいろ）。

const SLOTS := [Equipment.Slot.BALL, Equipment.Slot.SWORD, Equipment.Slot.BOW, Equipment.Slot.STAFF, Equipment.Slot.ARMOR]

func test_items_have_valid_rank_and_slot():
	for id in ItemCatalog.ITEMS:
		assert_between(ItemCatalog.rank(id), 1, 5, id)
		assert_true(Equipment.NAMES.has(ItemCatalog.slot(id)), id)
		assert_ne(ItemCatalog.name_of(id), "", id)

func test_rank1_is_one_plain_item_per_slot():
	for s in SLOTS:
		var list := ItemCatalog.of(s, 1)
		assert_eq(list.size(), 1, str(s))
		assert_eq(ItemCatalog.traits(list[0]), {}, list[0])

func test_higher_ranks_have_several_kinds_each_with_a_trait():
	for s in SLOTS:
		for r in range(2, 6):
			var list := ItemCatalog.of(s, r)
			assert_gte(list.size(), 2, "%s rank %d" % [s, r])
			var seen := {}
			for id in list:
				# 特色：traits か、杖なら魔法の組み合わせ（同じランクで違うもの）
				var key := str(ItemCatalog.traits(id)) + str(ItemCatalog.spells(id))
				assert_true(ItemCatalog.traits(id).size() > 0 or s == Equipment.Slot.STAFF, id)
				assert_false(seen.has(key), id)
				seen[key] = true
				assert_ne(ItemCatalog.trait_of(id), "" if s != Equipment.Slot.STAFF else "x", id)

func test_rank5_is_crafted_only():
	for id in ItemCatalog.ITEMS:
		if ItemCatalog.rank(id) == 5:
			assert_eq(ItemCatalog.sources(id), ["craft"], id)
			assert_true(Recipes.makes(id), id)
			assert_false(Shop.sells(id), id)
			assert_false(id in Loot.gear_pool("神秘の塔"), id)

func test_boss_drops_are_rank4():
	for b in BossKind.DATA:
		for d in BossKind.drops(b):
			if ItemCatalog.exists(d[0]):
				assert_eq(ItemCatalog.rank(d[0]), 4, b)

func test_no_chest_only_gear_and_sources_are_real():
	var boss_items := {}
	for b in BossKind.DATA:
		for d in BossKind.drops(b):
			boss_items[d[0]] = true
	var dropped := {}
	for region in Loot.REGION_GEAR_RANKS:
		for id in Loot.gear_pool(region):
			dropped[id] = true
	for id in ItemCatalog.ITEMS:
		var src := ItemCatalog.sources(id)
		assert_false(src == ["chest"], id)
		assert_eq("shop" in src, Shop.sells(id), id + " shop")
		assert_eq("craft" in src, Recipes.makes(id), id + " craft")
		assert_eq("boss" in src, boss_items.has(id), id + " boss")
		assert_eq("drop" in src, dropped.has(id), id + " drop")
		assert_true(src.size() > 0, id)

## 手に入れ方が1つだけ（落とし物か作るだけ）の装備も、たくさんある装備もある
func test_some_gear_has_one_source_and_some_many():
	var few := 0
	var many := 0
	for id in ItemCatalog.ITEMS:
		var src := ItemCatalog.sources(id).filter(func(x): return x != "chest" and x != "start")
		if src.size() == 1 and (src[0] == "boss" or src[0] == "craft"):
			few += 1
		if src.size() >= 3:
			many += 1
	assert_gte(few, 5)
	assert_gte(many, 5)

func test_materials_and_tools_have_variety():
	assert_gte(ItemCatalog.MATERIALS.size(), 12)
	assert_gte(ItemCatalog.TOOLS.size(), 7)
	assert_eq(ItemCatalog.ARROWS.size(), Arrow.KINDS.size())
	for k in Arrow.KINDS:
		assert_true(ItemCatalog.is_arrow(Arrow.ID[k]))

## 杖の魔法の数：ランク1〜2は1つ、3は1〜2、4は2つ、5は2〜3
func test_spell_count_by_rank():
	assert_eq(ItemCatalog.spell_range(1), Vector2i(1, 1))
	assert_eq(ItemCatalog.spell_range(2), Vector2i(1, 1))
	assert_eq(ItemCatalog.spell_range(3), Vector2i(1, 2))
	assert_eq(ItemCatalog.spell_range(4), Vector2i(2, 2))
	assert_eq(ItemCatalog.spell_range(5), Vector2i(2, 3))

func test_every_staff_follows_spell_count_rule():
	for id in ItemCatalog.ITEMS:
		if ItemCatalog.slot(id) != Equipment.Slot.STAFF:
			continue
		var r := ItemCatalog.spell_range(ItemCatalog.rank(id))
		assert_between(ItemCatalog.spells(id).size(), r.x, r.y, id)

func test_usable_spells():
	assert_eq(ItemCatalog.usable_spells("staff_star", 1), [Magic.Spell.FIREBALL])
	assert_eq(ItemCatalog.usable_spells("staff_star", 3).size(), 3)
	assert_eq(ItemCatalog.usable_spells("staff_fire_3", 3).size(), 2)
	assert_eq(ItemCatalog.usable_spells("", 3), [])

func test_label_and_traits():
	assert_eq(ItemCatalog.label("sword_1"), "剣")
	assert_eq(ItemCatalog.label("staff_fire_3"), "炎の杖★3")
	assert_eq(ItemCatalog.label("hide"), "獣の皮")
	assert_eq(ItemCatalog.trait_of("armor_travel"), "足＋10%")
	assert_eq(ItemCatalog.trait_value("sword_light", "rate", 1.0), 1.3)
	assert_eq(ItemCatalog.trait_value("sword_1", "rate", 1.0), 1.0)
	assert_eq(ItemCatalog.trait_of("potion"), "いのち＋6")
