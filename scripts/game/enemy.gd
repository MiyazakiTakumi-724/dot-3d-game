class_name Enemy
extends StackSprite
## 敵の見た目と動き。種類（EnemyKind）で動きが変わる（設計 2026-11-25 の4章）。
## スライム：往復して体当たり。ゴブリン・盾持ち：寄って、ためて叩く（melee_hit）。射手：2秒ごとに撃つ（shot）。
## 影：体が見えず、地面の影だけ。コウモリ：飛んで、段差・水・奈落を越えて寄る。イノシシ：縦か横に並ぶと、ためて突進。
## 火の玉：寄って、そばでためて弾ける（exploded）。亡霊：足音を聞いて遠くから寄る（しゃがむと気づかれにくい）。

signal shot(bullet: Bullet)
signal melee_hit
## 火の玉が弾けた（まわりにダメージ）
signal exploded(pos: Vector2, height: int)

const SHOOT_INTERVAL := 2.0
const SHOOT_RANGE := 140.0
const BULLET_SPEED := 80.0
## 飛ぶ敵が浮いている高さ（px）
const FLY_LIFT := 10.0
## 火の玉がためる時間
const BOMB_FUSE := 0.6

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
## イノシシの突進：0 なし、1 ためている、2 走っている
var charge_phase := 0
var _charge_time := 0.0
var _charge_dir := Vector2.ZERO
## 火の玉がためている残り秒（負ならためていない）
var _fuse := -1.0
var _bob := 0.0
## 当たったときに少しの間だけ光る（影の敵は、この間だけ体が見える）
var _hit_flash := 0.0

func setup(map: HeightMap, start_cell: Vector2i, start_dir: Vector2, p: Player, cam: StackCamera, enemy_kind: EnemyKind.Kind = EnemyKind.Kind.WEAK, first_shot_delay: float = SHOOT_INTERVAL, enemy_level := 1) -> void:
	kind = enemy_kind
	level = enemy_level
	attack = EnemyKind.attack(kind, level)
	walker = EnemyWalker.new(map, start_cell, start_dir, EnemyKind.hp(kind, level), EnemyKind.climb(kind))
	walker.chase_range = EnemyKind.chase_range(kind)
	walker.speed_mult = EnemyKind.speed_mult(kind)
	walker.flying = EnemyKind.flies(kind)
	can_shoot = EnemyKind.shoots(kind)
	target = p
	camera = cam
	draw_bias = 1
	sort_by_cell = true
	always_redraw = true  # 向きが変わる
	shadow_radius = 5.0
	_cooldown = first_shot_delay
	set_model(model_for(kind))
	walker.died.connect(queue_free)

## 種類ごとの形（ゲームの座標で8px前後のボクセル）。前は +y。
static func model_for(k: EnemyKind.Kind) -> VoxelModel:
	var m: VoxelModel
	match k:
		EnemyKind.Kind.SHIELD:
			m = VoxelModel.box(Vector3i(8, 8, 9), Color("6b7280"))
			for x in 8:
				for z in range(1, 8):
					m.set_voxel(Vector3i(x, 7, z), Color("a1784a"))  # 前の盾
			m.set_voxel(Vector3i(3, 7, 5), Color("d9c27a"))
			m.set_voxel(Vector3i(4, 7, 5), Color("d9c27a"))
			return m
		EnemyKind.Kind.FLYER:
			m = VoxelModel.box(Vector3i(4, 4, 4), Color("4a3b5c"))
			var w := VoxelModel.new()
			w.size = Vector3i(12, 4, 4)
			for x in 12:
				for y in 4:
					w.set_voxel(Vector3i(x, y, 2), Color("3a2d4a") if x < 4 or x >= 8 else Color("4a3b5c"))
			for x in range(4, 8):
				for y in 4:
					for z in 4:
						w.set_voxel(Vector3i(x, y, z), Color("4a3b5c"))
			w.set_voxel(Vector3i(5, 3, 3), Color("ff5050"))
			w.set_voxel(Vector3i(6, 3, 3), Color("ff5050"))
			return w
		EnemyKind.Kind.CHARGER:
			m = VoxelModel.box(Vector3i(8, 11, 7), Color("7a5634"))
			for x in [1, 6]:
				m.set_voxel(Vector3i(x, 10, 2), Color("eee8d5"))  # きば
				m.set_voxel(Vector3i(x, 10, 3), Color("eee8d5"))
		EnemyKind.Kind.BOMBER:
			m = VoxelModel.box(Vector3i(7, 7, 7), Color("ff7a1a"))
			for x in range(2, 5):
				for y in range(2, 5):
					m.set_voxel(Vector3i(x, y, 6), Color("ffd34d"))
		EnemyKind.Kind.GHOST:
			m = VoxelModel.box(Vector3i(7, 7, 10), Color("c8cfe8"))
			for x in 7:
				for y in 7:
					if (x + y) % 2 == 0:
						m.voxels().erase(Vector3i(x, y, 0))  # すそを ぎざぎざに
		EnemyKind.Kind.SHADOW:
			m = VoxelModel.box(Vector3i(8, 8, 8), Color("1d1b26"))
		EnemyKind.Kind.MELEE:
			m = VoxelModel.box(Vector3i(8, 8, 8), Color("7d3c98"))
		EnemyKind.Kind.SHOOTER:
			m = VoxelModel.box(Vector3i(8, 8, 8), Color("b9770e"))
		_:
			m = VoxelModel.box(Vector3i(8, 8, 8), Color("c0392b"))
	var eye_y := m.size.y - 1
	var ez := mini(5, m.size.z - 2)
	for x in 2:  # 目
		m.set_voxel(Vector3i(1 + x * 4, eye_y, ez), Color.WHITE)
		m.set_voxel(Vector3i(2 + x * 4, eye_y, ez), Color.WHITE)
	return m

func _sort_map() -> HeightMap:
	return walker.map if walker != null else null

## 当たった（影の敵は少しの間だけ姿を見せる）。
func flash() -> void:
	_hit_flash = 0.25

## 盾が前から防ぐか（from は攻撃してきた所）。
func blocks(from: Vector2) -> bool:
	return EnemyKind.blocks(kind, walker.dir, walker.pos, from)

func _process(delta: float) -> void:
	_hit_flash = maxf(0.0, _hit_flash - delta)
	var alive_target := target.hp > 0
	if kind == EnemyKind.Kind.GHOST:
		walker.chase_range = EnemyKind.hearing(kind, target.crouching)
	if kind == EnemyKind.Kind.CHARGER:
		_update_charge(delta)
	elif _fuse >= 0.0:
		_fuse -= delta
		if _fuse < 0.0:
			exploded.emit(walker.pos, walker.height)
			walker.take_damage(walker.hp)
			return
	else:
		if alive_target and walker.chase_range > 0.0:
			walker.chase(target.mover.pos, target.mover.height)
		walker.step(delta)
	if kind == EnemyKind.Kind.BOMBER and _fuse < 0.0 and alive_target \
			and walker.pos.distance_to(target.mover.pos) < EnemyKind.BOMB_TRIGGER and absi(walker.height - target.mover.height) <= 1:
		_fuse = BOMB_FUSE
	if EnemyKind.melee(kind):
		if alive_target and melee.update(delta, walker.pos, walker.height, target.mover.pos, target.mover.height):
			melee_hit.emit()
	# ためている間は体を明るく光らせる（よけるための合図）。毒は緑、やけどは赤、遅いと青
	var winding := melee.is_winding_up() or charge_phase == 1 or (_fuse >= 0.0 and int(_fuse * 12.0) % 2 == 0)
	if winding or _hit_flash > 0.0:
		self_modulate = Color(1.8, 1.8, 1.8)
	elif walker.is_poisoned():
		self_modulate = Color(1.4, 0.8, 0.6) if walker.is_burning() else Color(0.7, 1.3, 0.6)
	elif walker.is_slowed():
		self_modulate = Color(0.7, 0.9, 1.5)
	else:
		self_modulate = Color.WHITE
	if kind == EnemyKind.Kind.GHOST:
		self_modulate.a = 0.7
	if can_shoot and alive_target:
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
	_bob += delta
	world_pos = walker.pos
	base_height = walker.height
	lift_px = FLY_LIFT + sin(_bob * 5.0) * 2.0 if walker.flying else 0.0
	super._process(delta)

## イノシシ：同じ高さで縦か横に並ぶと、ためてから、その向きへ速く走る。ぶつかるか時間で止まる。
func _update_charge(delta: float) -> void:
	match charge_phase:
		0:
			var d := target.mover.pos - walker.pos
			var lined := absf(d.x) < 6.0 or absf(d.y) < 6.0
			if target.hp > 0 and lined and d.length() < EnemyKind.CHARGE_RANGE and target.mover.height == walker.height:
				charge_phase = 1
				_charge_time = 0.0
				_charge_dir = (Vector2(signf(d.x), 0) if absf(d.x) > absf(d.y) else Vector2(0, signf(d.y)))
				walker.dir = _charge_dir
			else:
				walker.step(delta)
		1:
			_charge_time += delta
			if _charge_time >= EnemyKind.CHARGE_WINDUP:
				charge_phase = 2
				_charge_time = 0.0
				walker.speed_mult = EnemyKind.CHARGE_SPEED_MULT
		2:
			_charge_time += delta
			walker.dir = _charge_dir
			var before := walker.pos
			walker.step(delta)
			if _charge_time >= EnemyKind.CHARGE_SECONDS or walker.pos.distance_to(before) < 0.01 or walker.dir != _charge_dir:
				charge_phase = 0
				walker.speed_mult = EnemyKind.speed_mult(kind)

func _draw() -> void:
	if camera == null:
		return
	var face_angle := walker.dir.angle() - PI / 2
	if kind == EnemyKind.Kind.SHADOW:
		# 影の敵は体が見えない（地面の影だけ）。当たった直後だけ姿が出る
		draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.45))
		if _hit_flash <= 0.0:
			return
	else:
		_draw_shadow()
	var lift := 0.0
	for i in _layers.size():
		var t := _layers[i]
		draw_set_transform(Vector2(0, -i + lift), face_angle - camera.angle, Vector2.ONE)
		draw_texture(t, -t.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 傷ついたら頭の上に体力のバーを出す
	if walker.alive and walker.hp < walker.max_hp:
		var y := -_layers.size() - 6.0 + lift
		draw_rect(Rect2(-6, y, 12, 2), Color(0.1, 0.05, 0.05))
		draw_rect(Rect2(-6, y, 12.0 * walker.hp / walker.max_hp, 2), Color("e74c3c"))
