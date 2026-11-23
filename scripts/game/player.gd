class_name Player
extends StackSprite
## プレイヤー。矢印キー / WASD で移動（画面基準）。

signal hp_changed(hp: int)

const SPEED := 60.0
const MAX_HP := 3

var mover: PlayerMover
var hp: int = MAX_HP
## false の間は動かせない（死亡処理中など）。
var controllable := true

func setup(map: HeightMap, rules: MovementRules, start_cell: Vector2i, cam: StackCamera) -> void:
	mover = PlayerMover.new(map, rules)
	mover.place(start_cell)
	camera = cam
	draw_bias = 2
	sort_by_cell = true
	var m := VoxelModel.box(Vector3i(6, 6, 10), Color("3b6dd8"))
	for y in 2:  # 顔の向きが分かるように前側に目印
		for x in 2:
			m.set_voxel(Vector3i(2 + x, 5, 7 + y), Color("f4e1c1"))
	set_model(m)
	_sync()

func take_hit() -> void:
	if hp <= 0:
		return
	hp -= 1
	hp_changed.emit(hp)

func set_hp(v: int) -> void:
	hp = v
	hp_changed.emit(hp)

func _process(delta: float) -> void:
	if hp > 0 and controllable:
		var dir := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A): dir.x -= 1
		if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D): dir.x += 1
		if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W): dir.y -= 1
		if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S): dir.y += 1
		if dir != Vector2.ZERO:
			mover.move(camera.screen_dir_to_world(dir.normalized()) * SPEED * delta)
	_sync()
	super._process(delta)

func _sync() -> void:
	world_pos = mover.pos
	base_height = mover.height

func _draw() -> void:
	if camera == null:
		return
	# 向いている方向の目印が回るよう、モデルの「前」(+y) を facing に合わせる
	var face_angle := mover.facing.angle() - PI / 2
	for i in _layers.size():
		var t := _layers[i]
		draw_set_transform(Vector2(0, -i), face_angle - camera.angle, Vector2.ONE)
		draw_texture(t, -t.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
