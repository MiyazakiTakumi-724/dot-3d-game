# 鉄球の1ステージ試作 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** sprite stackingで描いた小さなエリアを1つ作り、鉄球だけで敵を全滅させればクリアになる遊べる試作をGodotで作る。

**Architecture:** ゲームのルール（高さ、移動、鉄球、敵の弾、クリア判定）は描画から切り離して `RefCounted` のクラスに置き、GUTで単体テストする。描画は `StackSprite`（輪切り画像を重ねて描くノード）と `StackCamera`（カメラの回転と画面座標への変換）が担当する。素材はコードで定義したボクセルの形から輪切り画像を作る。

**Tech Stack:** Godot 4（最新の安定版）、GDScript、GUT（Godot Unit Test）。

**Spec:** 設計メモ「sprite stackingアクション 設計メモ」（Claude Docs）。`docs/design.md`。

## Global Constraints

- エンジンはGodot 4、言語はGDScript。
- 描画解像度は 320×180。拡大は整数倍のみ（`stretch/mode = "viewport"`、`stretch/scale_mode = "integer"`）。テクスチャのフィルタは `nearest`。
- 高さは「段」単位の整数。登れるのは1段まで、飛び降りは3段まで。この2つの値は `MovementRules` に置き、後でアイテムで変えられるようにする。
- ジャンプはない。段差には近づくと自動で登る。
- 鉄球は目の前に落とすだけ。落ちた段数でダメージが変わる。落とした鉄球は拾い直すまで再使用できない。
- 壁は敵の弾を防ぐ。ステルスはない。
- 敵は平らな所を歩くだけで、段差を上り下りしない。
- エリアの目標は敵の全滅。
- プレイヤーはカメラを回せる。
- 1マス = 16px、1段 = 輪切り8枚（こちらで決めた値。設計メモでは作る人に任せた項目）。

## Review Focus

1. **マップの端やマップの外に鉄球を落とす**：落とさない（何も起きず、鉄球は手に持ったまま）。→ Task 5 `test_drop_outside_map_keeps_ball`
2. **目の前のマスがプレイヤーより高い所に鉄球を落とす**：落ちる段数が0以下なら最低ダメージ（1）で、そのマスの上に置かれる。→ Task 5 `test_drop_onto_higher_cell_uses_min_damage`
3. **カメラを回した後の移動方向**：上キーは常に「画面の上」へ進む。→ Task 4 `test_input_is_relative_to_camera`
4. **鉄球が落ちた先の段差にあって、プレイヤーが登れない**：拾えないまま詰まる。プレイヤーの今いる段から登れないマスの鉄球は、1秒後にプレイヤーの足元へ戻す。→ Task 5 `test_unreachable_ball_returns_to_player`
5. **敵の弾が壁の角をすり抜ける**：弾は1フレームで進む距離が長くても、通り道の壁マスに当たって消える。→ Task 6 `test_fast_bullet_does_not_tunnel_wall`

---

## ファイル構成

```
project.godot
addons/gut/                     … GUT（AssetLibから導入）
scripts/rules/movement_rules.gd … 登れる段数・飛び降りられる段数
scripts/rules/height_map.gd     … マスごとの高さと壁
scripts/rules/player_mover.gd   … 高さを考えたプレイヤーの移動
scripts/rules/iron_ball.gd      … 鉄球の状態とダメージ
scripts/rules/bullet.gd         … 敵の弾と壁との当たり
scripts/rules/stage_state.gd    … クリア・ゲームオーバー判定
scripts/render/voxel_model.gd   … ボクセルの形 → 輪切り画像
scripts/render/stack_camera.gd  … カメラの回転と画面座標への変換
scripts/render/stack_sprite.gd  … 輪切りを重ねて描くノード
scenes/stage_01.tscn + scripts/game/stage_01.gd … 試作ステージ
scenes/player.tscn, enemy.tscn, ball.tscn + scripts/game/*.gd
tests/test_*.gd                 … GUTのテスト
```

---

### Task 1: プロジェクトの土台と高さのルール

**Files:**
- Create: `project.godot`, `scripts/rules/movement_rules.gd`, `scripts/rules/height_map.gd`
- Test: `tests/test_height_map.gd`

**Interfaces:**
- Produces:
  - `class_name MovementRules extends Resource`：`@export var max_climb: int = 1`、`@export var max_drop: int = 3`、`func can_step(from_h: int, to_h: int) -> bool`
  - `class_name HeightMap extends RefCounted`：`func _init(size: Vector2i)`、`func set_height(cell: Vector2i, h: int)`、`func get_height(cell: Vector2i) -> int`、`func set_wall(cell: Vector2i, wall: bool)`、`func is_wall(cell: Vector2i) -> bool`、`func in_bounds(cell: Vector2i) -> bool`、`const CELL_PX := 16`、`static func world_to_cell(p: Vector2) -> Vector2i`

- [ ] **Step 1:** Godot 4で新規プロジェクトを作り、Global Constraintsの表示設定（320×180、viewport、integer、nearest）を入れる。AssetLibからGUTを入れて有効にする。
- [ ] **Step 2: Write the failing test** `tests/test_height_map.gd`

```gdscript
extends GutTest
func test_climb_one_level_ok():   assert_true(MovementRules.new().can_step(0, 1))
func test_climb_two_levels_ng():  assert_false(MovementRules.new().can_step(0, 2))
func test_drop_three_levels_ok(): assert_true(MovementRules.new().can_step(3, 0))
func test_drop_four_levels_ng():  assert_false(MovementRules.new().can_step(4, 0))
func test_rules_are_changeable():
	var r := MovementRules.new(); r.max_climb = 2
	assert_true(r.can_step(0, 2))
func test_height_default_zero():  assert_eq(HeightMap.new(Vector2i(4, 4)).get_height(Vector2i(1, 1)), 0)
func test_out_of_bounds():        assert_false(HeightMap.new(Vector2i(4, 4)).in_bounds(Vector2i(4, 0)))
func test_world_to_cell():        assert_eq(HeightMap.world_to_cell(Vector2(17, 31)), Vector2i(1, 1))
```

- [ ] **Step 3:** GUTで実行し、失敗を確認（`godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`）。
- [ ] **Step 4:** `MovementRules` と `HeightMap` を実装する。範囲外の `get_height` は 0、`is_wall` は true を返す（外には出られない）。
- [ ] **Step 5:** テストが通ることを確認。
- [ ] **Step 6:** Commit `feat: プロジェクト設定と高さのルール`

### Task 2: ボクセルの形から輪切り画像を作る

**Files:**
- Create: `scripts/render/voxel_model.gd`
- Test: `tests/test_voxel_model.gd`

**Interfaces:**
- Produces: `class_name VoxelModel extends RefCounted`：`var size: Vector3i`、`func set_voxel(p: Vector3i, c: Color)`、`func slices() -> Array[Image]`（z=0が一番下）、`static func box(size: Vector3i, c: Color) -> VoxelModel`、`static func sphere(radius: int, c: Color) -> VoxelModel`

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest
func test_slice_count_equals_height():
	assert_eq(VoxelModel.box(Vector3i(16, 16, 8), Color.RED).slices().size(), 8)
func test_slice_pixel_color():
	var img: Image = VoxelModel.box(Vector3i(4, 4, 2), Color.RED).slices()[0]
	assert_eq(img.get_pixel(1, 1), Color.RED)
func test_empty_voxel_is_transparent():
	var m := VoxelModel.new(); m.size = Vector3i(4, 4, 1)
	assert_eq(m.slices()[0].get_pixel(0, 0).a, 0.0)
```

- [ ] **Step 2:** 失敗を確認。
- [ ] **Step 3:** 実装する。各輪切りは `Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)`。
- [ ] **Step 4:** 通ることを確認。
- [ ] **Step 5:** Commit `feat: ボクセルから輪切り画像を作る`

### Task 3: カメラと重ね描き

**Files:**
- Create: `scripts/render/stack_camera.gd`, `scripts/render/stack_sprite.gd`
- Test: `tests/test_stack_camera.gd`

**Interfaces:**
- Consumes: `VoxelModel.slices()`
- Produces:
  - `class_name StackCamera extends Node2D`：`var angle: float`（ラジアン）、`var focus: Vector2`（ワールド座標）、`func world_to_screen(world: Vector2, height_px: float) -> Vector2`、`func screen_dir_to_world(dir: Vector2) -> Vector2`、`func depth_key(world: Vector2) -> float`。Q/Eキーで90°/秒で回る。
  - `class_name StackSprite extends Node2D`：`func set_model(m: VoxelModel)`、`var world_pos: Vector2`、`var base_height: int`（段）、`var camera: StackCamera`。`_draw()` で各輪切りを `-camera.angle` だけ回して描き、i枚目を画面上に `i` px ずらす。`base_height` 1段につき8pxずらす。

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest
func test_focus_is_screen_center():
	var c := StackCamera.new(); c.focus = Vector2(100, 100)
	assert_eq(c.world_to_screen(Vector2(100, 100), 0), Vector2(160, 90))
func test_height_moves_up_on_screen():
	var c := StackCamera.new()
	assert_eq(c.world_to_screen(Vector2.ZERO, 8).y, c.world_to_screen(Vector2.ZERO, 0).y - 8)
func test_rotation_90():
	var c := StackCamera.new(); c.angle = PI / 2
	assert_almost_eq(c.world_to_screen(Vector2(10, 0), 0), Vector2(160, 80), Vector2(0.01, 0.01))
func test_screen_dir_roundtrip():
	var c := StackCamera.new(); c.angle = 1.0
	var w := c.screen_dir_to_world(Vector2.UP)
	assert_almost_eq((c.world_to_screen(w * 10, 0) - c.world_to_screen(Vector2.ZERO, 0)).normalized(), Vector2.UP, Vector2(0.01, 0.01))
```

- [ ] **Step 2:** 失敗を確認。
- [ ] **Step 3:** 実装する。画面中心は (160, 90)。ワールドの点を focus 基準で `-angle` 回転し、高さ分だけ y を引く。`depth_key` は回転後の y（大きいほど手前、後に描く）。
- [ ] **Step 4:** 通ることを確認。
- [ ] **Step 5:** 目視確認：箱と球を数個置いたテストシーンでQ/Eを押し、回しても立体に見え、手前の物が奥の物の上に描かれること。
- [ ] **Step 6:** Commit `feat: sprite stackingのカメラと描画`

### Task 4: プレイヤーの移動（自動で登る・飛び降り）

**Files:**
- Create: `scripts/rules/player_mover.gd`, `scenes/player.tscn`, `scripts/game/player.gd`
- Test: `tests/test_player_mover.gd`

**Interfaces:**
- Consumes: `HeightMap`, `MovementRules`, `StackCamera.screen_dir_to_world`
- Produces: `class_name PlayerMover extends RefCounted`：`func _init(map: HeightMap, rules: MovementRules)`、`var pos: Vector2`、`var height: int`、`var facing: Vector2`（単位ベクトル）、`func move(world_delta: Vector2) -> void`（登れない/降りられない/壁のマスへは入らない。入れたら `height` を更新）、`func front_cell() -> Vector2i`

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest
var map: HeightMap
func before_each():
	map = HeightMap.new(Vector2i(8, 8))
	map.set_height(Vector2i(2, 0), 1); map.set_height(Vector2i(3, 0), 3)
func _mover_at(cell: Vector2i) -> PlayerMover:
	var m := PlayerMover.new(map, MovementRules.new())
	m.pos = Vector2(cell) * 16 + Vector2(8, 8); m.height = map.get_height(cell); return m
func test_auto_climb_one():
	var m := _mover_at(Vector2i(1, 0)); m.move(Vector2(16, 0)); assert_eq(m.height, 1)
func test_blocked_by_two():
	var m := _mover_at(Vector2i(2, 0)); m.move(Vector2(16, 0)); assert_eq(HeightMap.world_to_cell(m.pos), Vector2i(2, 0))
func test_drop_three():
	var m := _mover_at(Vector2i(3, 0)); m.move(Vector2(0, 16)); assert_eq(m.height, 0)
func test_blocked_by_wall():
	map.set_wall(Vector2i(1, 1), true)
	var m := _mover_at(Vector2i(1, 0)); m.move(Vector2(0, 16)); assert_eq(HeightMap.world_to_cell(m.pos), Vector2i(1, 0))
func test_front_cell():
	var m := _mover_at(Vector2i(1, 1)); m.move(Vector2(1, 0)); assert_eq(m.front_cell(), Vector2i(2, 1))
func test_input_is_relative_to_camera():
	var c := StackCamera.new(); c.angle = PI / 2
	assert_almost_eq(c.screen_dir_to_world(Vector2.UP), Vector2(1, 0), Vector2(0.01, 0.01))
```

- [ ] **Step 2:** 失敗を確認。
- [ ] **Step 3:** `PlayerMover` を実装し、`player.gd` で矢印キー/WASD → `camera.screen_dir_to_world` → `mover.move(dir * 60 * delta)`。速度は60px/秒。
- [ ] **Step 4:** 通ることを確認。
- [ ] **Step 5:** Commit `feat: 高さを考えたプレイヤー移動`

### Task 5: 鉄球

**Files:**
- Create: `scripts/rules/iron_ball.gd`, `scenes/ball.tscn`, `scripts/game/ball.gd`
- Test: `tests/test_iron_ball.gd`

**Interfaces:**
- Consumes: `HeightMap`, `PlayerMover`
- Produces: `class_name IronBall extends RefCounted`：`enum State { HELD, FALLING, ON_GROUND }`、`var state: State`、`var cell: Vector2i`、`var height: int`、`signal landed(cell: Vector2i, damage: int)`、`func drop(player: PlayerMover, map: HeightMap) -> bool`、`func update(delta: float, player: PlayerMover, map: HeightMap, rules: MovementRules) -> void`、`func try_pick_up(player: PlayerMover) -> bool`、`static func damage_for(levels: int) -> int`

ダメージは `max(1, levels + 1)`（同じ段なら1、3段落ちなら4）。こちらで決めた値で、遊んで調整する。落下は1段あたり0.1秒。拾うのは同じマス・同じ段にいるときに拾うボタン（Z）。

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest
func test_damage_table():
	assert_eq(IronBall.damage_for(0), 1); assert_eq(IronBall.damage_for(3), 4)
func test_drop_from_ledge_damage():  # 3段の上から0段へ落とすとダメージ4で着地
	...  # 3段のマスに立つプレイヤー、前のマスは0段。drop → update(1.0) → landed(cell, 4) を watch_signals で確認
func test_cannot_reuse_until_picked():
	...  # drop 後にもう一度 drop すると false
func test_pick_up_returns_to_held():
	...  # 着地したマスへ移動して try_pick_up → true、state == HELD
func test_drop_outside_map_keeps_ball():
	...  # マップ端で外向きに drop → false、state == HELD
func test_drop_onto_higher_cell_uses_min_damage():
	...  # 0段に立ち、前が1段 → landed(cell, 1)、height == 1
func test_unreachable_ball_returns_to_player():
	...  # 0段に立ち、前が2段のマス（登れない）に落とす → update(1.5) 後、cell がプレイヤーのマスで state == ON_GROUND
```

（`...` の部分は、上のコメントの条件どおりにマップとプレイヤーを組み、コメントの値をassertする。）

- [ ] **Step 2:** 失敗を確認。
- [ ] **Step 3:** 実装する。`ball.gd` は `IronBall` を持ち、`landed` を受けてそのマスの敵に `take_damage(damage)` を呼ぶ。X キーで落とす。
- [ ] **Step 4:** 通ることを確認。
- [ ] **Step 5:** Commit `feat: 鉄球を落として拾う`

### Task 6: 敵と弾と壁

**Files:**
- Create: `scripts/rules/bullet.gd`, `scenes/enemy.tscn`, `scripts/game/enemy.gd`
- Test: `tests/test_bullet.gd`, `tests/test_enemy.gd`

**Interfaces:**
- Consumes: `HeightMap`, `PlayerMover`
- Produces:
  - `class_name Bullet extends RefCounted`：`var pos: Vector2`、`var vel: Vector2`、`var alive := true`、`func step(delta: float, map: HeightMap) -> void`（通り道を4px刻みで調べ、壁マスに触れたら `alive = false`）
  - `enemy.gd`：`var hp := 3`、`func take_damage(n: int)`、`signal died`。自分の段と同じ高さのマスだけを往復して歩き、2秒ごとにプレイヤーへ向けて弾（速さ80px/秒）を撃つ。弾がプレイヤーに当たるとプレイヤーのHPが1減る。プレイヤーのHPは3。

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest
func test_bullet_stops_at_wall():
	var map := HeightMap.new(Vector2i(8, 8)); map.set_wall(Vector2i(2, 0), true)
	var b := Bullet.new(); b.pos = Vector2(8, 8); b.vel = Vector2(80, 0)
	for i in 30: b.step(0.016, map)
	assert_false(b.alive)
func test_fast_bullet_does_not_tunnel_wall():
	var map := HeightMap.new(Vector2i(8, 8)); map.set_wall(Vector2i(2, 0), true)
	var b := Bullet.new(); b.pos = Vector2(8, 8); b.vel = Vector2(2000, 0)
	b.step(0.05, map)
	assert_false(b.alive)
func test_enemy_stays_on_its_level():
	...  # 0段の敵の進行方向に1段のマス → 一定時間後も敵のマスの高さは0
func test_enemy_dies_at_zero_hp():
	...  # take_damage(4) → died が発火
```

- [ ] **Step 2:** 失敗を確認。
- [ ] **Step 3:** 実装する。
- [ ] **Step 4:** 通ることを確認。
- [ ] **Step 5:** Commit `feat: 敵と弾、壁で防ぐ`

### Task 7: 試作ステージとクリア判定

**Files:**
- Create: `scripts/rules/stage_state.gd`, `scenes/stage_01.tscn`, `scripts/game/stage_01.gd`
- Test: `tests/test_stage_state.gd`

**Interfaces:**
- Consumes: ここまでの全部
- Produces: `class_name StageState extends RefCounted`：`enum Result { PLAYING, CLEAR, GAME_OVER }`、`func _init(enemy_count: int)`、`func on_enemy_died()`、`func on_player_hp(hp: int)`、`var result: Result`

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest
func test_clear_when_all_dead():
	var s := StageState.new(2); s.on_enemy_died(); s.on_enemy_died()
	assert_eq(s.result, StageState.Result.CLEAR)
func test_game_over_at_zero_hp():
	var s := StageState.new(2); s.on_player_hp(0)
	assert_eq(s.result, StageState.Result.GAME_OVER)
```

- [ ] **Step 2:** 失敗を確認。
- [ ] **Step 3:** 実装し、`stage_01` を作る：16×12マス、高さ0〜3の段差、壁を数か所、敵3体（平らな所）。高い所から鉄球を落とさないと倒しにくい配置にする。クリアで「CLEAR」、ゲームオーバーで「GAME OVER」を表示し、Rキーでやり直し。地形・プレイヤー・敵・鉄球はすべて `VoxelModel.box`/`sphere` で色分けした形。
- [ ] **Step 4:** テストが通ることを確認。
- [ ] **Step 5:** 目視確認：起動からクリアまで遊べる。カメラを回しても操作が画面基準。1段は登れて2段は登れない。3段から飛び降りられる。壁の裏で弾が防げる。
- [ ] **Step 6:** Commit `feat: 鉄球の試作ステージ`

### Task 8: Windows向け書き出し

**Files:**
- Create: `export_presets.cfg`

- [ ] **Step 1:** Godotのエクスポートテンプレートを入れ、Windows Desktop のプリセットを作る。
- [ ] **Step 2:** 書き出したexeを起動し、Task 7の目視確認と同じ流れでクリアまで遊べることを確認する。
- [ ] **Step 3:** Commit `chore: Windows書き出し設定`
