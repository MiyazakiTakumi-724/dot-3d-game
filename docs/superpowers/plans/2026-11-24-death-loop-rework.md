# 試作2の手直し（操作と屋外マップ） Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 試作2を design.md 5章どおりのマウス操作にし、マップを屋外の自然な地形に作り直す。

**Architecture:** ルールの追加（水、手に持つアイテム、鉄球の設定）は `scripts/rules/` に置いてGUTでテストする。入力は各ステージが読み、`Ball` ノードはキーを読まない見た目だけの層にする（試作1は自分で X/Z を読む）。地形の記号を増やし、`Terrain` が木・岩・水・橋・草のゆらぎを描く。

**Tech Stack:** Godot 4.5、GDScript、GUT 9.5.0

**Spec:** `docs/superpowers/specs/2026-11-23-death-loop-design.md`（10章が優先）

## Global Constraints

- 前の計画（`2026-11-24-death-loop-prototype.md`）の Global Constraints はそのまま有効。
- 左クリック＝手に持つアイテムを使う。数字キー＝手に持つアイテムを選ぶ（1＝鉄球、2＝回復）。Tab＝インベントリ（ゲームを止める）。右ドラッグ／Q・E＝カメラ。F＝扉。鉄球は歩いて拾う。
- 鉄球はカーソルの方向の目の前のマスに落とす。プレイヤーは常にカーソルの方を向く。
- 試作1（stage_01）は X/Z 操作と今の見た目のまま。
- 地図記号：数字＝高さ、`#`＝レンガの壁（試作1用）、`R`＝岩、`T`＝木、`~`＝水、`=`＝橋（高さ0で歩ける）、`_`＝奈落、`C`/`D`/`G`。`R`・`T` は壁扱い、`~` は通れないが弾は通る。

## Review Focus

1. **カーソルがプレイヤーの真上にある**：向きが壊れない（長さ0の向きにしない）。→ Task 4 `test_aim_at_own_position_keeps_facing`
2. **鉄球が地面にあるときにインベントリで強い鉄球を選ぶ**：地面の鉄球は変わらず、拾った時点で強い鉄球になる。→ Task 5 `test_equip_applies_when_ball_back_in_hand`
3. **インベントリを開いたまま閉じずに死ぬ／死亡中に開く**：死亡中は開けない。→ Task 5 `test_inventory_not_opened_while_dying`
4. **水に鉄球を落とす**：落とせない。→ Task 2 `test_cannot_drop_into_water`
5. **敵の弾が水の上を飛ぶ**：水では止まらない。→ Task 2 `test_bullet_flies_over_water`

---

### Task 1: カメラ（画面→ワールド、右ドラッグだけで回す）

**Files:** Modify `scripts/render/stack_camera.gd`; Test `tests/test_stack_camera.gd`, `tests/test_camera_mouse.gd`

- Produces: `StackCamera.screen_to_world(screen: Vector2, height_px: float) -> Vector2`（`world_to_screen` の逆）。マウスの左ドラッグでは回らない。
- Tests: `test_screen_to_world_roundtrip`（angle=1.0、height 16 で world→screen→world が一致）、`test_left_drag_does_not_rotate`（既存の左ドラッグのテストを置き換える）。

### Task 2: 水

**Files:** Modify `height_map.gd`, `player_mover.gd`, `enemy_walker.gd`, `iron_ball.gd`; Test 各テスト、`tests/test_bullet.gd`

- Produces: `HeightMap.set_water(cell, bool)`、`is_water(cell) -> bool`（外は false、壁ではない）。プレイヤーは水に入れない、敵は水の前で引き返す、鉄球は水に落とせない、弾は水で止まらない。
- Tests: `test_water_flag`, `test_cannot_walk_into_water`, `test_enemy_turns_at_water`, `test_cannot_drop_into_water`, `test_bullet_flies_over_water`。

### Task 3: 手に持つアイテムと、鉄球の設定

**Files:** Create `scripts/rules/hotbar.gd`; Modify `scripts/rules/inventory.gd`; Test `tests/test_hotbar.gd`, `tests/test_run_state.gd`

- Produces: `class_name Hotbar`：`enum Item { IRON_BALL, HEAL }`、`const SLOTS := [Item.IRON_BALL, Item.HEAL]`、`selected: Item`（初期 IRON_BALL）、`select_slot(n: int) -> bool`（1始まり、範囲外は false で変えない）。
- `Inventory.equipped_strong: bool`（インベントリでの設定。死んでも消えない）、`ball_is_strong() -> bool`（`equipped_strong and has_strong_ball`）。
- Tests: `test_default_is_iron_ball`, `test_select_slot_two_is_heal`, `test_out_of_range_slot_ignored`, `test_ball_is_strong_needs_both`, `test_equip_survives_death_and_returns_with_grave`。

### Task 4: 入力をステージへ移す、カーソルを向く

**Files:** Modify `scripts/game/ball.gd`（キーを読まない。`skip_pick_up` は消す）, `scripts/game/stage_01.gd`（X/Z を自分で読む）, `scripts/game/player.gd`; Test `tests/test_stage_01.gd`, `tests/test_area_02.gd`

- Produces: `Player.aim_at(world: Vector2) -> void`：プレイヤーから world への向きが 0.5px 以上なら `mover.facing` をその向きにする。`Player._process` は移動の後に、`aim_world`（`Vector2` か null）があればそれを向く。
- Tests: `test_aim_at_sets_front_cell`（右へ向けると front_cell が右隣）, `test_aim_at_own_position_keeps_facing`。試作1のテストが通ったままであること。

### Task 5: 試作2の操作（左クリック、歩いて拾う、F、Tab のインベントリ、狙いの印）

**Files:** Create `scripts/game/inventory_menu.gd`; Modify `scripts/game/area_02.gd`; Test `tests/test_area_02.gd`

- Produces（area_02）：`hotbar: Hotbar`、`use_item() -> bool`（IRON_BALL なら鉄球を落とす、HEAL なら `use_heal()`）、`open_inventory() -> bool`（PLAYING のときだけ。`get_tree().paused = true`）、`close_inventory()`、`menu: InventoryMenu`。`select_ball` は消す。毎フレーム：鉄球が手にあれば `set_strong(run.inventory.ball_is_strong())`、鉄球の上に立てば拾う、カーソルの位置を `player.aim_at` に渡す。
- `InventoryMenu`（CanvasLayer、`process_mode = ALWAYS`）：普通／強い鉄球のボタン（強いは持っているときだけ押せる）と持ち物の数。`choose_ball(strong: bool) -> bool`。
- 狙いの印：鉄球を手に持ち、1番を選んでいる間、`front_cell()` に暗い板を置く（落とせないマスなら出さない）。
- UI：`[1] BALL(NORMAL)  2 HEAL x1` のように選んでいる方を [ ] で囲む。操作の説明も新しいものにする。
- Tests: `test_left_click_item_drops_ball`, `test_heal_slot_uses_heal`, `test_walk_over_ball_picks_it_up`, `test_equip_applies_when_ball_back_in_hand`, `test_inventory_pauses_and_closes`, `test_inventory_not_opened_while_dying`, `test_menu_cannot_choose_strong_without_it`。既存の `test_select_strong_ball_needs_it` は消す。

### Task 6: 屋外の地形の描き方

**Files:** Modify `scripts/game/terrain.gd`; Test `tests/test_terrain.gd`

- Produces: `parse` が `R`・`T`（壁）、`~`（水）、`=`（高さ0の橋）を読み、`info["deco"]`（マス→"rock"/"tree"/"bridge"）を返す。`build(map, camera, parent, deco := {})`：木・岩・水・橋のモデル、草の上面の色ゆらぎ（マスごとに決まった2〜3色）と草むら。奈落は暗い裂け目（底に暗い板）。
- Tests: `test_parse_outdoor_symbols`。

### Task 7: 屋外のマップ

**Files:** Modify `scripts/game/area_02.gd`（LAYOUT、ENEMIES、PICKUPS、DOOR_OPEN_FROM、PLAYER_START）; Test `tests/test_area_02_layout.gd`（今のテストがそのまま通ること）

- 64×40マスくらい。外回りに1周する道（川・岩山・崖で回り込む）→ 最後の門でスタートの草地へ戻れる → 中央の高台にゴール。外周は水と木で囲む。
- 画面で確かめる（スタート、門、ゴール、崖と奈落）。

### Task 8: 資料の更新と全体の確認

- CLAUDE.md（操作、地図記号、テスト件数）。全体レビュー、PCのフォルダへ置き直す。
