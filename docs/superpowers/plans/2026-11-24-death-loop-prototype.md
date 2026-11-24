# 試作2「死と取り返しの流れ」 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 広いエリア1つで、死ぬ → チェックポイントから再開 → 墓石を叩いて取り返す、という流れを遊べるようにする。

**Architecture:** 死んだときに何が残り何が戻るかは `scripts/rules/` の RefCounted クラス（`Inventory`、`Gravestone`、`RunState`、`AreaState`）に集め、GUTで単体テストする。ステージはシーンを読み込み直さず（作り方B）、ルールの結果に合わせて敵ノードを作り直し、弾を消し、プレイヤーをチェックポイントへ移す。墓石と閉じた扉は `HeightMap` の「ふさぐもの」として持ち、移動・敵・弾が今の壁判定のまま止まるようにする。

**Tech Stack:** Godot 4.5、GDScript、GUT 9.5.0（同梱）。

**Spec:** `docs/superpowers/specs/2026-11-23-death-loop-design.md`（全体の仕様は `docs/design.md`）

## Global Constraints

- 新しいルールは `scripts/rules/` に RefCounted クラスとして書き、先にGUTで失敗するテストを書いてから実装する。
- 既存の58件のテストはすべて通ったままにする（`./run_tests.sh`）。
- 1マス＝16px、1段＝輪切り8枚（画面で8px）。描画解像度320×180、拡大は整数倍のみ。
- `z_index` は奥行きで決め、動くもの（墓石は動かないが、プレイヤーと同じマスに並ぶもの）は `sort_by_cell=true`。
- コメントとコミットメッセージは日本語。UIの文字は英語。
- 死んだらシーンを読み込み直さない（`reload_current_scene` を死亡処理に使わない）。
- 鉄球は1つずつ。場に出せるのは常に1つで、切り替えは手に持っているときだけ。
- 試作1（`scenes/stage_01.tscn`）は残す。新しいエリアをメインシーンにする。
- 仮の数値：敵1体のお金10・経験値1、回復1つで体力+1（最大3）、YOU DIEDの表示1.5秒、奈落の落ちる演出0.5秒。

## Review Focus

1. **死亡処理中にもう一度死ぬ**（倒れている間に弾が当たる、落ちている間に体力が0になる）：死ぬのは1回だけで、墓石は1つだけできる。→ Task 5 `test_second_death_while_dying_is_ignored`
2. **持ち物が空のまま死ぬ**：空の墓石ができ、古い墓石は中身ごと消える（新しく死ぬと古いのが消える、の通り）。→ Task 4 `test_empty_death_still_replaces_old_grave`
3. **お金が奇数のときに死ぬ**：25なら墓石に12、手元に13。→ Task 4 `test_odd_money_keeps_larger_half`
4. **奈落で死んだときの墓石の位置**：奈落のマスには置かず、最後に立っていた奈落以外のマス。→ Task 2 `test_last_safe_cell_skips_pit`
5. **再開した直後に古い弾が飛んでくる**：死んだ時点で飛んでいた弾はすべて消え、敵は撃つまでの待ち時間も初期値に戻る。→ Task 8 `test_respawn_clears_bullets_and_resets_enemies`

---

## ファイル構成

```
scripts/rules/height_map.gd     変更：奈落、ふさぐもの（墓石・扉）
scripts/rules/player_mover.gd   変更：奈落へ踏み込む、最後に立った安全なマス
scripts/rules/enemy_walker.gd   変更：奈落の前で引き返す
scripts/rules/iron_ball.gd      変更：強い鉄球、奈落に落とせない、墓石に落とせる、手元に戻す
scripts/rules/inventory.gd      新規：お金・素材・回復・強い鉄球・経験値
scripts/rules/gravestone.gd     新規：墓石の場所と中身
scripts/rules/run_state.gd      新規：死んだときの持ち物の移し替え、拾い済み、開けた扉、チェックポイント
scripts/rules/area_state.gd     新規：PLAYING / DYING / CLEAR と再開のタイミング
scripts/game/terrain.gd         新規：stage_01 から地形の作り方を切り出す（共有）
scripts/game/area_02.gd + scenes/area_02.tscn  新規：試作2のエリア
scripts/game/ball.gd            変更：1/2 で切り替え、強い鉄球の色
scripts/game/player.gd          変更：体力を外から設定、落ちる演出
tests/helpers/reach.gd          新規：テスト用の経路探索（test_ で始めないのでGUTは実行しない）
tests/test_*.gd                 追加・変更
```

---

### Task 1: HeightMap に奈落とふさぐものを足す

**Files:**
- Modify: `scripts/rules/height_map.gd`
- Test: `tests/test_height_map.gd`

**Interfaces:**
- Produces:
  - `enum Blocker { NONE, GRAVE, DOOR }`
  - `set_pit(cell: Vector2i, pit: bool) -> void`、`is_pit(cell: Vector2i) -> bool`（マップ外は false）
  - `set_blocker(cell: Vector2i, kind: Blocker) -> void`、`get_blocker(cell: Vector2i) -> Blocker`、`is_grave(cell) -> bool`
  - `is_wall(cell)` は「壁、またはふさぐものが NONE 以外」なら true（マップ外は今どおり true）。`set_blocker(cell, NONE)` で元の地形に戻る。

- [ ] **Step 1: 失敗するテストを書く**

```gdscript
func test_pit_flag():
	var m := HeightMap.new(Vector2i(4, 4))
	m.set_pit(Vector2i(1, 1), true)
	assert_true(m.is_pit(Vector2i(1, 1)))
	assert_false(m.is_pit(Vector2i(2, 1)))
	assert_false(m.is_pit(Vector2i(-1, 0)))
	assert_false(m.is_wall(Vector2i(1, 1)))

func test_blocker_acts_as_wall_and_clears():
	var m := HeightMap.new(Vector2i(4, 4))
	m.set_height(Vector2i(2, 2), 1)
	m.set_blocker(Vector2i(2, 2), HeightMap.Blocker.GRAVE)
	assert_true(m.is_wall(Vector2i(2, 2)))
	assert_true(m.is_grave(Vector2i(2, 2)))
	m.set_blocker(Vector2i(2, 2), HeightMap.Blocker.NONE)
	assert_false(m.is_wall(Vector2i(2, 2)))
	assert_eq(m.get_height(Vector2i(2, 2)), 1)

func test_door_is_wall_but_not_grave():
	var m := HeightMap.new(Vector2i(4, 4))
	m.set_blocker(Vector2i(0, 0), HeightMap.Blocker.DOOR)
	assert_true(m.is_wall(Vector2i(0, 0)))
	assert_false(m.is_grave(Vector2i(0, 0)))
```

- [ ] **Step 2: 失敗を確かめる** — Run: `./run_tests.sh test_height_map.gd` / Expected: 新しい3件が FAIL（関数がない）
- [ ] **Step 3: 実装する** — `_pits: PackedByteArray`、`_blockers: PackedByteArray` を `_walls` と同じ並びで持つ。
- [ ] **Step 4: 通ることを確かめる** — Run: `./run_tests.sh` / Expected: 全件 PASS（既存58件を含む）
- [ ] **Step 5: コミット** — `git commit -m "feat: 高さマップに奈落と墓石・扉のふさぎを足す"`

---

### Task 2: 奈落への踏み込みと、敵が奈落で引き返す

**Files:**
- Modify: `scripts/rules/player_mover.gd`, `scripts/rules/enemy_walker.gd`
- Test: `tests/test_player_mover.gd`, `tests/test_enemy.gd`

**Interfaces:**
- Consumes: `HeightMap.is_pit`
- Produces:
  - `PlayerMover.fell: bool`（奈落のマスに入った瞬間 true。以後 `move` は何もしない）
  - `PlayerMover.last_safe_cell: Vector2i`（最後に立っていた奈落以外のマス。`_init` 後は呼び出し側が `place(cell)` で設定）
  - `PlayerMover.place(cell: Vector2i) -> void`：pos をマスの中心、height をそのマスの高さ、`fell=false`、`last_safe_cell=cell` にする（再開時とテストで使う）
  - 奈落のマスは高さに関係なく踏み込める（`can_step` を見ない）。

- [ ] **Step 1: 失敗するテストを書く**

```gdscript
# test_player_mover.gd
func test_walking_into_pit_falls():
	map.set_pit(Vector2i(2, 1), true)
	var p := PlayerMover.new(map, rules)
	p.place(Vector2i(1, 1))
	for i in 20:
		p.move(Vector2(2, 0))
	assert_true(p.fell)
	assert_eq(p.cell(), Vector2i(2, 1))

func test_last_safe_cell_skips_pit():
	map.set_pit(Vector2i(3, 1), true)
	var p := PlayerMover.new(map, rules)
	p.place(Vector2i(1, 1))
	for i in 40:
		p.move(Vector2(2, 0))
	assert_true(p.fell)
	assert_eq(p.last_safe_cell, Vector2i(2, 1))

func test_no_move_after_fall():
	map.set_pit(Vector2i(2, 1), true)
	var p := PlayerMover.new(map, rules)
	p.place(Vector2i(1, 1))
	for i in 20:
		p.move(Vector2(2, 0))
	var before := p.pos
	p.move(Vector2(0, 5))
	assert_eq(p.pos, before)

# test_enemy.gd
func test_enemy_turns_at_pit():
	var m := HeightMap.new(Vector2i(6, 3))
	m.set_pit(Vector2i(3, 1), true)
	var w := EnemyWalker.new(m, Vector2i(1, 1), Vector2.RIGHT)
	for i in 200:
		w.step(0.05)
		assert_ne(w.cell(), Vector2i(3, 1))
```

（`test_player_mover.gd` に `map` と `rules` を用意する `before_each` がなければ足す。）

- [ ] **Step 2: 失敗を確かめる** — Run: `./run_tests.sh test_player_mover.gd` と `test_enemy.gd` / Expected: 新しい4件が FAIL
- [ ] **Step 3: 実装する** — `_try` で行き先が奈落なら移動を許して `fell=true`。マスが変わって奈落でなければ `last_safe_cell` を更新。`EnemyWalker.step` の引き返す条件に `map.is_pit(ahead)` を足す。
- [ ] **Step 4: 通ることを確かめる** — Run: `./run_tests.sh` / Expected: 全件 PASS
- [ ] **Step 5: コミット** — `git commit -m "feat: 奈落に落ちる・敵は奈落の前で引き返す"`

---

### Task 3: 強い鉄球と、奈落・墓石への落とし方

**Files:**
- Modify: `scripts/rules/iron_ball.gd`
- Test: `tests/test_iron_ball.gd`

**Interfaces:**
- Consumes: `HeightMap.is_pit`, `HeightMap.is_grave`
- Produces:
  - `IronBall.strong: bool`（初期 false）
  - `static func damage_for(levels: int, strong: bool = false) -> int`：普通は `maxi(1, levels + 1)`、強いは `maxi(2, levels + 2)`
  - `set_strong(v: bool) -> bool`：`state == HELD` のときだけ切り替えて true。それ以外は何もせず false。
  - `return_to_hand() -> void`：状態を HELD に戻す（死んだとき用）。
  - `drop` は奈落のマスには落とせない（false）。目の前が墓石のマスなら、壁でも落とせる（`height` は墓石のマスの地面の高さ）。
  - `landed` の damage は `damage_for(fall_levels, strong)`。

- [ ] **Step 1: 失敗するテストを書く**

```gdscript
func test_strong_damage_table():
	assert_eq(IronBall.damage_for(0, true), 2)
	assert_eq(IronBall.damage_for(1, true), 3)
	assert_eq(IronBall.damage_for(-1, true), 2)

func test_switch_only_when_held():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	assert_true(b.set_strong(true))
	b.drop(p, map)
	assert_false(b.set_strong(false))
	assert_true(b.strong)

func test_strong_ball_lands_with_strong_damage():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.set_strong(true)
	watch_signals(b)
	b.drop(p, map)
	b.update(1.0, p, map, rules)
	assert_signal_emitted_with_parameters(b, "landed", [Vector2i(2, 1), 2])

func test_cannot_drop_into_pit():
	map.set_pit(Vector2i(2, 1), true)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	assert_false(b.drop(p, map))
	assert_eq(b.state, IronBall.State.HELD)

func test_can_drop_onto_grave():
	map.set_blocker(Vector2i(2, 1), HeightMap.Blocker.GRAVE)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	assert_true(b.drop(p, map))

func test_cannot_drop_onto_door():
	map.set_blocker(Vector2i(2, 1), HeightMap.Blocker.DOOR)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	assert_false(IronBall.new().drop(p, map))

func test_return_to_hand():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.drop(p, map)
	b.return_to_hand()
	assert_eq(b.state, IronBall.State.HELD)
```

- [ ] **Step 2: 失敗を確かめる** — Run: `./run_tests.sh test_iron_ball.gd` / Expected: 新しい7件が FAIL
- [ ] **Step 3: 実装する**
- [ ] **Step 4: 通ることを確かめる** — Run: `./run_tests.sh` / Expected: 全件 PASS
- [ ] **Step 5: コミット** — `git commit -m "feat: 強い鉄球と、奈落・墓石への落とし方"`

---

### Task 4: 持ち物・墓石・冒険の状態（死んだときの移し替え）

**Files:**
- Create: `scripts/rules/inventory.gd`, `scripts/rules/gravestone.gd`, `scripts/rules/run_state.gd`
- Test: `tests/test_run_state.gd`

**Interfaces:**
- Produces:
  - `class_name Inventory extends RefCounted`：`money: int`、`materials: int`、`heals: int`、`has_strong_ball: bool`、`exp: int`（すべて初期0/false）。`try_use_heal(hp: int, max_hp: int) -> bool`：`heals > 0 and hp < max_hp` のとき heals を1減らして true。
  - `class_name Gravestone extends RefCounted`：`cell: Vector2i`、`money: int`、`materials: int`、`heals: int`、`has_strong_ball: bool`。
  - `class_name RunState extends RefCounted`：
    - `const ENEMY_MONEY := 10`、`const ENEMY_EXP := 1`
    - `inventory: Inventory`、`grave: Gravestone`（なければ null）、`checkpoint_cell: Vector2i`
    - `_init(checkpoint: Vector2i)`
    - `on_death(death_cell: Vector2i) -> Gravestone`：墓石に `money / 2`（切り捨て）、素材・回復・強い鉄球をすべて移し、手元にはお金の残りと経験値だけ残す。古い墓石は捨てて新しい墓石を `grave` にし、それを返す。
    - `break_grave() -> void`：墓石の中身をすべて手元に足し、`grave = null`。墓石がなければ何もしない。
    - `on_enemy_killed() -> void`：お金 +10、経験値 +1。
    - `enum PickupKind { MONEY, MATERIAL, HEAL, STRONG_BALL }`
    - `collect(id: int, kind: PickupKind, amount: int) -> bool`：拾い済みなら false。そうでなければ手元に足し、拾い済みにして true（STRONG_BALL は amount を見ず `has_strong_ball=true`、HEAL・MATERIAL・MONEY は amount を足す）。
    - `is_picked(id: int) -> bool`
    - `open_door(id: int) -> void`、`is_door_open(id: int) -> bool`
    - `is_near_checkpoint(cell: Vector2i) -> bool`：チェックポイントのマスか、その8近傍なら true。

- [ ] **Step 1: 失敗するテストを書く**

```gdscript
extends GutTest

var rs: RunState

func before_each():
	rs = RunState.new(Vector2i(1, 1))

func _fill():
	rs.inventory.money = 40
	rs.inventory.materials = 3
	rs.inventory.heals = 2
	rs.inventory.has_strong_ball = true
	rs.inventory.exp = 5

func test_death_moves_belongings_to_grave():
	_fill()
	var g := rs.on_death(Vector2i(9, 4))
	assert_eq(g.cell, Vector2i(9, 4))
	assert_eq([g.money, g.materials, g.heals, g.has_strong_ball], [20, 3, 2, true])
	var inv := rs.inventory
	assert_eq([inv.money, inv.materials, inv.heals, inv.has_strong_ball, inv.exp], [20, 0, 0, false, 5])

func test_odd_money_keeps_larger_half():
	rs.inventory.money = 25
	var g := rs.on_death(Vector2i(2, 2))
	assert_eq(g.money, 12)
	assert_eq(rs.inventory.money, 13)

func test_break_grave_returns_everything():
	_fill()
	rs.on_death(Vector2i(9, 4))
	rs.break_grave()
	var inv := rs.inventory
	assert_eq([inv.money, inv.materials, inv.heals, inv.has_strong_ball, inv.exp], [40, 3, 2, true, 5])
	assert_null(rs.grave)

func test_second_death_erases_old_grave():
	_fill()
	rs.on_death(Vector2i(9, 4))          # 墓石に 20, 手元 20
	rs.inventory.materials = 1
	var g2 := rs.on_death(Vector2i(3, 3)) # 墓石に 10, 手元 10
	assert_eq(rs.grave, g2)
	assert_eq([g2.money, g2.materials, g2.has_strong_ball], [10, 1, false])
	rs.break_grave()
	assert_eq(rs.inventory.money, 20)
	assert_false(rs.inventory.has_strong_ball)

func test_empty_death_still_replaces_old_grave():
	_fill()
	rs.on_death(Vector2i(9, 4))
	rs.inventory.money = 0
	var g2 := rs.on_death(Vector2i(3, 3))
	assert_eq(rs.grave, g2)
	assert_eq([g2.money, g2.materials, g2.heals, g2.has_strong_ball], [0, 0, 0, false])

func test_break_without_grave_does_nothing():
	rs.break_grave()
	assert_eq(rs.inventory.money, 0)

func test_enemy_reward():
	rs.on_enemy_killed()
	assert_eq([rs.inventory.money, rs.inventory.exp], [10, 1])

func test_pickups_only_once():
	assert_true(rs.collect(7, RunState.PickupKind.MONEY, 15))
	assert_false(rs.collect(7, RunState.PickupKind.MONEY, 15))
	assert_true(rs.is_picked(7))
	assert_eq(rs.inventory.money, 15)
	rs.collect(8, RunState.PickupKind.STRONG_BALL, 0)
	rs.collect(9, RunState.PickupKind.HEAL, 1)
	rs.collect(10, RunState.PickupKind.MATERIAL, 2)
	assert_eq([rs.inventory.has_strong_ball, rs.inventory.heals, rs.inventory.materials], [true, 1, 2])

func test_pickups_stay_picked_after_death():
	rs.collect(7, RunState.PickupKind.HEAL, 1)
	rs.on_death(Vector2i(2, 2))
	assert_true(rs.is_picked(7))

func test_doors_stay_open_after_death():
	rs.open_door(0)
	rs.on_death(Vector2i(2, 2))
	assert_true(rs.is_door_open(0))
	assert_false(rs.is_door_open(1))

func test_heal_use():
	rs.inventory.heals = 1
	assert_false(rs.inventory.try_use_heal(3, 3))
	assert_eq(rs.inventory.heals, 1)
	assert_true(rs.inventory.try_use_heal(2, 3))
	assert_eq(rs.inventory.heals, 0)
	assert_false(rs.inventory.try_use_heal(1, 3))

func test_near_checkpoint():
	assert_true(rs.is_near_checkpoint(Vector2i(1, 1)))
	assert_true(rs.is_near_checkpoint(Vector2i(2, 2)))
	assert_false(rs.is_near_checkpoint(Vector2i(3, 1)))
```

- [ ] **Step 2: 失敗を確かめる** — Run: `./run_tests.sh test_run_state.gd` / Expected: FAIL（クラスがない）
- [ ] **Step 3: 実装する**
- [ ] **Step 4: 通ることを確かめる** — Run: `./run_tests.sh` / Expected: 全件 PASS
- [ ] **Step 5: コミット** — `git commit -m "feat: 持ち物・墓石・死んだときの移し替え"`

---

### Task 5: エリアの状態（死亡処理のタイミングとクリア）

**Files:**
- Create: `scripts/rules/area_state.gd`
- Test: `tests/test_area_state.gd`

**Interfaces:**
- Produces: `class_name AreaState extends RefCounted`
  - `enum Result { PLAYING, DYING, CLEAR }`、`result: Result`
  - `const DEATH_SECONDS := 1.5`、`const FALL_SECONDS := 0.5`
  - `on_player_died(fell: bool) -> bool`：PLAYING のときだけ DYING にして true（待ち時間は `DEATH_SECONDS`、fell なら `FALL_SECONDS + DEATH_SECONDS`）。それ以外は false。
  - `is_falling() -> bool`：DYING かつ落下の演出中（最初の0.5秒）。
  - `update(delta: float) -> bool`：DYING の待ち時間が尽きた瞬間に PLAYING に戻して true（この時に呼び出し側が再開処理をする）。それ以外は false。
  - `on_goal() -> void`：PLAYING のときだけ CLEAR。CLEAR は以後変わらない。

- [ ] **Step 1: 失敗するテストを書く**

```gdscript
extends GutTest

func test_death_then_respawn_after_delay():
	var s := AreaState.new()
	assert_true(s.on_player_died(false))
	assert_eq(s.result, AreaState.Result.DYING)
	assert_false(s.update(1.4))
	assert_true(s.update(0.2))
	assert_eq(s.result, AreaState.Result.PLAYING)

func test_fall_adds_fall_time():
	var s := AreaState.new()
	s.on_player_died(true)
	assert_true(s.is_falling())
	assert_false(s.update(1.9))
	assert_false(s.is_falling())
	assert_true(s.update(0.2))

func test_second_death_while_dying_is_ignored():
	var s := AreaState.new()
	assert_true(s.on_player_died(true))
	assert_false(s.on_player_died(false))
	assert_false(s.update(1.9))   # 1回目の待ち時間（2.0秒）のまま
	assert_true(s.update(0.2))

func test_goal_clears_and_is_final():
	var s := AreaState.new()
	s.on_goal()
	assert_eq(s.result, AreaState.Result.CLEAR)
	assert_false(s.on_player_died(false))
	assert_eq(s.result, AreaState.Result.CLEAR)

func test_goal_ignored_while_dying():
	var s := AreaState.new()
	s.on_player_died(false)
	s.on_goal()
	assert_eq(s.result, AreaState.Result.DYING)
```

- [ ] **Step 2: 失敗を確かめる** — Run: `./run_tests.sh test_area_state.gd` / Expected: FAIL
- [ ] **Step 3: 実装する**
- [ ] **Step 4: 通ることを確かめる** — Run: `./run_tests.sh` / Expected: 全件 PASS
- [ ] **Step 5: コミット** — `git commit -m "feat: エリアの状態（死亡処理の待ち時間とクリア）"`

---

### Task 6: 地形の作り方を共有にする（試作1の動きは変えない）

**Files:**
- Create: `scripts/game/terrain.gd`
- Modify: `scripts/game/stage_01.gd`

**Interfaces:**
- Produces: `class_name Terrain extends RefCounted`
  - `static func parse(layout: Array, map: HeightMap) -> Dictionary`：数字＝高さ、`#`＝壁、`_`＝奈落（高さ0）、`C`＝チェックポイント（高さ0）、`D`＝扉（高さ0、`Blocker.DOOR` を置く）、`G`＝ゴール（高さ0）。戻り値は `{"checkpoint": Vector2i, "goal": Vector2i, "doors": Array[Vector2i]}`（見つからないものは入れない）。`map` は呼び出し側が `HeightMap.new(Vector2i(layout[0].length(), layout.size()))` で作って渡す。
  - `static func build(map: HeightMap, camera: StackCamera, parent: Node2D) -> void`：今の `stage_01._build_terrain` と同じ描き方。奈落のマスには何も置かない（背景の暗い色が見える）。
  - 地面・壁のモデルを作る関数は `stage_01.gd` から移す。

- [ ] **Step 1: テストを書く**（`tests/test_terrain.gd`）

```gdscript
extends GutTest

func test_parse_symbols():
	var layout := ["C1_", "#DG"]
	var m := HeightMap.new(Vector2i(3, 2))
	var info := Terrain.parse(layout, m)
	assert_eq(info["checkpoint"], Vector2i(0, 0))
	assert_eq(info["goal"], Vector2i(2, 1))
	assert_eq(info["doors"], [Vector2i(1, 1)])
	assert_eq(m.get_height(Vector2i(1, 0)), 1)
	assert_true(m.is_pit(Vector2i(2, 0)))
	assert_true(m.is_wall(Vector2i(0, 1)))
	assert_eq(m.get_blocker(Vector2i(1, 1)), HeightMap.Blocker.DOOR)
```

- [ ] **Step 2: 失敗を確かめる** — Run: `./run_tests.sh test_terrain.gd` / Expected: FAIL
- [ ] **Step 3: 実装し、`stage_01.gd` の `_build_map` と `_build_terrain` を `Terrain` 呼び出しに置き換える**
- [ ] **Step 4: 通ることを確かめる** — Run: `./run_tests.sh` / Expected: 全件 PASS（`test_stage_01.gd` が変わらず通ること）
- [ ] **Step 5: コミット** — `git commit -m "refactor: 地形の読み込みと描画を Terrain に切り出す"`

---

### Task 7: エリアの地図（距離・近道・届くことをテストで確かめる）

**Files:**
- Create: `scripts/game/area_02.gd`（この段階では地図と配置の定数、`_ready` で地形を作るまで）, `scenes/area_02.tscn`, `tests/helpers/reach.gd`
- Test: `tests/test_area_02_layout.gd`

**Interfaces:**
- Consumes: `Terrain.parse`, `Terrain.build`, `MovementRules.can_step`
- Produces（`area_02.gd` の定数。Task 8 が使う）:
  - `const LAYOUT := [...]`：40×28マスくらい（数倍ならよい）。仕様5章の置き方に従う：片端に `C` のある敵のいない安全地帯、奥へ続く台地と敵のいる道、奈落の横の細い道、奥に強い鉄球と扉 `D` と出口 `G`。
  - `const PLAYER_START: Vector2i`（チェックポイントの隣）
  - `const ENEMIES := [[開始マス, 向き, 最初に撃つまでの秒数], ...]`（試作1と同じ形）
  - `const PICKUPS := [[マス, RunState.PickupKind, 量], ...]`（配列の添字を id に使う。STRONG_BALL はちょうど1つ、HEAL は2つ以上）
  - `const DOOR_OPEN_FROM := [Vector2i, ...]`：`Terrain.parse` が返す `doors` と同じ順で、開けるときに立つ奥側のマス。
  - `tests/helpers/reach.gd`：`static func distance(map: HeightMap, rules: MovementRules, from: Vector2i, to: Vector2i) -> int`。4近傍、壁と奈落は通れない、`rules.can_step` で段差を判定する幅優先探索。届かなければ -1。

- [ ] **Step 1: 失敗するテストを書く**

```gdscript
extends GutTest
const Reach = preload("res://tests/helpers/reach.gd")

var area
var rules := MovementRules.new()

func before_each():
	area = load("res://scenes/area_02.tscn").instantiate()
	add_child_autofree(area)

## 速さ60px/秒、1マス16px → 1分で225マス
func test_back_of_area_is_over_a_minute_away():
	var d := Reach.distance(area.map, rules, area.checkpoint, area.goal)
	assert_gt(d, 225)

func test_everything_reachable_with_doors_closed():
	for p in area.PICKUPS:
		assert_gt(Reach.distance(area.map, rules, area.PLAYER_START, p[0]), 0, str(p[0]))
	for c in area.DOOR_OPEN_FROM:
		assert_gt(Reach.distance(area.map, rules, area.PLAYER_START, c), 0, str(c))

func test_open_door_is_a_short_way_back():
	for i in area.doors.size():
		area.map.set_blocker(area.doors[i], HeightMap.Blocker.NONE)
		var d := Reach.distance(area.map, rules, area.DOOR_OPEN_FROM[i], area.checkpoint)
		assert_between(d, 1, 40)

func test_no_enemy_near_checkpoint():
	for e in area.ENEMIES:
		var c: Vector2i = e[0]
		assert_gt(maxi(absi(c.x - area.checkpoint.x), absi(c.y - area.checkpoint.y)), 8)

func test_one_strong_ball():
	var n := 0
	for p in area.PICKUPS:
		if p[1] == RunState.PickupKind.STRONG_BALL:
			n += 1
	assert_eq(n, 1)

func test_narrow_path_beside_pit():
	var pits := 0
	for y in area.map.size.y:
		for x in area.map.size.x:
			if area.map.is_pit(Vector2i(x, y)):
				pits += 1
	assert_gt(pits, 0)
```

（`area.checkpoint`、`area.goal`、`area.doors` は `_ready` で `Terrain.parse` の結果を入れる変数。）

- [ ] **Step 2: 失敗を確かめる** — Run: `./run_tests.sh test_area_02_layout.gd` / Expected: FAIL
- [ ] **Step 3: 地図を描き、`_ready` で地形・カメラ・プレイヤーを置く**（敵・拾えるものの配置はまだ。プレイヤーが歩けるところまで）
- [ ] **Step 4: 通ることを確かめる** — Run: `./run_tests.sh` / Expected: 全件 PASS
- [ ] **Step 5: 画面を確かめる** — Run: `godot --path . res://scenes/area_02.tscn -- --screenshot=/tmp/area.png` で、チェックポイントの周りが映ること。重さ（FPS）をエディタで見て、目立って落ちるなら画面外のマスを描かない処理を足す（仕様5章）。
- [ ] **Step 6: コミット** — `git commit -m "feat: 試作2のエリアの地図"`

---

### Task 8: エリアの遊び（拾う、墓石、扉、回復、死んで再開、ゴール）

**Files:**
- Modify: `scripts/game/area_02.gd`, `scripts/game/ball.gd`, `scripts/game/player.gd`
- Test: `tests/test_area_02.gd`

**Interfaces:**
- Consumes: Task 1〜7 のすべて。
- Produces（テストから触る `area_02.gd` のメンバー）:
  - `map`, `rules`, `run: RunState`, `area_state: AreaState`, `player: Player`, `ball: Ball`, `enemies: Array[Enemy]`, `_bullets`
  - `_on_enemy_shot(b: Bullet) -> void`：試作1の `stage_01.gd` と同じく弾を足す。DYING・CLEAR の間は足さない。
  - `kill_player(fell: bool) -> void`：`area_state.on_player_died(fell)` が true のときだけ、墓石の場所（fell なら `player.mover.last_safe_cell`、そうでなければ今のマス）で `run.on_death` を呼び、古い墓石ノードとそのマスの `Blocker.GRAVE` を消して新しく置く。
  - `respawn() -> void`：敵ノードをすべて消して `ENEMIES` から作り直す、弾をすべて消す、`ball.rules_ball.return_to_hand()` と `set_strong(false)`（強い鉄球は墓石へ行ったため）、`player.mover.place(PLAYER_START)`、体力を最大に。`area_state.update` が true を返したフレームに呼ぶ。
  - `Player.set_hp(v: int) -> void`（`hp_changed` を出す）。`Player` は `area_state.is_falling()` の間、`lift_px` を下げて沈む演出をする（描き方は実装者に任せる）。
- 遊びの決まり（`_process` で毎フレーム）：
  - プレイヤーの体力が0、または `mover.fell` なら `kill_player`。
  - プレイヤーのマスに未回収の拾えるものがあれば `run.collect`、ノードを消す。
  - `run.is_near_checkpoint(player.mover.cell())` なら体力を最大に。
  - 鉄球の `landed` で、着いたマスが墓石なら `run.break_grave()`、墓石ノードを消し、`Blocker.NONE` に戻す。敵へのダメージは試作1と同じ。
  - 敵の `died` で `run.on_enemy_killed()`。
  - Z：目の前が閉じた扉で、今のマスがその扉の `DOOR_OPEN_FROM` なら `run.open_door(i)` と `Blocker.NONE`（鉄球を拾うより先に判定）。それ以外は今どおり鉄球を拾う。`Ball` が Z を見ているので、扉を開けたフレームは `Ball` に拾わせない（`ball.consume_z()` のような仕組みは実装者の判断）。
  - C：`run.inventory.try_use_heal(player.hp, Player.MAX_HP)` が true なら体力 +1。
  - 1/2：`ball.rules_ball.set_strong(false/true)`。2 は `run.inventory.has_strong_ball` のときだけ。強い鉄球は色を変える。
  - プレイヤーが `goal` のマスに入ったら `area_state.on_goal()`。
  - DYING の間はプレイヤーの操作と鉄球の操作を止める。
  - UI は仕様7章のとおり（`HP %d   MONEY %d   MAT %d   HEAL %d   EXP %d` と `BALL: NORMAL|STRONG (1/2 to switch)`、DYING 中は `YOU DIED`、クリアで `CLEAR`）。
  - 墓石は背の高い目立つ形・色（仕様4.2）。チェックポイントはたき火など休憩所と分かる形。

- [ ] **Step 1: 失敗するテストを書く**（主なもの。拾う・扉・回復・ゴールも同じ形で1件ずつ足す）

```gdscript
extends GutTest

var area

func before_each():
	area = load("res://scenes/area_02.tscn").instantiate()
	add_child_autofree(area)

func _finish_death():
	area.area_state.update(10.0)
	area.respawn()

func test_death_places_grave_and_respawns_at_checkpoint():
	area.run.inventory.money = 30
	var c := Vector2i(area.PLAYER_START.x + 2, area.PLAYER_START.y)
	area.player.mover.place(c)
	area.kill_player(false)
	assert_eq(area.run.grave.cell, c)
	assert_true(area.map.is_grave(c))
	_finish_death()
	assert_eq(area.player.mover.cell(), area.PLAYER_START)
	assert_eq(area.player.hp, Player.MAX_HP)
	assert_eq(area.run.inventory.money, 15)

func test_respawn_clears_bullets_and_resets_enemies():
	var e: Enemy = area.enemies[0]
	e.walker.take_damage(99)
	var b := Bullet.new()
	b.pos = area.player.mover.pos + Vector2(40, 0)
	area._on_enemy_shot(b)
	area.kill_player(false)
	_finish_death()
	assert_eq(area._bullets.size(), 0)
	assert_eq(area.enemies.size(), area.ENEMIES.size())
	for en in area.enemies:
		assert_true(en.walker.alive)
		assert_eq(en.walker.hp, EnemyWalker.MAX_HP)

func test_new_death_moves_grave_marker():
	var c1 := Vector2i(area.PLAYER_START.x + 2, area.PLAYER_START.y)
	area.player.mover.place(c1)
	area.kill_player(false)
	_finish_death()
	var c2 := Vector2i(area.PLAYER_START.x + 3, area.PLAYER_START.y)
	area.player.mover.place(c2)
	area.kill_player(false)
	assert_false(area.map.is_grave(c1))
	assert_true(area.map.is_grave(c2))

func test_ball_on_grave_breaks_it():
	area.run.inventory.money = 30
	var c := Vector2i(area.PLAYER_START.x + 2, area.PLAYER_START.y)
	area.player.mover.place(c)
	area.kill_player(false)
	_finish_death()
	var p: PlayerMover = area.player.mover
	p.place(Vector2i(c.x - 1, c.y))
	p.facing = Vector2.RIGHT
	var ball: IronBall = area.ball.rules_ball
	assert_true(ball.drop(p, area.map))
	ball.update(1.0, p, area.map, area.rules)
	assert_null(area.run.grave)
	assert_false(area.map.is_wall(c))
	assert_eq(area.run.inventory.money, 30)

func test_fall_puts_grave_on_last_safe_cell():
	# 奈落の隣の安全なマスを地図から探して、そこから奈落へ歩かせる
	var pit := Vector2i(-1, -1)
	var safe := Vector2i(-1, -1)
	for y in area.map.size.y:
		for x in area.map.size.x:
			var c := Vector2i(x, y)
			var left := Vector2i(x - 1, y)
			if area.map.is_pit(c) and not area.map.is_pit(left) and not area.map.is_wall(left):
				pit = c
				safe = left
	area.player.mover.place(safe)
	for i in 20:
		area.player.mover.move(Vector2(2, 0))
	area._process(0.016)
	assert_eq(area.area_state.result, AreaState.Result.DYING)
	assert_eq(area.run.grave.cell, safe)

func test_strong_ball_on_ground_goes_to_grave():
	area.run.inventory.has_strong_ball = true
	var ball: IronBall = area.ball.rules_ball
	ball.set_strong(true)
	var p: PlayerMover = area.player.mover
	p.facing = Vector2.RIGHT
	ball.drop(p, area.map)
	area.kill_player(false)
	_finish_death()
	assert_eq(ball.state, IronBall.State.HELD)
	assert_false(ball.strong)
	assert_true(area.run.grave.has_strong_ball)
```

（`PLAYER_START` の右2〜3マスが歩ける平地になるよう、Task 7 の地図で安全地帯を作っておくこと。奈落の左が平地でない地図なら、このテストの探し方を地図に合わせて変える。）

- [ ] **Step 2: 失敗を確かめる** — Run: `./run_tests.sh test_area_02.gd` / Expected: FAIL
- [ ] **Step 3: 実装する**
- [ ] **Step 4: 通ることを確かめる** — Run: `./run_tests.sh` / Expected: 全件 PASS
- [ ] **Step 5: コミット** — `git commit -m "feat: 試作2の遊び（墓石・扉・回復・死んで再開・ゴール）"`

---

### Task 9: メインシーンの切り替えと引き継ぎ資料

**Files:**
- Modify: `project.godot`（`run/main_scene="res://scenes/area_02.tscn"`）, `CLAUDE.md`（「現状」「構成」に試作2を足す、テスト件数を更新）, `docs/next-prototype-death-loop.md`（ステータスを「設計済み・実装済み」に）

- [ ] **Step 1: 書き換える**
- [ ] **Step 2: 全テストを確かめる** — Run: `./run_tests.sh` / Expected: 全件 PASS。件数を CLAUDE.md に書く。
- [ ] **Step 3: 画面を確かめる** — `godot --path . -- --screenshot=/tmp/main.png` でメインシーンが試作2になっていること。
- [ ] **Step 4: コミット** — `git commit -m "docs: 試作2をメインシーンにし、引き継ぎ資料を更新"`
