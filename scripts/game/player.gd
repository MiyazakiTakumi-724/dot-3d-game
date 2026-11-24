class_name Player
extends StackSprite
## プレイヤー。矢印キー / WASD で移動（画面基準）。

signal hp_changed(hp: int)

const SPEED := 60.0
const MAX_HP := 3
## ダメージを受けた後、次のダメージを受けない時間（秒）。この間は点滅する。
const INVULNERABLE_SECONDS := 1.0

var mover: PlayerMover
var hp: int = MAX_HP
## false の間は動かせない（死亡処理中など）。
var controllable := true
## マウスカーソルの画面上の位置。null でなければ、歩く向きとは別にいつもそちらを向く。
var aim_screen = null

var _invulnerable := 0.0

## カーソルが自分のマスの上にあるとき、向きを変えない範囲（画面px）
const AIM_DEAD_ZONE_PX := 6.0

func setup(map: HeightMap, rules: MovementRules, start_cell: Vector2i, cam: StackCamera) -> void:
	mover = PlayerMover.new(map, rules)
	mover.place(start_cell)
	camera = cam
	draw_bias = 2
	sort_by_cell = true
	always_redraw = true  # 向きが変わる
	shadow_radius = 4.0
	var m := VoxelModel.box(Vector3i(6, 6, 10), Color("3b6dd8"))
	for y in 2:  # 顔の向きが分かるように前側に目印
		for x in 2:
			m.set_voxel(Vector3i(2 + x, 5, 7 + y), Color("f4e1c1"))
	set_model(m)
	_sync()

## 1ダメージを受ける。無敵の間は受けない。受けたら true。
func take_hit() -> bool:
	if hp <= 0 or _invulnerable > 0.0:
		return false
	hp -= 1
	_invulnerable = INVULNERABLE_SECONDS
	hp_changed.emit(hp)
	return true

func is_invulnerable() -> bool:
	return _invulnerable > 0.0

func clear_invulnerable() -> void:
	_invulnerable = 0.0
	self_modulate.a = 1.0

## 画面上のカーソルに一番近い隣のマス（8方向）を向く。マスは高さも含めて画面に置いて比べるので、
## 高台から下のマスを指しても斜めにずれない。カーソルが自分のマスの上にあるときは向きを変えない。
func aim_at_screen(screen: Vector2) -> void:
	var here := mover.cell()
	if screen.distance_to(_cell_on_screen(here)) < AIM_DEAD_ZONE_PX:
		return
	var best := here
	var best_d := INF
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var n: Vector2i = here + Vector2i(dx, dy)
			var d := screen.distance_to(_cell_on_screen(n))
			if d < best_d:
				best_d = d
				best = n
	mover.facing = Vector2(best - here).normalized()

func _cell_on_screen(c: Vector2i) -> Vector2:
	return camera.world_to_screen(HeightMap.cell_center(c), mover.map.get_height(c) * LEVEL_PX)

func set_hp(v: int) -> void:
	hp = v
	hp_changed.emit(hp)

func _sort_map() -> HeightMap:
	return mover.map if mover != null else null

func _process(delta: float) -> void:
	if _invulnerable > 0.0:
		_invulnerable = maxf(0.0, _invulnerable - delta)
		# 0.1秒ごとに薄くして点滅させる
		self_modulate.a = 0.35 if int(_invulnerable * 10.0) % 2 == 1 else 1.0
	if hp > 0 and controllable:
		var dir := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A): dir.x -= 1
		if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D): dir.x += 1
		if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W): dir.y -= 1
		if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S): dir.y += 1
		if dir != Vector2.ZERO:
			mover.move(camera.screen_dir_to_world(dir.normalized()) * SPEED * delta)
		if aim_screen != null:
			aim_at_screen(aim_screen)
	_sync()
	super._process(delta)

func _sync() -> void:
	world_pos = mover.pos
	base_height = mover.height

func _draw() -> void:
	if camera == null:
		return
	_drawn_angle = camera.angle
	# 向いている方向の目印が回るよう、モデルの「前」(+y) を facing に合わせる
	var face_angle := mover.facing.angle() - PI / 2
	_draw_shadow()
	for i in _layers.size():
		var t := _layers[i]
		draw_set_transform(Vector2(0, -i), face_angle - camera.angle, Vector2.ONE)
		draw_texture(t, -t.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
