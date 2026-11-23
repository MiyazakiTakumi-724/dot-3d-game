class_name Enemy
extends StackSprite
## 敵の見た目。平らな所を往復し、2秒ごとにプレイヤーへ弾を撃つ。

signal shot(bullet: Bullet)

const SHOOT_INTERVAL := 2.0
const SHOOT_RANGE := 140.0
const BULLET_SPEED := 80.0

var walker: EnemyWalker
var target: Player
var _cooldown := SHOOT_INTERVAL

func setup(map: HeightMap, start_cell: Vector2i, start_dir: Vector2, p: Player, cam: StackCamera, first_shot_delay: float) -> void:
	walker = EnemyWalker.new(map, start_cell, start_dir)
	target = p
	camera = cam
	draw_bias = 1
	sort_by_cell = true
	_cooldown = first_shot_delay
	var m := VoxelModel.box(Vector3i(8, 8, 8), Color("c0392b"))
	for x in 2:  # 目
		m.set_voxel(Vector3i(1 + x * 4, 7, 5), Color.WHITE)
		m.set_voxel(Vector3i(2 + x * 4, 7, 5), Color.WHITE)
	set_model(m)
	walker.died.connect(queue_free)

func _process(delta: float) -> void:
	walker.step(delta)
	if target.hp > 0:
		_cooldown -= delta
		var to_player := target.mover.pos - walker.pos
		if _cooldown <= 0.0 and to_player.length() <= SHOOT_RANGE:
			_cooldown = SHOOT_INTERVAL
			var b := Bullet.new()
			b.pos = walker.pos
			b.vel = to_player.normalized() * BULLET_SPEED
			b.height = walker.height
			shot.emit(b)
	world_pos = walker.pos
	base_height = walker.height
	super._process(delta)

func _draw() -> void:
	if camera == null:
		return
	var face_angle := walker.dir.angle() - PI / 2
	for i in _layers.size():
		var t := _layers[i]
		draw_set_transform(Vector2(0, -i), face_angle - camera.angle, Vector2.ONE)
		draw_texture(t, -t.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
