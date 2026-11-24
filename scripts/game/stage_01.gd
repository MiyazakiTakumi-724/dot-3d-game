extends Node2D
## 鉄球の試作ステージ。地形・プレイヤー・敵・鉄球はすべてコードで作った形で描く。
## 操作：矢印/WASD 移動、マウスのボタンを押したまま左右に動かす or Q/E でカメラ回転、X 鉄球を落とす、Z 拾う、R やり直し

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
var _x_was_down := false
var _z_was_down := false

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
		enemy.setup(map, e[0], e[1], player, camera, EnemyKind.Kind.SHOOTER, e[2])
		enemy.walker.hp = EnemyWalker.MAX_HP  # 試作1の敵は体力3のまま
		enemy.shot.connect(_on_enemy_shot)
		enemy.walker.died.connect(_on_enemy_died)
		_world.add_child(enemy)
		enemies.append(enemy)
	state = StageState.new(enemies.size())
	_build_ui()
	_maybe_screenshot()

func _build_map() -> void:
	map = HeightMap.new(Vector2i(LAYOUT[0].length(), LAYOUT.size()))
	Terrain.parse(LAYOUT, map)

func _build_terrain() -> void:
	Terrain.build(map, camera, _world)
	Terrain.add_background(self)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = UiText.label()
	_label.position = Vector2(4, 2)
	layer.add_child(_label)
	_update_ui()

func _update_ui() -> void:
	var text := "体力 %d　　残りの敵 %d\n矢印:移動　X:鉄球を落とす　Z:拾う　右ドラッグ/Q・E:カメラ" % [player.hp, state.enemies_left]
	match state.result:
		StageState.Result.CLEAR:
			text += "\n\nクリア！　R:もう一度"
		StageState.Result.GAME_OVER:
			text += "\n\nやられた…　R:もう一度"
	_label.text = text

func _process(delta: float) -> void:
	_read_ball_keys()
	camera.follow(player.mover.pos, player.mover.height * StackSprite.LEVEL_PX, delta)
	_step_bullets(delta)
	if Input.is_physical_key_pressed(KEY_R) and state.result != StageState.Result.PLAYING:
		get_tree().reload_current_scene()

## X で鉄球を落とす、Z で拾う（試作1の操作）。
func _read_ball_keys() -> void:
	var x_down := Input.is_physical_key_pressed(KEY_X)
	var z_down := Input.is_physical_key_pressed(KEY_Z)
	if player.hp > 0:
		if x_down and not _x_was_down:
			ball.rules_ball.drop_at(player.mover, map, HeightMap.cell_center(player.mover.front_cell()))
		if z_down and not _z_was_down:
			ball.rules_ball.try_pick_up(player.mover)
	_x_was_down = x_down
	_z_was_down = z_down

func _step_bullets(delta: float) -> void:
	for i in range(_bullets.size() - 1, -1, -1):
		var b: Bullet = _bullets[i][0]
		var s: StackSprite = _bullets[i][1]
		b.step(delta, map)
		if player.hp > 0 and b.hits(player.mover.pos, player.mover.height, BULLET_HIT_RADIUS):
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
	s.sort_by_cell = true
	s.set_model(VoxelModel.sphere(2, Color("ffd23f")))
	s.refresh()  # 最初のフレームから弾の位置に出す
	_world.add_child(s)
	_bullets.append([b, s])

func _on_ball_landed(land_pos: Vector2, damage: int) -> void:
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive and IronBall.hits(land_pos, ball.rules_ball.height, e.walker.pos, e.walker.height):
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
