# 試作2の2回目の手直し（箱庭・日本語・簡単に・弾） Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 試作2のステージを浮いた箱庭の島にし、ガイドを日本語にし、敵を体力1・撃たない（体当たり）にし、弾の高さの不具合を直す。

**Architecture:** ルール（弾の高さ、敵の設定、体当たり、島の外）は `scripts/rules/` に置いてGUTでテストする。地形は高さの層と物の層の2つの文字の地図から読み、`Terrain` が「隣が低くて見える側面」だけを柱として描く（島のふちは下へ伸びる断面、水の柱は滝になる）。

**Tech Stack:** Godot 4.5、GDScript、GUT 9.5.0、PixelMplus（M+ FONT LICENSE）

**Spec:** `docs/superpowers/specs/2026-11-23-death-loop-design.md`（11章が優先）

## Global Constraints

- 前の計画の Global Constraints はそのまま有効。
- 試作1（stage_01）は1層の地図のまま読めること。敵は体力3で撃つまま。
- 新しい地図の記号（物の層）：`.` なし、`T` 丸い木、`P` とがった木、`B` 茂み、`R` 岩、`F` 花、`~` 水、`=` 橋、`_` 奈落、`C`/`D`/`G`。高さの層：`.` 島の外、数字＝高さ。
- UIの文字は PixelMplus（10px・12px）。サイズは整数のまま（ぼやけさせない）。

## Review Focus

1. **弾が崖の下から上の段へ撃たれる**：崖の側面で止まる。→ `test_bullet_stops_at_higher_ground`
2. **高台の敵の弾が低い所のプレイヤーの上を飛ぶ**：当たらない。→ `test_bullet_hits_only_same_height`
3. **敵に触れたまま立ち続ける**：1秒に1回だけダメージ。→ `test_enemy_touch_damage_has_cooldown`
4. **島の外**：歩けない、鉄球を落とせない、敵は引き返す。→ `test_void_is_wall`, `test_cannot_drop_into_void`
5. **地形の柱の高さ**：隣が低い所だけ側面を描く。島のふちは下へ伸びる。→ `test_column_bottom_*`

---

### Task 1: 弾の高さ

**Files:** Modify `scripts/rules/bullet.gd`, `scripts/game/area_02.gd`, `scripts/game/stage_01.gd`; Test `tests/test_bullet.gd`

- Produces: 弾は `map.get_height(c) > height` のマスにも当たって止まる。`Bullet.hits(target: Vector2, target_height: int, radius: float) -> bool`（同じ高さで、距離が radius 未満）。
- Tests: `test_bullet_stops_at_higher_ground`, `test_bullet_flies_over_lower_ground`, `test_bullet_hits_only_same_height`。

### Task 2: 敵の設定と体当たり

**Files:** Modify `scripts/rules/enemy_walker.gd`, `scripts/game/enemy.gd`, `scripts/game/player.gd`, `scripts/game/area_02.gd`; Test `tests/test_enemy.gd`, `tests/test_area_02.gd`

- Produces: `EnemyWalker.new(map, cell, dir, max_hp := 3)`、`EnemyWalker.touches(pos: Vector2, height: int) -> bool`（同じ高さで中心の距離が `TOUCH_RADIUS` 未満）。`Enemy.can_shoot`（area_02 では false）。`Player.take_hit() -> bool`（無敵の間は false）、`Player.INVULNERABLE_SECONDS := 1.0`、無敵の間は点滅。area_02 は毎フレーム体当たりを調べる。
- Tests: `test_walker_custom_hp`, `test_touches_needs_same_height`, `test_enemy_touch_damage_has_cooldown`, `test_area_enemies_have_one_hp_and_do_not_shoot`。

### Task 3: 日本語のフォントとガイド

**Files:** Create `fonts/`（PixelMplus10・12 と LICENSE）; Modify `project.godot`, `.gitignore`（`fonts/*.import` は入れる）, `area_02.gd`, `inventory_menu.gd`, `stage_01.gd`

- 画面の文字をすべて日本語にする。画面で確かめる。

### Task 4: 島の外と2層の地図

**Files:** Modify `height_map.gd`, `terrain.gd`; Test `tests/test_height_map.gd`, `tests/test_terrain.gd`, `tests/test_iron_ball.gd`

- Produces: `HeightMap.set_void/is_void`（`is_wall` は true）。`Terrain.parse_layers(heights: Array, objects: Array, map) -> Dictionary`（`deco` に tree/pine/bush/rock/flower/bridge）。
- Tests: `test_void_is_wall`, `test_parse_layers`, `test_cannot_drop_into_void`。

### Task 5: 箱庭の描き方

**Files:** Modify `terrain.gd`, `stack_sprite.gd`, `player.gd`, `enemy.gd`; Test `tests/test_terrain.gd`, `tests/test_stack_sprite.gd`

- Produces: `Terrain.column_bottom(map, cell) -> int`（隣の床の一番低い所。島の外の隣は下へ伸びる）。地面・水（滝）・橋・木・茂み・岩・花のモデル。暗いグラデーションの背景。`StackSprite.always_redraw`（動くもの用）。それ以外はカメラの角度が変わったときだけ描き直す。
- Tests: `test_column_bottom_flat_is_top_only`, `test_column_bottom_next_to_lower`, `test_column_bottom_at_island_edge_goes_down`, `test_static_sprite_redraws_only_on_turn`。

### Task 6: 箱庭のステージ

**Files:** Modify `area_02.gd`（HEIGHTS・OBJECTS・ENEMIES・PICKUPS・DOOR_OPEN_FROM・PLAYER_START）; Test `tests/test_area_02_layout.gd`

- 四角くない広い島。段々の地形と滝。外回りの道（1分以上）→ 門でたき火へ戻る → 高台のゴール。
- `test_no_enemy_can_shoot_into_safe_zone` を `test_no_enemy_walks_near_safe_zone` に置き換える。
- 画面で確かめる。

### Task 7: 資料の更新と全体の確認

- CLAUDE.md（日本語UI、地図記号、テスト件数）。全体レビュー、PCのフォルダへ置き直す、PRの説明を更新。
