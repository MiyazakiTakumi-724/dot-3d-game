extends GutTest
## 武器の使い分け（2026-11-26 の4回目の直し）：ボスの構え（崩し）、敵ごとの得意・不得意、弓を引く間の足。

func test_guard_softens_arrows_and_magic() -> void:
	var g := BossGuard.new(400)
	assert_almost_eq(g.mult("arrow"), BossGuard.GUARD_MULT["arrow"], 0.001)
	assert_lt(g.mult("arrow"), 0.5, "構えている間、矢はあまり効かない")
	assert_lt(g.mult("magic"), 1.0)
	assert_eq(g.mult("sword"), 1.0)
	assert_eq(g.mult("ball"), 1.0)

func test_sword_breaks_guard_and_staggers() -> void:
	var g := BossGuard.new(400)
	var hits := 0
	var broke := false
	while not broke and hits < 50:
		broke = g.hit("sword", 10)
		hits += 1
	assert_true(broke, "剣で削りきると崩れる")
	assert_lt(hits, 10, "剣なら10回もかからない")
	assert_true(g.broken())
	assert_eq(g.mult("arrow"), 1.0, "崩れている間は矢もふつうに入る")
	g.update(BossGuard.STAGGER + 0.1)
	assert_false(g.broken(), "時間がたつと立ち直る")
	assert_almost_eq(g.ratio(), 1.0, 0.001, "構えは元に戻る")

func test_arrows_barely_break_guard() -> void:
	var g := BossGuard.new(400)
	var arrows := 0
	while not g.broken() and arrows < 500:
		g.hit("arrow", 10)
		arrows += 1
	var g2 := BossGuard.new(400)
	var swords := 0
	while not g2.broken() and swords < 500:
		g2.hit("sword", 10)
		swords += 1
	assert_gt(arrows, swords * 5, "矢は剣よりずっと削れない")

func test_guard_regenerates_after_a_pause() -> void:
	var g := BossGuard.new(400)
	g.hit("sword", 20)
	var low := g.value
	g.update(BossGuard.REGEN_DELAY - 0.5)
	assert_almost_eq(g.value, low, 0.001, "すぐには戻らない")
	g.update(1.5)
	assert_gt(g.value, low, "しばらく攻撃されないと戻る")

func test_boss_weak_point_ignores_guard() -> void:
	var g := BossGuard.new(300, "arrow")
	assert_eq(g.mult("arrow"), 1.0, "弱点の武器は構えで弱まらない")
	var a := BossGuard.new(300, "arrow")
	var b := BossGuard.new(300)
	a.hit("arrow", 10)
	b.hit("arrow", 10)
	assert_lt(a.value, b.value, "弱点の武器は構えをよく削る")

func test_every_boss_has_a_weak_weapon() -> void:
	for name in BossKind.DATA:
		assert_true(BossGuard.WEAK.has(name), "%s の弱点" % name)
		assert_true(BossGuard.WEAK[name] in ["sword", "arrow", "magic", "ball", "bomb"])

func test_enemy_affinities_vary() -> void:
	var weak := {}
	var resist := {}
	for k in EnemyKind.Kind.values():
		for s in ["sword", "arrow", "magic", "ball", "bomb"]:
			var a := EnemyKind.affinity(k, s)
			assert_true(a in [EnemyKind.WEAK_MULT, 1.0, EnemyKind.RESIST_MULT])
			if a > 1.0:
				weak[s] = weak.get(s, 0) + 1
			elif a < 1.0:
				resist[s] = resist.get(s, 0) + 1
	for s in ["sword", "arrow", "magic", "ball"]:
		assert_gt(weak.get(s, 0), 0, "%s が弱点の敵がいる" % s)
	assert_gt(resist.get("arrow", 0), weak.get("arrow", 0), "矢が効きにくい敵の方が多い")

func test_some_affinities() -> void:
	assert_gt(EnemyKind.affinity(EnemyKind.Kind.FLYER, "arrow"), 1.0, "コウモリは矢に弱い")
	assert_lt(EnemyKind.affinity(EnemyKind.Kind.WEAK, "arrow"), 1.0, "スライムに矢は効きにくい")
	assert_gt(EnemyKind.affinity(EnemyKind.Kind.SHIELD, "ball"), 1.0, "盾持ちは鉄球に弱い")
	assert_gt(EnemyKind.affinity(EnemyKind.Kind.GHOST, "magic"), 1.0, "亡霊は魔法に弱い")
	assert_eq(EnemyKind.affinity(EnemyKind.Kind.CHARGER, "sword"), 1.0)
	assert_gt(EnemyKind.affinity(EnemyKind.Kind.WOLF, "sword"), 1.0, "狼は剣に弱い")
	assert_lt(EnemyKind.affinity(EnemyKind.Kind.WOLF, "arrow"), 1.0, "すばやい狼に矢は効きにくい")
	assert_gt(EnemyKind.affinity(EnemyKind.Kind.DARK_KNIGHT, "magic"), 1.0, "黒騎士は魔法に弱い")

func test_drawing_bow_slows_walking() -> void:
	assert_lt(Bow.DRAW_MOVE, 0.6, "弓を引いている間は歩くのが遅い")
	assert_lt(Bow.MOVING_CHARGE, 1.0, "歩きながらだと溜めるのが遅い")
	var b := Bow.new()
	b.start()
	b.update(0.5, true)
	var moving := b.rate()
	var c := Bow.new()
	c.start()
	c.update(0.5)
	assert_lt(moving, c.rate())
