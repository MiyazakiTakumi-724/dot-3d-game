# 試作3「大陸のエリアをつなぐ」実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 箱庭の島（area_02）を、1つの大陸に並んだ4エリア（野営地・岩場・丘陵・奥の森）に置き換え、エリアの端の矢印から歩いて切り替わるようにする。あわせて、鉄球を手の届く範囲の好きな場所に出せるようにし、敵1・敵2と時間で戻る敵、細かい段差と読みやすい高さの描き方を入れる。

**Architecture:** 1つのシーン（`scenes/field.tscn`）が、今いるエリアの地形・敵・印だけを `_area_root` の下に作り、出口に着いたら片付けて次のエリアを作る（設計の作り方A）。エリアの形・位置・出口・敵・拾いものは `AreaDef` のデータで、大陸全体は `WorldMap` がまとめる。エリアをまたいで残るもの（持ち物・墓石・拾い済み・開けた門・敵の復活時間）は `RunState` と `EnemyRoster` が持つ。

**Tech Stack:** Godot 4.5 / GDScript、GUT 9.5.0、地図の生成は Python 3（Pillow はプレビューだけ）。

**Spec:** `docs/superpowers/specs/2026-11-24-world-areas-design.md`（承認済み）。試作2の設計 `docs/superpowers/specs/2026-11-23-death-loop-design.md` の持ち物・墓石・奈落のルールを引き継ぐ。

## Global Constraints

- 新しいルールは `scripts/rules/` に RefCounted クラスとして書き、先に失敗するテストを書いてから実装する。
- 1マス＝16px、1段＝8px。描画解像度は320×180、拡大は整数倍のみ。
- コメントとコミットメッセージは日本語。コミットの最後に `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` と `Claude-Session: https://claude.ai/code/session_01V8ZRqMy3Fk13HeuYJHLPNU`。
- ブランチ `claude/project-thread-gkcqe0` に push する。新しいPRは作らない。
- UIの文字は日本語（`UiText`、10px か 12px）。キーの名前は英字。
- 鉄球が届くのは体の中心から24px（1.5マス）。当たりの半径は8px。拾うのは中心から6px以内で同じ高さ。
- 敵の復活は倒してから300秒（ゲームの中の時間）。復活は、エリアに入ったときにだけ判定する。死んでも敵は復活しない。
- 敵1：体力1、段差なし（climb 0）、体当たり。敵2：体力2、1段まで（climb 1）、近接攻撃（3マス＝48px以内で寄る、0.5秒ためて叩く、1ダメージ、体当たりなし）。撃つ敵：体力1、段差なし、2秒ごとに撃つ、体当たり。撃つ敵は奥の森だけ。
- 出口の前後3マス以内には、敵を置かず、敵も入らない。
- 切り替えは、暗くするのに0.2秒、明るくするのに0.2秒。エリアに入ると名前を2秒出す。
- 高さは0〜8段。平らな所はだいたい8×8マス以内（野営地の広場と、敵1のいる6×6以上の平地は例外）。
- 経路：たき火→丘陵→奥の森の強い鉄球まで歩いて90秒以上。門を開けた後は、強い鉄球のあたり→たき火が30秒以内。プレイヤーの速さは `Player` の今の値で計算する。

## Review Focus

1. 切り替えた直後に、もう一度出口を踏んで行ったり来たりしない（入った所は出口の1マス内側で、外へ歩かない限り切り替わらない）。→ Task 8 `test_arrival_does_not_bounce_back`
2. 墓石のあるエリアを出入りしても、墓石のマスがふさがったまま・別のエリアの同じマスがふさがる、が起きない。→ Task 8 `test_grave_blocks_only_in_its_area`
3. 敵2が段差を登って追ってくるとき、2段の崖・水・奈落・出口の近くに入らない。→ Task 2 `test_melee_walker_never_enters_two_level_step`
4. 切り替えの途中（暗い間）や死んでいる間に、クリック・F・Tab・出口が効かない。→ Task 8 `test_input_ignored_while_switching`
5. インベントリを開いて止まっている間は、敵の復活時間も進まない。→ Task 8 `test_clock_stops_while_paused`

---

### Task 1: 鉄球を好きな場所に落とす

**Files:**
- Modify: `scripts/rules/iron_ball.gd`、`scripts/game/ball.gd`、`scripts/render/stack_camera.gd`、`scripts/game/stage_01.gd`、`scripts/game/area_02.gd`（Task 8 で消すまで動くように）
- Test: `tests/test_iron_ball.gd`、`tests/test_stack_camera.gd`

**Interfaces:**
- Produces:
  - `IronBall.REACH_PX := 24.0`、`IronBall.HIT_RADIUS := 8.0`、`IronBall.PICK_RADIUS := 6.0`
  - `var pos: Vector2`（`cell: Vector2i` は消し、`func cell() -> Vector2i` にする）
  - `signal landed(pos: Vector2, damage: int)`
  - `static func reach_point(from: Vector2, target: Vector2) -> Vector2`：target が24pxより遠ければ、その方向の24pxの点。
  - `static func can_drop_at(point: Vector2, map: HeightMap) -> bool`：点のマスで今と同じ判定。
  - `func drop_at(player: PlayerMover, map: HeightMap, target: Vector2) -> bool`：`reach_point` で縮めた点に落とす。`drop()` は消す。
  - `static func hits(land_pos: Vector2, land_h: int, other_pos: Vector2, other_h: int) -> bool`：距離8px未満かつ同じ高さ。
  - `static func touches_cell(land_pos: Vector2, cell: Vector2i) -> bool`：マスの四角と点の距離が8px以下。
  - `try_pick_up` は「中心から6px以内かつ同じ高さ」。
  - `StackCamera.pick_ground(screen: Vector2, map: HeightMap, max_h: int) -> Vector2`：高い段から順に `screen_to_world(screen, h*8)` を試し、そのマスの高さが h なら返す。見つからなければ高さ0の点。

- [ ] **Step 1: 失敗するテストを書く**（`test_iron_ball.gd` の古い `drop` のテストは `drop_at` に書き換える）

```gdscript
func test_reach_point_clamps_to_24px():
	assert_eq(IronBall.reach_point(Vector2.ZERO, Vector2(100, 0)), Vector2(24, 0))
	assert_eq(IronBall.reach_point(Vector2.ZERO, Vector2(10, 5)), Vector2(10, 5))

func test_drop_at_free_position_from_ledge():
	map.set_height(Vector2i(1, 1), 3)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	watch_signals(b)
	var target := p.pos + Vector2(13, 3)  # 隣のマス（高さ0）の、中心でない点
	assert_true(b.drop_at(p, map, target))
	b.update(1.0, p, map, rules)
	assert_signal_emitted_with_parameters(b, "landed", [target, 4])

func test_drop_at_far_cursor_lands_at_reach():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.drop_at(p, map, p.pos + Vector2(200, 0))
	assert_eq(b.pos, p.pos + Vector2(24, 0))

func test_cannot_drop_on_water_point():
	map.set_water(Vector2i(2, 1), true)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	assert_false(IronBall.new().drop_at(p, map, p.pos + Vector2(16, 0)))

func test_hits_needs_same_height_and_8px():
	assert_true(IronBall.hits(Vector2.ZERO, 1, Vector2(7, 0), 1))
	assert_false(IronBall.hits(Vector2.ZERO, 1, Vector2(9, 0), 1))
	assert_false(IronBall.hits(Vector2.ZERO, 1, Vector2(2, 0), 2))

func test_touches_cell_within_radius():
	# マス(2,1)は x 32〜48。点 x=26 は8px以内
	assert_true(IronBall.touches_cell(Vector2(26, 24), Vector2i(2, 1)))
	assert_false(IronBall.touches_cell(Vector2(20, 24), Vector2i(2, 1)))

func test_pick_up_within_6px():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.drop_at(p, map, p.pos + Vector2(10, 0))
	b.update(1.0, p, map, rules)
	assert_false(b.try_pick_up(p))
	p.pos += Vector2(5, 0)
	assert_true(b.try_pick_up(p))
```

`test_stack_camera.gd` に：

```gdscript
func test_pick_ground_prefers_high_cell_under_cursor():
	var m := HeightMap.new(Vector2i(4, 4))
	m.set_height(Vector2i(1, 1), 2)
	var cam := StackCamera.new()
	cam.focus = HeightMap.cell_center(Vector2i(1, 1))
	var screen := cam.world_to_screen(HeightMap.cell_center(Vector2i(1, 1)), 16)
	assert_eq(HeightMap.world_to_cell(cam.pick_ground(screen, m, 8)), Vector2i(1, 1))
	cam.free()
```

- [ ] **Step 2: 実行して失敗を確かめる**

Run: `./run_tests.sh test_iron_ball.gd` と `./run_tests.sh test_stack_camera.gd`
Expected: FAIL（`reach_point` などが無い）

- [ ] **Step 3: 実装する**

`IronBall` を上の Interfaces どおりに直す。届かない所に落ちた鉄球が戻るときは `pos = player.pos`。`Ball._process` は `world_pos = rules_ball.pos`。`stage_01` は `drop_at(player.mover, map, HeightMap.cell_center(player.mover.front_cell()))` を呼び、着地は `IronBall.hits` で判定する。`area_02` は Task 8 で消すので、`drop_at` にカーソルの地面の点（`camera.pick_ground`）を渡すだけ直す。照準の影は落ちる点に出す。

- [ ] **Step 4: 全テストを実行する**

Run: `./run_tests.sh`
Expected: すべて PASS

- [ ] **Step 5: コミット** `feat: 鉄球を手の届く範囲の好きな場所に落とせるようにする`

---

### Task 2: 敵1・敵2（段差と近接攻撃）

**Files:**
- Modify: `scripts/rules/enemy_walker.gd`、`scripts/game/enemy.gd`
- Create: `scripts/rules/melee_attack.gd`、`scripts/rules/enemy_kind.gd`
- Test: `tests/test_enemy.gd`、`tests/test_melee_attack.gd`

**Interfaces:**
- Produces:
  - `EnemyKind`（`class_name EnemyKind extends RefCounted`）：`enum Kind { WEAK, MELEE, SHOOTER }`、`static func hp(k) -> int`（1/2/1）、`static func climb(k) -> int`（0/1/0）、`static func shoots(k) -> bool`、`static func contact(k) -> bool`（WEAK と SHOOTER が true）。
  - `EnemyWalker._init(map, cell, dir, max_hp := MAX_HP, climb := 0)`、`var climb: int`、`var forbidden := {}`（入らないマスの辞書。Vector2i → true）。
  - `EnemyWalker.chase(target: Vector2, target_h: int) -> void`：`CHASE_RANGE := 48.0` 以内で高さの差が climb 以下なら、`dir` を目標への向きにする（climb 0 の敵は何もしない）。
  - 歩けるマス：壁・奈落・水・forbidden でなく、高さの差が climb 以下。入ったら `height` を更新。入れないときは、追っている間はその軸の動きを止めて止まり、往復の間は引き返す。
  - `MeleeAttack`：`const RANGE := 16.0`、`const WINDUP := 0.5`、`const COOLDOWN := 1.0`、`enum State { IDLE, WINDUP, COOLDOWN }`、`func update(delta, self_pos, self_h, target_pos, target_h) -> bool`（ためが終わった瞬間に、距離16px以内かつ高さの差1以下なら true）、`func is_winding_up() -> bool`。
  - `Enemy.setup(map, cell, dir, p, cam, kind: EnemyKind.Kind, first_shot_delay := SHOOT_INTERVAL)`。`signal melee_hit`。ためている間は体を明るく光らせる（`self_modulate`）。種類ごとに色を変える（WEAK 赤、MELEE 紫、SHOOTER 黄土色など）。

- [ ] **Step 1: 失敗するテストを書く**

```gdscript
# test_enemy.gd
func test_weak_walker_turns_at_one_level_step():
	map.set_height(Vector2i(3, 1), 1)
	var w := EnemyWalker.new(map, Vector2i(1, 1), Vector2.RIGHT, 1, 0)
	for i in 60: w.step(1.0 / 30)
	assert_lt(w.pos.x, HeightMap.cell_center(Vector2i(3, 1)).x)

func test_melee_walker_climbs_one_level():
	map.set_height(Vector2i(3, 1), 1)
	var w := EnemyWalker.new(map, Vector2i(1, 1), Vector2.RIGHT, 2, 1)
	for i in 60: w.step(1.0 / 30)
	assert_eq(w.height, 1)

func test_melee_walker_never_enters_two_level_step():
	map.set_height(Vector2i(3, 1), 2)
	map.set_water(Vector2i(1, 2), true)
	var w := EnemyWalker.new(map, Vector2i(2, 1), Vector2.RIGHT, 2, 1)
	w.forbidden[Vector2i(1, 1)] = true
	for i in 300:
		w.chase(HeightMap.cell_center(Vector2i(3, 1)), 2)
		w.step(1.0 / 30)
		var c := w.cell()
		assert_true(c != Vector2i(3, 1) and c != Vector2i(1, 2) and c != Vector2i(1, 1))

func test_chase_only_within_48px():
	var w := EnemyWalker.new(map, Vector2i(1, 1), Vector2.UP, 2, 1)
	w.chase(w.pos + Vector2(60, 0), 0)
	assert_eq(w.dir, Vector2.UP)
	w.chase(w.pos + Vector2(40, 0), 0)
	assert_eq(w.dir, Vector2.RIGHT)
```

```gdscript
# test_melee_attack.gd
extends GutTest
func test_hits_after_windup_when_still_close():
	var a := MeleeAttack.new()
	assert_false(a.update(0.1, Vector2.ZERO, 0, Vector2(10, 0), 0))
	assert_true(a.is_winding_up())
	assert_true(a.update(0.5, Vector2.ZERO, 0, Vector2(10, 0), 1))

func test_dodge_by_moving_away_or_two_levels_up():
	var a := MeleeAttack.new()
	a.update(0.1, Vector2.ZERO, 0, Vector2(10, 0), 0)
	assert_false(a.update(0.5, Vector2.ZERO, 0, Vector2(30, 0), 0))
	var b := MeleeAttack.new()
	b.update(0.1, Vector2.ZERO, 0, Vector2(10, 0), 0)
	assert_false(b.update(0.5, Vector2.ZERO, 0, Vector2(10, 0), 2))

func test_cooldown_before_next_windup():
	var a := MeleeAttack.new()
	a.update(0.1, Vector2.ZERO, 0, Vector2(10, 0), 0)
	a.update(0.5, Vector2.ZERO, 0, Vector2(10, 0), 0)
	a.update(0.5, Vector2.ZERO, 0, Vector2(10, 0), 0)
	assert_false(a.is_winding_up())
```

- [ ] **Step 2: 失敗を確かめる** `./run_tests.sh test_enemy.gd`、`./run_tests.sh test_melee_attack.gd`
- [ ] **Step 3: 実装する**（Interfaces どおり。`area_02`・`stage_01` の `Enemy.setup` 呼び出しを、WEAK／SHOOTER を渡す形に直す。stage_01 の敵は体力3のままにするため、`setup` の後で `walker.hp = 3` を入れてよい）
- [ ] **Step 4: 全テスト** `./run_tests.sh` → PASS
- [ ] **Step 5: コミット** `feat: 段差を登らない敵1と、1段登って近接攻撃する敵2`

---

### Task 3: エリアと大陸のデータ

**Files:**
- Create: `scripts/rules/area_def.gd`、`scripts/rules/exit_def.gd`、`scripts/rules/world_map.gd`
- Test: `tests/test_world_map.gd`

**Interfaces:**
- Produces:
  - `ExitDef`：`enum Edge { NORTH, EAST, SOUTH, WEST }`、`var edge: Edge`、`var from: int`、`var to: int`（辺にそったマスの範囲。両端を含む。北・南は x、東・西は y）、`var target: String`、`var door_id := ""`（空でなければ、門で閉じた出口）、`var opens_here := false`（このエリアの側から門を開けられる）、`func cells(size: Vector2i) -> Array[Vector2i]`、`static func dir(edge) -> Vector2i`（外向き。NORTH＝(0,-1)）。
  - `AreaDef`：`var id: String`、`var title: String`（画面に出す名前）、`var origin: Vector2i`（大陸の上の左上のマス）、`var heights: Array`、`var objects: Array`（Terrain.parse_layers の2層）、`var exits: Array[ExitDef]`、`var enemies: Array`（`[cell: Vector2i, dir: Vector2, kind: EnemyKind.Kind]`）、`var pickups: Array`（`[cell, RunState.PickupKind, amount]`）、`func size() -> Vector2i`、`func entry_safe_cells() -> Dictionary`（すべての出口のマスからチェビシェフ距離3以内のマス）。
  - `WorldMap`：`func add(a: AreaDef)`、`func area(id) -> AreaDef`、`func exit_through(area_id: String, cell: Vector2i, push: Vector2i) -> ExitDef`（cell がその出口のマスで、push が出口の外向きと同じなら返す。なければ null）、`func arrival(area_id: String, exit: ExitDef, cell: Vector2i) -> Dictionary`（`{"area": String, "cell": Vector2i}`。大陸の座標で一歩外のマス＝相手の出口のマス、そこから相手の内側へ1マス）、`func problems() -> Array[String]`（エリアが重なる、出口の相手がいない、相手の出口と大陸の上で重ならない、相手のエリアと辺を接していない、を文字で返す。問題なければ空）。

- [ ] **Step 1: 失敗するテストを書く**（2つの小さなエリア A（origin (0,0)、4×3）と B（origin (4,0)、5×3）を、A の東 y1〜2 と B の西 y1〜2 でつなぐ）

```gdscript
func test_exit_through_needs_outward_push():
	assert_not_null(world.exit_through("a", Vector2i(3, 1), Vector2i(1, 0)))
	assert_null(world.exit_through("a", Vector2i(3, 1), Vector2i(0, 1)))
	assert_null(world.exit_through("a", Vector2i(3, 0), Vector2i(1, 0)))

func test_arrival_is_one_cell_inside_matching_exit():
	var ex := world.exit_through("a", Vector2i(3, 2), Vector2i(1, 0))
	assert_eq(world.arrival("a", ex, Vector2i(3, 2)), {"area": "b", "cell": Vector2i(1, 2)})

func test_problems_empty_for_matching_exits():
	assert_eq(world.problems(), [])

func test_problems_reports_misaligned_exit():
	world.area("b").exits[0].from = 0
	world.area("b").exits[0].to = 0
	assert_gt(world.problems().size(), 0)

func test_problems_reports_overlap():
	world.area("b").origin = Vector2i(3, 0)
	assert_gt(world.problems().size(), 0)

func test_entry_safe_cells_radius_3():
	var safe := world.area("b").entry_safe_cells()
	assert_true(safe.has(Vector2i(3, 1)))
	assert_false(safe.has(Vector2i(4, 1)))
```

- [ ] **Step 2: 失敗を確かめる** `./run_tests.sh test_world_map.gd`
- [ ] **Step 3: 実装する**（Interfaces どおり）
- [ ] **Step 4: テスト** `./run_tests.sh test_world_map.gd` → PASS
- [ ] **Step 5: コミット** `feat: エリアと大陸のデータ（出口のつながりを確かめる）`

---

### Task 4: エリアをまたぐ持ち物・墓石・門・敵の復活

**Files:**
- Modify: `scripts/rules/run_state.gd`、`scripts/rules/gravestone.gd`
- Create: `scripts/rules/enemy_roster.gd`
- Test: `tests/test_run_state.gd`、`tests/test_enemy_roster.gd`

**Interfaces:**
- Produces:
  - `Gravestone.area_id: String`。
  - `RunState._init(checkpoint_area: String, checkpoint: Vector2i)`、`var checkpoint_area: String`。
  - `RunState.on_death(area_id: String, death_cell: Vector2i) -> Gravestone`。
  - 拾いものと門の id は文字列（`"%s:%d" % [area_id, index]`、門は `ExitDef.door_id`）。`collect(id: String, kind, amount)`、`is_picked(id: String)`、`open_door(id: String)`、`is_door_open(id: String)`。
  - `RunState.is_near_checkpoint(area_id: String, cell: Vector2i) -> bool`。
  - `EnemyRoster`：`const RESPAWN_SECONDS := 300.0`、`var clock := 0.0`、`func tick(delta: float)`、`func kill(area_id: String, index: int)`、`func present(area_id: String, index: int) -> bool`（倒されていないか、倒してから300秒以上たった。たっていたら記録を消す）。
- 試作2の `area_02` と `test_run_state.gd` の呼び出しは、仮のエリア名 `"area_02"` を渡す形に直す（Task 8 で area_02 ごと消す）。

- [ ] **Step 1: 失敗するテストを書く**

```gdscript
# test_enemy_roster.gd
func test_killed_enemy_returns_after_300s():
	var r := EnemyRoster.new()
	r.kill("hills", 2)
	assert_false(r.present("hills", 2))
	r.tick(299.0)
	assert_false(r.present("hills", 2))
	r.tick(1.0)
	assert_true(r.present("hills", 2))

func test_other_area_same_index_is_separate():
	var r := EnemyRoster.new()
	r.kill("hills", 2)
	assert_true(r.present("rocks", 2))
```

```gdscript
# test_run_state.gd に足す
func test_grave_remembers_area():
	var run := RunState.new("camp", Vector2i(5, 5))
	var g := run.on_death("hills", Vector2i(3, 4))
	assert_eq(g.area_id, "hills")

func test_pickup_ids_per_area():
	var run := RunState.new("camp", Vector2i(5, 5))
	assert_true(run.collect("hills:0", RunState.PickupKind.MONEY, 5))
	assert_true(run.collect("rocks:0", RunState.PickupKind.MONEY, 5))
	assert_false(run.collect("hills:0", RunState.PickupKind.MONEY, 5))

func test_checkpoint_only_in_its_area():
	var run := RunState.new("camp", Vector2i(5, 5))
	assert_true(run.is_near_checkpoint("camp", Vector2i(6, 5)))
	assert_false(run.is_near_checkpoint("hills", Vector2i(6, 5)))
```

- [ ] **Step 2: 失敗を確かめる** `./run_tests.sh test_enemy_roster.gd`、`./run_tests.sh test_run_state.gd`
- [ ] **Step 3: 実装する**
- [ ] **Step 4: 全テスト** `./run_tests.sh` → PASS
- [ ] **Step 5: コミット** `feat: 墓石・拾いもの・門をエリアごとに覚え、倒した敵を5分で戻す`

---

### Task 5: エリアの端を外へ歩いたことを知らせる

**Files:**
- Modify: `scripts/rules/player_mover.gd`
- Test: `tests/test_player_mover.gd`

**Interfaces:**
- Produces: `PlayerMover.edge_push: Vector2i`。`move()` のたびに ZERO に戻し、マップの外のマスへ入ろうとして止まったら、外への向き（(1,0) など。斜めなら、外に出る方の軸だけ）を入れる。

- [ ] **Step 1: 失敗するテスト**

```gdscript
func test_edge_push_when_walking_out_of_map():
	var m := HeightMap.new(Vector2i(4, 4))
	var p := PlayerMover.new(m, MovementRules.new())
	p.place(Vector2i(3, 1))
	p.move(Vector2(10, 0))
	assert_eq(p.edge_push, Vector2i(1, 0))
	p.move(Vector2(-1, 0))
	assert_eq(p.edge_push, Vector2i.ZERO)

func test_no_edge_push_at_inner_wall():
	var m := HeightMap.new(Vector2i(4, 4))
	m.set_wall(Vector2i(2, 1), true)
	var p := PlayerMover.new(m, MovementRules.new())
	p.place(Vector2i(1, 1))
	p.move(Vector2(10, 0))
	assert_eq(p.edge_push, Vector2i.ZERO)
```

- [ ] **Step 2: 失敗を確かめる** `./run_tests.sh test_player_mover.gd`
- [ ] **Step 3: 実装する**
- [ ] **Step 4: テスト** → PASS
- [ ] **Step 5: コミット** `feat: エリアの端を外へ歩こうとした向きを覚える`

---

### Task 6: 高さを読みやすくする描き方と、出口の矢印・影

**Files:**
- Modify: `scripts/game/terrain.gd`、`scripts/game/player.gd`、`scripts/game/enemy.gd`
- Test: `tests/test_terrain.gd`

**Interfaces:**
- Produces:
  - `Terrain.ground_model(h, depth, v, flowers, bottom, lower_sides := 0)`：`lower_sides` は隣が低い辺のビット（1＝北、2＝東、4＝南、8＝西）。その辺の上の面の1列を明るい色にする。側面は、1段（8枚）ごとに1枚、少し暗い帯を入れ、下へ行くほど暗くする。上の面の色は高さ1段ごとに少しずつ明るくする（`Terrain.top_color(h: int) -> Color`、h が大きいほど明るい。0〜8）。
  - `Terrain.lower_sides(map, cell) -> int`。
  - `Terrain.arrow_model() -> VoxelModel`（地面に置く平たい矢印。北向き。回転は `StackSprite` の向きで付ける）。
  - プレイヤーと敵の足元に、半透明の黒い楕円の影（1枚の輪切り）。
- 色の細かい値は画面を見て決める。スクリーンショット（`xvfb-run -a godot --path . --rendering-driver opengl3 res://scenes/area_02.tscn -- --screenshot=out.png`）で、段の数が数えられるかを確かめる。

- [ ] **Step 1: 失敗するテスト**

```gdscript
func test_lower_sides_bits():
	var m := HeightMap.new(Vector2i(3, 3))
	m.set_height(Vector2i(1, 1), 2)
	m.set_height(Vector2i(1, 0), 2)
	assert_eq(Terrain.lower_sides(m, Vector2i(1, 1)), 2 | 4 | 8)

func test_top_color_brighter_when_higher():
	assert_gt(Terrain.top_color(5).v, Terrain.top_color(1).v)

func test_edge_highlight_on_lower_side():
	var plain := Terrain.ground_model(2, 3, 0, false, -1, 0)
	var lit := Terrain.ground_model(2, 3, 0, false, -1, 2)
	var top := plain.size.z - 1
	assert_gt(lit.get_voxel(Vector3i(15, 8, top)).v, plain.get_voxel(Vector3i(15, 8, top)).v)
```

（`VoxelModel.get_voxel` が無ければ足す。今の `ground_model` の引数の並びに合わせてテストを直してよいが、上の3つの性質は変えない。）

- [ ] **Step 2: 失敗を確かめる** `./run_tests.sh test_terrain.gd`
- [ ] **Step 3: 実装し、`Terrain.build` から `lower_sides` を渡す。影を足す**
- [ ] **Step 4: 全テストとスクリーンショットで確かめる** `./run_tests.sh` → PASS
- [ ] **Step 5: コミット** `feat: 段のふちの明るい線・側面の帯・高さで変わる色で、高さを読みやすくする`

---

### Task 7: 4エリアの地図を作るスクリプト

**Files:**
- Create: `tools/area_maps/`（`tools/island_map/` を土台に作り直す。`gen.py`・`check.py`・`place.py`・`splice.py`・`README.md`）
- Create: `scripts/areas/camp.gd`、`rocks.gd`、`hills.gd`、`forest.gd`（各 `static func def() -> AreaDef`。HEIGHTS・OBJECTS・ENEMIES・PICKUPS は生成した定数）、`scripts/areas/continent.gd`（`static func build() -> WorldMap`）
- Delete: `tools/island_map/`
- Test: `tests/test_areas_layout.gd`（`tests/helpers/reach.gd` を使う）

**Interfaces:**
- Consumes: Task 3 の `AreaDef`・`ExitDef`・`WorldMap`、Task 2 の `EnemyKind.Kind`、Task 4 の文字列 id。
- Produces: `Continent.build() -> WorldMap`（id は `"camp"`、`"rocks"`、`"hills"`、`"forest"`）、`Continent.START_AREA := "camp"`、`Continent.START_CELL: Vector2i`。たき火は camp の `C` の記号。門は forest→camp の出口の `door_id = "forest_gate"`（forest 側だけ `opens_here = true`）。

大陸の上の置き方（目安。WorldMap.problems() が空になること）：camp 24×20 を origin (0,0)、rocks 40×32 を西（origin.x = -40、camp の西の辺と重なる y の範囲に出口）、hills 48×36 を東（origin.x = 24）、forest 56×40 を北（origin.y = -40、x は camp と hills の両方の北の辺にかかる範囲）。

gen.py の地形の作り方：なめらかなノイズを0〜8に量子化して細かい段差を作り、2段以上の差は所々の崖だけに残す（それ以外は1段の段差になるようにならす）。エリアのふちまで地面にする（島の外は作らない）。出口のマスとその内側3マスは平らにし、出口に向けて登り道を作る。岩場は岩と崖、丘陵は段々と川、奥の森は木と高い崖、野営地は平らな広場とたき火。くぼみをふさぐ処理は今のものを使う。

- [ ] **Step 1: 失敗するテストを書く**

```gdscript
func test_continent_has_no_problems():
	assert_eq(Continent.build().problems(), [])

func test_every_exit_reachable_from_every_exit():
	# 各エリアで、門で閉じていない出口どうしが、歩いて行き来できる（reach.gd）

func test_heights_within_0_to_8_and_flats_small():
	# 各エリアの高さが0〜8。camp 以外で、同じ高さが続く平地が 12×12 の四角を含まない

func test_no_enemy_near_entries():
	# どの敵の初期マスも entry_safe_cells() に入らない

func test_route_lengths():
	# たき火→丘陵→森の強い鉄球の歩きの距離が 90秒以上、門を開けた後 強い鉄球→たき火 が 30秒以内（エリアをまたぐ距離は出口でつなぐ）

func test_shooters_only_in_forest():
	# SHOOTER は forest にだけいる。rocks・hills は WEAK が多い

func test_no_pocket_without_exit():
	# 今の test_area_02_layout.gd と同じ考えで、落ちたら出られないくぼみがない（各エリア）
```

（コメントの所は、`test_area_02_layout.gd` の書き方をそのまま使って実際のアサーションを書く。）

- [ ] **Step 2: 失敗を確かめる** `./run_tests.sh test_areas_layout.gd`
- [ ] **Step 3: スクリプトで地図を作り、`splice.py` で `scripts/areas/*.gd` に書き込む**
- [ ] **Step 4: テスト** `./run_tests.sh test_areas_layout.gd` → PASS
- [ ] **Step 5: コミット** `feat: 野営地・岩場・丘陵・奥の森の地図と、それを作るスクリプト`

---

### Task 8: エリアを入れ替えるメインシーン

**Files:**
- Create: `scripts/game/field.gd`、`scenes/field.tscn`
- Modify: `project.godot`（メインシーンを `res://scenes/field.tscn` に）
- Delete: `scenes/area_02.tscn`、`scripts/game/area_02.gd`、`tests/test_area_02.gd`、`tests/test_area_02_layout.gd`
- Test: `tests/test_field.gd`（`test_area_02.gd` の中身のうち、まだ当てはまるもの――死と墓石、回復、インベントリ、門、体当たりの無敵――を移す）

**Interfaces:**
- Consumes: Task 1〜7 のすべて。
- Produces（テストから使うもの）：
  - `var world: WorldMap`、`var area: AreaDef`、`var map: HeightMap`、`var run: RunState`、`var roster: EnemyRoster`、`var player: Player`、`var enemies: Array[Enemy]`
  - `func enter_area(id: String, cell: Vector2i) -> void`：`_area_root` の子を全部消して、地形・印・矢印・敵（`roster.present` のものだけ。`entry_safe_cells` を `forbidden` に入れる）・墓石（`run.grave.area_id == id` のときだけ、マスをふさぐ）を作る。地面の鉄球は手に戻す。弾は消す。名前を2秒出す。
  - `func is_switching() -> bool`：暗くしている間と明るくしている間。
  - 切り替え：`_play_step` で `world.exit_through(area.id, player.mover.cell(), player.mover.edge_push)` が返り、門で閉じていなければ、0.2秒暗くして `enter_area`、0.2秒で明るく。この間は入力・敵・弾を止める。
  - 門で閉じた出口：矢印は出さず、門の見た目を出口のマスに置く。`opens_here` の側で出口のマスに立つと「F：門を開ける」。
  - 死ぬ：`run.on_death(area.id, cell)`、1.5秒後に `enter_area(run.checkpoint_area, START_CELL)`。敵は復活しない（ただし checkpoint のエリアへ入るので、`present` の判定はそこで行われる）。
  - 時計：`_process` で `roster.tick(delta)`（`get_tree().paused` の間は `_process` が止まるので進まない）。
  - UI：今の2行に、墓石があれば「墓石：<エリアの名前>」を足す。ゴールと「クリア」は消す。始めのヒントは「矢印の端から、となりのエリアへ行ける」。
  - 鉄球：左クリックで `ball.rules_ball.drop_at(player.mover, map, camera.pick_ground(mouse, map, 8))`。照準の影は `reach_point` の点に出す。着地で `IronBall.hits` の敵にダメージ、`touches_cell` で墓石が壊れる。
  - 敵2の `melee_hit` で `player.take_hit()`。体当たりは `EnemyKind.contact` の敵だけ。
  - スクリーンショットの引数（`--screenshot`、`--angle`、`--player=x,y`、`--fps`、`--inventory`）に `--area=<id>` を足す。

- [ ] **Step 1: 失敗するテストを書く**（`test_area_02.gd` の書き方で、`load("res://scenes/field.tscn")`）

```gdscript
func test_walking_out_through_exit_switches_area():
	# camp の東の出口のマスに置き、東へ動かし続ける → 0.4秒あとに area.id == "hills"、
	# プレイヤーは hills の西の出口の1マス内側

func test_arrival_does_not_bounce_back():
	# 切り替えた直後に何もしなければ、2秒たっても area.id は変わらない

func test_input_ignored_while_switching():
	# 切り替え中に use_item()・try_open_door()・open_inventory() がすべて false

func test_killed_enemy_stays_dead_on_death_and_returns_after_300s_and_reentry():
	# hills で敵0を倒す → 死ぬ → camp で再開 → hills へ入っても敵0はいない
	# → roster.tick(300) → camp へ出て hills へ入り直すと敵0がいる

func test_enemy_not_back_while_staying_in_area():
	# hills で敵0を倒し、roster.tick(301) しても、hills にいる間は enemies に戻らない

func test_grave_blocks_only_in_its_area():
	# hills のマス c で死ぬ → camp では map.is_grave(c) が false → hills に入ると true

func test_gate_opens_only_from_forest_side():
	# camp の北の出口を外へ歩いても切り替わらない。forest の出口のマスで try_open_door() → true
	# その後 camp の北の出口から forest へ行ける

func test_clock_stops_while_paused():
	# open_inventory() の後、数フレーム回しても roster.clock が増えない

func test_ball_lands_where_aimed():
	# 平らな所で drop_at(player.mover.pos + Vector2(10, 4)) → 着地点に敵を置いておくと体力が減る
```

（コメントの所は、実際に GUT のアサーションで書く。）

- [ ] **Step 2: 失敗を確かめる** `./run_tests.sh test_field.gd`
- [ ] **Step 3: 実装する。area_02 とそのテストを消す**
- [ ] **Step 4: 全テストと、各エリアのスクリーンショット（`--area=camp` など4枚、角度を2つ）で確かめる。`--fps` で一番大きい forest が 60 FPS 前後か見る**
- [ ] **Step 5: コミット** `feat: 4つのエリアを歩いて行き来するメインシーン（箱庭の島を置き換える）`

---

### Task 9: 文書と、遊べる形で渡す

**Files:**
- Modify: `docs/design.md`（設計メモ12章のとおり 6・7・8・10章を直す）、`CLAUDE.md`（現状・構成・操作・テスト件数・地図のスクリプト）、`docs/superpowers/specs/2026-11-24-world-areas-design.md`（冒頭に「承認済み・実装済み」）

- [ ] **Step 1: 文書を直す**
- [ ] **Step 2: 全テスト** `./run_tests.sh` → PASS（件数を CLAUDE.md に書く）
- [ ] **Step 3: コミットして push** `docs: 試作3に合わせて仕様書と CLAUDE.md を直す` → `git push -u origin claude/project-thread-gkcqe0`
- [ ] **Step 4: プロジェクトを zip にして `/mnt/project-files/builds/` に置く**（前回と同じ作り方。`.godot/` と生成物は入れない）
