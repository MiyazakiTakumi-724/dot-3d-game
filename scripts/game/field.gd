extends Node2D
## 試作3：1つの大陸のエリアを歩いて行き来する（メインシーン）。
## 今いるエリアの地形・敵・印だけを _area_root の下に作る。矢印の出口から外へ歩くと、画面を暗くして
## 今のエリアを片付け、となりのエリアを作る。エリアをまたいで残るもの（持ち物・墓石・拾い済み・開けた門・
## 敵の復活時間）は RunState と EnemyRoster が持つ。死んでもシーンは読み込み直さず、野営地のたき火から再開する。
## 操作：矢印/WASD 移動、左クリック 手に持つアイテムを使う（鉄球はカーソルの場所、届くのは1.5マス）、
## 1/2 手に持つアイテムを選ぶ、Tab インベントリ、F 門を開ける、右ドラッグ or Q/E カメラ回転。鉄球は上を歩いて拾う。

const FADE_SECONDS := 0.2  ## 切り替えで暗くする時間（明るくするのも同じ）
const TITLE_SECONDS := 2.0  ## エリアに入ったとき名前を出しておく時間
const BULLET_HIT_RADIUS := 6.0
const FALL_SINK_PX := 40.0  ## 奈落に落ちる演出で沈む量（0.5秒で）
const GRAVE_HINT_SECONDS := 6.0
const MAX_HEIGHT := 8
const LEVEL_UP_SECONDS := 3.0
## 設定（簡単モードなど）。インベントリ画面の「設定」のページで変える
var settings := GameSettings.new()

var world: WorldMap
var area: AreaDef
var map: HeightMap
var rules := MovementRules.new()
var run: RunState
var roster := EnemyRoster.new()
var area_state := AreaState.new()
var hotbar := Hotbar.new()
var menu: InventoryMenu
var camera: StackCamera
var player: Player
var ball: Ball
## 鉄球が落ちる点に出す、地面の影のような印
var aim_marker: StackSprite
var enemies: Array[Enemy] = []
## 手に持っている鉄球のランク（Equipment）。落としている間は落としたときのまま
var ball_rank := 1

var _enemy_index := {}  # Enemy → area.enemies の番号
var _area_root: Node2D
var _bullets: Array = []  # [Bullet, StackSprite]
var _pickup_nodes := {}  # 拾いものの番号 → StackSprite
var _gate_nodes := {}  # 門の id → [StackSprite]
var _arrows: Array[StackSprite] = []
var _grave_node: StackSprite
## たき火（炎の形を時間で替えて、ゆらめかせる）
var _bonfire_node: StackSprite
## 暗い地方の石の壁や柱の上のかがり火（2026-11-26 の4回目の直し）：[スプライト, マス, 高さのpx]
var _braziers: Array = []
## かがり火を置く地方と、置く物の上の高さ（px）
const BRAZIER_THEMES := ["castle", "tower", "mist"]
const BRAZIER_ON := {"stonewall": 20.0, "column": 32.0}
const MAX_BRAZIERS := 10
var _bonfire_frame := 0
## このエリアのたき火のマス（なければ (-1, -1)）。近づくと、死んだときに戻る所がここになる
var _campfire_cell := Vector2i(-1, -1)
## 地形の絵を置く所（橋が下りたときなどに作り直す）
var _terrain_root: Node2D
var _deco := {}
## 仕掛けの小物（id → StackSprite の列）。的は開けた後も残す
var _gimmick_nodes := {}
var _target_nodes := {}
## 商人とボスの像 [マス, 言葉]（近づくと真ん中に出す）
var _talkers: Array = []
var map_view: WorldMapView
var _fade: ColorRect
## 切り替えの段階：0 なし、1 暗くしている、2 明るくしている
var _switch_phase := 0
var _switch_time := 0.0
var _switch_to := {}
var _title_time := 0.0
var _grave_hint_time := 0.0
## 始めたときに、どうすればよいかを出しておく残り秒数
var _start_hint_time := 8.0
var _boss_bar: Control  ## 下：戦っているボスの名前と体力
var _boss_fill: ColorRect
var _boss_label: Label
var _guard_fill: ColorRect  ## ボスの構え（崩し）
var _status: Label  ## 左上：体力・持ち物・手に持つアイテム・墓石のあるエリア（文字。画面には出さず、hud が描く）
var hud: Hud  ## いのちとマナのバー・手に持つ物の箱・杖の魔法の待ち時間
## 画面全体の空気：雲の影・地方の暗さと明かり・舞うもの（2026-11-26）
var atmosphere: Atmosphere
## 今のエリアの溶岩のマス（明かりにする）
var _lava_cells: Array[Vector2i] = []
var _message: Label  ## 真ん中：エリアの名前・門のヒント・やられた
var _popups: Control  ## ダメージの数字を置く所（エリアを切り替えると片付ける）
## 真ん中に少しの間だけ出す知らせ（レベルアップ・武器を手に入れたなど）
var _notice_text := ""
var _notice_time := 0.0
var sword := Sword.new()
var bow := Bow.new()
var magic := Magic.new()
var mana := Mana.new()
var _bolts: Array = []  # 飛んでいる魔法の弾 [Pellet, StackSprite, 魔法, 使った段]
var _fires: Array = []  # 火の玉の落ちた所の火 [位置, 段, 残り秒, StackSprite]
var _effects: Array = []  # 少しの間だけ出す絵（火柱・炎の雨）[StackSprite, 残り秒]
## 敵の落とし物（このエリアにいる間だけ）[マス, 品物の id, 数, StackSprite]
var _drops: Array = []
## 道具の薬で少しの間だけ強くなる（つよさ・守り・足）
var buffs := Buffs.new()
## 防具の特色「いのちの回復」の時計
var _regen_clock := 0.0
## お店・鍛冶屋の画面（商人のそばで F）
var shop_menu: ShopMenu
## たき火から移動する画面（2026-11-26 の4回目の直し）
var travel_menu: TravelMenu
## 話す・読む画面（2026-11-26、ストーリー）
var dialogue: DialogueBox
## エリアの人・看板・墓 {cell, person, node}
var _people: Array = []
## ボスを倒したあとに出す言葉 [残り秒, 名前, ページ, full]
var _story_queue: Array = []
## このエリアのボス
var bosses: Array[Boss] = []
## 投げた爆弾 [位置, 高さ, 残り秒, StackSprite]
var _bombs: Array = []
## 画面を白くする光（ブライト）。設定で弱められる
var _flash: ColorRect
var _flash_time := 0.0
var rng := RandomNumberGenerator.new()
## 魔法の弾の照準（狙う高さに浮かぶ輪）。地面の影は aim_marker
var aim_reticle: StackSprite
## セーブの枠（1〜3。0 はセーブしない：テストと画面の確認）。2026-11-26 独自の開発1
var save_slot := 0
## タイトル画面を出している間（うしろで町をカメラが回る）
var in_title := false
var title_menu: TitleMenu
var pause_menu: PauseMenu
const TITLE_TURN := 0.12  ## タイトル画面でカメラが回る速さ（1秒あたりのラジアン）
var _ui_layer: CanvasLayer
var _shots: Array = []  # 飛んでいる矢 [Arrow, StackSprite, ダメージ]
const STUCK_ARROW_SECONDS := 0.8  ## 落ちた矢を地面に刺さったまま見せる時間
var _arrow_blink := 0.0
## まだ作っていない、ほかのエリアのモデルの名前（遊んでいる間に少しずつ作る）
var _warm_queue: Array[String] = []
const WARM_BUDGET_MS := 10.0  ## 1フレームでモデル作りに使う時間

func _ready() -> void:
	world = Continent.build()
	if _real_run():
		settings.load_file()  # 保存した設定（2026-11-26 独自の開発1）。テストと画面の確認では読まない
		InventoryMenu.apply_window(settings.fullscreen)
	Sfx.attach(self)  # 効果音を鳴らす所（2026-11-26）
	Sfx.level = settings.sfx_level
	if DisplayServer.get_name() != "headless" and not _real_run():
		var mode := DisplayServer.window_get_mode()
		settings.fullscreen = mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	var camp_info: Dictionary = Continent.load_map(world.area(Continent.START_AREA))[1]
	run = RunState.new(Continent.START_AREA, camp_info["checkpoint"])
	camera = StackCamera.new()
	camera.shake_enabled = settings.shake
	add_child(camera)
	Terrain.add_background(self)
	atmosphere = Atmosphere.new()
	add_child(atmosphere)
	atmosphere.setup(camera)
	_area_root = Node2D.new()
	add_child(_area_root)

	player = Player.new()
	add_child(player)
	ball = Ball.new()
	ball.rules_ball.landed.connect(_on_ball_landed)
	add_child(ball)
	aim_marker = StackSprite.new()
	aim_marker.camera = camera
	aim_marker.sort_by_cell = true
	aim_marker.draw_bias = 1
	aim_marker.voxel_scale = Props.VOXEL_SCALE
	aim_marker.set_model(Props.aim_shadow())
	aim_marker.force_hidden = true
	add_child(aim_marker)
	aim_reticle = StackSprite.new()
	aim_reticle.camera = camera
	aim_reticle.draw_bias = 4
	aim_reticle.force_hidden = true
	aim_reticle.voxel_scale = Props.VOXEL_SCALE
	aim_reticle.set_model(Props.aim_ring())
	add_child(aim_reticle)
	rng.randomize()

	enter_area(Continent.START_AREA, Continent.START_CELL)
	player.setup(map, rules, Continent.START_CELL, camera)
	apply_stats()
	player.set_hp(player.max_hp)
	ball.setup(player, map, rules, camera)
	camera.follow(player.mover.pos, player.mover.height * StackSprite.LEVEL_PX, 1.0)
	_title_time = 0.0  # 始めは名前より操作のヒントを出す

	_build_ui()
	menu = InventoryMenu.new()
	menu.setup(run, settings)
	menu.close_requested.connect(close_inventory)
	menu.stats_changed.connect(apply_stats)
	menu.skill_learned.connect(_on_skill_learned)
	menu.settings_changed.connect(_on_settings_changed)
	add_child(menu)
	shop_menu = ShopMenu.new()
	shop_menu.setup(run)
	shop_menu.bought.connect(_on_bought)
	add_child(shop_menu)
	travel_menu = TravelMenu.new()
	travel_menu.setup(run, world)
	travel_menu.chosen.connect(_on_travel)
	add_child(travel_menu)
	dialogue = DialogueBox.new()
	dialogue.setup()
	dialogue.finished.connect(_on_dialogue_done)
	add_child(dialogue)
	var map_layer := CanvasLayer.new()
	map_layer.layer = 5
	add_child(map_layer)
	map_view = WorldMapView.new()
	map_view.setup(world, run)
	map_layer.add_child(map_view)
	pause_menu = PauseMenu.new()
	pause_menu.setup(settings)
	pause_menu.settings_changed.connect(_on_settings_changed)
	pause_menu.to_title.connect(_pause_to_title)
	pause_menu.quit_game.connect(_pause_quit)
	add_child(pause_menu)
	title_menu = TitleMenu.new()
	title_menu.setup(settings)
	title_menu.settings_changed.connect(_on_settings_changed)
	title_menu.start_new.connect(start_new_game)
	title_menu.load_slot.connect(load_game)
	title_menu.quit_game.connect(func(): get_tree().quit())
	add_child(title_menu)
	StackCamera.apply_pixel_scale(self)
	warm_hero_looks()
	_maybe_screenshot()
	if _real_run():
		show_title()

## エリアを作り直す。今のエリアの地形・敵・弾・印を片付け、id のエリアを cell から始める。
## 地面の見た目ごとの足音（2026-11-26）
const STEP_SOUNDS := {"grass": "step_grass", "mountain": "step_gravel", "lava": "step_gravel", "castle": "step_stone", "tower": "step_stone", "town": "step_stone", "mist": "step_grass"}

## 土の道を描く地方（町と塔は石畳）
const TRAIL_THEMES := ["grass", "mountain", "lava", "castle", "mist"]

func enter_area(id: String, cell: Vector2i) -> void:
	for e in enemies:
		if is_instance_valid(e):
			e.shot.disconnect(_on_enemy_shot)
			e.set_process(false)
	enemies.clear()
	_enemy_index.clear()
	_bullets.clear()
	_shots.clear()
	_bolts.clear()
	_fires.clear()
	_effects.clear()
	_drops.clear()
	_bombs.clear()
	_lobs.clear()
	_hot.clear()
	_rollers.clear()
	_strikes.clear()
	_pits_tmp.clear()  # 地図は読み込み直すので、開いた奈落も元に戻る
	for b in bosses:
		if is_instance_valid(b):
			b.set_process(false)
	bosses.clear()
	bow.cancel()
	_pickup_nodes.clear()
	_gate_nodes.clear()
	_gimmick_nodes.clear()
	_target_nodes.clear()
	_talkers.clear()
	_people.clear()
	_arrows.clear()
	_grave_node = null
	if _popups != null:
		for c in _popups.get_children():
			c.queue_free()
	for c in _area_root.get_children():
		_area_root.remove_child(c)
		c.queue_free()

	area = world.area(id)
	player.step_sound = STEP_SOUNDS.get(area.theme, "step_grass")
	if atmosphere != null:
		atmosphere.set_theme(area.theme)
	run.visit(id)
	var loaded := Continent.load_map(area)
	map = loaded[0]
	var info: Dictionary = loaded[1]
	_deco = info["deco"]
	_lava_cells.clear()
	for k in _deco:
		if k is Vector2i and _deco[k] == "lava":
			_lava_cells.append(k)
	for g in area.gimmicks:
		if run.is_gimmick_open(g.id):
			_apply_open(g)
	if area.theme in TRAIL_THEMES and not _deco.has("paths"):
		# 出口とたき火をつなぐ土の道（見た目だけ。2026-11-26 の4回目の直し）
		_deco["paths"] = Trails.cells(map, area.exits, info.get("checkpoint", Vector2i(-1, -1)))
	_terrain_root = Node2D.new()
	_area_root.add_child(_terrain_root)
	Terrain.build(map, camera, _terrain_root, _deco)
	_bonfire_node = null
	_campfire_cell = Vector2i(-1, -1)
	if info.has("checkpoint"):
		_campfire_cell = info["checkpoint"]
		_bonfire_node = _marker(info["checkpoint"], Props.bonfire(), 1)
	_place_braziers()
	_place_gimmicks()
	_place_talkers(info)
	_place_story(info)
	for i in area.pickups.size():
		var p = area.pickups[i]
		if not run.is_picked(area.pickup_id(i)):
			_pickup_nodes[i] = _marker(p[0], Props.pickup(p[1]), 1)
		elif is_chest(p[1]):
			_marker(p[0], Props.chest_open(), 1)  # 開けた宝箱は、開いたまま残す
	for ex in area.exits:
		if ex.door_id != "" and not run.is_door_open(ex.door_id):
			_close_gate(ex)
		else:
			_add_arrows(ex)
	if run.grave != null and run.grave.area_id == id:
		map.set_blocker(run.grave.cell, HeightMap.Blocker.GRAVE)
		_grave_node = _marker(run.grave.cell, Props.grave(), 2)
	_spawn_enemies()
	_spawn_bosses()

	if player.mover != null:
		player.mover.map = map
		player.mover.place(cell)
		player.mover.edge_push = Vector2i.ZERO  # 着いたとたんに戻らないように
		camera.focus = player.mover.pos
		camera.focus_height = player.mover.height * StackSprite.LEVEL_PX
	if ball.player != null:
		ball.map = map
		ball.rules_ball.return_to_hand()  # 地面に置いたままの鉄球は手元に戻る
	aim_marker.sort_map = map
	_title_time = TITLE_SECONDS
	_queue_warm()
	autosave()

## となりのエリアのモデルを作る順番に並べる（warm は後ろから取る）。エリアが多いので、遠いエリアは入るときに作る。
func _queue_warm() -> void:
	var near: Array[String] = []
	for ex in area.exits:
		if not near.has(ex.target):
			near.append(ex.target)
	var seen := {}
	_warm_queue.clear()
	for id in near:
		var loaded := Continent.load_map(world.area(id))
		for k in Terrain.model_keys(loaded[0], loaded[1]["deco"]):
			if not Terrain.is_cached(k) and not seen.has(k):
				seen[k] = true
				_warm_queue.append(k)

func warm_left() -> int:
	return _warm_queue.size()

func _spawn_enemies() -> void:
	var safe := area.entry_safe_cells()
	for i in area.enemies.size():
		if not roster.present(area.id, i):
			continue
		var d = area.enemies[i]
		var e := Enemy.new()
		var lv := run.enemy_level(d[3] if d.size() > 3 else 1)
		e.setup(map, d[0], d[1], player, camera, d[2], Enemy.SHOOT_INTERVAL, lv)
		e.walker.forbidden = safe
		e.shot.connect(_on_enemy_shot)
		e.melee_hit.connect(_on_melee_hit.bind(e))
		e.exploded.connect(_on_enemy_exploded.bind(e))
		e.lobbed.connect(_on_enemy_lobbed.bind(e))
		_wire_enemy(e)
		e.walker.died.connect(_on_enemy_died.bind(area.id, i, e.kind, lv, e.walker))
		_area_root.add_child(e)
		enemies.append(e)
		_enemy_index[e] = i

## まだ倒していないボスを置く。双子は2体で1つ（片方はもう片方の後ろに隠れる）。
func _spawn_bosses() -> void:
	var twins: Array[Boss] = []
	for d in area.bosses:
		var g := BossKind.group(d[1])
		if run.is_boss_defeated(g):
			continue
		var b := Boss.new()
		b.setup(self, d[1], d[0], map, camera, run.bosses_defeated)
		b.walker.forbidden = area.entry_safe_cells()
		b.walker.died.connect(_on_boss_part_died.bind(b))
		_area_root.add_child(b)
		bosses.append(b)
		if g == "双子":
			twins.append(b)
	if twins.size() == 2:
		twins[0].partner = twins[1]
		twins[1].partner = twins[0]
		twins[1].hider = true

## ボスの1体が倒れた。双子は2体とも倒したら。落とし物はランク4の品物とボスの素材。
func _on_boss_part_died(b: Boss) -> void:
	var g := b.group
	for o in bosses:
		if is_instance_valid(o) and o != b and o.group == g and o.walker.alive:
			return
	var cell := b.walker.cell()
	_drop_loot(cell, BossKind.drops(g))
	var levels := run.on_boss_killed(g, BossKind.exp_reward(g))
	camera.shake(4.0)
	if run.cleared and g == "ブライト":
		notice("ブライトを倒した！\n大陸に光が戻った ― おわり ―\n（このあとも遊べる）", 8.0)
	elif levels > 0:
		notice("%sを倒した！\nレベル%d になった　Tab：ポイントを振る" % [g, run.stats.level], 5.0)
	else:
		notice("%sを倒した！" % g, 4.0)
	if run.can_open_door(RunState.SEAL_DOOR) and g in RunState.REGION_BOSSES and run.seal_bosses_left() == 0:
		notice("%sを倒した！\n神秘の塔の封印が解けた（町の南西の門）" % g, 6.0)
	elif g in RunState.REGION_BOSSES and run.mist_bosses_left() == 0 and RunState.REGION_BOSSES.size() - run.seal_bosses_left() == Story.MIST_BOSSES:
		notice("%sを倒した！\n霧の谷の霧が 薄くなった（草原の 沼の小道の南）" % g, 6.0)
	# ストーリー：倒したあとの言葉（ブライトは終わりの言葉）
	if g == "ブライト":
		_story_queue.append([3.0, "", Story.ending(Story.flags(run)), true])
	elif not Story.boss_beat(g).is_empty():
		_story_queue.append([2.0, g, Story.boss_beat(g), false])
	apply_stats()
	autosave()

## ボスが手下を呼ぶ（廃城の主の亡霊・女王蜂の蜂・ブライトの影）。手下は倒しても落とし物も経験値もなく、戻ってもこない。
func spawn_minion(kind: EnemyKind.Kind, at: Vector2) -> Enemy:
	var c := HeightMap.world_to_cell(at)
	if not map.in_bounds(c) or map.is_wall(c) or map.is_pit(c) or map.is_water(c):
		return null
	var e := Enemy.new()
	e.setup(map, c, Vector2.DOWN, player, camera, kind, Enemy.SHOOT_INTERVAL, run.enemy_level(Loot.region_level(area.region)))
	e.minion = true
	e.walker.forbidden = area.entry_safe_cells()
	e.shot.connect(_on_enemy_shot)
	e.melee_hit.connect(_on_melee_hit.bind(e))
	e.exploded.connect(_on_enemy_exploded.bind(e))
	e.lobbed.connect(_on_enemy_lobbed.bind(e))
	_wire_enemy(e)
	_area_root.add_child(e)
	enemies.append(e)
	_effect_sprite(Props.rain_ring(8.0), e.walker.pos, e.walker.height, 0.0, 0.3)
	return e

## 敵の技（2026-11-26）に要るつなぎ：落ちてくる矢を調べる・スライムが分かれる・魔術師が呼ぶ。
func _wire_enemy(e: Enemy) -> void:
	e.field = self
	e.split.connect(_on_slime_split)
	e.summon.connect(_on_enemy_summon)

## スライムが倒れて、小さい2匹に分かれる（落とし物も経験値もない）。
func _on_slime_split(pos: Vector2, _h: int) -> void:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return
	for k in 2:
		var at := pos + Vector2(-6.0 if k == 0 else 6.0, 0.0)
		var s := spawn_minion(EnemyKind.Kind.WEAK, at)
		if s == null:
			s = spawn_minion(EnemyKind.Kind.WEAK, pos)
		if s != null:
			s.make_small()

func _on_enemy_summon(kind: EnemyKind.Kind, at: Vector2) -> void:
	if area_state.result == AreaState.Result.PLAYING and not is_switching():
		spawn_minion(kind, at)

## 飛んでいる矢のうち、pos から r 以内に落ちるものの落ちる所（なければ Vector2.INF）。ゴブリンがよけるのに使う。
func incoming_arrow(pos: Vector2, r: float) -> Vector2:
	for sh in _shots:
		var a: Arrow = sh[0]
		if a.to.distance_to(pos) < r:
			return a.to
	return Vector2.INF

## ボスの体の一部（宝箱の王のにせものなど）をエリアに置く。
func add_boss_part(n: Node) -> void:
	_area_root.add_child(n)

## 少しあとに落ちてくる攻撃（溶岩の火柱・ブライトの光の雨）。落ちる所に印が出て、delay 秒後にそこにいるとダメージ。
var _strikes: Array = []  # [位置, 高さ, 残り秒, 広さ, ダメージ, 落ちたときの絵]
## 落ちた攻撃の数（テスト用）
var strikes_done := 0
func boss_strike(at: Vector2, delay: float, radius: float, dmg: int, model: VoxelModel) -> void:
	var c := HeightMap.world_to_cell(at)
	if not map.in_bounds(c) or map.is_wall(c):
		return
	var h := map.get_height(c)
	_effect_sprite(Props.aim_shadow(), at, h, 0.0, delay).set_meta("steady", true)
	_strikes.append([at, h, delay, radius, dmg, model])
	Sfx.play("warn", at, -4.0)

func strikes_count() -> int:
	return _strikes.size()

func _step_strikes(delta: float) -> void:
	for i in range(_strikes.size() - 1, -1, -1):
		_strikes[i][2] -= delta
		if _strikes[i][2] > 0.0:
			continue
		var s = _strikes[i]
		_strikes.remove_at(i)
		strikes_done += 1
		_effect_sprite(s[5], s[0], s[1], 0.0, 0.35)
		Sfx.play("strike", s[0], -3.0)
		if area_state.result == AreaState.Result.PLAYING and player.mover.pos.distance_to(s[0]) < s[3] \
				and absi(player.mover.height - s[1]) <= 1:
			hurt_player(s[4])

## 転がる大岩（岩転がしの巨人の2段目）。まっすぐ転がり、低い所へは落ち、高い所や壁で止まって砕ける。
var _rollers: Array = []  # [位置, 向き, 待ち秒, ダメージ, 絵, 高さ]
const ROLL_SPEED := 90.0
const ROLL_WAIT := 0.7
func boss_roll(from: Vector2, dir: Vector2, dmg: int, model: VoxelModel = null) -> void:
	var c := HeightMap.world_to_cell(from)
	while map.in_bounds(c) and (map.is_wall(c) or map.is_pit(c)):
		c += Vector2i(dir.round())  # 端が壁なら、転がりだせる所まで進める
		var cc := HeightMap.cell_center(c)
		from = Vector2(cc.x, from.y) if dir.x != 0.0 else Vector2(from.x, cc.y)
	if not map.in_bounds(c):
		return
	var h := map.get_height(c)
	var s := _effect_sprite(model if model != null else BossModels.model("", "boulder"), from, h, 0.0, 30.0)
	if model == null:
		s.voxel_scale = BossModels.DRAW_SCALE
	s.set_meta("steady", true)
	_rollers.append([from, dir, ROLL_WAIT, dmg, s, h])
	Sfx.play("roll", from)

func rollers_count() -> int:
	return _rollers.size()

func _step_rollers(delta: float) -> void:
	for i in range(_rollers.size() - 1, -1, -1):
		var r = _rollers[i]
		var s = r[4]  # 消えているかもしれないので型を付けない
		if r[2] > 0.0:
			r[2] -= delta  # 転がりだす前に少しゆれる（よける合図）
			if is_instance_valid(s):
				s.world_pos = r[0] + Vector2(sin(r[2] * 60.0), 0) * 1.0
			continue
		var next: Vector2 = r[0] + r[1] * ROLL_SPEED * delta
		var c := HeightMap.world_to_cell(next + r[1] * 6.0)
		var stop: bool = not map.in_bounds(c) or map.is_wall(c) or map.get_height(c) > r[5]
		if not stop:
			r[0] = next
			var here := HeightMap.world_to_cell(next)
			if map.in_bounds(here) and not map.is_pit(here):
				r[5] = map.get_height(here)
		if is_instance_valid(s):
			s.world_pos = r[0]
			s.base_height = r[5]
		if area_state.result == AreaState.Result.PLAYING and player.mover.pos.distance_to(r[0]) < 10.0 \
				and player.mover.height == r[5]:
			hurt_player(r[3])
		if stop:
			camera.shake(2.0)
			_effect_sprite(Props.rain_ring(12.0), r[0], r[5], 0.0, 0.3)
			Sfx.play("break", r[0])
			if is_instance_valid(s):
				s.queue_free()
			_rollers.remove_at(i)

## 少しの間だけ開く奈落（岩転がしの巨人・岩窟のぬし。2026-11-25 夜の2回目の直し）。
## はじめの warn 秒はひびの印だけで、そのあと open_for 秒だけ奈落になる（落ちると死ぬ）。閉じると元の地面に戻る。
## 出口のそば・墓石・落ちている鉄球と落とし物・敵とボスのいるマスには開かない。
var _pits_tmp: Array = []  # [マスの配列, ひびの残り秒, 開いている残り秒, 絵の配列]
func boss_pits(cells: Array, warn: float, open_for: float) -> int:
	var safe := area.entry_safe_cells()
	var busy := {}
	for e in enemies:
		if is_instance_valid(e):
			busy[e.walker.cell()] = true
	for b in bosses:
		if is_instance_valid(b):
			busy[b.walker.cell()] = true
	if ball.rules_ball.state != IronBall.State.HELD:
		busy[ball.rules_ball.cell()] = true
	for d in _drops:
		busy[d[0]] = true
	for p in _pits_tmp:
		for c in p[0]:
			busy[c] = true
	var ok: Array = []
	var sprites: Array = []
	for c in cells:
		if ok.has(c) or not map.in_bounds(c) or map.is_wall(c) or map.is_pit(c) or map.is_water(c) or map.is_void(c) \
				or map.get_blocker(c) != HeightMap.Blocker.NONE or safe.has(c) or busy.has(c):
			continue
		ok.append(c)
		var s := _effect_sprite(Props.crack_mark(), HeightMap.cell_center(c), map.get_height(c), 0.3, warn + open_for)
		sprites.append(s)
	if not ok.is_empty():
		_pits_tmp.append([ok, warn, open_for, sprites])
		Sfx.play("crack", HeightMap.cell_center(ok[0]))
	return ok.size()

## 今開いている奈落のマスの数（テスト用）
func open_pits() -> int:
	var n := 0
	for p in _pits_tmp:
		if p[1] <= 0.0:
			n += p[0].size()
	return n

func _step_pits(delta: float) -> void:
	for i in range(_pits_tmp.size() - 1, -1, -1):
		var p = _pits_tmp[i]
		if p[1] > 0.0:
			p[1] -= delta
			for s in p[3]:
				if is_instance_valid(s):
					s.modulate.a = 0.55 + 0.45 * sin(_arrow_blink * 14.0)  # ひびが点滅する（よける合図）
			if p[1] > 0.0:
				continue
			camera.shake(2.5)
			Sfx.play("pit", HeightMap.cell_center(p[0][0]))
			for j in p[0].size():
				var c: Vector2i = p[0][j]
				map.set_pit(c, true)
				if is_instance_valid(p[3][j]):
					p[3][j].set_model(Props.hole())
					p[3][j].modulate.a = 1.0
					p[3][j].set_meta("steady", true)
			# 立っているマスが開いたら、そのまま落ちる
			if area_state.result == AreaState.Result.PLAYING and p[0].has(player.mover.cell()):
				player.mover.fell = true
			continue
		p[2] -= delta
		if p[2] <= 0.0:
			for c in p[0]:
				map.set_pit(c, false)
			for s in p[3]:
				if is_instance_valid(s):
					s.queue_free()
			_pits_tmp.remove_at(i)

## 燃えている床の数（テスト用）
func hot_count() -> int:
	return _hot.size()

## ボスの弾（巨人の岩・火の息など）。敵の弾と同じに飛ぶ。
func boss_shot(b: Bullet) -> void:
	_on_enemy_shot(b)

## ボスの攻撃の絵などを少しの間だけ置く（boss.gd から）。
func effect_at(model: VoxelModel, pos: Vector2, h: int, seconds: float) -> StackSprite:
	return _effect_sprite(model, pos, h, 0.0, seconds)

## 燃える跡（溶岩洞のぬし）。入るとダメージ。
var _hot: Array = []  # [位置, 高さ, 残り秒, ダメージ]
var _hot_clock := 0.0
func boss_fire(pos: Vector2, h: int, seconds: float, dmg: int) -> void:
	_effect_sprite(Props.flame(rng.randi() % 3), pos, h, 0.0, seconds)
	Sfx.play("fire", pos, -8.0)
	_hot.append([pos, h, seconds, dmg])

func _step_boss_floor(delta: float) -> void:
	_hot_clock -= delta
	for i in range(_hot.size() - 1, -1, -1):
		_hot[i][2] -= delta
		if _hot[i][2] <= 0.0:
			_hot.remove_at(i)
	if _hot_clock > 0.0 or area_state.result != AreaState.Result.PLAYING:
		return
	var mv := player.mover
	for f in _hot:
		if mv.pos.distance_to(f[0]) < 8.0 and mv.height == f[1]:
			_hot_clock = 0.5
			hurt_player(f[3])
			return
	for b in bosses:
		if is_instance_valid(b) and b.lava_flooded() and mv.height <= Boss.LAVA_LOW:
			_hot_clock = 1.0
			hurt_player(maxi(1, b.attack / 2))
			return

## 戦っているボス（体力のバーを出す）。いなければ null。
func active_boss() -> Boss:
	for b in bosses:
		if is_instance_valid(b) and b.active and b.walker.alive:
			return b
	return null

func enemy_index(e: Enemy) -> int:
	return _enemy_index.get(e, -1)

## そのエリアの番号の敵が、今いるか（倒されていない）。
func has_enemy(index: int) -> bool:
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive and _enemy_index.get(e, -1) == index:
			return true
	return false

func _on_enemy_died(area_id: String, index: int, kind: EnemyKind.Kind, level: int, w: EnemyWalker) -> void:
	roster.kill(area_id, index)
	if area_id == area.id:
		_drop_loot(w.cell(), Loot.roll_kind(kind, area.region, level, rng, loot_mult()))
	if run.on_enemy_killed(kind, level) > 0:
		notice("レベル%d になった！\nTab：ポイントを振る" % run.stats.level)
		Sfx.play("level_up")
		apply_stats()

## 落とし物を、そのマスとまわりの空いたマスに置く。
func _drop_loot(cell: Vector2i, drops: Array) -> void:
	var spots: Array[Vector2i] = [cell]
	for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		spots.append(cell + d)
	var k := 0
	for d in drops:
		while k < spots.size() and not _drop_ok(spots[k]):
			k += 1
		spawn_drop(spots[mini(k, spots.size() - 1)] if k < spots.size() else cell, d[0], d[1])
		k += 1

func _drop_ok(c: Vector2i) -> bool:
	return map.in_bounds(c) and not map.is_wall(c) and not map.is_pit(c) and not map.is_water(c)

## 敵が落とし物をする割合（狩人の弓の特色）。
func loot_mult() -> float:
	return float(run.inventory.equipment.trait_of(Equipment.Slot.BOW, "loot", 1.0))

## 火の玉が弾けた：まわりのプレイヤーにダメージ。
func _on_enemy_exploded(pos: Vector2, h: int, e: Enemy) -> void:
	_effect_sprite(Props.rain_ring(EnemyKind.BOMB_RADIUS), pos, h, 0.0, 0.4)
	camera.shake(2.0)
	Sfx.play("explosion", pos)
	if area_state.result == AreaState.Result.PLAYING and not is_switching() \
			and player.mover.pos.distance_to(pos) < EnemyKind.BOMB_RADIUS and absi(player.mover.height - h) <= 1:
		hurt_player(e.attack)

## 投石兵の石：[落ちる所, 高さ, 残り秒, 全部の秒, ダメージ, 石の絵, 投げた所, 投げた高さ]
var _lobs: Array = []

## 投石兵が石を投げた：落ちる所に影を出し、石を山なりに飛ばす。着いたときにそこにいるとダメージ。
func _on_enemy_lobbed(at: Vector2, h: int, delay: float, dmg: int, e: Enemy) -> void:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return
	var c := HeightMap.world_to_cell(at)
	var ground := map.get_height(c) if map.in_bounds(c) else h
	_effect_sprite(Props.aim_shadow(), at, ground, 0.0, delay).set_meta("steady", true)
	var stone := _effect_sprite(Props.bullet(), e.walker.pos, e.walker.height, 6.0, delay)
	stone.modulate = Color(0.75, 0.7, 0.62)
	stone.set_meta("steady", true)
	_lobs.append([at, ground, delay, delay, dmg, stone, e.walker.pos, e.walker.height])
	Sfx.play("throw", e.walker.pos)

func _step_lobs(delta: float) -> void:
	for i in range(_lobs.size() - 1, -1, -1):
		var l = _lobs[i]
		l[2] -= delta
		var t := clampf(1.0 - l[2] / l[3], 0.0, 1.0)
		var stone = l[5]  # 消えているかもしれないので型を付けない
		if is_instance_valid(stone):
			stone.world_pos = (l[6] as Vector2).lerp(l[0], t)
			var hy := lerpf(l[7] * StackSprite.LEVEL_PX, l[1] * StackSprite.LEVEL_PX, t) + 6.0 + sin(t * PI) * 34.0
			stone.base_height = l[1]
			stone.lift_px = hy - l[1] * StackSprite.LEVEL_PX
		if l[2] > 0.0:
			continue
		_lobs.remove_at(i)
		_effect_sprite(Props.rain_ring(10.0), l[0], l[1], 0.0, 0.25)
		Sfx.play("arrow_hit", l[0])
		if area_state.result == AreaState.Result.PLAYING and player.mover.pos.distance_to(l[0]) < 11.0 \
				and absi(player.mover.height - l[1]) <= 1:
			hurt_player(l[4])

## 画面の真ん中に、少しの間だけ知らせを出す。
func notice(text: String, seconds := LEVEL_UP_SECONDS) -> void:
	_notice_text = text
	_notice_time = seconds

func _on_melee_hit(e: Enemy) -> void:
	Sfx.play("enemy_swing", e.walker.pos)
	if area_state.result == AreaState.Result.PLAYING and not is_switching():
		hurt_player(e.attack)

## 敵の攻撃（攻撃力 enemy_attack）を受ける。無敵の間は受けない。受けたら true。
func hurt_player(enemy_attack: int) -> bool:
	var dmg := Damage.enemy_hit(enemy_attack, settings.easy_mode, defense())
	if not player.take_hit(dmg):
		return false
	_popup(player.mover.pos, player.mover.height, dmg, Color("ff6b6b"))
	Sfx.play("hurt")
	return true

## 守り：防具の特色と守りの薬。
func defense() -> int:
	return int(run.inventory.equipment.armor_bonus("def") + buffs.value("def"))

## ステータス（レベル・振り分け・技能）と防具を、体力の最大・足の速さ・段差の決まりに反映する。
## 最大が増えた分は今の体力も増える。毎フレーム呼んでよい（防具が墓石に入ったときなども、これで合う）。
func apply_stats() -> void:
	var move_skills := run.stats.skills_in(PlayerStats.Stat.MOVE)
	player.can_crouch = move_skills >= 1
	rules.max_drop = 3 + (1 if move_skills >= 2 else 0)  # 受け身
	player.mover.slow_climb = move_skills >= 3  # よじ登り
	var new_max := run.stats.max_hp(run.inventory.equipment.armor_hp())
	if new_max > player.max_hp:
		player.hp += new_max - player.max_hp
	player.max_hp = new_max
	player.hp = mini(player.hp, new_max)
	var eq := run.inventory.equipment
	player.speed_mult = run.stats.move_speed_mult() * (1.0 + eq.armor_bonus("speed") + buffs.value("speed"))
	mana.set_max(run.stats.max_mana() + int(eq.armor_bonus("mana")) + int(eq.trait_of(Equipment.Slot.STAFF, "mana", 0)))

## 手に持っている武器を足した攻撃力。
## ランクのほかに、品物の特色「つよさ＋」と力の薬も足す。
func current_attack() -> int:
	var rank := 0
	var id := held_item()
	match hotbar.selected:
		Hotbar.Item.IRON_BALL:
			rank = ball_rank
		Hotbar.Item.SWORD, Hotbar.Item.BOW, Hotbar.Item.STAFF:
			rank = run.inventory.equipment.effective(Hotbar.WEAPON_SLOT[hotbar.selected])
	var extra := int(ItemCatalog.trait_value(id, "atk", 0)) + int(buffs.value("atk"))
	return run.stats.attack(Equipment.rank_attack(rank) + extra)

## 手に持っている武器の品物の id（鉄球は落としている間も、落とした鉄球）。
func held_item() -> String:
	match hotbar.selected:
		Hotbar.Item.IRON_BALL:
			return ball.rules_ball.item
		Hotbar.Item.SWORD, Hotbar.Item.BOW, Hotbar.Item.STAFF:
			return run.inventory.equipment.current(Hotbar.WEAPON_SLOT[hotbar.selected])
	return ""

## 武器の特色（毒・やけど・遅くする・吸いとる）を、当たった敵に与える。
func _apply_traits(e, id: String) -> void:
	var w: EnemyWalker = e.walker
	if float(ItemCatalog.trait_value(id, "poison", 0)) > 0.0:
		w.poison(Arrow.POISON_SECONDS)
	if float(ItemCatalog.trait_value(id, "burn", 0)) > 0.0:
		w.burn(Magic.BURN_SECONDS)
	if float(ItemCatalog.trait_value(id, "slow", 0)) > 0.0:
		w.slow(Magic.SLOW_SECONDS)
	var drain := int(ItemCatalog.trait_value(id, "drain", 0))
	if drain > 0 and player.hp > 0:
		player.set_hp(mini(player.max_hp, player.hp + drain))
	if e.has_method("flash"):
		e.flash()

## 手に持っている鉄球のランクと品物を、装備に合わせる（落としている間は替えない）。
func _sync_ball_rank() -> void:
	if ball.rules_ball.state != IronBall.State.HELD:
		return
	ball_rank = run.inventory.equipment.effective(Equipment.Slot.BALL)
	ball.rules_ball.set_strong(ball_rank >= 2)
	ball.rules_ball.set_item(run.inventory.equipment.current(Equipment.Slot.BALL))

## 攻撃が当たる相手（敵とボス）。どれも walker（EnemyWalker）と blocks(from)・flash() を持つ。
func targets() -> Array:
	var out := []
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive:
			out.append(e)
	for b in bosses:
		if is_instance_valid(b) and b.walker.alive and b.active:
			out.append(b)
			for d in b.decoys:
				if is_instance_valid(d) and d.walker.alive:
					out.append(d)
	return out

## 攻撃を当てる。入ったら true。source は "sword"・"arrow"・"magic"・"ball"・"bomb"。id は武器の品物（特色を与える）。
## 敵の種類とようすで、入り方が変わる（敵は EnemyKind.hit_rule、ボスは Boss.hit_rule）：
## 浮いている敵に剣と鉄球は「とどかない」、すけている亡霊は「すりぬけた」、盾の正面は「ふせいだ」、
## 甲虫のかたい殻は1だけ（「かたい」）、目を回しているイノシシは2倍。
## 敵・ボスの体が大きい分、攻撃が当たる範囲を広げる量（px。2026-11-26 に敵とボスを大きくした）。
static func body_extra(e) -> float:
	if e is Boss:
		return BossModels.BODY_EXTRA
	if e is Enemy:
		return EnemyModels.BODY_EXTRA
	return 0.0

func damage_target(e, dmg: int, from: Vector2, id := "", color := Color.WHITE, source := "sword") -> bool:
	var rule: String = e.hit_rule(source, from)
	var gray := Color("b0b8c8")
	match rule:
		"miss":
			_popup_text(e.walker.pos, e.walker.height, "とどかない", gray)
			Sfx.play("miss", e.walker.pos)
			return false
		"pass":
			_popup_text(e.walker.pos, e.walker.height, "すりぬけた", gray)
			Sfx.play("miss", e.walker.pos)
			return false
		"block":
			_popup_text(e.walker.pos, e.walker.height, "ふせいだ", gray)
			Sfx.play("block", e.walker.pos)
			if e.has_method("on_blocked"):
				e.on_blocked()
			return false
		"armor":
			dmg = 1
			_popup_text(e.walker.pos, e.walker.height, "かたい", gray)
			color = gray
			Sfx.play("block", e.walker.pos)
		"weak":
			dmg *= 2
			color = Color("ffd54a")
			Sfx.play("weak", e.walker.pos)
		_:
			Sfx.play("arrow_hit" if source == "arrow" else "hit", e.walker.pos)
	# 武器の得意・不得意（2026-11-26）。ふつうの敵は種類ごと、ボスは構え（崩し）
	if e is Enemy:
		var aff := EnemyKind.affinity(e.kind, source)
		if aff > 1.0:
			dmg = maxi(1, roundi(dmg * aff))
			_popup_text(e.walker.pos, e.walker.height + 2, "弱点！", Color("ffb347"))
			if color == Color.WHITE:
				color = Color("ffb347")
		elif aff < 1.0:
			dmg = maxi(1, roundi(dmg * aff))
			_popup_text(e.walker.pos, e.walker.height + 2, "効きにくい", gray)
	elif e is Boss:
		var before_broken: bool = e.guard.broken()
		dmg = e.guard_damage(source, dmg)
		if not before_broken and e.guard.broken():
			_popup_text(e.walker.pos, e.walker.height + 3, "崩した！", Color("ffd54a"))
			Sfx.play("weak", e.walker.pos)
			camera.shake(2.0)
		elif e.guard.mult(source) < 1.0:
			_popup_text(e.walker.pos, e.walker.height + 2, "構えている", gray)
	e.walker.take_damage(dmg)
	if not e.walker.alive:
		Sfx.play("boss_die" if e is Boss else "enemy_die", e.walker.pos)
	_popup(e.walker.pos, e.walker.height, dmg, color)
	if id != "":
		_apply_traits(e, id)
	elif e.has_method("flash"):
		e.flash()
	e.on_hit(source)
	return true

func _popup_text(pos: Vector2, h: int, text: String, color: Color) -> void:
	_popups.add_child(DamagePopup.make_text(camera, pos, h * StackSprite.LEVEL_PX, text, color))

func _popup(pos: Vector2, h: int, amount: int, color: Color) -> void:
	_popups.add_child(DamagePopup.make(camera, pos, h * StackSprite.LEVEL_PX, amount, color))

func is_switching() -> bool:
	return _switch_phase != 0

func _start_switch(to: Dictionary) -> void:
	Sfx.play("area")
	_switch_phase = 1
	_switch_time = 0.0
	_switch_to = to
	player.controllable = false
	_area_root.process_mode = Node.PROCESS_MODE_DISABLED  # 敵と弾を止める

func _update_switch(delta: float) -> void:
	_switch_time += delta
	if _switch_phase == 1:
		_fade.color.a = clampf(_switch_time / FADE_SECONDS, 0.0, 1.0)
		if _switch_time >= FADE_SECONDS:
			enter_area(_switch_to["area"], _switch_to["cell"])
			_switch_phase = 2
			_switch_time = 0.0
	elif _switch_phase == 2:
		# エリアを作った直後の重いフレームで、明るくする演出を飛ばさない（1フレームで進むのは0.1秒まで）
		_switch_time += minf(delta, 0.1) - delta
		_fade.color.a = clampf(1.0 - _switch_time / FADE_SECONDS, 0.0, 1.0)
		if _switch_time >= FADE_SECONDS:
			_switch_phase = 0
			_fade.color.a = 0.0
			player.controllable = true
			_area_root.process_mode = Node.PROCESS_MODE_INHERIT

func _process(delta: float) -> void:
	_update_time_scale()
	if in_title:
		camera.angle = wrapf(camera.angle + TITLE_TURN * delta, -PI, PI)
	else:
		run.play_time += delta / maxf(Engine.time_scale, 0.01)
	roster.tick(delta)
	sword.update(delta)
	bow.update(delta * float(run.inventory.equipment.trait_of(Equipment.Slot.BOW, "charge", 1.0)), player.moving)
	magic.update(delta)
	buffs.update(delta)
	if area_state.result == AreaState.Result.PLAYING:
		mana.update(delta)
		_regen(delta)
	player.mover.tick(delta)
	if bow.charging and (hotbar.selected != Hotbar.Item.BOW or menu.is_open() or area_state.result != AreaState.Result.PLAYING):
		bow.cancel()
	player.charge = bow.rate() if bow.charging else -1.0
	player.set_look(held_look(), run.inventory.equipment.current(Equipment.Slot.ARMOR))
	if not _warm_queue.is_empty() and not is_switching():
		Terrain.warm(_warm_queue, WARM_BUDGET_MS)
	elif not is_switching():
		Sfx.warm_step(2.0)  # 効果音を少しずつ作っておく
	Sfx.listener = player.mover.pos
	_step_story_queue(delta)
	if is_switching():
		_update_switch(delta)
	elif dialogue != null and dialogue.is_open():
		pass  # 話している間は世界を止める（2026-11-26）
	else:
		if area_state.update(delta):
			respawn()
		_step_bullets(delta)
		_step_lobs(delta)
		_step_strikes(delta)
		_step_rollers(delta)
		_step_pits(delta)
		_step_shots(delta)
		_step_bolts(delta)
		_step_fires(delta)
		_step_effects(delta)
		_step_poison(delta)
		_step_bombs(delta)
		_step_boss_floor(delta)
		if shop_menu.is_open() and not _near_merchant():
			shop_menu.close()
		if travel_menu.is_open() and not near_campfire():
			travel_menu.close()
		if area_state.result == AreaState.Result.PLAYING and not in_title:
			if player.hp <= 0 or player.mover.fell:
				kill_player(player.mover.fell)
			else:
				_play_step()
				_hold_to_swing()
		if area_state.is_falling():
			player.lift_px = maxf(-FALL_SINK_PX, player.lift_px - FALL_SINK_PX / AreaState.FALL_SECONDS * delta)
		elif area_state.result == AreaState.Result.DYING and player.mover.fell:
			player.modulate.a = 0.0
	_update_aim()
	_update_lights()
	if map_view != null and map_view.visible:
		_sync_map()
	_flash_time = maxf(0.0, _flash_time - delta)
	_flash.color.a = clampf(_flash_time / 0.5, 0.0, 1.0) * settings.flash_strength()
	camera.follow(player.mover.pos, player.mover.height * StackSprite.LEVEL_PX, delta)
	_title_time = maxf(0.0, _title_time - delta)
	_grave_hint_time = maxf(0.0, _grave_hint_time - delta)
	_notice_time = maxf(0.0, _notice_time - delta)
	_start_hint_time = maxf(0.0, _start_hint_time - delta)
	_arrow_blink += delta
	var frame := int(_arrow_blink * 8.0) % 3
	if frame != _bonfire_frame:
		_bonfire_frame = frame
		if _bonfire_node != null and is_instance_valid(_bonfire_node):
			_bonfire_node.set_model(Props.bonfire(frame))
		for b in _braziers:
			if is_instance_valid(b[0]):
				b[0].set_model(Props.brazier((frame + b[1].x) % 3))
	var a := 0.55 + 0.45 * sin(_arrow_blink * 4.0)
	for s in _arrows:
		s.modulate.a = a
	_update_ui()

## 防具の特色「いのちの回復」：5秒ごとに いのち＋1。
func _regen(delta: float) -> void:
	var regen := int(run.inventory.equipment.armor_bonus("regen"))
	if regen <= 0 or player.hp <= 0 or player.hp >= player.max_hp:
		_regen_clock = 0.0
		return
	_regen_clock += delta
	if _regen_clock >= 5.0:
		_regen_clock -= 5.0
		player.set_hp(mini(player.max_hp, player.hp + regen))

## 全体マップに、自分のいる所とカメラの向きを渡す。
func _sync_map() -> void:
	map_view.current_id = area.id
	map_view.player_pos = player.mover.pos
	map_view.view_angle = camera.angle

## 画面を白くする（ブライトの光）。
func flash_screen(seconds: float) -> void:
	_flash_time = maxf(_flash_time, seconds)
	Sfx.play("flash")

## 遊んでいる間の毎フレームの処理：拾う、たき火で回復、体当たり、鉄球、出口。
func _play_step() -> void:
	var c := player.mover.cell()
	for i in _pickup_nodes.keys():
		var p = area.pickups[i]
		if is_chest(p[1]):
			continue  # 宝箱は F で開ける（try_open_chest）
		var reach := RunState.can_reach_pickup(player.mover.pos, player.mover.height, p[0], map.get_height(p[0]))
		if reach and run.collect(area.pickup_id(i), p[1], p[2]):
			_pickup_nodes[i].queue_free()
			_pickup_nodes.erase(i)
			_on_picked(p[1], p[2])
	if _campfire_cell.x >= 0 and absi(c.x - _campfire_cell.x) <= 1 and absi(c.y - _campfire_cell.y) <= 1 \
			and not run.is_near_checkpoint(area.id, c):
		run.set_checkpoint(area.id, _campfire_cell)
		notice("たき火で休んだ\n死んだら、ここから やり直す", 2.5)
		Sfx.play("rest")
		autosave()
	if run.is_near_checkpoint(area.id, c) and player.hp < player.max_hp:
		player.set_hp(player.max_hp)
	for e in enemies:
		if is_instance_valid(e) and e.touch_hurts() and e.walker.touches(player.mover.pos, player.mover.height):
			hurt_player(e.attack)
			break
	for b in bosses:
		if is_instance_valid(b) and b.touch_hurts() and b.walker.touches(player.mover.pos, player.mover.height):
			hurt_player(b.attack)
			break
	for i in range(_drops.size() - 1, -1, -1):
		var d = _drops[i]
		if RunState.can_reach_pickup(player.mover.pos, player.mover.height, d[0], map.get_height(d[0])):
			run.take_drop(d[1], d[2])
			d[3].queue_free()
			_drops.remove_at(i)
			_on_picked(d[1], d[2])
	if ball.rules_ball.try_pick_up(player.mover):
		Sfx.play("ball_pick")
	_sync_ball_rank()
	apply_stats()
	var ex := world.exit_through(area.id, c, player.mover.edge_push)
	if ex != null and (ex.door_id == "" or run.is_door_open(ex.door_id)):
		_start_switch(world.arrival(area.id, ex, c))

## F11：全画面とウィンドウを切りかえる（メニューを開いていても効く。2026-11-26）
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		settings.fullscreen = not settings.fullscreen
		InventoryMenu.apply_window(settings.fullscreen)
		menu.refresh()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if in_title:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		if map_view.visible:
			toggle_map()
		elif not is_switching():
			pause_menu.open(run.play_time)
		get_viewport().set_input_as_handled()
		return
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var d := 1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1
		if hotbar.selected == Hotbar.Item.STAFF:
			cycle_spell(d)
			get_viewport().set_input_as_handled()
		elif hotbar.selected == Hotbar.Item.TOOL:
			run.inventory.cycle_tool(d)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if bow.charging:
			release_bow()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		use_item()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				hotbar.select_slot(event.physical_keycode - KEY_0, run.inventory.equipment)
			KEY_F:
				if not try_open_shop() and not try_open_chest() and not try_pull_lever() and not try_talk() and not try_use_campfire():
					try_open_door()
			KEY_TAB:
				open_inventory()
			KEY_SPACE:
				spin_slash()
			KEY_M:
				toggle_map()
			_:
				return
		get_viewport().set_input_as_handled()

## 手に持っているアイテムを使う（左クリック）。鉄球ならカーソルの場所（届く所まで）に落とす。
func use_item() -> bool:
	if area_state.result != AreaState.Result.PLAYING or is_switching() or not player.controllable:
		return false
	if menu.is_open():
		return false  # 開いている間のクリックは画面の操作に使う
	match hotbar.selected:
		Hotbar.Item.IRON_BALL:
			var dropped := ball.rules_ball.drop_at(player.mover, map, _aim_point())
			if dropped:
				Sfx.play("ball_drop")
			return dropped
		Hotbar.Item.SWORD:
			return swing_sword()
		Hotbar.Item.BOW:
			return start_bow()
		Hotbar.Item.STAFF:
			return cast_spell()
		Hotbar.Item.TOOL:
			return use_tool()
	return false

## 剣を振る（カーソルの方を向いている）。飛び降りてすぐなら落下斬り。墓石も壊せる。
func swing_sword() -> bool:
	if run.inventory.equipment.effective(Equipment.Slot.SWORD) == 0 or not sword.try_swing():
		return false
	var id := run.inventory.equipment.current(Equipment.Slot.SWORD)
	sword.cooldown = Sword.INTERVAL / float(ItemCatalog.trait_value(id, "rate", 1.0))
	var reach := float(ItemCatalog.trait_value(id, "reach", 1.0))
	var mv := player.mover
	var st := run.stats
	var fall := mv.recent_drop(Sword.FALL_WINDOW)
	var strong_fall := st.skills_in(PlayerStats.Stat.SWORD) >= 1
	var thrust := st.skills_in(PlayerStats.Stat.SWORD) >= 2  # 技能「突き」
	player.swing(fall > 0, thrust)
	Sfx.play("thrust" if thrust else "sword")
	for g in _closed_gimmicks():
		if g.by_sword(mv.pos, mv.height, mv.facing, map, thrust):
			open_gimmick(g)
	for e in targets():
		if Sword.hits(mv.pos, mv.height, mv.facing, e.walker.pos, e.walker.height, thrust, reach + body_extra(e) / Sword.REACH):
			var dmg := Damage.sword(current_attack(), st.points_in(PlayerStats.Stat.SWORD), fall, strong_fall)
			damage_target(e, dmg, mv.pos, id, Color("ffb347") if fall > 0 else Color.WHITE, "sword")
	if run.grave != null and run.grave.area_id == area.id:
		var g := run.grave.cell
		if Sword.hits(mv.pos, mv.height, mv.facing, HeightMap.cell_center(g), map.get_height(g), thrust):
			_remove_grave_marker()
			run.break_grave()
	return true

## 今撃てる矢の数（選んだ種類が使えて残っていればその数、なければ普通の矢の数）。
func _usable_arrows() -> int:
	var inv := run.inventory
	if Arrow.usable(inv.arrow_kind, _bow_skills()) and inv.arrow_count(inv.arrow_kind) > 0:
		return inv.arrow_count(inv.arrow_kind)
	return inv.arrow_count(Arrow.Kind.NORMAL)

func _bow_skills() -> int:
	return run.stats.skills_in(PlayerStats.Stat.BOW)

## 弓を溜め始める（左ボタンを押した）。弓か、使える矢がなければ false。
func start_bow() -> bool:
	if run.inventory.equipment.effective(Equipment.Slot.BOW) == 0 or bow.charging:
		return false
	var inv := run.inventory
	if inv.arrow_count(Arrow.Kind.NORMAL) <= 0 and not (Arrow.usable(inv.arrow_kind, _bow_skills()) and inv.arrow_count(inv.arrow_kind) > 0):
		notice("矢がない", 1.5)
		return false
	bow.start()
	Sfx.play("bow_draw")
	return true

## 離して撃つ。カーソルの所へ（届かなければ手前に）山なりに飛ぶ。技能「連射」なら2本。
func release_bow() -> bool:
	var r := bow.release()
	if r <= 0.0:
		return false
	var shots := maxi(2 if _bow_skills() >= 3 else 1, int(run.inventory.equipment.trait_of(Equipment.Slot.BOW, "multi", 1)))
	var fired := false
	for i in shots:
		var k := run.inventory.take_arrow(_bow_skills())
		if k < 0:
			break
		var target := _aim_point()
		if i == 1:  # 2本目は少し横にずらす
			var side := (target - player.mover.pos).normalized().orthogonal() * 6.0
			target += side
		_fire_arrow(k, r, target)
		fired = true
	if fired:
		player.anim.play_loose()
		Sfx.play("bow_shoot")
	return fired

func _fire_arrow(kind: Arrow.Kind, r: float, target: Vector2) -> void:
	var mv := player.mover
	var land := Bow.landing(mv.pos, mv.height, target, r, map, _bow_range())
	var land_h := map.get_height(HeightMap.world_to_cell(land))
	var a := Arrow.new()
	a.kind = kind
	a.rate = r
	a.from_h = mv.height
	a.launch(mv.pos, mv.height * StackSprite.LEVEL_PX + 6.0, land, land_h * StackSprite.LEVEL_PX)
	var lower := maxi(0, mv.height - land_h) if _bow_skills() >= 2 else 0
	var dmg := Damage.bow(current_attack(), r, Arrow.MULT[kind], run.stats.points_in(PlayerStats.Stat.BOW), lower)
	var s := StackSprite.new()
	s.camera = camera
	s.sort_by_cell = true
	s.sort_map = map
	s.sort_radius = 2.0
	s.draw_bias = 3
	s.shadow_radius = 1.5
	s.always_redraw = true
	s.voxel_scale = Props.VOXEL_SCALE
	s.outline_color = Player.OUTLINE_COLOR
	s.turn = a.direction().angle() - PI / 2  # 模型の前（+y）を飛ぶ向きへ
	_area_root.add_child(s)
	_shots.append([a, s, dmg, mv.pos])
	_place_shot(a, s)

func shots_in_flight() -> int:
	return _shots.size()

## 飛んでいる矢を、今の位置・高さ・傾きに合わせる（傾きの段が変わったときだけ模型を替える）。
## 矢の真ん中が、矢の高さに来るように置く。
func _place_shot(a: Arrow, s: StackSprite) -> void:
	var m := Props.arrow_model(a.kind, atan(a.slope()))
	if not s.has_meta("model") or s.get_meta("model") != m:
		s.set_meta("model", m)
		s.set_model(m)
	var hp := a.height_px() - Props.ARROW_BOX.z / 2.0 * Props.VOXEL_SCALE
	s.world_pos = a.pos()
	s.base_height = int(floor(hp / StackSprite.LEVEL_PX))
	s.lift_px = hp - s.base_height * StackSprite.LEVEL_PX
	s.refresh()

## 落ちた矢は、少しの間地面に刺さったまま見せる。
func _stick_arrow(a: Arrow) -> void:
	var c := HeightMap.world_to_cell(a.to)
	if not map.in_bounds(c) or map.is_water(c) or map.is_pit(c) or map.is_wall(c):
		return
	var m := Props.arrow_model(a.kind, -Props.PITCH_MAX)
	var s := _effect_sprite(m, a.to, map.get_height(c), -Props.ARROW_BOX.z * 0.25 * Props.VOXEL_SCALE, STUCK_ARROW_SECONDS)
	s.outline_color = Player.OUTLINE_COLOR
	s.turn = a.direction().angle() - PI / 2
	s.set_meta("steady", true)

## 飛んでいる矢を進め、落ちた所の敵（同じ高さ）に当てる。墓石にも当たる。
func _step_shots(delta: float) -> void:
	for i in range(_shots.size() - 1, -1, -1):
		var a: Arrow = _shots[i][0]
		var s: StackSprite = _shots[i][1]
		var dmg: int = _shots[i][2]
		var from: Vector2 = _shots[i][3]
		if not a.update(delta):
			_place_shot(a, s)
			continue
		s.queue_free()
		_shots.remove_at(i)
		_stick_arrow(a)
		_arrow_landed(a, dmg, from)

func _bow_range() -> float:
	return float(run.inventory.equipment.trait_of(Equipment.Slot.BOW, "range", 1.0))

func _arrow_landed(a: Arrow, dmg: int, from := Vector2.ZERO) -> void:
	if area_state.result != AreaState.Result.PLAYING:
		return
	for g in _closed_gimmicks():
		if g.by_arrow(a.to):
			open_gimmick(g)
	var c := HeightMap.world_to_cell(a.to)
	if not map.in_bounds(c) or map.is_water(c) or map.is_pit(c):
		return
	var land_h := map.get_height(c)
	# 撃った所より高い地面に落ちた矢は、そこの敵に当たらない（下から上へは攻撃できない）
	for e in targets():
		if Damage.can_hit(a.from_h, land_h) and Arrow.hits(a.to, land_h, e.walker.pos, e.walker.height, body_extra(e)):
			if damage_target(e, dmg, from, run.inventory.equipment.current(Equipment.Slot.BOW), Color.WHITE, "arrow"):
				if a.kind == Arrow.Kind.POISON:
					e.walker.poison(Arrow.POISON_SECONDS)
				elif a.kind == Arrow.Kind.FIRE:
					e.walker.burn(Magic.BURN_SECONDS)
			break  # 1本の矢は1体だけ
	if run.grave != null and run.grave.area_id == area.id and IronBall.touches_cell(a.to, run.grave.cell):
		_remove_grave_marker()
		run.break_grave()

## 毒のダメージ（毎秒1）。
func _step_poison(delta: float) -> void:
	for e in enemies + bosses:
		if is_instance_valid(e) and e.walker.alive:
			var d: int = e.walker.update_poison(delta)
			if d > 0:
				_popup(e.walker.pos, e.walker.height, d, Color("9be36b"))

## 回転斬り（剣の3つ目の技能、Space）。周りの敵をまとめて斬る。式は普通の一振りと同じ。
func spin_slash() -> bool:
	if area_state.result != AreaState.Result.PLAYING or is_switching() or not player.controllable:
		return false
	var st := run.stats
	if hotbar.selected != Hotbar.Item.SWORD or st.skills_in(PlayerStats.Stat.SWORD) < 3:
		return false
	if run.inventory.equipment.effective(Equipment.Slot.SWORD) == 0 or not sword.try_spin():
		return false
	var mv := player.mover
	player.spin()
	Sfx.play("spin")
	var id := run.inventory.equipment.current(Equipment.Slot.SWORD)
	for e in targets():
		if Sword.hits_around(mv.pos, mv.height, e.walker.pos, e.walker.height, float(ItemCatalog.trait_value(id, "reach", 1.0)) + body_extra(e) / Sword.REACH):
			var dmg := Damage.sword(current_attack(), st.points_in(PlayerStats.Stat.SWORD), 0)
			damage_target(e, dmg, mv.pos, id, Color.WHITE, "sword")
	return true

## 今の装備で持ちかえられる物の姿（立ち姿・歩く姿・鉄球を放した姿）を、先に作っておく
## （立ち姿は1つ作るのに50〜80msかかるので、持ちかえたときに止まらないように）。
func warm_hero_looks() -> void:
	var eq := run.inventory.equipment
	var helds := ["", "heal"]
	for slot in [Equipment.Slot.BALL, Equipment.Slot.SWORD, Equipment.Slot.BOW, Equipment.Slot.STAFF]:
		if eq.current(slot) != "":
			helds.append(eq.current(slot))
	HeroModel.warm(helds, eq.current(Equipment.Slot.ARMOR))

## 主人公が手に持って見せる物（HeroModel）。鉄球・剣・弓・杖は品物の id、回復は "heal"。
## 鉄球は持っている間だけ両手で抱える（落としたあとは何も持たない）。
func held_look() -> String:
	match hotbar.selected:
		Hotbar.Item.IRON_BALL:
			if ball.rules_ball.state == IronBall.State.HELD:
				return run.inventory.equipment.current(Equipment.Slot.BALL)
		Hotbar.Item.SWORD, Hotbar.Item.BOW, Hotbar.Item.STAFF:
			return run.inventory.equipment.current(Hotbar.WEAPON_SLOT[hotbar.selected])
		Hotbar.Item.TOOL:
			return "heal"  # 道具は薬のびんの姿
	return ""

## 剣は左ボタンを押したままでも、振れるようになるたびに振る。
func _hold_to_swing() -> void:
	var held := hotbar.selected == Hotbar.Item.SWORD or hotbar.selected == Hotbar.Item.STAFF
	if held and not menu.is_open() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		use_item()

## 手に持つ杖で、今使える魔法（ステータスの魔法の数まで）。
func usable_spells() -> Array:
	return ItemCatalog.usable_spells(run.inventory.equipment.current(Equipment.Slot.STAFF), run.stats.spell_slots())

## 選んでいる魔法。使えるものがなければ -1。
func current_spell() -> int:
	return magic.current(usable_spells())

## ホイールで使う魔法を替える。
func cycle_spell(d: int) -> void:
	magic.cycle(d, usable_spells())

## 魔法の狙い。画面の点 screen にカーソルがあるとき、狙う点・高さの段・重なっている敵。
## 敵の体にカーソルを重ねると、その敵に合う。そうでなければ、カーソルの下の地面。
func magic_aim_at(screen: Vector2) -> Dictionary:
	var best = null
	var best_d := 8.0
	for e in targets():
		var d := screen.distance_to(camera.world_to_screen(e.walker.pos, e.walker.height * StackSprite.LEVEL_PX + 4.0))
		if d < best_d:
			best_d = d
			best = e
	if best != null:
		return {"point": best.walker.pos, "level": best.walker.height, "enemy": best}
	var ground := camera.pick_ground(screen, map, MAX_HEIGHT)
	return {"point": ground, "level": map.get_height(HeightMap.world_to_cell(ground)), "enemy": null}

## 火柱・炎の雨を起こす点（届く所まで）。
func _spell_point(spell: int, aim: Dictionary) -> Vector2:
	var reach := Magic.PILLAR_REACH if spell == Magic.Spell.FIRE_PILLAR else Magic.THUNDER_REACH if spell == Magic.Spell.THUNDER else Magic.RAIN_REACH
	var from := player.mover.pos
	var p: Vector2 = aim["point"]
	if p.distance_to(from) > reach:
		p = from + (p - from).normalized() * reach
	return p

## 魔法を使う（押したままで続けて使う）。マナが足りなければ false。
func cast_spell(screen = null) -> bool:
	var spell := current_spell()
	if spell < 0:
		return false
	var cost_mult := spell_cost_mult()
	if mana.value < Magic.cost_of(spell, cost_mult):
		if magic.cooldown <= 0.0:
			notice("マナが足りない", 1.0)
			Sfx.play("no_mana")
		return false
	if spell == Magic.Spell.HEAL and player.hp >= player.max_hp:
		return false
	if not magic.try_cast(spell, mana, cost_mult):
		return false
	player.anim.play_cast()
	Sfx.play("fire_cast" if spell in [Magic.Spell.FIREBALL, Magic.Spell.FIRE_PILLAR, Magic.Spell.FIRE_RAIN] else ("heal" if spell == Magic.Spell.HEAL else "magic"))
	var aim := magic_aim_at(screen if screen != null else get_local_mouse_position())
	match spell:
		Magic.Spell.NULL_BOLT, Magic.Spell.FIREBALL, Magic.Spell.ICE_SHARD:
			_launch_bolt(spell, aim)
		Magic.Spell.FIRE_PILLAR:
			_fire_pillar(_spell_point(spell, aim))
		Magic.Spell.FIRE_RAIN:
			_fire_rain(_spell_point(spell, aim))
		Magic.Spell.THUNDER:
			_thunder(_spell_point(spell, aim))
		Magic.Spell.HEAL:
			player.set_hp(mini(player.max_hp, player.hp + Magic.HEAL_AMOUNT))
			_popup_text(player.mover.pos, player.mover.height, "+%d" % Magic.HEAL_AMOUNT, Color("7ee081"))
	return true

## 杖の特色で変わる、魔法のマナの倍率。
func spell_cost_mult() -> float:
	return float(run.inventory.equipment.trait_of(Equipment.Slot.STAFF, "cost", 1.0))

## 雷：狙った点に落ちる。自分と同じか低い所の敵に当たる（高い所からでなくてもよい）。
func _thunder(point: Vector2) -> void:
	var mv := player.mover
	_magic_gimmicks(point, Magic.THUNDER_RADIUS)
	for e in targets():
		if e.walker.pos.distance_to(point) < Magic.THUNDER_RADIUS and e.walker.height <= mv.height:
			_hit_enemy(e, Magic.Spell.THUNDER, mv.height)
	var c := HeightMap.world_to_cell(point)
	var ground := map.get_height(c) if map.in_bounds(c) else 0
	_effect_sprite(Props.pillar(), point, ground, 0.0, 0.25).modulate = Color(1.2, 1.2, 2.0)
	camera.shake(1.5)
	Sfx.play("thunder", point)

## 魔法を敵に当てる。from_h は使ったときの段で、それより高い所の敵には当たらない（false を返す）。
func _hit_enemy(e, spell: int, from_h: int) -> bool:
	if not Damage.can_hit(from_h, e.walker.height):
		return false
	var dmg := Damage.magic(current_attack(), Magic.POWER[spell], run.stats.points_in(PlayerStats.Stat.MAGIC))
	if not damage_target(e, dmg, player.mover.pos, "", Color.WHITE, "magic"):
		return false
	if spell == Magic.Spell.ICE_SHARD:
		e.walker.slow(Magic.SLOW_SECONDS)
	return true

## 無の弾・火の玉：狙った高さへまっすぐ飛ばす。
func _launch_bolt(spell: int, aim: Dictionary) -> void:
	var mv := player.mover
	var p := Pellet.new()
	p.aim(mv.pos, mv.height * StackSprite.LEVEL_PX + 5.0, aim["point"], aim["level"] * StackSprite.LEVEL_PX + 4.0)
	var s := StackSprite.new()
	s.camera = camera
	s.sort_by_cell = true
	s.sort_map = map
	s.sort_radius = 2.0
	s.draw_bias = 3
	s.voxel_scale = Props.VOXEL_SCALE
	s.set_model(Props.bolt(spell == Magic.Spell.FIREBALL))
	if spell == Magic.Spell.ICE_SHARD:
		s.modulate = Color(0.6, 0.9, 1.6)
	_area_root.add_child(s)
	_bolts.append([p, s, spell, mv.height])
	_place_bolt(p, s)

func bolts_in_flight() -> int:
	return _bolts.size()

func _place_bolt(p: Pellet, s: StackSprite) -> void:
	s.world_pos = p.pos
	s.base_height = maxi(0, int(floor(p.z / StackSprite.LEVEL_PX)))
	s.lift_px = p.z - s.base_height * StackSprite.LEVEL_PX
	s.refresh()

## 魔法の弾を進める。体に当たった敵にダメージ。火の玉は止まった所で弾けて、まわりも焼く。墓石に当たれば壊す。
func _step_bolts(delta: float) -> void:
	var playing := area_state.result == AreaState.Result.PLAYING
	for i in range(_bolts.size() - 1, -1, -1):
		var p: Pellet = _bolts[i][0]
		var s: StackSprite = _bolts[i][1]
		var spell: int = _bolts[i][2]
		var from_h: int = _bolts[i][3]
		p.step(delta, map)
		if p.alive and playing:
			for e in targets():
				if Damage.can_hit(from_h, e.walker.height) and p.hits_body(e.walker.pos, e.walker.height, body_extra(e)):
					if spell != Magic.Spell.FIREBALL:
						_hit_enemy(e, spell, from_h)
					p.alive = false
					break
		if not p.alive:
			if playing:
				_magic_gimmicks(p.pos, 4.0)
			if playing and spell == Magic.Spell.FIREBALL:
				_explode(p.pos, p.z, from_h)
			if playing and run.grave != null and run.grave.area_id == area.id and p.hit_grave == run.grave.cell:
				_remove_grave_marker()
				run.break_grave()
			s.queue_free()
			_bolts.remove_at(i)
			continue
		_place_bolt(p, s)

## 火の玉が弾ける。まわりの、高さの近い敵にダメージとやけど。地面の近くなら、そこが少しの間燃える（自分より高い地面は燃えない）。
func _explode(pos: Vector2, z: float, from_h: int) -> void:
	Sfx.play("magic_hit", pos)
	_burn_gimmicks(pos, Magic.FIREBALL_RADIUS)
	for e in targets():
		if e.walker.pos.distance_to(pos) < Magic.FIREBALL_RADIUS \
				and absf(e.walker.height * StackSprite.LEVEL_PX + 4.0 - z) <= 12.0:
			if _hit_enemy(e, Magic.Spell.FIREBALL, from_h):
				e.walker.burn(Magic.BURN_SECONDS)
	var c := HeightMap.world_to_cell(pos)
	if map.in_bounds(c) and not map.is_wall(c) and z - map.get_height(c) * StackSprite.LEVEL_PX < 10.0 \
			and Damage.can_hit(from_h, map.get_height(c)):
		var s := _effect_sprite(Props.flame(rng.randi() % 3), pos, map.get_height(c), 0.0, Magic.FIRE_PATCH_SECONDS)
		_fires.append([pos, map.get_height(c), Magic.FIRE_PATCH_SECONDS, s])

## 燃えている所に入った敵はやけどする。
func _step_fires(delta: float) -> void:
	for i in range(_fires.size() - 1, -1, -1):
		var f = _fires[i]
		f[2] -= delta
		if f[2] <= 0.0:
			_fires.remove_at(i)
			continue
		for e in targets():
			if e.walker.height == f[1] and e.walker.pos.distance_to(f[0]) < 10.0 \
					and not e.walker.is_burning():
				e.walker.burn(Magic.BURN_SECONDS)

func fires_burning() -> int:
	return _fires.size()

## 火柱：狙った点に立ち、そこの敵に当たる。自分より高い所の敵には当たらない。
func _fire_pillar(point: Vector2) -> void:
	var mv := player.mover
	_burn_gimmicks(point, Magic.PILLAR_RADIUS)
	_magic_gimmicks(point, Magic.PILLAR_RADIUS)
	for e in targets():
		if e.walker.pos.distance_to(point) < Magic.PILLAR_RADIUS:
			if _hit_enemy(e, Magic.Spell.FIRE_PILLAR, mv.height):
				e.walker.burn(Magic.BURN_SECONDS)
	var c := HeightMap.world_to_cell(point)
	if run.grave != null and run.grave.area_id == area.id and c == run.grave.cell \
			and Damage.can_hit(mv.height, map.get_height(c)):
		_remove_grave_marker()
		run.break_grave()
	var ground := map.get_height(c) if map.in_bounds(c) else 0
	_effect_sprite(Props.pillar(), point, ground, 0.0, 0.4)
	Sfx.play("fire", point)

## 炎の雨：狙った点のまわりに降る。自分より高い所の敵には当たらない。高い所から使うほど広い。
func _fire_rain(point: Vector2) -> void:
	var mv := player.mover
	var c := HeightMap.world_to_cell(point)
	var ground := map.get_height(c) if map.in_bounds(c) else mv.height
	var r := Magic.rain_radius(mv.height, ground)
	_burn_gimmicks(point, r)
	_magic_gimmicks(point, r)
	for e in targets():
		if e.walker.height <= mv.height and e.walker.pos.distance_to(point) < r:
			_hit_enemy(e, Magic.Spell.FIRE_RAIN, mv.height)
	_effect_sprite(Props.rain_ring(r), point, ground, 0.0, 0.5)
	Sfx.play("fire", point)
	for k in 5:
		var off := Vector2.from_angle(rng.randf() * TAU) * rng.randf() * r
		var fc := HeightMap.world_to_cell(point + off)
		if map.in_bounds(fc) and not map.is_wall(fc) and map.get_height(fc) <= mv.height:
			_effect_sprite(Props.flame(rng.randi() % 3), point + off, map.get_height(fc), 0.0, 0.5)

## 少しの間だけ出す絵を置く。
func _effect_sprite(model: VoxelModel, pos: Vector2, h: int, lift: float, seconds: float) -> StackSprite:
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = pos
	s.base_height = h
	s.lift_px = lift
	s.sort_by_cell = true
	s.sort_map = map
	s.sort_radius = 3.0
	s.draw_bias = 2
	s.voxel_scale = Props.VOXEL_SCALE
	s.set_model(model)
	s.refresh()
	_area_root.add_child(s)
	_effects.append([s, seconds])
	return s

func _step_effects(delta: float) -> void:
	for i in range(_effects.size() - 1, -1, -1):
		_effects[i][1] -= delta
		# ほかの所（転がる大岩・大蛇の影など）が先に消した絵もある。型付きの変数に入れる前に確かめる（消えた絵を入れるとエラーで止まる）
		var s = _effects[i][0]
		if _effects[i][1] <= 0.0 or not is_instance_valid(s):
			if is_instance_valid(s):
				s.queue_free()
			_effects.remove_at(i)
			continue
		var flicker := 1.0 if s.has_meta("steady") else 0.85 + 0.15 * sin(_arrow_blink * 20.0)  # 炎はゆらめく
		s.modulate.a = clampf(_effects[i][1] * 4.0, 0.0, 1.0) * flicker

## 敵の落とし物を置く（このエリアにいる間だけ残る）。
func spawn_drop(cell: Vector2i, id: String, amount: int) -> void:
	var s := _marker(cell, Props.pickup(id), 1)
	_drops.append([cell, id, amount, s])

func drops_left() -> int:
	return _drops.size()

## 技能を覚えたときの知らせ。使い方があるものは、そのキーも出す。
func _on_skill_learned(skill: String) -> void:
	Sfx.play("skill")
	var how := {
		"しゃがみ": "C か 左Ctrl：しゃがむ（撃つ敵の弾をよける）",
		"回転斬り": "剣を持って Space：回転斬り",
		"よじ登り": "2段の段差に向かって歩き続けると登れる",
		"受け身": "4段まで飛び降りられる",
		"矢の種類": "Tab：弓の枠で毒矢を選べる",
		"突き": "剣が正面へ細く長く届く",
		"魔法2つ目": "杖に魔法が2つあれば、ホイールで替えて使える",
		"最大マナ＋10": "マナが %d までたまる" % run.stats.max_mana(),
		"魔法3つ目": "杖に魔法が3つあれば、3つとも使える",
	}
	notice("技能「%s」を覚えた！\n%s" % [skill, how.get(skill, "")], 4.0)

## 拾った（宝箱・落ちているもの・敵の落とし物）ときの知らせ。
func _on_picked(id: String, amount: int) -> void:
	player.anim.play_pickup()  # かがんで拾う
	Sfx.play("coin" if id == ItemCatalog.MONEY else ("item" if ItemCatalog.exists(id) else "pickup"))
	if ItemCatalog.exists(id):
		warm_hero_looks()
		var slot := ItemCatalog.slot(id)
		var how := {Equipment.Slot.SWORD: "2：持ちかえ　クリック：振る", Equipment.Slot.BOW: "3：持ちかえ　押して溜め、離して撃つ",
			Equipment.Slot.STAFF: "4：持ちかえ　ホイール：魔法を替える", Equipment.Slot.BALL: "Tab：持ち物で選ぶ",
			Equipment.Slot.ARMOR: "Tab：持ち物で着る"}
		notice("%sを手に入れた！\n%s" % [ItemCatalog.label(id), how.get(slot, "")], 3.0)
	elif id == ItemCatalog.MONEY:
		notice("お金 ＋%d" % amount, 1.2)
	else:
		notice("%s ×%d" % [ItemCatalog.name_of(id), amount], 1.5)

## 手に持つ道具（5番、ホイールで替える）を使う。
func use_tool() -> bool:
	var inv := run.inventory
	var id := inv.current_tool()
	if id == "":
		notice("道具を持っていない\nお店で買うか、鍛冶屋で作れる", 1.5)
		return false
	var d: Dictionary = ItemCatalog.TOOLS[id]
	if d.has("heal"):
		if player.hp >= player.max_hp:
			return false
		var amount: int = player.max_hp if d["heal"] < 0 else d["heal"]
		player.set_hp(mini(player.max_hp, player.hp + amount))
		player.anim.play_drink()
		Sfx.play("drink")
		Sfx.play("heal")
	elif d.has("mana"):
		if mana.value >= mana.max_value:
			return false
		mana.value = minf(mana.max_value, mana.value + d["mana"])
		player.anim.play_drink()
		Sfx.play("drink")
	elif d.has("buff"):
		var bf: Array = d["buff"]
		buffs.add(bf[0], bf[1], bf[2])
		player.anim.play_drink()
		Sfx.play("drink")
		notice("%s：%s" % [ItemCatalog.name_of(id), d["info"]], 1.5)
	elif d.has("warp"):
		inv.take(id, 1)
		notice("帰りの羽で、たき火へ戻った", 2.0)
		Sfx.play("teleport")
		_start_switch({"area": run.checkpoint_area, "cell": run.respawn_cell()})
		return true
	elif d.has("bomb"):
		_throw_bomb(_aim_point(), d["bomb"])
	inv.take(id, 1)
	return true

## 爆弾を投げる（届くのは4マスまで）。1秒で弾けて、まわりの敵とボスにダメージ。下から上へは届かない。
func _throw_bomb(point: Vector2, power: int) -> void:
	var from := player.mover.pos
	if point.distance_to(from) > 64.0:
		point = from + (point - from).normalized() * 64.0
	var c := HeightMap.world_to_cell(point)
	var h := map.get_height(c) if map.in_bounds(c) else player.mover.height
	var s := _effect_sprite(Props.pickup("bomb"), point, h, 0.0, 1.0)
	s.set_meta("steady", true)
	_bombs.append([point, h, 1.0, power, player.mover.height])
	Sfx.play("throw")

func _step_bombs(delta: float) -> void:
	for i in range(_bombs.size() - 1, -1, -1):
		_bombs[i][2] -= delta
		if _bombs[i][2] > 0.0:
			continue
		var b = _bombs[i]
		_bombs.remove_at(i)
		camera.shake(3.0)
		_effect_sprite(Props.rain_ring(20.0), b[0], b[1], 0.0, 0.4)
		Sfx.play("explosion", b[0])
		_burn_gimmicks(b[0], 20.0)
		for e in targets():
			if e.walker.pos.distance_to(b[0]) < 20.0 and absi(e.walker.height - b[1]) <= 1 and Damage.can_hit(b[4], e.walker.height):
				damage_target(e, b[3], b[0], "", Color("ffb347"), "bomb")
		for g in _closed_gimmicks():
			if (g.kind == Gimmick.Kind.CRACK and g.by_ball(b[0], 1)) or g.by_bomb(b[0], 20.0):
				open_gimmick(g)

func open_inventory() -> bool:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return false
	menu.open()
	Sfx.play("ui_open")
	return true

func close_inventory() -> void:
	menu.close()

## カーソルが指している地面の点。
func _aim_point() -> Vector2:
	return camera.pick_ground(get_local_mouse_position(), map, MAX_HEIGHT)

## カーソルの方を向かせ、鉄球が落ちる点に印を出す。
func _update_aim() -> void:
	var playing := area_state.result == AreaState.Result.PLAYING and not is_switching()
	var target := IronBall.reach_point(player.mover.pos, _aim_point(), ball.rules_ball.reach)
	if playing and target.distance_to(player.mover.pos) > 4.0:
		player.mover.facing = (target - player.mover.pos).normalized()
	var show := playing and hotbar.selected == Hotbar.Item.IRON_BALL \
		and ball.rules_ball.state == IronBall.State.HELD and IronBall.can_drop_at(target, map, player.mover.height)
	var show_reticle := false
	var spell := current_spell() if playing and hotbar.selected == Hotbar.Item.STAFF else -1
	if spell in Magic.BOLTS:
		# 魔法の弾：狙う高さに輪を浮かべ、その真下の地面に影を出す
		var aim := magic_aim_at(get_local_mouse_position())
		target = aim["point"]
		var c := HeightMap.world_to_cell(target)
		show = map.in_bounds(c)
		show_reticle = show
		aim_reticle.world_pos = target
		aim_reticle.base_height = aim["level"]
		aim_reticle.lift_px = 4.0
	elif spell >= 0:
		# 火柱・炎の雨：届く所までの地面に影を出す
		target = _spell_point(spell, magic_aim_at(get_local_mouse_position()))
		show = map.in_bounds(HeightMap.world_to_cell(target))
	aim_reticle.force_hidden = not show_reticle
	if playing and bow.charging:
		# 弓を溜めている間は、今離したら矢が落ちる点（届かなければ手前）
		target = Bow.landing(player.mover.pos, player.mover.height, _aim_point(), bow.rate(), map, _bow_range())
		show = map.in_bounds(HeightMap.world_to_cell(target))
	aim_marker.force_hidden = not show
	if show:
		aim_marker.world_pos = target
		aim_marker.base_height = map.get_height(HeightMap.world_to_cell(target))

## 死亡処理を始める。墓石を置き（古い墓石は消える）、操作を止める。
func kill_player(fell: bool) -> void:
	if not area_state.on_player_died(fell):
		return
	var c := player.mover.last_safe_cell if fell else player.mover.cell()
	_remove_grave_marker()
	run.on_death(area.id, c)
	map.set_blocker(c, HeightMap.Blocker.GRAVE)
	_grave_node = _marker(c, Props.grave(), 2)
	player.controllable = false
	if fell:
		player.anim.play_fall()  # 両手を上げて落ちていく
		Sfx.play("fall")
	else:
		player.anim.play_die()  # ひざをついてから横たわる
		Sfx.play("die")

## 野営地のたき火から再開する。敵は復活しない（倒した敵は時間で戻る）。
func respawn() -> void:
	buffs.clear()
	enter_area(run.checkpoint_area, run.respawn_cell())
	_sync_ball_rank()  # ランク2以上の鉄球は墓石に入っているので、ランク1に戻る
	player.set_hp(player.max_hp)
	player.clear_invulnerable()
	player.anim.revive()
	player.lift_px = 0.0
	player.modulate.a = 1.0
	player.controllable = true
	_title_time = 0.0
	if run.grave != null:
		_grave_hint_time = GRAVE_HINT_SECONDS

## 門で閉じた出口を、このエリアの側から開けられる所（出口の1マス内側）に立っていれば開ける。
func try_open_door() -> bool:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return false
	var ex := _gate_here()
	if ex == null:
		return false
	if not run.can_open_door(ex.door_id):
		notice(door_hint(ex.door_id), 2.5)
		return false
	run.open_door(ex.door_id)
	player.anim.play_push()
	Sfx.play("seal" if ex.door_id == RunState.SEAL_DOOR else "door")
	for c in ex.cells(area.size()):
		map.set_blocker(c, HeightMap.Blocker.NONE)
	for s in _gate_nodes.get(ex.door_id, []):
		s.queue_free()
	_gate_nodes.erase(ex.door_id)
	_add_arrows(ex)
	return true

func _gate_here() -> ExitDef:
	var c := player.mover.cell()
	for ex in area.exits:
		if ex.door_id == "" or not ex.opens_here or run.is_door_open(ex.door_id):
			continue
		for g in ex.cells(area.size()):
			if g - ex.outward() == c:
				return ex
	return null

func _close_gate(ex: ExitDef) -> void:
	var nodes := []
	var model := Props.seal() if ex.door_id == RunState.SEAL_DOOR else Props.gate()
	for c in ex.cells(area.size()):
		map.set_blocker(c, HeightMap.Blocker.DOOR)
		nodes.append(_marker(c, model, 1))
	_gate_nodes[ex.door_id] = nodes

func _add_arrows(ex: ExitDef) -> void:
	var model := Props.exit_arrow(ex.outward())
	for c in ex.cells(area.size()):
		var s := _marker(c, model, 0, false)
		s.lift_px = 0.5
		_arrows.append(s)

func arrow_count() -> int:
	return _arrows.size()

func _step_bullets(delta: float) -> void:
	for i in range(_bullets.size() - 1, -1, -1):
		var b: Bullet = _bullets[i][0]
		var s: StackSprite = _bullets[i][1]
		b.step(delta, map)
		var playing := area_state.result == AreaState.Result.PLAYING
		# しゃがんでいると、撃つ敵の弾は頭の上を通り過ぎる（技能「しゃがみ」）
		if playing and player.hp > 0 and not player.crouching and b.hits(player.mover.pos, player.mover.height, BULLET_HIT_RADIUS):
			b.alive = false
			hurt_player(b.damage)
		if not b.alive or not map.in_bounds(HeightMap.world_to_cell(b.pos)):
			s.queue_free()
			_bullets.remove_at(i)
			continue
		s.world_pos = b.pos
		_place_bullet_sprite(b, s)

func _on_enemy_shot(b: Bullet) -> void:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = b.pos
	_place_bullet_sprite(b, s)
	s.draw_bias = 3
	s.sort_by_cell = true
	s.sort_map = map
	s.sort_radius = 2.0
	s.voxel_scale = Props.VOXEL_SCALE
	s.set_model(Props.bullet())
	s.refresh()
	_area_root.add_child(s)
	_bullets.append([b, s])
	Sfx.play("enemy_shoot", b.pos)

## 弾の絵を弾の高さ（z）に合わせる。
func _place_bullet_sprite(b: Bullet, s: StackSprite) -> void:
	var z := b.get_z()
	s.base_height = maxi(0, floori(z / StackSprite.LEVEL_PX))
	s.lift_px = z - s.base_height * StackSprite.LEVEL_PX - 1.0

## 鉄球が着いた。ダメージは17章の式で、攻撃力（強い鉄球なら上乗せ）・落とした高さ・レベルで決まる。
func _on_ball_landed(land_pos: Vector2, _legacy_damage: int) -> void:
	Sfx.play("ball_land", land_pos, 0.0, 0.04)
	if area_state.result != AreaState.Result.PLAYING:
		return  # 死んでいる間に着いた鉄球は何も壊さない（できたばかりの墓石を壊さないように）
	if run.grave != null and run.grave.area_id == area.id and IronBall.touches_cell(land_pos, run.grave.cell):
		_remove_grave_marker()  # 墓石のマスを空けてから中身を戻す（break_grave で grave が null になるため）
		run.break_grave()
	for g in _closed_gimmicks():
		if g.by_ball(land_pos, ball.rules_ball.fall_levels):
			open_gimmick(g)
	var id := ball.rules_ball.item
	var damage := Damage.iron_ball(current_attack() if hotbar.selected == Hotbar.Item.IRON_BALL else _ball_attack(), ball.rules_ball.fall_levels)
	var radius := IronBall.hit_radius(float(ItemCatalog.trait_value(id, "radius", 1.0)))
	for e in targets():
		if IronBall.hits(land_pos, ball.rules_ball.height, e.walker.pos, e.walker.height, radius + body_extra(e)):
			# 鉄球は上から落ちるので、盾では防げない（浮いている敵には当たらない）。ボスの弱点は、ボスが決める
			damage_target(e, damage, land_pos, id, Color.WHITE, "ball")

func _ball_attack() -> int:
	var extra := int(ItemCatalog.trait_value(ball.rules_ball.item, "atk", 0)) + int(buffs.value("atk"))
	return run.stats.attack(Equipment.rank_attack(ball_rank) + extra)

func _remove_grave_marker() -> void:
	if run.grave != null and run.grave.area_id == area.id:
		map.set_blocker(run.grave.cell, HeightMap.Blocker.NONE)
	if _grave_node != null:
		_grave_node.queue_free()
		_grave_node = null

## マスに小物（Props の模型）を置く。outline なら主人公と同じ暗いふちを付ける。
func _marker(cell: Vector2i, model: VoxelModel, bias: int, outline := true) -> StackSprite:
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = HeightMap.cell_center(cell)
	s.base_height = map.get_height(cell)
	s.sort_by_cell = true
	s.draw_bias = bias
	s.voxel_scale = Props.VOXEL_SCALE
	if outline:
		s.outline_color = Player.OUTLINE_COLOR
	s.set_model(model)
	s.refresh()
	_area_root.add_child(s)
	return s

# ---------------------------------------------------------------- 仕掛け・商人・ボスの像・全体マップ（2026-11-25）

## 開いた仕掛けの形を地図に書く（的の橋は、橋の絵にする）。
func _apply_open(g: Gimmick) -> void:
	g.open(map)
	if g.kind == Gimmick.Kind.TARGET:
		for c in g.cells:
			_deco[c] = "bridge"

func _closed_gimmicks() -> Array[Gimmick]:
	var out: Array[Gimmick] = []
	if area_state.result != AreaState.Result.PLAYING:
		return out
	for g in area.gimmicks:
		if not run.is_gimmick_open(g.id):
			out.append(g)
	return out

func _place_gimmicks() -> void:
	for g in area.gimmicks:
		var opened := run.is_gimmick_open(g.id)
		if g.kind in [Gimmick.Kind.TARGET, Gimmick.Kind.PLATE, Gimmick.Kind.LEVER, Gimmick.Kind.CRYSTAL]:
			var ts := []
			for c in g.trigger:
				var flat := g.kind == Gimmick.Kind.PLATE
				var lit := g.kind == Gimmick.Kind.CRYSTAL and opened
				ts.append(_marker(c, switch_model(g.kind, opened), 0 if flat else 1, not lit))
			_target_nodes[g.id] = ts
		if not opened and g.kind not in [Gimmick.Kind.TARGET, Gimmick.Kind.CRYSTAL]:
			var model: VoxelModel = {Gimmick.Kind.CRACK: Props.crack_rock(), Gimmick.Kind.THORNS: Props.thorns(),
				Gimmick.Kind.VINES: Props.vines(), Gimmick.Kind.PLATE: Props.bars(), Gimmick.Kind.LEVER: Props.bars(),
				Gimmick.Kind.BRITTLE: Props.brittle_wall()}[g.kind]
			var ns := []
			for c in g.cells:
				ns.append(_marker(c, model, 1))
			_gimmick_nodes[g.id] = ns

## 仕掛けの、武器を当てる所の模型（的・押し板・レバー・水晶）。opened なら開けた後の姿。
static func switch_model(kind: Gimmick.Kind, opened: bool) -> VoxelModel:
	match kind:
		Gimmick.Kind.PLATE:
			return Props.plate(opened)
		Gimmick.Kind.LEVER:
			return Props.lever(opened)
		Gimmick.Kind.CRYSTAL:
			return Props.crystal(opened)
	return Props.target(opened)

## 仕掛けを開ける（岩が砕ける・橋が下りる・茨が燃える・つたが切れる）。死んでも開いたまま。
func open_gimmick(g: Gimmick) -> void:
	if run.is_gimmick_open(g.id):
		return
	run.open_gimmick(g.id)
	_apply_open(g)
	for s in _gimmick_nodes.get(g.id, []):
		if is_instance_valid(s):
			s.queue_free()
	_gimmick_nodes.erase(g.id)
	match g.kind:
		Gimmick.Kind.CRACK:
			notice("岩が砕けた！", 1.5)
			camera.shake(3.0)
			Sfx.play("break")
			for c in g.cells:
				var dust := ImpactDust.new()
				dust.setup(camera, HeightMap.cell_center(c), map.get_height(c), 4)
				_area_root.add_child(dust)
		Gimmick.Kind.THORNS:
			notice("茨が燃えつきた！", 1.5)
			Sfx.play("burn")
			for c in g.cells:
				_effect_sprite(Props.flame(rng.randi() % 3), HeightMap.cell_center(c), map.get_height(c), 0.0, 0.8)
		Gimmick.Kind.VINES:
			notice("つたを斬った！", 1.5)
			Sfx.play("snip")
		Gimmick.Kind.TARGET:
			notice("的に当たった！\n橋が下りた", 2.0)
			Sfx.play("bridge")
			for s in _target_nodes.get(g.id, []):
				s.set_model(Props.target(true))
			_rebuild_terrain()
		Gimmick.Kind.PLATE, Gimmick.Kind.LEVER:
			notice(("押し板が沈んだ！" if g.kind == Gimmick.Kind.PLATE else "レバーを引いた！") + "\n鉄格子が上がった", 2.0)
			Sfx.play("switch")
			Sfx.play("lift", HeightMap.cell_center(g.cells[0]), -4.0)
			for s in _target_nodes.get(g.id, []):
				s.set_model(switch_model(g.kind, true))
		Gimmick.Kind.CRYSTAL:
			notice("水晶が光った！\n足場がせり上がった", 2.0)
			Sfx.play("seal")
			Sfx.play("lift", HeightMap.cell_center(g.cells[0]))
			camera.shake(2.0)
			for s in _target_nodes.get(g.id, []):
				s.outline_color = Color(0, 0, 0, 0)  # 光っているので、ふちなし
				s.set_model(switch_model(g.kind, true))
			_rebuild_terrain()
			# 足場の上に立っていたら、一緒に上がる
			var pc := player.mover.cell()
			if pc in g.cells:
				player.mover.height = map.get_height(pc)
		Gimmick.Kind.BRITTLE:
			notice("もろい壁が崩れた！", 1.5)
			camera.shake(3.0)
			Sfx.play("break")
			for c in g.cells:
				var dust := ImpactDust.new()
				dust.setup(camera, HeightMap.cell_center(c), map.get_height(c), 5)
				_area_root.add_child(dust)

## 地形の絵を作り直す（橋が下りたとき）。
func _rebuild_terrain() -> void:
	if _terrain_root != null:
		_area_root.remove_child(_terrain_root)
		_terrain_root.queue_free()
	_terrain_root = Node2D.new()
	_area_root.add_child(_terrain_root)
	_area_root.move_child(_terrain_root, 0)
	Terrain.build(map, camera, _terrain_root, _deco)

## 炎の魔法が point のまわり radius に当たった。茨が燃える。
func _burn_gimmicks(point: Vector2, radius: float) -> void:
	for g in _closed_gimmicks():
		if g.by_fire(point, radius):
			open_gimmick(g)

## 明かり（2026-11-26）：たき火・燃えている所・火の玉・溶岩・主人公（暗い地方だけ）。Atmosphere が画面を照らす。
func _update_lights() -> void:
	if atmosphere == null:
		return
	var list := []
	var flick := 0.92 + 0.08 * sin(_arrow_blink * 13.0) * sin(_arrow_blink * 7.3)
	if _campfire_cell.x >= 0:
		list.append([HeightMap.cell_center(_campfire_cell), map.get_height(_campfire_cell) * StackSprite.LEVEL_PX + 6.0, 100.0 * flick, 1.0])
	if atmosphere.is_dark():
		var mv := player.mover
		list.append([mv.pos, mv.height * StackSprite.LEVEL_PX + 8.0, 64.0, 0.8, 0.0])
	for b in _braziers:
		list.append([HeightMap.cell_center(b[1]), b[2], 72.0 * flick, 0.9, 0.7])
	for f in _fires:
		list.append([f[0], f[1] * StackSprite.LEVEL_PX + 4.0, 44.0 * flick, 0.9])
	for b in _bolts:
		var p: Pellet = b[0]
		list.append([p.pos, p.z, 30.0, 0.8])
	if not _lava_cells.is_empty():
		var f := camera.focus
		var near := []
		for c in _lava_cells:
			var d := HeightMap.cell_center(c).distance_squared_to(f)
			if d < 150.0 * 150.0 and (c.x + c.y) % 2 == 0:  # 画面の近くの、1つおきのマス
				near.append([d, c])
		near.sort_custom(func(a, b): return a[0] < b[0])
		for e in near.slice(0, 8):
			var c: Vector2i = e[1]
			list.append([HeightMap.cell_center(c), map.get_height(c) * StackSprite.LEVEL_PX, 40.0 * flick, 0.55])
	atmosphere.set_lights(list)

## 暗い地方の石の壁と柱の上に、ところどころかがり火を置く（マスで決まる。MAX_BRAZIERS まで）。
func _place_braziers() -> void:
	_braziers.clear()
	if not area.theme in BRAZIER_THEMES:
		return
	for y in map.size.y:
		for x in map.size.x:
			var c := Vector2i(x, y)
			var kind: String = _deco.get(c, "")
			if not BRAZIER_ON.has(kind) or (x * 7 + y * 13) % 11 != 0:
				continue
			var s := _marker(c, Props.brazier(x % 3), 6, false)
			s.lift_px = BRAZIER_ON[kind]
			_braziers.append([s, c, map.get_height(c) * StackSprite.LEVEL_PX + BRAZIER_ON[kind] + 6.0])
			if _braziers.size() >= MAX_BRAZIERS:
				return

## 魔法（弾・炎・雷）が point のまわり radius に当たった。水晶が光る。
func _magic_gimmicks(point: Vector2, radius: float) -> void:
	for g in _closed_gimmicks():
		if g.by_magic(point, radius):
			open_gimmick(g)

## となりにある、まだ引いていないレバー。なければ null。
func lever_here() -> Gimmick:
	if area_state.result != AreaState.Result.PLAYING:
		return null
	for g in _closed_gimmicks():
		if g.by_hand(player.mover.cell(), map):
			return g
	return null

## そばのレバーを引く（F）。なければ false。
func try_pull_lever() -> bool:
	if is_switching():
		return false
	var g := lever_here()
	if g == null:
		return false
	open_gimmick(g)
	return true

func gimmick_markers(id: String) -> int:
	return _gimmick_nodes.get(id, []).size()

## 商人を置く。町は道具屋・武器屋・鍛冶屋、地方の休憩所は旅の商人。
func _place_talkers(_info: Dictionary) -> void:
	for m in area.merchants:
		var shop: String = m[1]
		var v: int = {"tool": 0, "weapon": 1, "smith": 3}.get(shop, 2)
		_marker(m[0], Props.merchant(v), 1)
		_talkers.append([m[0], "%s\nF：お店を見る" % Shop.NAMES[shop], shop])

## 近くにいる商人・像の言葉。なければ空。
func _talk_here() -> String:
	var c := player.mover.cell()
	for t in _talkers:
		var tc: Vector2i = t[0]
		if absi(c.x - tc.x) <= 1 and absi(c.y - tc.y) <= 1:
			return t[1]
	return ""

## 2026-11-26（3回目の直し）：宝箱（装備の入った拾いもの）は、歩いて拾わず、そばで F を押して開ける。
## そばとは、同じ高さで、宝箱のマスの中心から CHEST_REACH 以内。開けた宝箱は開いたまま残る。
const CHEST_REACH := 24.0

static func is_chest(id: String) -> bool:
	return ItemCatalog.exists(id)

## そばにある、まだ開けていない宝箱の番号（なければ -1）。
func chest_here() -> int:
	for i in _pickup_nodes.keys():
		var p = area.pickups[i]
		if is_chest(p[1]) and map.get_height(p[0]) == player.mover.height \
				and player.mover.pos.distance_to(HeightMap.cell_center(p[0])) <= CHEST_REACH:
			return i
	return -1

## そばの宝箱を開ける。なければ false。
func try_open_chest() -> bool:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return false
	var i := chest_here()
	if i < 0:
		return false
	var p = area.pickups[i]
	if not run.collect(area.pickup_id(i), p[1], p[2]):
		return false
	var node: StackSprite = _pickup_nodes[i]
	_pickup_nodes.erase(i)
	node.set_model(Props.chest_open())
	effect_at(Props.rain_ring(10.0), node.world_pos, node.base_height, 0.3)
	Sfx.play("chest")
	_on_picked(p[1], p[2])
	return true

## 近くの商人のお店を開く。そばにいなければ false。
func try_open_shop() -> bool:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return false
	var c := player.mover.cell()
	for tk in _talkers:
		var tc: Vector2i = tk[0]
		if tk.size() > 2 and absi(c.x - tc.x) <= 1 and absi(c.y - tc.y) <= 1:
			menu.close()
			shop_menu.open(tk[2])
			return true
	return false

## たき火のそば（たき火のマスのまわり8マス）にいるか。
func near_campfire() -> bool:
	if _campfire_cell.x < 0:
		return false
	var c := player.mover.cell()
	return absi(c.x - _campfire_cell.x) <= 1 and absi(c.y - _campfire_cell.y) <= 1

## たき火のそばで F：一度休んだたき火へ移る画面を開く（2026-11-26 の4回目の直し）。
func try_use_campfire() -> bool:
	if area_state.result != AreaState.Result.PLAYING or is_switching() or not near_campfire():
		return false
	menu.close()
	travel_menu.open(area.id)
	return true

func _on_travel(id: String) -> void:
	if not run.travel_to(id):
		return
	Sfx.play("teleport")
	_start_switch({"area": id, "cell": run.respawn_cell()})

func _near_merchant() -> bool:
	var c := player.mover.cell()
	for tk in _talkers:
		var tc: Vector2i = tk[0]
		if tk.size() > 2 and absi(c.x - tc.x) <= 2 and absi(c.y - tc.y) <= 2:
			return true
	return false

func _on_bought(id: String) -> void:
	Sfx.play("craft" if shop_menu.shop_id == "smith" else "buy")
	if ItemCatalog.exists(id):
		warm_hero_looks()
	apply_stats()

## M キーで全体マップを開く・閉じる（開いている間も世界は動く）。
func toggle_map() -> void:
	map_view.current_id = area.id
	_sync_map()
	map_view.visible = not map_view.visible
	map_view.queue_redraw()
	Sfx.play("ui_open" if map_view.visible else "ui_close")

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2  # 画面全体の空気（Atmosphere、レイヤー1）より上
	add_child(layer)
	_ui_layer = layer
	_status = UiText.label()
	_status.position = Vector2(4, 2)
	_status.visible = false  # 文字の表示はテスト用に残し、画面には Hud（バーと箱）を出す
	layer.add_child(_status)
	hud = Hud.new()
	hud.field = self
	layer.add_child(hud)
	_message = UiText.label(true)
	_message.position = Vector2(0, 92)
	_message.size = Vector2(320, 40)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_message)
	_boss_bar = Control.new()
	_boss_bar.position = Vector2(80, 24)
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_boss_bar)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.05, 0.05, 0.85)
	bg.size = Vector2(160, 4)
	bg.position = Vector2(0, 12)
	_boss_bar.add_child(bg)
	_boss_fill = ColorRect.new()
	_boss_fill.color = Color("e74c3c")
	_boss_fill.size = Vector2(160, 4)
	_boss_fill.position = Vector2(0, 12)
	_boss_bar.add_child(_boss_fill)
	var half := ColorRect.new()  # 半分の印（ここを切ると2段目）
	half.color = Color(1, 1, 1, 0.7)
	half.size = Vector2(1, 4)
	half.position = Vector2(80, 12)
	_boss_bar.add_child(half)
	var gbg := ColorRect.new()
	gbg.color = Color(0.08, 0.08, 0.1, 0.85)
	gbg.size = Vector2(160, 2)
	gbg.position = Vector2(0, 17)
	_boss_bar.add_child(gbg)
	_guard_fill = ColorRect.new()
	_guard_fill.color = Color("e8d27a")
	_guard_fill.size = Vector2(160, 2)
	_guard_fill.position = Vector2(0, 17)
	_boss_bar.add_child(_guard_fill)
	_boss_label = UiText.label()
	_boss_label.size = Vector2(160, 12)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_bar.add_child(_boss_label)
	_boss_bar.visible = false
	_popups = Control.new()
	_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_popups)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.size = Vector2(320, 180)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_flash)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.size = Vector2(320, 180)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_update_ui()

func _update_ui() -> void:
	_status.text = status_text()
	var b := active_boss()
	_message.text = ui_message()
	_boss_bar.visible = b != null
	if b != null:
		_boss_label.text = b.group + ("（怒り）" if b.phase == 2 else "") + ("　崩れた！" if b.guard.broken() else "")
		_guard_fill.size.x = 160.0 * (b.guard.stagger / BossGuard.STAGGER if b.guard.broken() else b.guard.ratio())
		_guard_fill.color = Color("ffd54a") if b.guard.broken() else Color("c8c0a0")
		_boss_fill.size.x = 160.0 * b.walker.hp / b.walker.max_hp
		var twin_hp := 0
		var twin_max := 0
		for o in bosses:
			if is_instance_valid(o) and o.group == b.group:
				twin_hp += o.walker.hp
				twin_max += o.walker.max_hp
		_boss_fill.size.x = 160.0 * twin_hp / maxf(1.0, twin_max)

## 左上の2行。
func status_text() -> String:
	var inv := run.inventory
	var st := run.stats
	var text := "Lv%d いのち%d/%d マナ%d/%d 経験%d/%d お金%d" % [st.level, player.hp, player.max_hp,
		floori(mana.value), mana.max_value, st.exp_in_level(), st.exp_level_span(), inv.money]
	for k in buffs.active():
		text += " %s%d" % [{"atk": "力", "def": "守", "speed": "速"}[k], ceili(buffs.remaining(k))]
	if run.grave != null:
		text += "　墓石：%s" % world.area(run.grave.area_id).title
	return text + "\n" + hotbar_text()

## 手に持つ物の箱の中身（Hud が描く）：id（アイコン）、name（選んだとき箱の上に出す名前）、count（右下の数）、ok（使えるか）。
## 持っていない武器は id が空。
func hotbar_slot(item: Hotbar.Item) -> Dictionary:
	var eq := run.inventory.equipment
	match item:
		Hotbar.Item.TOOL:
			var tool := run.inventory.current_tool()
			if tool == "":
				return {"name": "道具（なし）"}
			return {"id": tool, "name": "%s ×%d　ホイール：替える" % [ItemCatalog.name_of(tool), run.inventory.count(tool)],
				"count": run.inventory.count(tool)}
		Hotbar.Item.IRON_BALL:
			var bid := ball.rules_ball.item
			var held := ball.rules_ball.state == IronBall.State.HELD
			return {"id": bid, "name": ItemCatalog.label(bid) + ("" if held else "（拾いに行く）"), "ok": held}
	var slot: Equipment.Slot = Hotbar.WEAPON_SLOT[item]
	if eq.effective(slot) == 0:
		return {}
	var id := eq.current(slot)
	var out := {"id": id, "name": ItemCatalog.label(id)}
	if item == Hotbar.Item.BOW:
		out["count"] = _usable_arrows()
		out["ok"] = _usable_arrows() > 0
		out["name"] += "　矢%d" % _usable_arrows()
	elif item == Hotbar.Item.STAFF and current_spell() >= 0:
		var spell := current_spell()
		out["name"] += "：" + Magic.NAMES[spell]
		if usable_spells().size() > 1:
			out["name"] += "（ホイール）"
	return out

## 手に持つアイテムの並び。持っている武器だけ出し、選んでいるものを [ ] で囲む。
func hotbar_text() -> String:
	var eq := run.inventory.equipment
	var parts: Array[String] = []
	for i in Hotbar.SLOTS.size():
		var item: Hotbar.Item = Hotbar.SLOTS[i]
		var name := ""
		if item == Hotbar.Item.TOOL:
			var tool := run.inventory.current_tool()
			if tool == "":
				continue
			name = "%s×%d" % [ItemCatalog.name_of(tool), run.inventory.count(tool)]
		elif item == Hotbar.Item.IRON_BALL:
			name = InventoryMenu.weapon_label(Equipment.Slot.BALL, ball.rules_ball.item)
		else:
			var slot: Equipment.Slot = Hotbar.WEAPON_SLOT[item]
			if eq.effective(slot) == 0:
				continue
			name = InventoryMenu.weapon_label(slot, eq.current(slot))
			if item == Hotbar.Item.BOW:
				name += "(矢%d)" % _usable_arrows()
			elif item == Hotbar.Item.STAFF and item == hotbar.selected and current_spell() >= 0:
				var spell := current_spell()
				name += ":" + Magic.NAMES[spell]
				if magic.remaining(spell) > 0.0:
					name += "(%d)" % ceili(magic.remaining(spell))
		var t := "%d %s" % [i + 1, name]
		parts.append("[%s]" % t if item == hotbar.selected else " %s " % t)
	return "".join(parts)

## 開かない門の知らせ。封印の門はボスの数、ボスの間の門は地方の印の数。
func door_hint(door_id: String) -> String:
	if RunState.BOSS_DOORS.has(door_id):
		var seal: String = RunState.BOSS_DOORS[door_id]
		return "%sが %d個 そろうと開く（あと%d個）\n寄り道のエリアで探す" % [ItemCatalog.label(seal), RunState.SEALS_PER_DOOR, run.seals_left(door_id)]
	if door_id == Story.MIST_DOOR:
		return "霧が濃くて 進めない\n地方のぬしを あと%d体 倒すと 霧が薄くなる" % run.mist_bosses_left()
	if door_id == Story.KEEP_DOOR:
		return "闇の砦の門。紋章が 刻まれている\n村のお守りが 要りそうだ"
	return "神秘の塔の封印の門\nあと%d体のボスを倒すと開く" % run.seal_bosses_left()

## 画面の真ん中に出す言葉。なければ空。
func ui_message() -> String:
	if map_view != null and map_view.visible:
		return ""
	if dialogue != null and dialogue.is_open():
		return ""
	if area_state.result == AreaState.Result.DYING:
		return "やられた…\nたき火から やり直す"
	if _gate_here() != null:
		var door := _gate_here().door_id
		if not run.can_open_door(door):
			return door_hint(door)
		return "F：門を開ける"
	if _notice_time > 0.0:
		return _notice_text
	if chest_here() >= 0:
		return "F：宝箱を開ける"
	if lever_here() != null:
		return "F：レバーを引く"
	if _title_time > 0.0:
		return area.title if area.region == "はじまりの地" else "%s\n%s" % [area.region, area.title]
	var talk := _talk_here()
	if talk != "" and not shop_menu.is_open():
		return talk
	var who := person_here()
	if not who.is_empty() and (dialogue == null or not dialogue.is_open()):
		var pp: Dictionary = who["person"]
		return ("F：読む（%s）" if Story.is_object(pp["look"]) else "F：話す（%s）") % pp["name"]
	if travel_menu != null and near_campfire() and not travel_menu.is_open() and run.bonfire_areas().size() > 1:
		return "F：たき火から移動する"
	if _grave_hint_time > 0.0:
		return "死んだ場所に墓石がある\n鉄球を落として壊すと、持ち物が戻る"
	if _start_hint_time > 0.0:
		return "地面の矢印の先へ歩くと、となりのエリアへ行ける"
	return ""

## 確認用：エリアの敵を消し、すべての種類（17種類）の敵をプレイヤーのまわりに並べて止める（`--zoo`）。
func _show_zoo() -> void:
	for e in enemies:
		e.queue_free()
	enemies.clear()
	var c0 := HeightMap.world_to_cell(player.mover.pos)
	for k in EnemyKind.Kind.size():
		var cell := c0 + Vector2i(-4 + (k % 5) * 2, -3 + (k / 5) * 2 + (1 if k >= 5 else 0))
		var e := Enemy.new()
		e.setup(map, cell, Vector2.DOWN, player, camera, k)
		_area_root.add_child(e)
		enemies.append(e)
		e._process(0.0)
		e.set_process(false)
		e.refresh()

## `-- --screenshot=path.png` で数フレーム後に画面を保存して終了する（確認用）。
## `--area=hills` でエリア、`--player=x,y` で位置、`--angle=0.8` でカメラ角度。`--fps` で平均FPSを出す。
## `--offset=dx,dy` でプレイヤーをマスの中心からずらす。`--ball=dx,dy` で鉄球をプレイヤーからずらして地面に置く。
## `--gear` で試しの武器と防具を持ち、`--hold=2` で手に持つ物を選ぶ。`--inventory` でインベントリを開いた画面（`--inventory=stats` でステータスのページ、`--inventory=staff` で試しの杖を持って杖の欄）。`--exp=30` で経験値を足す。
func _maybe_screenshot() -> void:
	var path := ""
	var measure_fps := false
	var place = null
	var offset := Vector2.ZERO
	var ball_offset = null
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screenshot="):
			path = a.trim_prefix("--screenshot=")
		elif a.begins_with("--angle="):
			camera.angle = float(a.trim_prefix("--angle="))
		elif a.begins_with("--area="):
			enter_area(a.trim_prefix("--area="), Continent.START_CELL)
		elif a.begins_with("--player="):
			var p := a.trim_prefix("--player=").split(",")
			place = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--offset="):
			var o := a.trim_prefix("--offset=").split(",")
			offset = Vector2(float(o[0]), float(o[1]))
		elif a.begins_with("--ball="):
			var o := a.trim_prefix("--ball=").split(",")
			ball_offset = Vector2(float(o[0]), float(o[1]))
		elif a == "--fps":
			measure_fps = true
		elif a.begins_with("--inventory"):
			if a == "--inventory=stats":
				menu.page = InventoryMenu.Page.STATS
			elif a == "--inventory=settings":
				menu.page = InventoryMenu.Page.SETTINGS
			elif a == "--inventory=controls":
				menu.page = InventoryMenu.Page.SETTINGS
				get_tree().create_timer(0.1).timeout.connect(menu.show_controls.bind(true))
			elif a == "--inventory=items":
				menu.page = InventoryMenu.Page.ITEMS
				for id in ["hide", "bone", "herb", "potion", "bomb", "iron_ore", "star_shard", "giant_core", "seal_mt", "arrow", "ether", "feather"]:
					run.inventory.add(id, 3)
				run.inventory.money = 120
				for id in ["sword_1", "sword_light", "bow_long", "staff_fire_3", "armor_leather", "sword_flame"]:
					run.inventory.equipment.gain(id)
			elif a == "--inventory=staff":
				run.stats.add_exp(PlayerStats.exp_to_reach(8))
				for id in ["staff_none_1", "staff_fire_3", "staff_storm"]:
					run.inventory.equipment.gain(id)
				menu.selected_slot = Equipment.Slot.STAFF
			get_tree().create_timer(0.05).timeout.connect(open_inventory)
		elif a == "--gear":
			run.stats.add_exp(PlayerStats.exp_to_reach(8))  # ランク3の杖を使えるように
			for i in 3:
				run.stats.allocate(PlayerStats.Stat.MAGIC)
			for id in ["sword_1", "bow_1", "staff_fire_3", "armor_1"]:
				run.inventory.equipment.gain(id)
			run.inventory.add_arrows(Arrow.Kind.NORMAL, 20)
			run.inventory.add("potion", 3)
			apply_stats()
		elif a.begins_with("--shop="):
			var shop := a.trim_prefix("--shop=")
			run.inventory.money = 500
			for id in ["wood", "scrap", "hide", "herb", "iron_ore"]:
				run.inventory.add(id, 5)
			get_tree().create_timer(0.05).timeout.connect(shop_menu.open.bind(shop))
		elif a.begins_with("--tip="):
			var n := int(a.trim_prefix("--tip="))
			get_tree().create_timer(0.2).timeout.connect(func():
				if menu.is_open() and n < menu._items_box.get_child_count():
					menu._items_box.get_child(n).mouse_entered.emit())
		elif a == "--boss":
			for b in bosses:
				b.wake()
		elif a == "--zoo":
			get_tree().create_timer(0.02).timeout.connect(_show_zoo)
		elif a.begins_with("--hold="):
			hotbar.select_slot(int(a.trim_prefix("--hold=")), run.inventory.equipment)
		elif a == "--map":
			for id in world.ids():
				run.visit(id)
			toggle_map()
		elif a.begins_with("--exp="):
			run.stats.add_exp(int(a.trim_prefix("--exp=")))
			apply_stats()
		elif a == "--notitle":
			_title_time = 0.0
		elif a == "--prologue":
			show_prologue()
		elif a == "--ending":
			_open_dialogue("", Story.ending(Story.flags(run)), true)
		elif a.begins_with("--talk="):
			var who := a.trim_prefix("--talk=")
			for pp in _people:
				if pp["person"]["id"] == who:
					for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
						var c: Vector2i = pp["cell"] + d
						if _walkable(c):
							place = c
							break
			if place != null:
				player.mover.place(place)
				try_talk()
		elif a.begins_with("--title"):
			show_title()  # タイトル画面（--title=load・new・settings でその欄。2026-11-26 独自の開発1）
			match a.trim_prefix("--title="):
				"load":
					title_menu.show_mode(TitleMenu.Mode.LOAD)
					title_menu.show_slots(TitleMenu.Mode.LOAD)
				"new":
					title_menu.show_slots(TitleMenu.Mode.NEW)
				"settings":
					title_menu.show_mode(TitleMenu.Mode.SETTINGS)
		elif a.begins_with("--pause"):
			pause_menu.visible = true  # 画面の確認では木を止めない（止めると撮れない）
			pause_menu._info.text = "遊んだ時間 1:23"
			if a == "--pause=settings":
				pause_menu.show_settings(true)
	if place != null:
		player.mover.place(place)
		player.mover.pos += offset
		camera.focus_height = player.mover.height * StackSprite.LEVEL_PX
	if ball_offset != null:
		var b := ball.rules_ball
		b.pos = player.mover.pos + ball_offset
		b.height = map.get_height(b.cell())
		b.state = IronBall.State.ON_GROUND
	if path == "":
		return
	var start := Time.get_ticks_msec()
	var frames := 120 if measure_fps else 10
	for i in frames:
		await get_tree().process_frame
	if measure_fps:
		print("FPS: %.1f" % (frames * 1000.0 / (Time.get_ticks_msec() - start)))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()

# ---------------------------------------------------------------- ストーリー（2026-11-26 の4回目の直し）

## はじまりの言葉（黒い画面）。テストと画面の確認では出さない。
func show_prologue() -> void:
	_open_dialogue("", Story.PROLOGUE, true)

func _screenshot_mode() -> bool:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screenshot") or a == "--noprologue":
			return true
	return false

func _open_dialogue(name_: String, pages: Array, full := false) -> void:
	if pages.is_empty() or dialogue == null:
		return
	if menu != null and menu.is_open():
		close_inventory()
	if shop_menu != null:
		shop_menu.close()
	if travel_menu != null:
		travel_menu.close()
	bow.cancel()
	dialogue.open(name_, pages, full)
	player.controllable = false
	_freeze_actors(true)

func _on_dialogue_done() -> void:
	_freeze_actors(false)
	if not is_switching():
		player.controllable = true

## 話している間は、敵とボスを止める（地形はカメラに合わせて描きつづける）。
func _freeze_actors(on: bool) -> void:
	for e in enemies + bosses:
		if is_instance_valid(e):
			e.set_process(not on)
	for b in bosses:
		if is_instance_valid(b):
			for d in b.decoys:
				if is_instance_valid(d):
					d.set_process(not on)

func _step_story_queue(delta: float) -> void:
	if _story_queue.is_empty() or (dialogue != null and dialogue.is_open()) or is_switching():
		return
	_story_queue[0][0] -= delta
	if _story_queue[0][0] > 0.0 or area_state.result != AreaState.Result.PLAYING:
		return
	var q = _story_queue.pop_front()
	_open_dialogue(q[1], q[2], q[3])

## そばにいる人・看板・墓（となり8マス）。なければ空。
func person_here() -> Dictionary:
	if area_state.result != AreaState.Result.PLAYING:
		return {}
	var c := player.mover.cell()
	for p in _people:
		var pc: Vector2i = p["cell"]
		if absi(c.x - pc.x) <= 1 and absi(c.y - pc.y) <= 1:
			return p
	return {}

## そばの人と話す・看板を読む（F）。いなければ false。
func try_talk() -> bool:
	if is_switching() or (dialogue != null and dialogue.is_open()):
		return false
	var p := person_here()
	if p.is_empty():
		return false
	var who: Dictionary = p["person"]
	var pages := Story.lines(who, Story.flags(run))
	if pages.is_empty():
		return false
	if p["node"] != null and is_instance_valid(p["node"]) and not Story.is_object(who["look"]):
		var d: Vector2 = player.mover.pos - HeightMap.cell_center(p["cell"])
		p["node"].turn = d.angle() - PI / 2  # こちらを向く
	_open_dialogue(who["name"], pages)
	return true

## 人・看板・墓の模型。
static func person_model(look: String) -> VoxelModel:
	match look:
		"sign":
			return Props.signboard()
		"grave":
			return Props.grave()
	return Props.villager(look)

## エリアの人・看板・墓を置く（Story.PEOPLE と、仕掛けのヒントの看板）。歩いて行ける所で、まわり8マスが同じ高さの平らな所に置き、
## そのマスはふさぐ（道は切れない）。anchor の近くから探す。
func _place_story(info: Dictionary) -> void:
	var people: Array = Story.people(area.id).duplicate()
	var kinds := {}
	for g in area.gimmicks:
		if run.is_gimmick_open(g.id) or kinds.has(g.kind) or g.cells.is_empty():
			continue
		kinds[g.kind] = true
		people.append({"id": "hint_%d" % g.kind, "name": "看板", "look": "sign", "anchor": "gimmick", "at": g.cells[0],
			"talk": [["", [Story.gimmick_hint(g.kind)]]]})
	if people.is_empty():
		return
	var reach := _reachable_cells(info)
	var used := {}
	var avoid := _story_avoid(info)
	for p in people:
		var anchor := _story_anchor(p, info)
		var c := _story_cell(anchor, reach, used, avoid)
		if c.x < 0:
			continue
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				used[c + Vector2i(dx, dy)] = true
		map.set_blocker(c, HeightMap.Blocker.NPC)
		var node := _marker(c, person_model(p["look"]), 1)
		if p["look"] == "spirit":
			node.modulate.a = 0.7
		var to_anchor := HeightMap.cell_center(anchor) - HeightMap.cell_center(c)
		if p["look"] != "sign" and to_anchor.length() > 1.0:
			node.turn = to_anchor.angle() - PI / 2
		_people.append({"cell": c, "person": p, "node": node})

func _story_anchor(p: Dictionary, info: Dictionary) -> Vector2i:
	var a: String = p.get("anchor", "center")
	var center := map.size / 2
	if a == "bonfire":
		return info.get("checkpoint", center)
	if a == "gimmick":
		return p.get("at", center)
	if a.begins_with("shop:"):
		for m in area.merchants:
			if m[1] == a.substr(5):
				return m[0]
	if a.begins_with("exit:"):
		for ex in area.exits:
			if ex.target == a.substr(5):
				var mid := Trails.exit_middle(map, ex)
				if mid.x >= 0:
					return mid
	return center

## 人を置かないマス：拾いもの・出口のそば・敵の出る所・ボスのまわり・たき火・仕掛け。
func _story_avoid(info: Dictionary) -> Dictionary:
	var out := area.entry_safe_cells()
	var spots: Array = []
	for p in area.pickups:
		spots.append(p[0])
	for e in area.enemies:
		spots.append(e[0])
	for g in area.gimmicks:
		spots.append_array(g.cells)
		spots.append_array(g.trigger)
	if info.has("checkpoint"):
		spots.append(info["checkpoint"])
	for c in spots:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				out[c + Vector2i(dx, dy)] = true
	for b in area.bosses:
		for dy in range(-6, 7):
			for dx in range(-6, 7):
				out[b[0] + Vector2i(dx, dy)] = true
	return out

## anchor に一番近い、置けるマス（anchor からは2マス以上はなす）。なければ (-1, -1)。
func _story_cell(anchor: Vector2i, reach: Dictionary, used: Dictionary, avoid: Dictionary) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	for c in reach:
		if used.has(c) or avoid.has(c):
			continue
		var d := Vector2(c - anchor).length_squared()
		if d < 4.0 or d >= best_d:
			continue
		var h := map.get_height(c)
		var flat := true
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n: Vector2i = c + Vector2i(dx, dy)
				if not reach.has(n) or map.get_height(n) != h or map.is_water(n):
					flat = false
		if flat:
			best = c
			best_d = d
	return best

## 出口とたき火から歩いて行けるマス（登りは1段、飛び降りは3段まで）。
func _reachable_cells(info: Dictionary) -> Dictionary:
	var seen := {}
	var todo: Array[Vector2i] = []
	for ex in area.exits:
		var c := Trails.exit_middle(map, ex)
		if c.x >= 0 and not seen.has(c):
			seen[c] = true
			todo.append(c)
	if info.has("checkpoint"):
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var c: Vector2i = info["checkpoint"] + d
			if _walkable(c) and not seen.has(c):
				seen[c] = true
				todo.append(c)
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		var h := map.get_height(c)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if seen.has(n) or not _walkable(n):
				continue
			var dh := map.get_height(n) - h
			if dh > 1 or dh < -3:
				continue
			seen[n] = true
			todo.append(n)
	return seen

func _walkable(c: Vector2i) -> bool:
	return map.in_bounds(c) and not map.is_wall(c) and not map.is_water(c) and not map.is_pit(c) and not map.is_void(c)


# ---------------------------------------------------------------- セーブ・タイトル・止める画面（2026-11-26 独自の開発1）

## 本当に遊んでいるか（テストと画面の確認ではない）。設定の読み込みとタイトル画面はこのときだけ。
func _real_run() -> bool:
	return is_inside_tree() and get_tree().current_scene == self and not _screenshot_mode()

## 一覧に出す場所の名前。
func place_name() -> String:
	if area == null:
		return ""
	return area.title if area.region == "はじまりの地" else "%s　%s" % [area.region, area.title]

## セーブの枠を選んで遊んでいれば、今の冒険を書く。
func autosave() -> bool:
	if save_slot <= 0 or in_title or run == null:
		return false
	return SaveGame.write(save_slot, run, place_name())

func _on_settings_changed() -> void:
	camera.shake_enabled = settings.shake
	if _real_run():
		settings.save_file()

## 設定「カメラを回す間ゆっくり」：回している間だけ時間をゆっくりにする。
func _update_time_scale() -> void:
	var slow := settings.slow_turn and camera != null and camera.turning and not in_title \
			and not get_tree().paused and area_state.result == AreaState.Result.PLAYING
	Engine.time_scale = GameSettings.SLOW_TURN_SCALE if slow else 1.0

## タイトル画面を出す。うしろは はじまりの町で、カメラがゆっくり回る。
func show_title() -> void:
	in_title = true
	save_slot = 0
	get_tree().paused = false
	for m in [menu, shop_menu, travel_menu]:
		if m.is_open():
			m.close()
	map_view.visible = false
	if area == null or area.id != Continent.START_AREA:
		enter_area(Continent.START_AREA, Continent.START_CELL)
	player.visible = false
	player.controllable = false
	ball.visible = false
	hud.visible = false
	_message.visible = false
	title_menu.open()

## タイトルから遊びに入る（新しく始める・つづきから）。
func _leave_title() -> void:
	in_title = false
	title_menu.close()
	player.visible = true
	ball.visible = true
	hud.visible = true
	_message.visible = true
	camera.angle = 0.0
	_fade.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.6)

## 冒険の状態の外（field が持つもの）を、始めた直後の形に戻す。
func _reset_session() -> void:
	area_state = AreaState.new()
	roster = EnemyRoster.new()
	buffs.clear()
	hotbar.selected = Hotbar.Item.IRON_BALL
	ball.rules_ball.return_to_hand()
	player.clear_invulnerable()
	player.anim.revive()
	player.lift_px = 0.0
	player.modulate.a = 1.0
	_story_queue.clear()

## はじめから：枠 slot に新しい冒険を書いて、はじまりの言葉を出す。
func start_new_game(slot: int) -> void:
	var camp_info: Dictionary = Continent.load_map(world.area(Continent.START_AREA))[1]
	run.load_dict(RunState.new(Continent.START_AREA, camp_info["checkpoint"]).to_dict())
	_reset_session()
	save_slot = slot
	_leave_title()
	enter_area(Continent.START_AREA, Continent.START_CELL)
	_after_load()
	show_prologue()

## つづきから：枠 slot を読み、最後に休んだたき火から始める。
func load_game(slot: int) -> bool:
	if not SaveGame.read(slot, run):
		return false
	_reset_session()
	save_slot = slot
	_leave_title()
	enter_area(run.checkpoint_area, run.respawn_cell())
	_after_load()
	if run.grave != null:
		_grave_hint_time = GRAVE_HINT_SECONDS
	return true

func _after_load() -> void:
	_sync_ball_rank()
	apply_stats()
	player.set_hp(player.max_hp)
	mana.set_max(run.stats.max_mana())
	mana.value = mana.max_value
	player.controllable = true
	warm_hero_looks()
	menu.refresh()

func _pause_to_title() -> void:
	autosave()
	pause_menu.visible = false
	get_tree().paused = false
	show_title()

func _pause_quit() -> void:
	autosave()
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		autosave()  # ウィンドウを閉じたときも書く
