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
	ball.setup(player, map, rules, camera)
	camera.follow(player.mover.pos, player.mover.height * StackSprite.LEVEL_PX, 1.0)
	_title_time = 0.0  # 始めは名前より操作のヒントを出す

	_build_ui()
	menu = InventoryMenu.new()
	menu.setup(run)
	menu.close_requested.connect(close_inventory)
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
	_pickup_nodes.clear()
	_gate_nodes.clear()
	_arrows.clear()
	_grave_node = null
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
		e.setup(map, d[0], d[1], player, camera, d[2])
		e.walker.forbidden = safe
		e.shot.connect(_on_enemy_shot)
		e.melee_hit.connect(_on_melee_hit)
		e.walker.died.connect(_on_enemy_died.bind(area.id, i))
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

func _on_enemy_died(area_id: String, index: int) -> void:
	roster.kill(area_id, index)
	run.on_enemy_killed()

func _on_melee_hit() -> void:
	if area_state.result == AreaState.Result.PLAYING and not is_switching():
		player.take_hit()

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
	if not _warm_queue.is_empty() and not is_switching():
		Terrain.warm(_warm_queue, WARM_BUDGET_MS)
	if is_switching():
		_update_switch(delta)
	else:
		if area_state.update(delta):
			respawn()
		_step_bullets(delta)
		if area_state.result == AreaState.Result.PLAYING:
			if player.hp <= 0 or player.mover.fell:
				kill_player(player.mover.fell)
			else:
				_play_step()
		if area_state.is_falling():
			player.lift_px = maxf(-FALL_SINK_PX, player.lift_px - FALL_SINK_PX / AreaState.FALL_SECONDS * delta)
		elif area_state.result == AreaState.Result.DYING and player.mover.fell:
			player.modulate.a = 0.0
	_update_aim()
	camera.follow(player.mover.pos, player.mover.height * StackSprite.LEVEL_PX, delta)
	_title_time = maxf(0.0, _title_time - delta)
	_grave_hint_time = maxf(0.0, _grave_hint_time - delta)
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
	if run.is_near_checkpoint(area.id, c) and player.hp < Player.MAX_HP:
		player.set_hp(Player.MAX_HP)
	for e in enemies:
		if is_instance_valid(e) and EnemyKind.contact(e.kind) and e.walker.touches(player.mover.pos, player.mover.height):
			player.take_hit()
			break
	ball.rules_ball.try_pick_up(player.mover)
	if ball.rules_ball.state == IronBall.State.HELD:
		ball.rules_ball.set_strong(run.inventory.ball_is_strong())
	var ex := world.exit_through(area.id, c, player.mover.edge_push)
	if ex != null and (ex.door_id == "" or run.is_door_open(ex.door_id)):
		_start_switch(world.arrival(area.id, ex, c))

func _unhandled_input(event: InputEvent) -> void:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		use_item()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				hotbar.select_slot(1)
			KEY_2:
				hotbar.select_slot(2)
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
	match hotbar.selected:
		Hotbar.Item.IRON_BALL:
			return ball.rules_ball.drop_at(player.mover, map, _aim_point())
		Hotbar.Item.HEAL:
			return use_heal()
	return false

func use_heal() -> bool:
	if not run.inventory.try_use_heal(player.hp, Player.MAX_HP):
		return false
	player.set_hp(player.hp + 1)
	return true

func open_inventory() -> bool:
	if area_state.result != AreaState.Result.PLAYING or is_switching():
		return false
	menu.open()
	_message.text = ""
	get_tree().paused = true
	return true

func close_inventory() -> void:
	menu.close()
	get_tree().paused = false

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
	ball.rules_ball.set_strong(run.inventory.ball_is_strong())  # 強い鉄球は墓石に入っているので普通に戻る
	player.set_hp(Player.MAX_HP)
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
			player.take_hit()
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

func _on_ball_landed(land_pos: Vector2, damage: int) -> void:
	if area_state.result != AreaState.Result.PLAYING:
		return  # 死んでいる間に着いた鉄球は何も壊さない（できたばかりの墓石を壊さないように）
	if run.grave != null and run.grave.area_id == area.id and IronBall.touches_cell(land_pos, run.grave.cell):
		_remove_grave_marker()  # 墓石のマスを空けてから中身を戻す（break_grave で grave が null になるため）
		run.break_grave()
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive and IronBall.hits(land_pos, ball.rules_ball.height, e.walker.pos, e.walker.height):
			e.walker.take_damage(damage)

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

func _pickup_model(kind: RunState.PickupKind) -> VoxelModel:
	match kind:
		RunState.PickupKind.MONEY:
			return VoxelModel.box(Vector3i(4, 4, 2), Color("ffd23f"))
		RunState.PickupKind.MATERIAL:
			return VoxelModel.box(Vector3i(4, 4, 4), Color("a0785a"))
		RunState.PickupKind.HEAL:
			return VoxelModel.box(Vector3i(4, 4, 5), Color("ff6fa8"))
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
	_guide.text = "クリック:使う　1・2:持ちかえ　Tab:持ち物　右ドラッグ:カメラ"
	layer.add_child(_guide)
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
	var hearts := ""
	for i in Player.MAX_HP:
		hearts += "●" if i < player.hp else "○"
	var text := "体力 %s　お金 %d　素材 %d　経験 %d" % [hearts, inv.money, inv.materials, inv.exp]
	if run.grave != null:
		text += "　墓石：%s" % world.area(run.grave.area_id).title
	var ball_name := "鉄球（強い）" if ball.rules_ball.strong else "鉄球"
	var heal_name := "回復×%d" % inv.heals
	if hotbar.selected == Hotbar.Item.IRON_BALL:
		text += "\n[1 %s]　 2 %s" % [ball_name, heal_name]
	else:
		text += "\n 1 %s　[2 %s]" % [ball_name, heal_name]
	return text

## 画面の真ん中に出す言葉。なければ空。
func ui_message() -> String:
	if area_state.result == AreaState.Result.DYING:
		return "やられた…\nたき火から やり直す"
	if _gate_here() != null:
		return "F：門を開ける"
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
## `--inventory` でインベントリを開いた画面。
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
		elif a == "--inventory":
			get_tree().create_timer(0.05).timeout.connect(open_inventory)
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
