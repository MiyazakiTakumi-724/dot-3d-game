extends Node2D
## 試作2「死と取り返しの流れ」のエリア。死んでもシーンを読み込み直さず、中身を戻してチェックポイントから再開する。
## 操作：矢印/WASD 移動、左クリック 手に持つアイテムを使う（カーソルの方向）、1/2 手に持つアイテムを選ぶ、
## Tab インベントリ（使う鉄球を決める）、F 門を開ける、右ドラッグ or Q/E カメラ回転。鉄球は上を歩いて拾う。

## 数字 = 高さ（段）、R = 岩、T = 木、~ = 水、= = 橋、_ = 奈落、C = チェックポイント、D = 門、G = ゴール
## 海に囲まれた島。左下のたき火の草地から、南の川（橋が交互）→ 東の台地 → 北の裂け目（奈落）→ 西の森と、
## 外回りに1周する。西の森の下の門を開けると、たき火の草地へすぐ戻れる。ゴールは中央の島（西の橋から入る）の東の高台。
const LAYOUT := [
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~TT00TT0T0T0T00000000000000000R000000000000T00T00TTT000TT0T00~~",
	"~~T0000000000000000000___00000000___0000_000000000000000000000~~",
	"~~00000000000000000000___________________000000000000000000000~~",
	"~~TTTTTTTTTT0000000000___________________000000000000000000000~~",
	"~~TTTTTTTTTT0000000000___________________00000000000000000000T~~",
	"~~TTTTTTTTTT0000000000___________________000000000000000000000~~",
	"~~00000000000000000000_______0000_0000___000000000000000000000~~",
	"~~000000000000000000000000000000000000000000000000000000000000~~",
	"~~00000000000000~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~00000000000000~~",
	"~~00000000000000~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~0000000000000T~~",
	"~~0000TTTTTTTTTT~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR~~TTTTT000000000~~",
	"~~0000TTTTTTTTTT~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR~~TTTTT000000000~~",
	"~~T000TTTTTTTTTT~~000000000000RRR00000000003G3~~00003333332100~~",
	"~~00000000000000~~000000000000RRR0000000000333~~00003333332100~~",
	"~~TTTTTTTTTT0000~~0000RRR00000RRR0000000000333~~00003333332100~~",
	"~~TTTTTTTTTT0000~~0000RRR00000RRR0000RRR000333~~00003333332100~~",
	"~~00000000000000~~0000RRR00000RRR0000RRR000333~~01233333332100~~",
	"~~T000TTTTTTTTTT~~0000RRR00000RRR0000RRR000333~~01233333332100~~",
	"~~T000TTTTTTTTTT~~0000RRR00000RRR0000RRR000333~~01233333332100~~",
	"~~T000TTTTTTTTTT~~0000RRR00000RRR0000RRR000333~~00003333332100~~",
	"~~00000000000000~~0000RRR00000RRR0000RRR123333~~00003333332100~~",
	"~~00000000000000~~0000RRR000000000000RRR123333~~00003333332100~~",
	"~~00000000000000==0000RRR000000000000RRR123333~~00003333332100~~",
	"~~00000000000000~~0000RRR000000000000RRR000333~~00RRRRR00RRRRR~~",
	"~~00000000000000~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR~~00RRRRR00RRRRR~~",
	"~~T0000000000000~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR~~0000000000000T~~",
	"~~T0000000000000~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~00000000000000~~",
	"~~RRRRRRDRRRRRRR~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~0000000000000T~~",
	"~~00000000000000TT0000~~000000~~0000000000~~000000000000000000~~",
	"~~T0000000000000TT0000==000000~~0000000000==00000000000000000T~~",
	"~~00000000000000TT0000~~000000~~0000000000~~00000000000000000T~~",
	"~~000C0000000000TT0000~~000000~~0RRRRRRR00~~000000000000000000~~",
	"~~00000000000000TT0000~~000000~~0RRRRRRR00~~000000000000000000~~",
	"~~00000000000000T00000~~000000~~0000000000~~00000000000000000T~~",
	"~~00000000000000000000~~000000==0000000000~~000000000000000000~~",
	"~~000T0000000T0T0T0TT0~~0TT000~~0TT0T000T0~~TT00000T00T0T000T0~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
]
const PLAYER_START := Vector2i(6, 33)
## ゴールは高台の上にあるので、その高さにする（地図の記号 G は高さ0として読まれるため）
const GOAL_HEIGHT := 3
## [開始マス, 向き, 最初に撃つまでの秒数]
const ENEMIES := [
	[Vector2i(26, 32), Vector2.DOWN, 1.6],
	[Vector2i(36, 31), Vector2.RIGHT, 2.0],
	[Vector2i(36, 36), Vector2.LEFT, 2.4],
	[Vector2i(52, 33), Vector2.RIGHT, 1.8],
	[Vector2i(60, 16), Vector2.DOWN, 2.2],
	[Vector2i(50, 15), Vector2.DOWN, 1.5],
	[Vector2i(55, 20), Vector2.DOWN, 2.6],
	[Vector2i(45, 5), Vector2.LEFT, 1.7],
	[Vector2i(15, 4), Vector2.DOWN, 2.1],
	[Vector2i(26, 2), Vector2.RIGHT, 2.5],
	[Vector2i(8, 10), Vector2.RIGHT, 1.9],
	[Vector2i(4, 15), Vector2.RIGHT, 2.3],
	[Vector2i(13, 18), Vector2.LEFT, 1.4],
	[Vector2i(27, 20), Vector2.DOWN, 2.0],
	[Vector2i(34, 24), Vector2.UP, 1.6],
	[Vector2i(41, 16), Vector2.DOWN, 2.2],
]
## [マス, 種類, 量]。配列の添字を拾い済みの判定に使う。
const PICKUPS := [
	[Vector2i(10, 31), RunState.PickupKind.MONEY, 5],
	[Vector2i(27, 36), RunState.PickupKind.MONEY, 10],
	[Vector2i(50, 35), RunState.PickupKind.MONEY, 10],
	[Vector2i(58, 6), RunState.PickupKind.MONEY, 15],
	[Vector2i(5, 22), RunState.PickupKind.MONEY, 15],
	[Vector2i(20, 20), RunState.PickupKind.MONEY, 20],
	[Vector2i(40, 34), RunState.PickupKind.MATERIAL, 1],
	[Vector2i(55, 15), RunState.PickupKind.MATERIAL, 1],
	[Vector2i(44, 24), RunState.PickupKind.MATERIAL, 1],
	[Vector2i(45, 30), RunState.PickupKind.HEAL, 1],
	[Vector2i(50, 8), RunState.PickupKind.HEAL, 1],
	[Vector2i(14, 10), RunState.PickupKind.HEAL, 1],
	[Vector2i(35, 15), RunState.PickupKind.HEAL, 1],
	[Vector2i(4, 26), RunState.PickupKind.STRONG_BALL, 0],
]
## 門を開けるときに立つ奥側のマス。Terrain.parse が返す doors と同じ順。
const DOOR_OPEN_FROM := [Vector2i(8, 28)]

const BULLET_HIT_RADIUS := 6.0
const FALL_SINK_PX := 40.0  ## 奈落に落ちる演出で沈む量（0.5秒で）

var map: HeightMap
var rules := MovementRules.new()
var run: RunState
var area_state := AreaState.new()
var hotbar := Hotbar.new()
var menu: InventoryMenu
## 鉄球が落ちるマスに出す、地面の影のような印
var aim_marker: StackSprite
var camera: StackCamera
var player: Player
var ball: Ball
var enemies: Array[Enemy] = []
var checkpoint: Vector2i
var goal: Vector2i
var doors: Array = []
var _bullets: Array = []  # [Bullet, StackSprite]
var _pickup_nodes := {}   # 拾えるものの id → StackSprite
var _door_nodes: Array = []
var _grave_node: StackSprite
var _world: Node2D
var _label: Label

func _ready() -> void:
	map = HeightMap.new(Vector2i(LAYOUT[0].length(), LAYOUT.size()))
	var info := Terrain.parse(LAYOUT, map)
	checkpoint = info["checkpoint"]
	goal = info["goal"]
	map.set_height(goal, GOAL_HEIGHT)
	doors = info["doors"]
	run = RunState.new(checkpoint)
	camera = StackCamera.new()
	add_child(camera)
	_world = Node2D.new()
	add_child(_world)
	Terrain.build(map, camera, _world, info["deco"])
	RenderingServer.set_default_clear_color(Terrain.SEA_COLOR)
	_build_markers()

	player = Player.new()
	player.setup(map, rules, PLAYER_START, camera)
	_world.add_child(player)

	ball = Ball.new()
	ball.setup(player, map, rules, camera)
	ball.rules_ball.landed.connect(_on_ball_landed)
	_world.add_child(ball)

	aim_marker = _marker(PLAYER_START, _aim_model(), 1)
	aim_marker.force_hidden = true

	_spawn_enemies()
	_build_ui()
	menu = InventoryMenu.new()
	menu.setup(run)
	menu.close_requested.connect(close_inventory)
	add_child(menu)
	_maybe_screenshot()

func _process(delta: float) -> void:
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
	camera.focus = player.mover.pos
	_update_ui()

## 遊んでいる間の毎フレームの処理：拾う、チェックポイントで回復、ゴール、キー操作。
func _play_step() -> void:
	var c := player.mover.cell()
	for i in PICKUPS.size():
		var p = PICKUPS[i]
		if p[0] == c and run.collect(i, p[1], p[2]):
			_pickup_nodes[i].queue_free()
			_pickup_nodes.erase(i)
	if run.is_near_checkpoint(c) and player.hp < Player.MAX_HP:
		player.set_hp(Player.MAX_HP)
	if c == goal:
		area_state.on_goal()
	# 落とした鉄球は上を歩くだけで拾う
	ball.rules_ball.try_pick_up(player.mover)
	# インベントリで決めた鉄球は、手に持っているときに反映する
	if ball.rules_ball.state == IronBall.State.HELD:
		ball.rules_ball.set_strong(run.inventory.ball_is_strong())

func _unhandled_input(event: InputEvent) -> void:
	if area_state.result != AreaState.Result.PLAYING:
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

## 手に持っているアイテムを使う（左クリック）。鉄球ならカーソルの方向の目の前に落とす。
func use_item() -> bool:
	if area_state.result != AreaState.Result.PLAYING or not player.controllable:
		return false
	match hotbar.selected:
		Hotbar.Item.IRON_BALL:
			return ball.rules_ball.drop(player.mover, map)
		Hotbar.Item.HEAL:
			return use_heal()
	return false

func open_inventory() -> bool:
	if area_state.result != AreaState.Result.PLAYING:
		return false
	menu.open()
	get_tree().paused = true
	return true

func close_inventory() -> void:
	menu.close()
	get_tree().paused = false

## カーソルの方を向かせ、鉄球が落ちるマスに印を出す。
func _update_aim() -> void:
	var playing := area_state.result == AreaState.Result.PLAYING
	if playing:
		player.aim_screen = get_viewport().get_mouse_position()
	else:
		player.aim_screen = null
	var target := player.mover.front_cell()
	var show := playing and hotbar.selected == Hotbar.Item.IRON_BALL \
		and ball.rules_ball.state == IronBall.State.HELD and IronBall.can_drop_at(target, map)
	aim_marker.force_hidden = not show
	if show:
		aim_marker.world_pos = HeightMap.cell_center(target)
		aim_marker.base_height = map.get_height(target)

## 死亡処理を始める。墓石を置き（古い墓石は消える）、操作を止める。
func kill_player(fell: bool) -> void:
	if not area_state.on_player_died(fell):
		return
	var c := player.mover.last_safe_cell if fell else player.mover.cell()
	_remove_grave_marker()
	run.on_death(c)
	map.set_blocker(c, HeightMap.Blocker.GRAVE)
	_grave_node = _marker(c, _grave_model(), 2)
	player.controllable = false

## チェックポイントから再開する。敵は全員復活し、飛んでいる弾は消える。
## 拾い済みのもの・開けた扉・墓石はそのまま。
func respawn() -> void:
	for e in enemies:
		if is_instance_valid(e):
			# queue_free した敵も、このフレームの残りで _process が走って弾を撃てるので、先に切り離す
			e.shot.disconnect(_on_enemy_shot)
			e.set_process(false)
			e.queue_free()
	enemies.clear()
	_spawn_enemies()
	for b in _bullets:
		b[1].queue_free()
	_bullets.clear()
	ball.rules_ball.return_to_hand()
	ball.rules_ball.set_strong(run.inventory.ball_is_strong())  # 強い鉄球は墓石に入っているので普通に戻る
	player.mover.place(PLAYER_START)
	player.set_hp(Player.MAX_HP)
	player.lift_px = 0.0
	player.modulate.a = 1.0
	player.controllable = true

## 門の奥側の前のマス（DOOR_OPEN_FROM）に立っていれば、向きに関係なく開ける。開けたら true。
func try_open_door() -> bool:
	for i in doors.size():
		if run.is_door_open(i):
			continue
		if player.mover.cell() == DOOR_OPEN_FROM[i]:
			run.open_door(i)
			map.set_blocker(doors[i], HeightMap.Blocker.NONE)
			_door_nodes[i].queue_free()
			return true
	return false

func _can_open_door_here() -> bool:
	for i in doors.size():
		if not run.is_door_open(i) and player.mover.cell() == DOOR_OPEN_FROM[i]:
			return true
	return false

func use_heal() -> bool:
	if not run.inventory.try_use_heal(player.hp, Player.MAX_HP):
		return false
	player.set_hp(player.hp + 1)
	return true

func _spawn_enemies() -> void:
	for e in ENEMIES:
		var enemy := Enemy.new()
		enemy.setup(map, e[0], e[1], player, camera, e[2])
		enemy.shot.connect(_on_enemy_shot)
		enemy.walker.died.connect(run.on_enemy_killed)
		_world.add_child(enemy)
		enemies.append(enemy)

func _step_bullets(delta: float) -> void:
	for i in range(_bullets.size() - 1, -1, -1):
		var b: Bullet = _bullets[i][0]
		var s: StackSprite = _bullets[i][1]
		b.step(delta, map)
		var playing := area_state.result == AreaState.Result.PLAYING
		if b.alive and playing and player.hp > 0 and b.pos.distance_to(player.mover.pos) < BULLET_HIT_RADIUS:
			b.alive = false
			player.take_hit()
		if not b.alive or not map.in_bounds(HeightMap.world_to_cell(b.pos)):
			s.queue_free()
			_bullets.remove_at(i)
			continue
		s.world_pos = b.pos

func _on_enemy_shot(b: Bullet) -> void:
	if area_state.result != AreaState.Result.PLAYING:
		return
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = b.pos
	s.base_height = b.height
	s.lift_px = 3
	s.draw_bias = 3
	s.sort_by_cell = true
	s.set_model(VoxelModel.sphere(2, Color("ffd23f")))
	s.refresh()  # 最初のフレームから弾の位置に出す
	_world.add_child(s)
	_bullets.append([b, s])

func _on_ball_landed(cell: Vector2i, damage: int) -> void:
	if map.is_grave(cell):
		_remove_grave_marker()  # 墓石のマスを空けてから中身を戻す（break_grave で grave が null になるため）
		run.break_grave()
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive and e.walker.cell() == cell and e.walker.height == ball.rules_ball.height:
			e.walker.take_damage(damage)

func _remove_grave_marker() -> void:
	if run.grave != null:
		map.set_blocker(run.grave.cell, HeightMap.Blocker.NONE)
	if _grave_node != null:
		_grave_node.queue_free()
		_grave_node = null

## チェックポイント（たき火）、ゴール（旗）、扉、拾えるものを置く。
func _build_markers() -> void:
	_marker(checkpoint, _bonfire_model(), 1)
	_marker(goal, _flag_model(), 1)
	for d in doors:
		_door_nodes.append(_marker(d, _door_model(), 1))
	for i in PICKUPS.size():
		var p = PICKUPS[i]
		_pickup_nodes[i] = _marker(p[0], _pickup_model(p[1]), 1)

func _marker(cell: Vector2i, model: VoxelModel, bias: int) -> StackSprite:
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = HeightMap.cell_center(cell)
	s.base_height = map.get_height(cell)
	s.sort_by_cell = true
	s.draw_bias = bias
	s.set_model(model)
	s.refresh()
	_world.add_child(s)
	return s

func _aim_model() -> VoxelModel:
	return VoxelModel.box(Vector3i(14, 14, 1), Color(0, 0, 0, 0.35))

## 墓石：遠くからでも見つけやすい、背の高い白っぽい石。
func _grave_model() -> VoxelModel:
	var m := VoxelModel.box(Vector3i(10, 6, 22), Color("d8d4e8"))
	for z in range(14, 18):  # 十字の横棒
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

func _flag_model() -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(8, 2, 24)
	for z in 24:
		m.set_voxel(Vector3i(0, 0, z), Color("e0e0e0"))
	for z in range(16, 24):
		for x in range(1, 8):
			m.set_voxel(Vector3i(x, 0, z), Color("3fbf5f"))
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
	_label = Label.new()
	_label.position = Vector2(4, 2)
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 2)
	layer.add_child(_label)
	_update_ui()

func _update_ui() -> void:
	var inv := run.inventory
	var text := "HP %d   MONEY %d   MAT %d   HEAL %d   EXP %d\n" % [player.hp, inv.money, inv.materials, inv.heals, inv.exp]
	var ball_name := "BALL:STRONG" if ball.rules_ball.strong else "BALL:NORMAL"
	var heal_name := "HEAL x%d" % inv.heals
	if hotbar.selected == Hotbar.Item.IRON_BALL:
		text += "[1 %s]   2 %s\n" % [ball_name, heal_name]
	else:
		text += " 1 %s   [2 %s]\n" % [ball_name, heal_name]
	text += "CLICK: use  1/2: hold  TAB: inventory  F: gate  R-DRAG/QE: camera"
	if area_state.result == AreaState.Result.PLAYING and _can_open_door_here():
		text += "\n\nF: open the gate"
	match area_state.result:
		AreaState.Result.DYING:
			text += "\n\nYOU DIED"
		AreaState.Result.CLEAR:
			text += "\n\nCLEAR!"
	_label.text = text

## `-- --screenshot=path.png` で数フレーム後に画面を保存して終了する（確認用）。
## `--angle=0.8` でカメラ角度、`--player=x,y` でプレイヤー位置を変えられる。`--fps` で平均FPSを出す。`--inventory` でインベントリを開いた画面。
func _maybe_screenshot() -> void:
	var path := ""
	var measure_fps := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screenshot="):
			path = a.trim_prefix("--screenshot=")
		elif a.begins_with("--angle="):
			camera.angle = float(a.trim_prefix("--angle="))
		elif a.begins_with("--player="):
			var p := a.trim_prefix("--player=").split(",")
			player.mover.place(Vector2i(int(p[0]), int(p[1])))
		elif a == "--fps":
			measure_fps = true
		elif a == "--inventory":
			open_inventory.call_deferred()
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
