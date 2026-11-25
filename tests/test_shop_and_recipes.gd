extends GutTest
## お店で買う・鍛冶屋で作る・持ち物の数（2026-11-25 の設計 2・3章）。

var inv: Inventory

func before_each():
	inv = Inventory.new()

func _row(shop: String, id: String) -> int:
	for i in Shop.STOCK[shop].size():
		if Shop.STOCK[shop][i][0] == id:
			return i
	return -1

func test_buy_needs_money_and_takes_it():
	var i := _row("weapon", "sword_1")
	assert_false(Shop.buy(inv, "weapon", i))
	inv.money = 100
	assert_true(Shop.buy(inv, "weapon", i))
	assert_eq(inv.money, 100 - Shop.STOCK["weapon"][i][1])
	assert_true(inv.equipment.has("sword_1"))
	assert_false(Shop.buy(inv, "weapon", i))  # もう持っている

func test_buy_counted_items_in_bundles():
	inv.money = 100
	assert_true(Shop.buy(inv, "tool", _row("tool", "arrow")))
	assert_eq(inv.count("arrow"), 10)
	assert_true(Shop.buy(inv, "tool", _row("tool", "potion")))
	assert_true(Shop.buy(inv, "tool", _row("tool", "potion")))
	assert_eq(inv.count("potion"), 2)

func test_town_sells_every_rank1_weapon():
	for id in ["sword_1", "bow_1", "staff_none_1", "armor_1"]:
		assert_gte(_row("weapon", id), 0, id)

func test_every_shop_item_is_known():
	for k in Shop.STOCK:
		assert_true(Shop.NAMES.has(k), k)
		for row in Shop.STOCK[k]:
			assert_true(ItemCatalog.known(row[0]), row[0])
			assert_gt(row[1], 0)

func test_every_recipe_uses_known_materials():
	for r in Recipes.LIST:
		assert_true(ItemCatalog.known(r[0]), r[0])
		for m in r[2]:
			assert_true(ItemCatalog.is_material(m), "%s %s" % [r[0], m])

func _recipe(id: String) -> int:
	for i in Recipes.LIST.size():
		if Recipes.LIST[i][0] == id:
			return i
	return -1

func test_make_takes_materials_and_money():
	var i := _recipe("sword_1")
	assert_false(Recipes.make(inv, i))
	inv.add("wood", 3)
	inv.add("scrap", 2)
	inv.money = 15
	assert_true(Recipes.can_make(inv, i))
	assert_true(Recipes.make(inv, i))
	assert_eq([inv.count("wood"), inv.count("scrap"), inv.money], [1, 0, 5])
	assert_true(inv.equipment.has("sword_1"))
	assert_false(Recipes.can_make(inv, i))  # もう持っている

func test_make_arrows_in_bundles():
	inv.add("wood", 1)
	inv.add("scrap", 1)
	assert_true(Recipes.make(inv, _recipe("arrow")))
	assert_eq(inv.count("arrow"), 10)
	assert_eq(Recipes.cost_text(_recipe("arrow")), "丈夫な枝1 鉄くず1")

func test_rank5_needs_boss_materials():
	for r in Recipes.LIST:
		if ItemCatalog.rank(r[0]) == 5:
			assert_true(r[2].has("star_shard"), r[0])
			var boss_mat := false
			for m in r[2]:
				boss_mat = boss_mat or ItemCatalog.MATERIALS[m]["where"] in BossKind.DATA or m == "giant_core"
			assert_true(boss_mat, r[0])

func test_inventory_counts_and_tools():
	assert_eq(inv.current_tool(), "")
	inv.add("bomb", 2)
	inv.add("potion", 1)
	assert_eq(inv.tools(), ["potion", "bomb"])
	assert_eq(inv.current_tool(), "potion")
	inv.cycle_tool(1)
	assert_eq(inv.current_tool(), "bomb")
	assert_true(inv.take("bomb", 2))
	assert_false(inv.take("bomb"))
	assert_eq(inv.current_tool(), "potion")
	assert_false(inv.add("no_such", 1))
	inv.add("money", 7)
	assert_eq(inv.money, 7)
	inv.add("hide", 2)
	assert_eq(inv.materials(), ["hide"])

func test_buffs_wear_off():
	var b := Buffs.new()
	b.add("atk", 3, 30.0)
	b.add("atk", 2, 10.0)
	assert_eq(b.value("atk"), 3.0)
	b.update(29.0)
	assert_eq(b.value("atk"), 3.0)
	b.update(2.0)
	assert_eq(b.value("atk"), 0.0)
	assert_eq(b.active(), [])
