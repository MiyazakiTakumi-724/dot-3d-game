extends GutTest
## 敵の技（2026-11-26 の4回目の直し）：イノシシのほかの敵は、いくつもの動きを使い分ける。

var f

func before_each():
	seed(7)
	f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)

func _flat() -> HeightMap:
	var m := HeightMap.new(Vector2i(24, 11))
	for y in 11:
		for x in 24:
			m.set_height(Vector2i(x, y), 1)
	return m

## プレイヤーを (4, 5) に、敵を右へ dist px の所に置く。
func _setup(kind: EnemyKind.Kind, dist: float) -> Enemy:
	var m := _flat()
	f.map = m
	f.player.mover.map = m
	f.player.mover.place(Vector2i(4, 5))
	f.player.mover.facing = Vector2.RIGHT
	for e in f.enemies:
		e.queue_free()
	f.enemies.clear()
	var e := Enemy.new()
	e.setup(m, Vector2i(4, 5), Vector2.LEFT, f.player, f.camera, kind)
	f._wire_enemy(e)
	add_child_autofree(e)
	e.set_process(false)
	e.walker.pos = f.player.mover.pos + Vector2(dist, 0)
	e.face = Vector2.LEFT
	f.enemies.append(e)
	return e

## 敵だけを動かす（プレイヤーは止まったまま、いのちは減らない）。
func _run(e: Enemy, seconds: float, step := 0.05) -> void:
	for i in int(seconds / step):
		f.player.clear_invulnerable()
		f.player.set_hp(f.player.max_hp)
		if not is_instance_valid(e):
			return
		e._process(step)

func _used(e: Enemy, move: String, seconds: float, keep_dist := -1.0) -> bool:
	for i in int(seconds / 0.05):
		if not is_instance_valid(e):
			return false
		if move in e.moves_used:
			return true
		if keep_dist > 0.0 and e._act == "":
			e.walker.pos = f.player.mover.pos + Vector2(keep_dist, 0)
		_run(e, 0.05)
	return is_instance_valid(e) and move in e.moves_used

func test_goblin_lunges_from_a_little_away() -> void:
	var e := _setup(EnemyKind.Kind.MELEE, 36.0)
	assert_true(_used(e, "lunge", 3.0, 36.0), "少し離れていると跳び斬り")

func test_goblin_throws_knife_at_kiters() -> void:
	var e := _setup(EnemyKind.Kind.MELEE, 96.0)
	var shots := []
	e.shot.connect(func(b): shots.append(b))
	assert_true(_used(e, "knife", 4.0, 96.0), "遠いとナイフ")
	assert_gt(shots.size(), 0)

func test_goblin_dodges_falling_arrow() -> void:
	var e := _setup(EnemyKind.Kind.MELEE, 48.0)
	e._skill_cd = 99.0
	var a := Arrow.new()
	a.launch(f.player.mover.pos, 8.0, e.walker.pos, 8.0)
	f._shots.append([a, null, 1, f.player.mover.pos])
	var dodged := false
	for i in 8:
		e._dodge_cd = 0.0
		e._process(0.0)
		if "dodge" in e.moves_used:
			dodged = true
			break
	f._shots.clear()
	assert_true(dodged, "落ちてくる矢を横へよける")

func test_goblin_leads_its_chase() -> void:
	var e := _setup(EnemyKind.Kind.MELEE, 50.0)
	e._pv = Vector2(0, 60)
	assert_eq(e._lead(0.5), f.player.mover.pos + Vector2(0, 30))

func test_shooter_leaps_back_and_fans() -> void:
	var e := _setup(EnemyKind.Kind.SHOOTER, 16.0)
	assert_true(_used(e, "leap_back", 2.5, 16.0), "近づかれると跳び下がる")
	var e2 := _setup(EnemyKind.Kind.SHOOTER, 80.0)
	assert_true(_used(e2, "spread", 14.0, 80.0), "扇に3発")

func test_shield_bashes_and_counters() -> void:
	var e := _setup(EnemyKind.Kind.SHIELD, 20.0)
	assert_true(_used(e, "bash", 2.0, 20.0), "正面に近いと突き飛ばす")
	var e2 := _setup(EnemyKind.Kind.SHIELD, 20.0)
	assert_false(f.damage_target(e2, 3, f.player.mover.pos, "", Color.WHITE, "sword"))
	assert_has(e2.moves_used, "counter", "防いだらすぐ叩き返す")

func test_shadow_steps_behind() -> void:
	var e := _setup(EnemyKind.Kind.SHADOW, 60.0)
	assert_true(_used(e, "behind", 2.0, 60.0))
	assert_lt(e.walker.pos.x, f.player.mover.pos.x, "背中（向きの反対）に現れる")

func test_wasp_stings_from_afar() -> void:
	var e := _setup(EnemyKind.Kind.WASP, 70.0)
	assert_true(_used(e, "sting", 4.0, 70.0))

func test_bomber_rushes_and_bursts_when_slashed() -> void:
	var e := _setup(EnemyKind.Kind.BOMBER, 40.0)
	assert_true(_used(e, "rush", 2.0, 40.0))
	var e2 := _setup(EnemyKind.Kind.BOMBER, 14.0)
	var booms := []
	e2.exploded.connect(func(p, h): booms.append(p))
	f.damage_target(e2, 1, f.player.mover.pos, "", Color.WHITE, "sword")
	_run(e2, 0.3)
	assert_eq(booms.size(), 1, "剣で叩くとすぐ弾ける")

func test_ghost_curses_and_appears_behind() -> void:
	var e := _setup(EnemyKind.Kind.GHOST, 60.0)
	assert_true(_used(e, "curse", 3.0, 60.0))
	var e2 := _setup(EnemyKind.Kind.GHOST, 60.0)
	assert_true(_used(e2, "behind", EnemyKind.GHOST_SOLID + EnemyKind.GHOST_FADED + 0.5))

func test_spear_sweeps_close_and_thrusts() -> void:
	var e := _setup(EnemyKind.Kind.SPEAR, 12.0)
	assert_true(_used(e, "sweep", 2.5, 12.0), "近すぎると払う")
	var e2 := _setup(EnemyKind.Kind.SPEAR, 30.0)
	assert_true(_used(e2, "thrust", 3.0))

func test_lobber_volleys() -> void:
	var e := _setup(EnemyKind.Kind.LOBBER, 80.0)
	assert_true(_used(e, "volley", 10.0, 80.0))

func test_mage_bolts_and_novas() -> void:
	var e := _setup(EnemyKind.Kind.MAGE, 70.0)
	assert_true(_used(e, "bolt", 6.0, 70.0), "先読みの速い弾 %s" % [e.moves_used])
	var e2 := _setup(EnemyKind.Kind.MAGE, 20.0)
	assert_true(_used(e2, "nova", 2.5, 20.0))

func test_beetle_rolls_and_flips_on_wall() -> void:
	var e := _setup(EnemyKind.Kind.BEETLE, 50.0)
	assert_true(_used(e, "roll", 2.0, 50.0))
	var e2 := _setup(EnemyKind.Kind.BEETLE, 12.0)
	assert_true(_used(e2, "horn", 2.5, 12.0))

func test_mimic_leaps_and_spits() -> void:
	var e := _setup(EnemyKind.Kind.MIMIC, 40.0)
	e._wake_mimic()
	assert_true(_used(e, "leap", 2.0, 40.0))
	var e2 := _setup(EnemyKind.Kind.MIMIC, 90.0)
	e2._wake_mimic()
	assert_true(_used(e2, "coins", 4.0, 90.0))

func test_slime_splits_into_two_small() -> void:
	var e := _setup(EnemyKind.Kind.WEAK, 40.0)
	var before: int = f.enemies.size()
	e.walker.take_damage(e.walker.hp)
	var small := 0
	for x in f.enemies:
		if is_instance_valid(x) and x != e and x.small:
			small += 1
			assert_true(x.minion)
	assert_eq(small, 2, "倒すと小さい2匹に分かれる")
	# 小さい方はもう分かれない
	var s: Enemy = f.enemies[f.enemies.size() - 1]
	var n: int = f.enemies.size()
	s.walker.take_damage(s.walker.hp)
	assert_eq(f.enemies.size(), n)
	assert_gt(n, before)

func test_every_kind_but_boar_has_moves() -> void:
	# 技のある種類（イノシシのほか）
	for k in EnemyKind.Kind.values():
		if k == EnemyKind.Kind.CHARGER:
			continue
		var e := _setup(k, 40.0)
		if k == EnemyKind.Kind.MIMIC:
			e._wake_mimic()
		for d in [40.0, 16.0, 80.0, 30.0]:
			if e.moves_used.size() > 0 or not is_instance_valid(e):
				break
			_used(e, "__none__", 4.0, d)
		assert_true(is_instance_valid(e) and e.moves_used.size() > 0, "%s の技" % EnemyKind.name_of(k))

# ---- 霧の谷の敵（2026-11-26）

func test_wolf_leaps_at_you() -> void:
	var e := _setup(EnemyKind.Kind.WOLF, 50.0)
	assert_true(_used(e, "leap", 3.0, 50.0), "狼は跳びかかる")

func test_wolf_howls_and_speeds_up() -> void:
	var e := _setup(EnemyKind.Kind.WOLF, 90.0)
	assert_true(_used(e, "howl", 2.0, 90.0), "見つけると遠吠え")
	assert_gt(e.frenzy, 0.0, "遠吠えのあとは速い")

func test_wolf_circles_before_biting() -> void:
	var e := _setup(EnemyKind.Kind.WOLF, 40.0)
	e._skill_cd = 99.0
	e._howled = true
	var start: Vector2 = e.walker.pos - f.player.mover.pos
	_run(e, 0.6)
	var now: Vector2 = e.walker.pos - f.player.mover.pos
	assert_gt(absf(start.angle_to(now)), 0.15, "まわりを回る")

func test_dark_knight_waves_charges_and_spins() -> void:
	var e := _setup(EnemyKind.Kind.DARK_KNIGHT, 120.0)
	var shots := []
	e.shot.connect(func(b): shots.append(b))
	assert_true(_used(e, "wave", 5.0, 120.0), "離れると剣の衝撃波")
	assert_gte(shots.size(), 3)
	var e2 := _setup(EnemyKind.Kind.DARK_KNIGHT, 60.0)
	assert_true(_used(e2, "charge", 4.0, 60.0), "中くらいの間合いで突進")
	var e3 := _setup(EnemyKind.Kind.DARK_KNIGHT, 14.0)
	assert_true(_used(e3, "spin", 3.0, 14.0), "近いと回転斬り")

func test_dark_knight_blocks_arrows_from_the_front() -> void:
	var e := _setup(EnemyKind.Kind.DARK_KNIGHT, 40.0)
	assert_eq(e.hit_rule("arrow", f.player.mover.pos), "block")
	assert_eq(e.hit_rule("magic", f.player.mover.pos), "")
	assert_eq(e.hit_rule("arrow", e.walker.pos + Vector2(40, 0)), "", "背中からは入る")
