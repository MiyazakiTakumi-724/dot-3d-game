extends GutTest
## 敵の種類（2026-11-25 に増やした）と落とし物、ボスの数値。

func test_every_kind_has_data():
	for k in EnemyKind.Kind.values():
		assert_true(EnemyKind.DATA.has(k), str(k))
		assert_ne(EnemyKind.name_of(k), "")
		assert_gt(EnemyKind.hp(k), 0)
		assert_gt(EnemyKind.attack(k), 0)
	assert_gte(EnemyKind.Kind.size(), 9)

func test_old_kinds_keep_their_numbers():
	assert_eq([EnemyKind.hp(EnemyKind.Kind.WEAK), EnemyKind.attack(EnemyKind.Kind.WEAK)], [5, 3])
	assert_eq([EnemyKind.hp(EnemyKind.Kind.MELEE), EnemyKind.attack(EnemyKind.Kind.MELEE)], [10, 4])
	assert_eq(EnemyKind.climb(EnemyKind.Kind.MELEE), 1)
	assert_true(EnemyKind.shoots(EnemyKind.Kind.SHOOTER))
	assert_false(EnemyKind.contact(EnemyKind.Kind.MELEE))

## 盾持ちは正面の左右60°からの攻撃を防ぐ。背中からは通る
func test_shield_blocks_only_the_front():
	var k := EnemyKind.Kind.SHIELD
	var at := Vector2(50, 50)
	assert_true(EnemyKind.blocks(k, Vector2.RIGHT, at, at + Vector2(30, 5)))
	assert_false(EnemyKind.blocks(k, Vector2.RIGHT, at, at + Vector2(-30, 0)))
	assert_false(EnemyKind.blocks(k, Vector2.RIGHT, at, at + Vector2(0, 30)))
	assert_false(EnemyKind.blocks(EnemyKind.Kind.MELEE, Vector2.RIGHT, at, at + Vector2(30, 0)))

## 亡霊は足音を聞く。しゃがんで歩くと気づかれにくい
func test_ghost_hears_footsteps():
	var k := EnemyKind.Kind.GHOST
	assert_gt(EnemyKind.hearing(k, false), EnemyKind.hearing(k, true))
	assert_eq(EnemyKind.hearing(EnemyKind.Kind.MELEE, true), EnemyKind.chase_range(EnemyKind.Kind.MELEE))

func test_loot_always_gives_money_and_region_materials():
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var mats := {}
	for i in 200:
		var drops := Loot.roll("山岳", 2, rng)
		assert_eq(drops[0][0], "money")
		assert_gt(drops[0][1], 0)
		for d in drops.slice(1):
			assert_true(ItemCatalog.known(d[0]), d[0])
			if ItemCatalog.is_material(d[0]):
				mats[d[0]] = true
	assert_true(mats.has("iron_ore"))
	assert_false(mats.has("obsidian"))

func test_gear_pool_by_region():
	for id in Loot.gear_pool("はじまりの地"):
		assert_eq(ItemCatalog.rank(id), 1, id)
	assert_true("sword_frost" in Loot.gear_pool("神秘の塔"))
	assert_false("sword_frost" in Loot.gear_pool("山岳"))

func test_bosses_drop_materials():
	for b in BossKind.DATA:
		var drops := BossKind.drops(b)
		assert_gt(drops.size(), 0, b)
		var has_mat := false
		for d in drops:
			assert_true(ItemCatalog.known(d[0]), d[0])
			has_mat = has_mat or ItemCatalog.is_material(d[0])
		assert_true(has_mat, b)
	assert_eq(BossKind.group("双子（左）"), "双子")
	assert_gt(BossKind.hp("岩転がしの巨人", 2), BossKind.hp("岩転がしの巨人", 0))

# ---- 敵の動き（EnemyWalker）

func _flat_map(w := 10, h := 5) -> HeightMap:
	var m := HeightMap.new(Vector2i(w, h))
	return m

## 遅くする（氷・霜）：速さが半分になり、時間で戻る
func test_slow_halves_speed():
	var m := _flat_map()
	var w := EnemyWalker.new(m, Vector2i(2, 2), Vector2.RIGHT, 5, 0)
	var x0 := w.pos.x
	w.step(1.0)
	var normal := w.pos.x - x0
	w.slow(2.0)
	assert_true(w.is_slowed())
	x0 = w.pos.x
	w.step(1.0)
	assert_almost_eq(w.pos.x - x0, normal * 0.5, 0.01)
	w.step(1.5)
	assert_false(w.is_slowed())

## 速さの倍率
func test_speed_mult():
	var m := _flat_map()
	var w := EnemyWalker.new(m, Vector2i(2, 2), Vector2.RIGHT, 5, 0)
	w.speed_mult = 2.0
	var x0 := w.pos.x
	w.step(0.5)
	assert_almost_eq(w.pos.x - x0, EnemyWalker.SPEED, 0.01)

## 飛ぶ敵は水・奈落・高い段差の上も進む
func test_flyer_crosses_water_and_cliffs():
	var m := _flat_map()
	m.set_height(Vector2i(4, 2), 5)
	m.set_water(Vector2i(5, 2), true)
	var w := EnemyWalker.new(m, Vector2i(3, 2), Vector2.RIGHT, 5, 0)
	assert_false(w.can_enter(Vector2i(4, 2)))
	w.flying = true
	assert_true(w.can_enter(Vector2i(4, 2)))
	assert_true(w.can_enter(Vector2i(5, 2)))
	assert_false(w.can_enter(Vector2i(-1, 2)))

## 寄ってくる距離は敵ごと。段差を登らない敵（climb 0）でも、同じ高さなら寄る
func test_chase_range_per_kind():
	var m := _flat_map()
	var w := EnemyWalker.new(m, Vector2i(2, 2), Vector2.RIGHT, 5, 0)
	w.chase_range = 80.0
	w.chase(w.pos + Vector2(70, 0) * Vector2(-1, 0), 0)
	assert_eq(w.dir, Vector2.LEFT)
