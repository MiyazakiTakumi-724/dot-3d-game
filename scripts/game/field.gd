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
## 簡単モード（受けるダメージが半分。design.md 13章）。設定画面はまだない
var easy_mode := false

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
var _fade: ColorRect
## 切り替えの段階：0 なし、1 暗くしている、2 明るくしている
var _switch_phase := 0
var _switch_time := 0.0
var _switch_to := {}
var _title_time := 0.0
var _grave_hint_time := 0.0
## 始めたときに、どうすればよいかを出しておく残り秒数
var _start_hint_time := 8.0
var _status: Label  ## 左上：体力・持ち物・手に持つアイテム・墓石のあるエリア
var _message: Label  ## 真ん中：エリアの名前・門のヒント・やられた
var _guide: Label  ## 下：操作の説明
var _popups: Control  ## ダメージの数字を置く所（エリアを切り替えると片付ける）
## 真ん中に少しの間だけ出す知らせ（レベルアップ・武器を手に入れたなど）
var _notice_text := ""
var _notice_time := 0.0
var sword := Sword.new()
var bow := Bow.new()
var _shots: Array = []  # 飛んでいる矢 [Arrow, StackSprite, ダメージ]
var _arrow_blink := 0.0
## まだ作っていない、ほかのエリアのモデルの名前（遊んでいる間に少しずつ作る）
var _warm_queue: Array[String] = []
const WARM_BUDGET_MS := 10.0  ## 1フレームでモデル作りに使う時間

func _ready() -> void:
	world = Continent.build()
	var camp_info: Dictionary = Continent.load_map(world.area(Continent.START_AREA))[1]
	run = RunState.new(Continent.START_AREA, camp_info["checkpoint"])
	camera = StackCamera.new()
	add_child(camera)
	Terrain.add_background(self)
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
	aim_marker.set_model(VoxelModel.box(Vector3i(6, 6, 1), Color(0, 0, 0, 0.35)))
	aim_marker.force_hidden = true
	add_child(aim_marker)

	enter_area(Continent.START_AREA, Continent.START_CELL)
	player.setup(map, rules, Continent.START_CELL, camera)
	apply_stats()
	player.set_hp(player.max_hp)
	ball.setup(player, map, rules, camera)
	camera.follow(player.mover.pos, player.mover.height * StackSprite.LEVEL_PX, 1.0)
	_title_time = 0.0  # 始めは名前より操作のヒントを出す

	_build_ui()
	menu = InventoryMenu.new()
	menu.setup(run)
	menu.close_requested.connect(close_inventory)
	menu.stats_changed.connect(apply_stats)
	add_child(menu)
	_maybe_screenshot()

## エリアを作り直す。今のエリアの地形・敵・弾・印を片付け、id のエリアを cell から始める。
func enter_area(id: String, cell: Vector2i) -> void:
	for e in enemies:
		if is_instance_valid(e):
			e.shot.disconnect(_on_enemy_shot)
			e.set_process(false)
	enemies.clear()
	_enemy_index.clear()
	_bullets.clear()
	_shots.clear()
	bow.cancel()
	_pickup_nodes.clear()
	_gate_nodes.clear()
	_arrows.clear()
	_grave_node = null
	if _popups != null:
		for c in _popups.get_children():
			c.queue_free()
	for c in _area_root.get_children():
		_area_root.remove_child(c)
		c.queue_free()

	area = world.area(id)
	var loaded := Continent.load_map(area)
	map = loaded[0]
	var info: Dictionary = loaded[1]
	Terrain.build(map, camera, _area_root, info["deco"])
	if info.has("checkpoint"):
		_marker(info["checkpoint"], _bonfire_model(), 1)
	for i in area.pickups.size():
		var p = area.pickups[i]
		if not run.is_picked(area.pickup_id(i)):
			_pickup_nodes[i] = _marker(p[0], _pickup_model(p[1]), 1)
	for ex in area.exits:
		if ex.door_id != "" and not run.is_door_open(ex.door_id):
			_close_gate(ex)
		else:
			_add_arrows(ex)
	if run.grave != null and run.grave.area_id == id:
		map.set_blocker(run.grave.cell, HeightMap.Blocker.GRAVE)
		_grave_node = _marker(run.grave.cell, _grave_model(), 2)
	_spawn_enemies()

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

## となりのエリアを先に、ほかのエリアのモデルを作る順番に並べる（warm は後ろから取る）。
func _queue_warm() -> void:
	var near: Array[String] = []
	var far: Array[String] = []
	for ex in area.exits:
		if not near.has(ex.target):
			near.append(ex.target)
	for id in world.ids():
		if id != area.id and not near.has(id):
			far.append(id)
	var seen := {}
	_warm_queue.clear()
	for id in far + near:
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
		e.walker.died.connect(_on_enemy_died.bind(area.id, i, e.kind, lv))
		_area_root.add_child(e)
		enemies.append(e)
		_enemy_index[e] = i

func enemy_index(e: Enemy) -> int:
	return _enemy_index.get(e, -1)

## そのエリアの番号の敵が、今いるか（倒されていない）。
func has_enemy(index: int) -> bool:
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive and _enemy_index.get(e, -1) == index:
			return true
	return false

func _on_enemy_died(area_id: String, index: int, kind: EnemyKind.Kind, level: int) -> void:
	roster.kill(area_id, index)
	if run.on_enemy_killed(kind, level) > 0:
		notice("レベル%d になった！\nTab：ポイントを振る" % run.stats.level)
		apply_stats()

## 画面の真ん中に、少しの間だけ知らせを出す。
func notice(text: String, seconds := LEVEL_UP_SECONDS) -> void:
	_notice_text = text
	_notice_time = seconds

func _on_melee_hit(e: Enemy) -> void:
	if area_state.result == AreaState.Result.PLAYING and not is_switching():
		hurt_player(e.attack)

## 敵の攻撃（攻撃力 enemy_attack）を受ける。無敵の間は受けない。受けたら true。
func hurt_player(enemy_attack: int) -> bool:
	var dmg := Damage.enemy_hit(enemy_attack, easy_mode)
	if not player.take_hit(dmg):
		return false
	_popup(player.mover.pos, player.mover.height, dmg, Color("ff6b6b"))
	return true

## ステータス（レベル・振り分け）を体力の最大と足の速さに反映する。最大が増えた分は今の体力も増える。
func apply_stats() -> void:
	var new_max := run.stats.max_hp()
	if new_max > player.max_hp:
		player.hp += new_max - player.max_hp
	player.max_hp = new_max
	player.hp = mini(player.hp, new_max)
	player.speed_mult = run.stats.move_speed_mult()

## 手に持っている武器を足した攻撃力。
func current_attack() -> int:
	var rank := 0
	match hotbar.selected:
		Hotbar.Item.IRON_BALL:
			rank = ball_rank
		Hotbar.Item.SWORD, Hotbar.Item.BOW, Hotbar.Item.GUN:
			rank = run.inventory.equipment.effective(Hotbar.WEAPON_SLOT[hotbar.selected])
	return run.stats.attack(Equipment.rank_attack(rank))

## 手に持っている鉄球のランクを、装備に合わせる（落としている間は替えない）。
func _sync_ball_rank() -> void:
	if ball.rules_ball.state != IronBall.State.HELD:
		return
	ball_rank = run.inventory.equipment.effective(Equipment.Slot.BALL)
	ball.rules_ball.set_strong(ball_rank >= 2)

func _popup(pos: Vector2, h: int, amount: int, color: Color) -> void:
	_popups.add_child(DamagePopup.make(camera, pos, h * StackSprite.LEVEL_PX, amount, color))

func is_switching() -> bool:
	return _switch_phase != 0

func _start_switch(to: Dictionary) -> void:
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
	roster.tick(delta)
	sword.update(delta)
	bow.update(delta)
	player.mover.tick(delta)
	if bow.charging and (hotbar.selected != Hotbar.Item.BOW or menu.is_open() or area_state.result != AreaState.Result.PLAYING):
		bow.cancel()
	player.charge = bow.rate() if bow.charging else -1.0
	if not _warm_queue.is_empty() and not is_switching():
		Terrain.warm(_warm_queue, WARM_BUDGET_MS)
	if is_switching():
		_update_switch(delta)
	else:
		if area_state.update(delta):
			respawn()
		_step_bullets(delta)
		_step_shots(delta)
		_step_poison(delta)
		if area_state.result == AreaState.Result.PLAYING:
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
	camera.follow(player.mover.pos, player.mover.height * StackSprite.LEVEL_PX, delta)
	_title_time = maxf(0.0, _title_time - delta)
	_grave_hint_time = maxf(0.0, _grave_hint_time - delta)
	_notice_time = maxf(0.0, _notice_time - delta)
	_start_hint_time = maxf(0.0, _start_hint_time - delta)
	_arrow_blink += delta
	var a := 0.55 + 0.45 * sin(_arrow_blink * 4.0)
	for s in _arrows:
		s.modulate.a = a
	_update_ui()

## 遊んでいる間の毎フレームの処理：拾う、たき火で回復、体当たり、鉄球、出口。
func _play_step() -> void:
	var c := player.mover.cell()
	for i in _pickup_nodes.keys():
		var p = area.pickups[i]
		var reach := RunState.can_reach_pickup(player.mover.pos, player.mover.height, p[0], map.get_height(p[0]))
		if reach and run.collect(area.pickup_id(i), p[1], p[2]):
			_pickup_nodes[i].queue_free()
			_pickup_nodes.erase(i)
			_on_picked(p[1], p[2])
	if run.is_near_checkpoint(area.id, c) and player.hp < player.max_hp:
		player.set_hp(player.max_hp)
	for e in enemies:
		if is_instance_valid(e) and EnemyKind.contact(e.kind) and e.walker.touches(player.mover.pos, player.mover.height):
			hurt_player(e.attack)
			break
	ball.rules_ball.try_pick_up(player.mover)
	_sync_ball_rank()
	var ex := world.exit_through(area.id, c, player.mover.edge_push)
	if ex != null and (ex.door_id == "" or run.is_door_open(ex.door_id)):
		_start_switch(world.arrival(area.id, ex, c))

func _unhandled_input(event: InputEvent) -> void:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
				try_open_door()
			KEY_TAB:
				open_inventory()
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
			return ball.rules_ball.drop_at(player.mover, map, _aim_point())
		Hotbar.Item.SWORD:
			return swing_sword()
		Hotbar.Item.BOW:
			return start_bow()
		Hotbar.Item.HEAL:
			return use_heal()
	return false

## 剣を振る（カーソルの方を向いている）。飛び降りてすぐなら落下斬り。墓石も壊せる。
func swing_sword() -> bool:
	if run.inventory.equipment.effective(Equipment.Slot.SWORD) == 0 or not sword.try_swing():
		return false
	var mv := player.mover
	var st := run.stats
	var fall := mv.recent_drop(Sword.FALL_WINDOW)
	var strong_fall := st.skills_in(PlayerStats.Stat.SWORD) >= 1
	var up := Sword.reaches_up(run.inventory.equipment.effective(Equipment.Slot.SWORD), st.skills_in(PlayerStats.Stat.SWORD) >= 2)
	var dmg := Damage.sword(current_attack(), st.points_in(PlayerStats.Stat.SWORD), fall, strong_fall)
	player.swing(fall > 0)
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive and Sword.hits(mv.pos, mv.height, mv.facing, e.walker.pos, e.walker.height, up):
			e.walker.take_damage(dmg)
			_popup(e.walker.pos, e.walker.height, dmg, Color("ffb347") if fall > 0 else Color.WHITE)
	if run.grave != null and run.grave.area_id == area.id:
		var g := run.grave.cell
		if Sword.hits(mv.pos, mv.height, mv.facing, HeightMap.cell_center(g), map.get_height(g), up):
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
	return true

## 離して撃つ。カーソルの所へ（届かなければ手前に）山なりに飛ぶ。技能「連射」なら2本。
func release_bow() -> bool:
	var r := bow.release()
	if r <= 0.0:
		return false
	var shots := 2 if _bow_skills() >= 3 else 1
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
	return fired

func _fire_arrow(kind: Arrow.Kind, r: float, target: Vector2) -> void:
	var mv := player.mover
	var land := Bow.landing(mv.pos, mv.height, target, r, map)
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
	s.set_model(VoxelModel.box(Vector3i(2, 2, 2), Color("9be36b") if kind == Arrow.Kind.POISON else Color("e8d9b0")))
	_area_root.add_child(s)
	_shots.append([a, s, dmg])
	_place_shot(a, s)

func shots_in_flight() -> int:
	return _shots.size()

func _place_shot(a: Arrow, s: StackSprite) -> void:
	var hp := a.height_px()
	s.world_pos = a.pos()
	s.base_height = int(floor(hp / StackSprite.LEVEL_PX))
	s.lift_px = hp - s.base_height * StackSprite.LEVEL_PX
	s.refresh()

## 飛んでいる矢を進め、落ちた所の敵（同じ高さ）に当てる。墓石にも当たる。
func _step_shots(delta: float) -> void:
	for i in range(_shots.size() - 1, -1, -1):
		var a: Arrow = _shots[i][0]
		var s: StackSprite = _shots[i][1]
		var dmg: int = _shots[i][2]
		if not a.update(delta):
			_place_shot(a, s)
			continue
		s.queue_free()
		_shots.remove_at(i)
		_arrow_landed(a, dmg)

func _arrow_landed(a: Arrow, dmg: int) -> void:
	if area_state.result != AreaState.Result.PLAYING:
		return
	var c := HeightMap.world_to_cell(a.to)
	if not map.in_bounds(c) or map.is_water(c) or map.is_pit(c):
		return
	var land_h := map.get_height(c)
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive and Arrow.hits(a.to, land_h, e.walker.pos, e.walker.height):
			e.walker.take_damage(dmg)
			_popup(e.walker.pos, e.walker.height, dmg, Color.WHITE)
			if a.kind == Arrow.Kind.POISON:
				e.walker.poison(Arrow.POISON_SECONDS)
			break  # 1本の矢は1体だけ
	if run.grave != null and run.grave.area_id == area.id and IronBall.touches_cell(a.to, run.grave.cell):
		_remove_grave_marker()
		run.break_grave()

## 毒のダメージ（毎秒1）。
func _step_poison(delta: float) -> void:
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive:
			var d := e.walker.update_poison(delta)
			if d > 0:
				_popup(e.walker.pos, e.walker.height, d, Color("9be36b"))

## 剣は左ボタンを押したままでも、振れるようになるたびに振る。
func _hold_to_swing() -> void:
	if hotbar.selected == Hotbar.Item.SWORD and not menu.is_open() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		use_item()

func _on_picked(kind: RunState.PickupKind, amount: int) -> void:
	match kind:
		RunState.PickupKind.BOW:
			notice("弓を手に入れた！\n3：持ちかえ　押して溜め、離して撃つ")
		RunState.PickupKind.ARROWS:
			notice("矢 ×%d" % amount, 1.5)
		RunState.PickupKind.POISON_ARROWS:
			notice("毒矢 ×%d\n（弓の技能「矢の種類」で使える）" % amount)
		RunState.PickupKind.SWORD:
			notice("剣を手に入れた！\n2：持ちかえ　クリック：振る")
		RunState.PickupKind.STRONG_BALL:
			notice("鉄球（ランク2）を手に入れた！\nTab：持ち物で選ぶ")

func use_heal() -> bool:
	if not run.inventory.try_use_heal(player.hp, player.max_hp):
		return false
	player.set_hp(mini(player.max_hp, player.hp + Inventory.HEAL_AMOUNT))
	return true

func open_inventory() -> bool:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return false
	menu.open()
	return true

func close_inventory() -> void:
	menu.close()

## カーソルが指している地面の点。
func _aim_point() -> Vector2:
	return camera.pick_ground(get_viewport().get_mouse_position(), map, MAX_HEIGHT)

## カーソルの方を向かせ、鉄球が落ちる点に印を出す。
func _update_aim() -> void:
	var playing := area_state.result == AreaState.Result.PLAYING and not is_switching()
	var target := IronBall.reach_point(player.mover.pos, _aim_point())
	if playing and target.distance_to(player.mover.pos) > 4.0:
		player.mover.facing = (target - player.mover.pos).normalized()
	var show := playing and hotbar.selected == Hotbar.Item.IRON_BALL \
		and ball.rules_ball.state == IronBall.State.HELD and IronBall.can_drop_at(target, map, player.mover.height)
	if playing and bow.charging:
		# 弓を溜めている間は、今離したら矢が落ちる点（届かなければ手前）
		target = Bow.landing(player.mover.pos, player.mover.height, _aim_point(), bow.rate(), map)
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
	_grave_node = _marker(c, _grave_model(), 2)
	player.controllable = false

## 野営地のたき火から再開する。敵は復活しない（倒した敵は時間で戻る）。
func respawn() -> void:
	enter_area(run.checkpoint_area, Continent.START_CELL)
	_sync_ball_rank()  # ランク2以上の鉄球は墓石に入っているので、ランク1に戻る
	player.set_hp(player.max_hp)
	player.clear_invulnerable()
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
	run.open_door(ex.door_id)
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
	for c in ex.cells(area.size()):
		map.set_blocker(c, HeightMap.Blocker.DOOR)
		nodes.append(_marker(c, _door_model(), 1))
	_gate_nodes[ex.door_id] = nodes

func _add_arrows(ex: ExitDef) -> void:
	var model := Terrain.arrow_model(ex.outward())
	for c in ex.cells(area.size()):
		var s := _marker(c, model, 0)
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
		if playing and player.hp > 0 and b.hits(player.mover.pos, player.mover.height, BULLET_HIT_RADIUS):
			b.alive = false
			hurt_player(b.damage)
		if not b.alive or not map.in_bounds(HeightMap.world_to_cell(b.pos)):
			s.queue_free()
			_bullets.remove_at(i)
			continue
		s.world_pos = b.pos

func _on_enemy_shot(b: Bullet) -> void:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = b.pos
	s.base_height = b.height
	s.lift_px = 3
	s.draw_bias = 3
	s.sort_by_cell = true
	s.sort_map = map
	s.sort_radius = 2.0
	s.set_model(VoxelModel.sphere(2, Color("ffd23f")))
	s.refresh()
	_area_root.add_child(s)
	_bullets.append([b, s])

## 鉄球が着いた。ダメージは17章の式で、攻撃力（強い鉄球なら上乗せ）・落とした高さ・レベルで決まる。
func _on_ball_landed(land_pos: Vector2, _legacy_damage: int) -> void:
	if area_state.result != AreaState.Result.PLAYING:
		return  # 死んでいる間に着いた鉄球は何も壊さない（できたばかりの墓石を壊さないように）
	if run.grave != null and run.grave.area_id == area.id and IronBall.touches_cell(land_pos, run.grave.cell):
		_remove_grave_marker()  # 墓石のマスを空けてから中身を戻す（break_grave で grave が null になるため）
		run.break_grave()
	var damage := Damage.iron_ball(current_attack(), ball.rules_ball.fall_levels, run.stats.level)
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive and IronBall.hits(land_pos, ball.rules_ball.height, e.walker.pos, e.walker.height, IronBall.hit_radius(ball_rank)):
			e.walker.take_damage(damage)
			_popup(e.walker.pos, e.walker.height, damage, Color.WHITE)

func _remove_grave_marker() -> void:
	if run.grave != null and run.grave.area_id == area.id:
		map.set_blocker(run.grave.cell, HeightMap.Blocker.NONE)
	if _grave_node != null:
		_grave_node.queue_free()
		_grave_node = null

func _marker(cell: Vector2i, model: VoxelModel, bias: int) -> StackSprite:
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = HeightMap.cell_center(cell)
	s.base_height = map.get_height(cell)
	s.sort_by_cell = true
	s.draw_bias = bias
	s.set_model(model)
	s.refresh()
	_area_root.add_child(s)
	return s

## 墓石：遠くからでも見つけやすい、背の高い白っぽい石。
func _grave_model() -> VoxelModel:
	var m := VoxelModel.box(Vector3i(10, 6, 22), Color("d8d4e8"))
	for z in range(14, 18):
		for x in range(2, 8):
			m.set_voxel(Vector3i(x, 0, z), Color("6c5c9a"))
	for z in range(10, 21):
		m.set_voxel(Vector3i(4, 0, z), Color("6c5c9a"))
		m.set_voxel(Vector3i(5, 0, z), Color("6c5c9a"))
	return m

func _bonfire_model() -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(10, 10, 9)
	for y in 10:
		for x in 10:
			for z in 2:
				m.set_voxel(Vector3i(x, y, z), Color("5b3a22"))
	for z in range(2, 9):
		var r := 4 - z / 2
		for y in range(5 - r, 5 + r):
			for x in range(5 - r, 5 + r):
				m.set_voxel(Vector3i(x, y, z), Color("ff8c1a") if z < 6 else Color("ffd23f"))
	return m

func _door_model() -> VoxelModel:
	var m := VoxelModel.box(Vector3i(14, 14, 20), Color("7a5230"))
	for z in 20:
		for y in 14:
			m.set_voxel(Vector3i(6, y, z), Color("5b3a22"))
	return m

## 宝箱：茶色の箱に金色の帯。武器が入っている。
func _chest_model() -> VoxelModel:
	var m := VoxelModel.box(Vector3i(10, 7, 7), Color("8a5a2b"))
	for x in 10:
		for y in 7:
			m.set_voxel(Vector3i(x, y, 4), Color("ffd23f"))
	for z in 7:
		m.set_voxel(Vector3i(4, 6, z), Color("ffd23f"))
		m.set_voxel(Vector3i(5, 6, z), Color("ffd23f"))
	return m

func _pickup_model(kind: RunState.PickupKind) -> VoxelModel:
	match kind:
		RunState.PickupKind.MONEY:
			return VoxelModel.box(Vector3i(4, 4, 2), Color("ffd23f"))
		RunState.PickupKind.MATERIAL:
			return VoxelModel.box(Vector3i(4, 4, 4), Color("a0785a"))
		RunState.PickupKind.HEAL:
			return VoxelModel.box(Vector3i(4, 4, 5), Color("ff6fa8"))
		RunState.PickupKind.SWORD, RunState.PickupKind.BOW:
			return _chest_model()
		RunState.PickupKind.ARROWS, RunState.PickupKind.POISON_ARROWS:
			var m := VoxelModel.box(Vector3i(6, 2, 2), Color("e8d9b0"))
			var tip := Color("9be36b") if kind == RunState.PickupKind.POISON_ARROWS else Color("9aa0a8")
			for y in 2:
				m.set_voxel(Vector3i(5, y, 0), tip)
				m.set_voxel(Vector3i(5, y, 1), tip)
			return m
		_:
			return VoxelModel.sphere(4, Color("7a2230"))

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_status = UiText.label()
	_status.position = Vector2(4, 2)
	layer.add_child(_status)
	_message = UiText.label(true)
	_message.position = Vector2(0, 112)
	_message.size = Vector2(320, 40)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_message)
	_guide = UiText.label()
	_guide.position = Vector2(4, 166)
	_guide.modulate.a = 0.8
	_guide.text = "クリック:使う　1〜5:持ちかえ　Tab:持ち物　右ドラッグ:カメラ"
	layer.add_child(_guide)
	_popups = Control.new()
	_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_popups)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.size = Vector2(320, 180)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_update_ui()

func _update_ui() -> void:
	_status.text = status_text()
	_message.text = ui_message()

## 左上の2行。
func status_text() -> String:
	var inv := run.inventory
	var st := run.stats
	var text := "Lv%d　体力 %d/%d　経験 %d/%d　お金 %d　素材 %d" % [st.level, player.hp, player.max_hp, st.exp_in_level(), st.exp_level_span(), inv.money, inv.materials]
	if run.grave != null:
		text += "　墓石：%s" % world.area(run.grave.area_id).title
	return text + "\n" + hotbar_text()

## 手に持つアイテムの並び。持っている武器だけ出し、選んでいるものを [ ] で囲む。
func hotbar_text() -> String:
	var eq := run.inventory.equipment
	var parts: Array[String] = []
	for i in Hotbar.SLOTS.size():
		var item: Hotbar.Item = Hotbar.SLOTS[i]
		var name := ""
		if item == Hotbar.Item.HEAL:
			name = "回復×%d" % run.inventory.heals
		elif item == Hotbar.Item.IRON_BALL:
			name = InventoryMenu.weapon_label(Equipment.Slot.BALL, ball_rank)
		else:
			var slot: Equipment.Slot = Hotbar.WEAPON_SLOT[item]
			if eq.effective(slot) == 0:
				continue
			name = InventoryMenu.weapon_label(slot, eq.effective(slot))
			if item == Hotbar.Item.BOW:
				name += "(矢%d)" % _usable_arrows()
		var t := "%d %s" % [i + 1, name]
		parts.append("[%s]" % t if item == hotbar.selected else " %s " % t)
	return "".join(parts)

## 画面の真ん中に出す言葉。なければ空。
func ui_message() -> String:
	if area_state.result == AreaState.Result.DYING:
		return "やられた…\nたき火から やり直す"
	if _gate_here() != null:
		return "F：門を開ける"
	if _notice_time > 0.0:
		return _notice_text
	if _title_time > 0.0:
		return area.title
	if _grave_hint_time > 0.0:
		return "死んだ場所に墓石がある\n鉄球を落として壊すと、持ち物が戻る"
	if _start_hint_time > 0.0:
		return "WASD・矢印：移動\n地面の矢印の先へ歩くと、となりのエリアへ行ける"
	return ""

## `-- --screenshot=path.png` で数フレーム後に画面を保存して終了する（確認用）。
## `--area=hills` でエリア、`--player=x,y` で位置、`--angle=0.8` でカメラ角度。`--fps` で平均FPSを出す。
## `--offset=dx,dy` でプレイヤーをマスの中心からずらす。`--ball=dx,dy` で鉄球をプレイヤーからずらして地面に置く。
## `--inventory` でインベントリを開いた画面（`--inventory=stats` でステータスのページ）。`--exp=30` で経験値を足す。
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
			get_tree().create_timer(0.05).timeout.connect(open_inventory)
		elif a.begins_with("--exp="):
			run.stats.add_exp(int(a.trim_prefix("--exp=")))
			apply_stats()
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
