extends GutTest
## ボスの仕様（balance-pass 5章）を、ボスの間に入って1つずつ確かめる。
## どのボスも、体力が半分を切ると2段目になり、攻撃が増える。

var f

func before_each():
	f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)

func after_each():
	get_tree().paused = false

## ボスの名前 → いるエリア（隠しボスも各地方に1体）
const WHERE := {
	"岩転がしの巨人": "mt_5",
	"草むらの大蛇": "gr_5",
	"満ち引きする溶岩": "lv_5",
	"廃城の主": "cs_5",
	"岩窟のぬし": "mt_x",
	"溶岩洞のぬし": "lv_x",
	"女王蜂": "gr_x",
	"宝箱の王": "cs_x",
	"双子": "tw_2",
	"らせん塔の番人": "tw_3",
	"ブライト": "tw_4",
}

## ボスの間に入り、ボスを起こす。プレイヤーはボスの近くの歩けるマスに置く。
func _enter(g: String) -> Boss:
	var id: String = WHERE[g]
	var a: AreaDef = f.world.area(id)
	var cell: Vector2i = a.bosses[0][0]
	f.enter_area(id, cell)
	f.player.mover.place(_near_cell(f.map, cell))
	for b in f.bosses:
		b.wake()
	for b in f.bosses:
		if b.group == g:
			return b
	return null

func _near_cell(m: HeightMap, cell: Vector2i) -> Vector2i:
	for r in range(3, 8):
		for d in [Vector2i(0, r), Vector2i(0, -r), Vector2i(r, 0), Vector2i(-r, 0)]:
			var c: Vector2i = cell + d
			if m.in_bounds(c) and not m.is_wall(c) and not m.is_pit(c) and not m.is_water(c) and m.get_height(c) == m.get_height(cell):
				return c
	return cell

func _half(b: Boss) -> void:
	b.walker.take_damage(b.walker.max_hp / 2 + 1)

func _run(seconds: float, step := 0.05) -> void:
	var n := int(seconds / step)
	for i in n:
		f.player.clear_invulnerable()
		f.player.set_hp(f.player.max_hp)
		for b in f.bosses:
			if is_instance_valid(b):
				b._process(step)
		f._process(step)

# ---------------------------------------------------------------- どのボスにも

func test_rules_phase_and_flying():
	assert_eq(BossKind.phase(100, 100), 1)
	assert_eq(BossKind.phase(51, 100), 1)
	assert_eq(BossKind.phase(50, 100), 2)
	assert_true(BossKind.flies("女王蜂"))
	assert_false(BossKind.flies("岩転がしの巨人"))

func test_every_boss_is_in_its_area_and_one_per_hidden_area():
	for g in WHERE:
		var b := _enter(g)
		assert_not_null(b, g)
		if b != null:
			assert_eq(b.walker.hp, b.walker.max_hp, g)
	for id in ["mt_x", "lv_x", "gr_x", "cs_x"]:
		assert_eq(f.world.area(id).bosses.size(), 1, id)

func test_every_boss_enters_phase_two_at_half_hp():
	for g in WHERE:
		var b := _enter(g)
		assert_eq(b.phase, 1, g)
		_half(b)
		if g == "双子":
			b.partner.walker.take_damage(b.partner.walker.max_hp / 2 + 1)
		_run(0.1)
		assert_eq(b.phase, 2, g)
		assert_string_contains(f.ui_message(), "怒った", g)

func test_boss_models_are_fine_detail():
	for g in WHERE:
		var m := BossModels.model(g)
		assert_gt(maxi(m.size.x, maxi(m.size.y, m.size.z)), 30, g)  # 主人公と同じ細かさ（前の倍）

# ---------------------------------------------------------------- それぞれ

## 巨人：2段目で、下の地面を端から端へ大岩が転がる
func test_giant_rolls_boulders_in_phase_two():
	var b := _enter("岩転がしの巨人")
	_half(b)
	_run(5.5)
	assert_gt(f.rollers_count(), 0)

## 大蛇：2段目でもぐる（その間は攻撃が効かない）。影が先に出てから、足元に出る
func test_snake_burrows_and_comes_up_under_player():
	var b := _enter("草むらの大蛇")
	_half(b)
	_run(7.2)
	assert_gt(b.burrow, 0.0)
	assert_eq(b.hit_rule("arrow", f.player.mover.pos), "block")
	_run(1.8)
	assert_eq(b.burrow, 0.0)
	assert_lt(b.walker.pos.distance_to(f.player.mover.pos), 20.0)

## 溶岩：2段目は満ち引きが速く、火柱が立つ（先に印）
func test_lava_pillars_in_phase_two():
	var b := _enter("満ち引きする溶岩")
	_half(b)
	_run(3.2)
	assert_gt(f.strikes_count(), 0)

## 廃城の主：2段目で亡霊を呼ぶ
func test_knight_calls_ghosts():
	var b := _enter("廃城の主")
	_half(b)
	_run(0.1)
	var ghosts := 0
	for e in f.enemies:
		if is_instance_valid(e) and e.kind == EnemyKind.Kind.GHOST and e.minion:
			ghosts += 1
	assert_gt(ghosts, 0)
	assert_lte(b.minion_count(), Boss.MAX_MINIONS)

## 岩窟のぬし：2段目で転がり、壁にぶつかると目を回す。目を回している間は2倍入る
func test_golem_stuns_on_wall_and_takes_double():
	var b := _enter("岩窟のぬし")
	_half(b)
	b.stunned = 1.0
	assert_eq(b.hit_rule("sword", f.player.mover.pos), "weak")
	var hp: int = b.walker.hp
	f.damage_target(b, 5, f.player.mover.pos)
	assert_eq(b.walker.hp, hp - 10)
	assert_false(b.touch_hurts())

## 溶岩洞のぬし：2段目で跳びかかり、着いた所のまわりに炎の輪
func test_salamander_leaps_and_rings_fire():
	var b := _enter("溶岩洞のぬし")
	_half(b)
	_run(0.1)
	var before: int = f.hot_count()
	_run(5.5)
	assert_gte(f.hot_count() - before, 8)

## 双子：片方が倒れると、残りが怒って速くなる
func test_twins_enrage_when_one_falls():
	var b := _enter("双子")
	var other: Boss = b.partner
	var speed: float = other.walker.speed_mult
	b.walker.take_damage(99999)
	_run(0.1)
	assert_true(other.enraged)
	assert_gt(other.walker.speed_mult, speed)

## らせん塔の番人：背中だけ効く。2段目で回る向きが変わる
func test_guardian_back_only_and_reverses():
	var b := _enter("らせん塔の番人")
	var front: Vector2 = b.walker.pos + b.facing() * 20.0
	var back: Vector2 = b.walker.pos - b.facing() * 20.0
	assert_eq(b.hit_rule("arrow", front), "block")
	assert_eq(b.hit_rule("arrow", back), "")
	_half(b)
	_run(0.1)
	var spin: float = b._spin
	_run(5.2)
	assert_eq(b._spin, -spin)

## ブライト：2段目で光の雨と、影を呼ぶ
func test_bright_light_rain_and_shadows():
	var b := _enter("ブライト")
	_half(b)
	_run(12.2)
	assert_gt(f.strikes_count() + f.strikes_done, 0)
	assert_gt(b.minion_count(), 0)

## 女王蜂：浮いているので剣と鉄球は届かない。矢は当たる。蜂を呼ぶ。2段目で急降下して降りると、剣も届く
func test_queen_bee_flies_calls_wasps_and_lands():
	var b := _enter("女王蜂")
	assert_eq(b.hit_rule("sword", f.player.mover.pos), "miss")
	assert_eq(b.hit_rule("ball", b.walker.pos), "miss")
	assert_eq(b.hit_rule("arrow", f.player.mover.pos), "")
	_run(9.2)
	var wasps := 0
	for e in f.enemies:
		if is_instance_valid(e) and e.kind == EnemyKind.Kind.WASP:
			wasps += 1
	assert_gt(wasps, 0)
	_half(b)
	b.landed = 1.0
	assert_eq(b.hit_rule("sword", f.player.mover.pos), "")

## 宝箱の王：にせものの宝箱にまぎれる。にせものは1回で壊れ、本物は入れ替わる
func test_chest_king_hides_among_decoys():
	var b := _enter("宝箱の王")
	assert_eq(b.decoys.size(), Boss.DECOYS)
	assert_false(b.touch_hurts())
	var t: Array = f.targets()
	for d in b.decoys:
		assert_true(d in t)
	var d0: BossDecoy = b.decoys[0]
	assert_true(f.damage_target(d0, 3, f.player.mover.pos, "", Color.WHITE, "arrow"))
	assert_false(d0.walker.alive)
	var spots := {}
	for d in b.decoys:
		if is_instance_valid(d) and d.walker.alive:
			spots[d.walker.cell()] = true
	var where := b.walker.cell()
	f.player.mover.place(Vector2i(1, 1))  # 噛みつかれない所
	_run(Boss.CHEST_SHUFFLE + 0.2)
	assert_eq(b.decoys.filter(func(d): return is_instance_valid(d) and d.walker.alive).size(), Boss.DECOYS)
	var moved := b.walker.cell() != where
	for d in b.decoys:
		if is_instance_valid(d) and not spots.has(d.walker.cell()):
			moved = true
	assert_true(moved)

## 宝箱の王の本物だけ、背中に金のしっぽがある（カメラを回すと見分けられる）
func test_real_chest_has_a_tail_decoys_do_not():
	var real := BossModels.model("宝箱の王")
	var fake := BossModels.model("宝箱の王", "decoy")
	assert_gt(real.voxels().size(), fake.voxels().size())

## 2026-11-25 夜のエラー：転がる大岩が砕けたり大蛇の影が消えたりして、絵が先に消えていると、次のフレームで止まった
func test_effects_freed_elsewhere_do_not_stop_the_game():
	_enter("岩転がしの巨人")
	var s: StackSprite = f.effect_at(Props.aim_shadow(), f.player.mover.pos, 0, 2.0)
	s.free()
	f._step_effects(0.1)
	assert_eq(f._effects.filter(func(x): return not is_instance_valid(x[0])).size(), 0)

## 巨人の2段目で大岩を転がし続けても止まらない（砕けた大岩の絵が残らない）
func test_giant_boulders_break_cleanly():
	var b := _enter("岩転がしの巨人")
	_half(b)
	_run(12.0)
	assert_eq(f._effects.filter(func(x): return not is_instance_valid(x[0])).size(), 0)

# ---------------------------------------------------------------- 2026-11-25 夜（2回目の直し）に足した技

func _bullets() -> int:
	return f._bullets.size()

## seconds の間 _run して、どこかで cond が true になったか。
func _run_until(cond: Callable, seconds: float, step := 0.05) -> bool:
	for i in int(seconds / step):
		_run(step, step)
		if cond.call():
			return true
	return false

## 一時的な奈落：ひびが出てから開き、少しすると閉じて元の地面に戻る。出口のそばには開かない
func test_boss_pits_open_then_close():
	_enter("岩転がしの巨人")
	var c: Vector2i = f.player.mover.cell()
	var far := Vector2i(-1, -1)
	for d in [Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3)]:
		var t: Vector2i = c + d
		if f.map.in_bounds(t) and not f.map.is_wall(t) and not f.map.is_pit(t) and not f.map.is_water(t):
			far = t
			break
	assert_ne(far, Vector2i(-1, -1))
	assert_eq(f.boss_pits([far], 0.5, 1.0), 1)
	assert_false(f.map.is_pit(far), "はじめはひびだけ")
	f._step_pits(0.6)
	assert_true(f.map.is_pit(far))
	assert_eq(f.open_pits(), 1)
	f._step_pits(1.1)
	assert_false(f.map.is_pit(far), "閉じる")
	assert_eq(f.open_pits(), 0)
	var entry: Vector2i = f.area.entry_safe_cells().keys()[0]
	assert_eq(f.boss_pits([entry], 0.5, 1.0), 0, "出口のそばには開かない")

## 立っているマスが奈落になると、落ちて死ぬ
func test_falling_into_boss_pit_kills():
	_enter("岩転がしの巨人")
	assert_eq(f.boss_pits([f.player.mover.cell()], 0.1, 3.0), 1)
	f._step_pits(0.2)
	assert_true(f.player.mover.fell)
	f._process(0.05)
	assert_eq(f.area_state.result, AreaState.Result.DYING)

## 巨人：地面を叩いて、主人公の足元に奈落を開ける（岩場のボスが奈落を作る）
func test_giant_cracks_ground_under_player():
	var b := _enter("岩転がしの巨人")
	b._clock1 = Boss.GIANT_QUAKE
	_run(0.1)
	assert_gt(f._pits_tmp.size(), 0)
	assert_eq(f.open_pits(), 0, "先にひび")
	var cells: Array = f._pits_tmp[0][0]
	assert_true(cells.has(f.player.mover.cell()), "足元を含む")
	_half(b)
	_run(0.1)
	b._clock1 = Boss.GIANT_QUAKE_2
	var before: int = f._pits_tmp.size()
	_run(0.1)
	assert_gt(f._pits_tmp.size(), before)
	assert_gt(f._pits_tmp[f._pits_tmp.size() - 1][0].size(), 4, "2段目は列も")

## 大蛇：少し離れていると、ためて突進して噛みつく
func test_snake_lunges():
	var b := _enter("草むらの大蛇")
	b._clock1 = 4.0
	b._cool = 0.0
	assert_true(_run_until(func():
		f.camera.angle = b._view_angle  # 体が見える向きから
		return b._dash_time > 0.0, 3.0))

## 溶岩：引いているとき、溶岩の玉も落とす。2段目は炎の車輪が転がる
func test_lava_drops_bombs_and_rolls_fire_wheels():
	var b := _enter("満ち引きする溶岩")
	assert_true(_run_until(func(): return f.strikes_count() > 0, 4.0))
	_half(b)
	_run(0.1)
	b._clock3 = 6.0
	_run(0.1)
	assert_gt(f.rollers_count(), 0)

## 廃城の主：離れると3方向に衝撃波。2段目は主人公へ向かう印の列
func test_knight_waves_and_cracks():
	var b := _enter("廃城の主")
	b._clock1 = 5.0
	b._cool = 0.0
	assert_true(_run_until(func(): return _bullets() >= 3, 3.0))
	_half(b)
	_run(0.1)
	b._clock3 = 6.0
	assert_true(_run_until(func(): return f.strikes_count() >= 5, 2.0), "突進のあとでも割る")

## 岩窟のぬし：地響きで、まわりに奈落を開ける。2段目は大岩を転がしてくる
func test_golem_quakes_pits_and_rolls_boulders():
	var b := _enter("岩窟のぬし")
	b._clock1 = Boss.GOLEM_QUAKE
	_run(0.1)
	assert_gt(f._pits_tmp.size(), 0)
	_half(b)
	_run(0.1)
	b._clock3 = 7.0
	_run(0.1)
	assert_gt(f.rollers_count(), 0)

## 溶岩洞のぬし：離れると火を5方向に吐く。2段目は火の雨
func test_salamander_breathes_fire_and_rains():
	var b := _enter("溶岩洞のぬし")
	b._clock1 = 4.0
	b._cool = 0.0
	assert_true(_run_until(func(): return _bullets() >= 5, 3.0))
	_half(b)
	_run(0.1)
	b._clock3 = 5.0
	_run(0.1)
	assert_gte(f.strikes_count(), 3)

## 双子：前に立つ方が、ためて突進する
func test_twin_in_front_charges():
	var b := _enter("双子")
	var front: Boss = b if not b.hider else b.partner
	front._clock1 = 5.0
	front._cool = 0.0
	assert_true(_run_until(func(): return front._dash_time > 0.0, 3.0))

## 番人：床に十字の印が出て、火柱が立つ
func test_guardian_cross_pillars():
	var b := _enter("らせん塔の番人")
	b._clock1 = 6.0
	_run(0.1)
	assert_gte(f.strikes_count(), 6, "壁の上には立たないので、12のうち少なくとも6")

## ブライト：ときどき別の所へ移る。2段目は回る光の柱の列
func test_bright_teleports_and_sweeps():
	var b := _enter("ブライト")
	var at: Vector2 = b.walker.pos
	b._clock1 = 10.0
	_run(0.1)
	assert_ne(b.walker.pos, at)
	_half(b)
	_run(0.1)
	b._clock3 = 7.0
	_run(0.1)
	assert_gte(f.strikes_count(), 10)

## 女王蜂：ときどき針を8方向に撃つ
func test_queen_needle_ring():
	var b := _enter("女王蜂")
	b._clock1 = 7.0
	_run(0.1)
	assert_gte(_bullets(), 8)

## 宝箱の王：ときどき本物だけが口を開けて金貨を吐く。2段目は擬態箱を呼ぶ
func test_chest_king_spits_coins_and_calls_mimic():
	var b := _enter("宝箱の王")
	b._clock1 = 5.0
	_run(0.1)
	assert_gte(_bullets(), 3)
	assert_gt(b.open_time, 0.0)
	_half(b)
	_run(0.1)
	b._clock3 = 12.0
	_run(0.1)
	var mimics := 0
	for e in f.enemies:
		if is_instance_valid(e) and e.kind == EnemyKind.Kind.MIMIC and e.minion:
			mimics += 1
	assert_eq(mimics, 1)
