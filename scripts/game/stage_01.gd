extends Node2D
## 鉄球の試作ステージ。地形・プレイヤー・敵・鉄球はすべてコードで作った形で描く。
## 操作：矢印/WASD 移動、Q/E カメラ回転、X 鉄球を落とす、Z 拾う、R やり直し

## 数字 = 高さ（段）、# = 壁
const LAYOUT := [
	"0000000000000000",
	"0123333000000000",
	"0000333000#00000",
	"0000333000#00000",
	"0000000000000000",
	"00#0000000000#00",
	"0000000000000000",
	"0000000003333210",
	"000##00003333000",
	"0000000003333000",
	"0000000000000000",
	"0000000000000000",
]
const PLAYER_START := Vector2i(1, 11)
## [開始マス, 向き, 最初に撃つまでの秒数]
const ENEMIES := [
	[Vector2i(10, 4), Vector2.LEFT, 1.5],
	[Vector2i(4, 6), Vector2.RIGHT, 2.2],
	[Vector2i(12, 10), Vector2.LEFT, 2.9],
]
const LEVEL_COLORS := [Color("5f8f4e"), Color("7a9a55"), Color("98a85c"), Color("b5b063")]
const WALL_COLOR := Color("8a8f99")
const BULLET_HIT_RADIUS := 6.0

var map: HeightMap
var rules := MovementRules.new()
var state: StageState
var camera: StackCamera
var player: Player
var ball: Ball
var enemies: Array[Enemy] = []
var _bullets: Array = []  # [Bullet, StackSprite]
var _world: Node2D
var _label: Label

func _ready() -> void:
	_build_map()
	camera = StackCamera.new()
	add_child(camera)
	_world = Node2D.new()
	add_child(_world)
	_build_terrain()

	player = Player.new()
	player.setup(map, rules, PLAYER_START, camera)
	player.hp_changed.connect(_on_player_hp)
	_world.add_child(player)

	ball = Ball.new()
	ball.setup(player, map, rules, camera)
	ball.rules_ball.landed.connect(_on_ball_landed)
	_world.add_child(ball)

	for e in ENEMIES:
		var enemy := Enemy.new()
		enemy.setup(map, e[0], e[1], player, camera, e[2])
		enemy.shot.connect(_on_enemy_shot)
		enemy.walker.died.connect(_on_enemy_died)
		_world.add_child(enemy)
		enemies.append(enemy)
	state = StageState.new(enemies.size())
	_build_ui()
	_maybe_screenshot()

func _build_map() -> void:
	map = HeightMap.new(Vector2i(LAYOUT[0].length(), LAYOUT.size()))
	for y in LAYOUT.size():
		for x in LAYOUT[y].length():
			var ch: String = LAYOUT[y][x]
			if ch == "#":
				map.set_wall(Vector2i(x, y), true)
			else:
				map.set_height(Vector2i(x, y), int(ch))

func _build_terrain() -> void:
	var models := {}
	for y in map.size.y:
		for x in map.size.x:
			var cell := Vector2i(x, y)
			var key: String = "wall" if map.is_wall(cell) else str(map.get_height(cell))
			if not models.has(key):
				models[key] = _wall_model() if key == "wall" else _ground_model(int(key))
			var s := StackSprite.new()
			s.camera = camera
			s.world_pos = HeightMap.cell_center(cell)
			s.set_model(models[key])
			_world.add_child(s)

func _ground_model(h: int) -> VoxelModel:
	var layers := maxi(1, h * StackSprite.LEVEL_PX)
	var top: Color = LEVEL_COLORS[clampi(h, 0, LEVEL_COLORS.size() - 1)]
	var m := VoxelModel.new()
	m.size = Vector3i(16, 16, layers)
	for z in layers:
		var c := top if z == layers - 1 else Color("6b5a45").lightened(0.03 * (z % 8))
		for yy in 16:
			for xx in 16:
				# 上面の縁を少し暗くしてマスの区切りを見せる
				var edge := xx == 0 or yy == 0 or xx == 15 or yy == 15
				m.set_voxel(Vector3i(xx, yy, z), c.darkened(0.12) if edge and z == layers - 1 else c)
	return m

func _wall_model() -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(14, 14, 20)
	for z in 20:
		for yy in 14:
			for xx in 14:
				var brick := (z % 5 == 0) or ((xx + (z / 5) * 4) % 7 == 0)
				m.set_voxel(Vector3i(xx, yy, z), WALL_COLOR.darkened(0.15) if brick else WALL_COLOR)
	return m

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
	var text := "HP %d   ENEMIES %d\nMOVE: arrows  CAMERA: Q/E  DROP: X  PICK UP: Z" % [player.hp, state.enemies_left]
	match state.result:
		StageState.Result.CLEAR:
			text += "\n\nCLEAR!   R: retry"
		StageState.Result.GAME_OVER:
			text += "\n\nGAME OVER   R: retry"
	_label.text = text

func _process(delta: float) -> void:
	camera.focus = player.mover.pos
	_step_bullets(delta)
	if Input.is_physical_key_pressed(KEY_R) and state.result != StageState.Result.PLAYING:
		get_tree().reload_current_scene()

func _step_bullets(delta: float) -> void:
	for i in range(_bullets.size() - 1, -1, -1):
		var b: Bullet = _bullets[i][0]
		var s: StackSprite = _bullets[i][1]
		b.step(delta, map)
		if b.alive and player.hp > 0 and b.pos.distance_to(player.mover.pos) < BULLET_HIT_RADIUS:
			b.alive = false
			player.take_hit()
		if not b.alive or not map.in_bounds(HeightMap.world_to_cell(b.pos)):
			s.queue_free()
			_bullets.remove_at(i)
			continue
		s.world_pos = b.pos

func _on_enemy_shot(b: Bullet) -> void:
	if state.result != StageState.Result.PLAYING:
		return
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = b.pos
	s.base_height = b.height
	s.lift_px = 3
	s.draw_bias = 3
	s.set_model(VoxelModel.sphere(2, Color("ffd23f")))
	_world.add_child(s)
	_bullets.append([b, s])

func _on_ball_landed(cell: Vector2i, damage: int) -> void:
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive and e.walker.cell() == cell and e.walker.height == ball.rules_ball.height:
			e.walker.take_damage(damage)

func _on_enemy_died() -> void:
	state.on_enemy_died()
	_update_ui()

func _on_player_hp(hp: int) -> void:
	state.on_player_hp(hp)
	_update_ui()

## `-- --screenshot=path.png` で数フレーム後に画面を保存して終了する（確認用）。
## `--angle=0.8` でカメラ角度、`--player=x,y` でプレイヤー位置を変えられる。
func _maybe_screenshot() -> void:
	var path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screenshot="):
			path = a.trim_prefix("--screenshot=")
		elif a.begins_with("--angle="):
			camera.angle = float(a.trim_prefix("--angle="))
		elif a.begins_with("--player="):
			var p := a.trim_prefix("--player=").split(",")
			var c := Vector2i(int(p[0]), int(p[1]))
			player.mover.pos = HeightMap.cell_center(c)
			player.mover.height = map.get_height(c)
	if path == "":
		return
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
