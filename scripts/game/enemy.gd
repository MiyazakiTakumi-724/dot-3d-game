class_name Enemy
extends StackSprite
## 敵の見た目。種類（EnemyKind）で動きが変わる。
## 撃つ敵は2秒ごとにプレイヤーへ弾を撃つ。敵2は近くのプレイヤーへ寄り、ためてから叩く（melee_hit）。

signal shot(bullet: Bullet)
signal melee_hit

const SHOOT_INTERVAL := 2.0
const SHOOT_RANGE := 140.0
const BULLET_SPEED := 80.0

var walker: EnemyWalker
var kind: EnemyKind.Kind = EnemyKind.Kind.WEAK
var melee := MeleeAttack.new()
var target: Player
## false なら撃たない（体当たりだけの敵）
var can_shoot := true
var level := 1
## 攻撃力（体当たり・叩く・弾のダメージのもと）
var attack := 1
var _cooldown := SHOOT_INTERVAL

func setup(map: HeightMap, start_cell: Vector2i, start_dir: Vector2, p: Player, cam: StackCamera, enemy_kind: EnemyKind.Kind = EnemyKind.Kind.WEAK, first_shot_delay: float = SHOOT_INTERVAL, enemy_level := 1) -> void:
	kind = enemy_kind
	level = enemy_level
	attack = EnemyKind.attack(kind, level)
	walker = EnemyWalker.new(map, start_cell, start_dir, EnemyKind.hp(kind, level), EnemyKind.climb(kind))
	can_shoot = EnemyKind.shoots(kind)
	target = p
	camera = cam
	draw_bias = 1
	sort_by_cell = true
	always_redraw = true  # 向きが変わる
	shadow_radius = 5.0
	_cooldown = first_shot_delay
	var m := VoxelModel.box(Vector3i(8, 8, 8), _body_color(kind))
	for x in 2:  # 目
		m.set_voxel(Vector3i(1 + x * 4, 7, 5), Color.WHITE)
		m.set_voxel(Vector3i(2 + x * 4, 7, 5), Color.WHITE)
	set_model(m)
	walker.died.connect(queue_free)

static func _body_color(k: EnemyKind.Kind) -> Color:
	match k:
		EnemyKind.Kind.MELEE:
			return Color("7d3c98")
		EnemyKind.Kind.SHOOTER:
			return Color("b9770e")
	return Color("c0392b")

func _sort_map() -> HeightMap:
	return walker.map if walker != null else null

func _process(delta: float) -> void:
	if kind == EnemyKind.Kind.MELEE and target.hp > 0:
		walker.chase(target.mover.pos, target.mover.height)
	walker.step(delta)
	if kind == EnemyKind.Kind.MELEE:
		if target.hp > 0 and melee.update(delta, walker.pos, walker.height, target.mover.pos, target.mover.height):
			melee_hit.emit()
		# ためている間は体を明るく光らせる（よけるための合図）
		self_modulate = Color(1.8, 1.8, 1.8) if melee.is_winding_up() else Color.WHITE
	if walker.is_poisoned() and not melee.is_winding_up():
		# 毒は緑、やけどは赤っぽく
		self_modulate = Color(1.4, 0.8, 0.6) if walker.is_burning() else Color(0.7, 1.3, 0.6)
	elif kind != EnemyKind.Kind.MELEE:
		self_modulate = Color.WHITE
	if can_shoot and target.hp > 0:
		_cooldown -= delta
		var to_player := target.mover.pos - walker.pos
		# 自分より高い所にいる相手は撃たない（下から上へは当たらない）
		if _cooldown <= 0.0 and to_player.length() <= SHOOT_RANGE and Damage.can_hit(walker.height, target.mover.height):
			_cooldown = SHOOT_INTERVAL
			# 相手の体へまっすぐ撃つ。高い所からなら下まで届き、下からだと崖に当たりやすい
			var b := Bullet.new()
			b.aim(walker.pos, walker.height, target.mover.pos, target.mover.height, BULLET_SPEED)
			b.damage = attack
			shot.emit(b)
	world_pos = walker.pos
	base_height = walker.height
	super._process(delta)

func _draw() -> void:
	if camera == null:
		return
	var face_angle := walker.dir.angle() - PI / 2
	_draw_shadow()
	for i in _layers.size():
		var t := _layers[i]
		draw_set_transform(Vector2(0, -i), face_angle - camera.angle, Vector2.ONE)
		draw_texture(t, -t.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 傷ついたら頭の上に体力のバーを出す
	if walker.alive and walker.hp < walker.max_hp:
		var y := -_layers.size() - 6.0
		draw_rect(Rect2(-6, y, 12, 2), Color(0.1, 0.05, 0.05))
		draw_rect(Rect2(-6, y, 12.0 * walker.hp / walker.max_hp, 2), Color("e74c3c"))
