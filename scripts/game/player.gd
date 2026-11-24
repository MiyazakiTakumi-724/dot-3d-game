class_name Player
extends StackSprite
## プレイヤー。矢印キー / WASD で移動（画面基準）。

signal hp_changed(hp: int)

const SPEED := 60.0
## 試作1の体力。試作3からは max_hp をステータスから決める
const MAX_HP := 3
## ダメージを受けた後、次のダメージを受けない時間（秒）。この間は点滅する。
const INVULNERABLE_SECONDS := 1.0

var mover: PlayerMover
var hp: int = MAX_HP
var max_hp: int = MAX_HP
## 足の速さの倍率（体の動きのポイントで上がる）
var speed_mult := 1.0
## false の間は動かせない（死亡処理中など）。
var controllable := true
## マウスカーソルの画面上の位置。null でなければ、歩く向きとは別にいつもそちらを向く。
var aim_screen = null

var _invulnerable := 0.0
## 剣を振った跡を見せる残り時間と、落下斬りか
## 技能「しゃがみ」を覚えていれば、C か左Ctrlを押している間しゃがむ（遅くなり、撃つ敵の弾をよけられる）
var can_crouch := false
var crouching := false
const CROUCH_SPEED := 0.5
const CROUCH_HIDE_LAYERS := 8  ## しゃがむと下の輪切り（足）をこれだけ描かず、体を下げる（主人公は細かく描くので、ゲームの座標で4px）
const OUTLINE_COLOR := Color(0.09, 0.07, 0.12)  ## 体のまわりのふち（草の上でも見分けやすく）
## 今の姿（手に持つ物と防具）。set_look で変える
var held_look := ""
var armor_look := ""
## 回転斬りの見た目
var _spin_t := 0.0
## 弓のチャージ率（0.3〜1.0）。溜めていなければ負。頭の上にバーを出す
var charge := -1.0
var _swing_t := 0.0
var _swing_fall := false
## 飛び降りたときに、少しの間だけ上に浮かせて「落ちていく」ように見せる量（px）
var _drop_lift := 0.0
var _last_height := 0
const SWING_SHOW := 0.15
const DROP_SPEED := 200.0  ## 飛び降りの見た目の落ちる速さ（px/秒）

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
	voxel_scale = HeroModel.VOXEL_SCALE
	outline_color = OUTLINE_COLOR
	set_model(HeroModel.build(held_look, armor_look))
	_sync()

## 姿を変える（手に持つ物の品物 id と防具の id。HeroModel.build）。同じなら何もしない。
func set_look(held: String, armor: String) -> void:
	if held == held_look and armor == armor_look:
		return
	held_look = held
	armor_look = armor
	set_model(HeroModel.build(held, armor))

## amount のダメージを受ける。無敵の間は受けない。受けたら true。
func take_hit(amount := 1) -> bool:
	if hp <= 0 or _invulnerable > 0.0:
		return false
	hp = maxi(0, hp - amount)
	_invulnerable = INVULNERABLE_SECONDS
	hp_changed.emit(hp)
	return true

func is_invulnerable() -> bool:
	return _invulnerable > 0.0

## 剣を振った見た目（向いている方に弧を描く）。
func swing(fall: bool) -> void:
	_swing_t = SWING_SHOW
	_swing_fall = fall

func spin() -> void:
	_spin_t = SWING_SHOW * 2.0

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
	_swing_t = maxf(0.0, _swing_t - delta)
	_spin_t = maxf(0.0, _spin_t - delta)
	crouching = can_crouch and hp > 0 and controllable and (Input.is_physical_key_pressed(KEY_C) or Input.is_physical_key_pressed(KEY_CTRL))
	if hp > 0 and controllable:
		var dir := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A): dir.x -= 1
		if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D): dir.x += 1
		if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W): dir.y -= 1
		if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S): dir.y += 1
		if dir != Vector2.ZERO:
			var spd := SPEED * speed_mult * (CROUCH_SPEED if crouching else 1.0)
			mover.move(camera.screen_dir_to_world(dir.normalized()) * spd * delta, delta)
		if aim_screen != null:
			aim_at_screen(aim_screen)
	_update_drop_lift(delta)
	_sync()
	super._process(delta)

func _update_drop_lift(delta: float) -> void:
	# 歩いて下の段へ移ったときだけ（place で置き直したときは since_drop が INF）
	if mover.height < _last_height and mover.since_drop == 0.0:
		_drop_lift = (_last_height - mover.height) * LEVEL_PX
	_last_height = mover.height
	if _drop_lift > 0.0:
		_drop_lift = maxf(0.0, _drop_lift - DROP_SPEED * delta)
		lift_px = _drop_lift

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
	_draw_stack(face_angle - camera.angle, CROUCH_HIDE_LAYERS if crouching else 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _swing_t > 0.0:
		# 向いている方（画面の上での向き）に、体の真ん中の高さで弧を描く。落下斬りは橙で太く
		var a := mover.facing.rotated(-camera.angle).angle()
		var col := Color("ffb347") if _swing_fall else Color(1, 1, 1, 0.9)
		draw_arc(Vector2(0, -5), 14.0, a - Sword.HALF_ARC, a + Sword.HALF_ARC, 9, col, 3.0 if _swing_fall else 2.0)
	if _spin_t > 0.0:
		draw_arc(Vector2(0, -4), 16.0, 0.0, TAU, 20, Color(1, 1, 1, 0.9), 2.0)
	if charge >= 0.0:
		var y := -_layers.size() * voxel_scale - 4.0  # 頭の上（弓を持っている間は、鉄球は頭に乗せていない）
		var k := (charge - Bow.MIN_RATE) / (1.0 - Bow.MIN_RATE)
		draw_rect(Rect2(-7, y, 14, 3), Color(0.05, 0.05, 0.08))
		draw_rect(Rect2(-6, y + 1, 12.0 * k, 1), Color("ffd23f") if k >= 1.0 else Color("e8d9b0"))
