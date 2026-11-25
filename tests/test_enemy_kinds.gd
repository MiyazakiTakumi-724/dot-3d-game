extends GutTest
## 敵の種類（2026-11-25 に増やした）と落とし物、ボスの数値。

func test_every_kind_has_data():
	for k in EnemyKind.Kind.values():
		assert_true(EnemyKind.DATA.has(k), str(k))
		assert_ne(EnemyKind.name_of(k), "")
		assert_gt(EnemyKind.hp(k), 0)
		assert_gt(EnemyKind.attack(k), 0)
	assert_gte(EnemyKind.Kind.size(), 15)

## 2026-11-25 夜：基準の数値を上げた。主人公の剣（ランク1）で何回も当てないと倒れない
func test_enemies_need_many_hits():
	var sword := Damage.sword(PlayerStats.BASE_ATTACK, 0, 0)
	for k in EnemyKind.Kind.values():
		if k == EnemyKind.Kind.WASP:
			continue  # 蜂は小さくて弱い（数で来る）
		assert_gte(ceili(EnemyKind.hp(k) / float(sword)), 4, EnemyKind.name_of(k))
	assert_gte(PlayerStats.BASE_HP / EnemyKind.attack(EnemyKind.Kind.WEAK), 4, "スライムには何回か当たっても平気")

## 浮いている敵（コウモリ・蜂）には剣と鉄球が当たらない。甲虫はひっくり返すまでかたい
func test_hit_rules():
	var at := Vector2(50, 50)
	var from := at + Vector2(20, 0)
	for k in [EnemyKind.Kind.FLYER, EnemyKind.Kind.WASP]:
		assert_true(EnemyKind.flies(k))
		assert_eq(EnemyKind.hit_rule(k, "sword", Vector2.LEFT, at, from), "miss")
		assert_eq(EnemyKind.hit_rule(k, "ball", Vector2.LEFT, at, from), "miss")
		assert_eq(EnemyKind.hit_rule(k, "arrow", Vector2.LEFT, at, from), "")
		assert_eq(EnemyKind.hit_rule(k, "magic", Vector2.LEFT, at, from), "")
	var b := EnemyKind.Kind.BEETLE
	assert_eq(EnemyKind.hit_rule(b, "sword", Vector2.LEFT, at, from), "armor")
	assert_eq(EnemyKind.hit_rule(b, "arrow", Vector2.LEFT, at, from), "armor")
	assert_eq(EnemyKind.hit_rule(b, "ball", Vector2.LEFT, at, from), "")
	assert_eq(EnemyKind.hit_rule(b, "sword", Vector2.LEFT, at, from, {"flipped": true}), "")
	var s := EnemyKind.Kind.SHIELD
	assert_eq(EnemyKind.hit_rule(s, "sword", Vector2.RIGHT, at, from), "block")
	assert_eq(EnemyKind.hit_rule(s, "ball", Vector2.RIGHT, at, from), "")
	assert_eq(EnemyKind.hit_rule(s, "sword", Vector2.LEFT, at, from), "")
	assert_eq(EnemyKind.hit_rule(EnemyKind.Kind.GHOST, "ball", Vector2.LEFT, at, from, {"faded": true}), "pass")
	assert_eq(EnemyKind.hit_rule(EnemyKind.Kind.CHARGER, "sword", Vector2.LEFT, at, from, {"stunned": true}), "weak")
	assert_eq(EnemyKind.hit_rule(EnemyKind.Kind.MELEE, "sword", Vector2.LEFT, at, from), "")

func test_old_kinds_keep_their_roles():
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

func test_mimic_drops_more():
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var money_mimic := 0
	var money_slime := 0
	var gear := 0
	for i in 100:
		var m := Loot.roll_kind(EnemyKind.Kind.MIMIC, "廃城", 3, rng)
		var w := Loot.roll_kind(EnemyKind.Kind.WEAK, "廃城", 3, rng)
		money_mimic += m[0][1]
		money_slime += w[0][1]
		assert_gte(m.size(), 3, "擬態箱は素材を2つ以上")
		for d in m:
			if ItemCatalog.exists(d[0]):
				gear += 1
	assert_gt(money_mimic, money_slime * 3)
	assert_gt(gear, 20, "擬態箱は装備をよく落とす")

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
