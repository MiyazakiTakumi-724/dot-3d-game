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
## しゃがんでいられる時間と、次にしゃがめるまでの待ち（2026-11-26 の4回目の直し）
var crouch := Crouch.new()
const CROUCH_SPEED := 0.5
const CROUCH_HIDE_LAYERS := 8  ## しゃがむと下の輪切り（足）をこれだけ描かず、体を下げる（主人公は細かく描くので、ゲームの座標で4px）
const OUTLINE_COLOR := Color(0.09, 0.07, 0.12)  ## 体のまわりのふち（草の上でも見分けやすく）
const HEAL_SPARKLE := Color("ffd6e8")  ## 薬を飲んだときに上るきらめき
## 今の姿（手に持つ物と防具）。set_look で変える
var held_look := ""
var armor_look := ""
## 動き（歩く・鉄球を放す・拾う・剣を振る・着地）。姿勢を選び、下げ・ひねり・縮みを決める
var anim := HeroAnim.new()
var _shown_model: VoxelModel
## 1フレームにこれより大きく動いたら、歩いたのではなく置き直した（エリアの切り替えなど）とみなす
const TELEPORT_PX := 8.0
## 回転斬りの見た目
var _spin_t := 0.0
## 弓のチャージ率（0.3〜1.0）。溜めていなければ負。頭の上にバーを出す
var charge := -1.0
var _swing_t := 0.0
var _swing_fall := false
var _swing_thrust := false
## 飛び降りたときに、少しの間だけ上に浮かせて「落ちていく」ように見せる量（px）
var _drop_lift := 0.0
var _last_height := 0
## 足音の名前（エリアの地面で替わる。field.gd が入れる。2026-11-26）
var step_sound := "step_grass"
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
	_apply_model()
	_sync()

## 姿を変える（手に持つ物の品物 id と防具の id。HeroModel.build）。同じなら何もしない。
func set_look(held: String, armor: String) -> void:
	if held == held_look and armor == armor_look:
		return
	held_look = held
	armor_look = armor
	_apply_model()

## 今の持ち物と動きの姿勢に合う姿にする。何も持たない姿（鉄球を放す・よじ登る・門を押す・倒れる）は持つ物をしまい、
## 薬を飲む姿はいつも薬を持つ。持つ物に合わない動きの姿（剣を持たずに振るなど）は立ち姿にする。
func _apply_model() -> void:
	var pose := anim.pose()
	var held := held_look
	if pose in HeroModel.ITEMLESS_POSES:
		held = ""
	elif pose == "drink":
		held = "heal"
	elif pose != "" and not pose.begins_with("step") and not pose in HeroModel.item_poses(held):
		pose = ""
	var m := HeroModel.build(held, armor_look, pose)
	if m != _shown_model:
		_shown_model = m
		set_model(m)

## amount のダメージを受ける。無敵の間は受けない。受けたら true。
func take_hit(amount := 1) -> bool:
	if hp <= 0 or _invulnerable > 0.0:
		return false
	hp = maxi(0, hp - amount)
	_invulnerable = INVULNERABLE_SECONDS
	anim.play_hurt()
	hp_changed.emit(hp)
	return true

func is_invulnerable() -> bool:
	return _invulnerable > 0.0

## 剣を振った見た目（向いている方に弧を描き、体をひねる）。thrust（技能「突き」）なら、前へ踏み込んでまっすぐ突く筋を描く。
func swing(fall: bool, thrust := false) -> void:
	_swing_t = SWING_SHOW
	_swing_fall = fall
	_swing_thrust = thrust
	anim.play_swing(SWING_SHOW, thrust)

## 回転斬りの見た目（まわりに輪を描き、体を1回転させる）。
func spin() -> void:
	_spin_t = SWING_SHOW * 2.0
	anim.play_spin(SWING_SHOW * 2.0)

func clear_invulnerable() -> void:
	_invulnerable = 0.0
	self_modulate = Color.WHITE

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
	var alpha := 1.0
	if _invulnerable > 0.0:
		_invulnerable = maxf(0.0, _invulnerable - delta)
		# 0.1秒ごとに薄くして点滅させる
		alpha = 0.35 if int(_invulnerable * 10.0) % 2 == 1 else 1.0
	# ダメージを受けた直後は赤く光る（1より大きい赤で明るく、ほかの色は弱める）
	var f := anim.hurt_flash()
	self_modulate = Color(1.0 + 0.8 * f, 1.0 - 0.45 * f, 1.0 - 0.45 * f, alpha)
	_swing_t = maxf(0.0, _swing_t - delta)
	_spin_t = maxf(0.0, _spin_t - delta)
	var want_crouch := can_crouch and hp > 0 and controllable and (Input.is_physical_key_pressed(KEY_C) or Input.is_physical_key_pressed(KEY_CTRL))
	var was_crouching := crouching
	crouching = crouch.update(want_crouch, delta)
	if was_crouching and not crouching and want_crouch:
		Sfx.play("ui_close", null, -10.0)  # 時間が切れて立った
	var before := mover.pos
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
	var moved := mover.pos.distance_to(before)
	anim.set_charge(charge)
	anim.set_climb(mover.climb_progress() if hp > 0 else 0.0)
	anim.update(delta, moved if moved < TELEPORT_PX else 0.0)
	if anim.stepped and controllable:
		Sfx.play(step_sound, null, -8.0 if crouching else -3.0, 0.12)
	if mover.height > _last_height and moved > 0.0 and moved < TELEPORT_PX and controllable:
		Sfx.play("climb", null, -4.0)  # 歩いて段を登った
	_apply_model()
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
		if _drop_lift <= 0.0:
			anim.play_land()  # 着いた瞬間に少し縮む
			Sfx.play("land")

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
	var skip := maxi(CROUCH_HIDE_LAYERS if crouching else 0, anim.dip_layers())
	var rot := face_angle - camera.angle + anim.twist()
	var screen_face := mover.facing.rotated(-camera.angle)
	if anim.pose() == "down":
		# 倒れた姿は、画面の上でいつも横に寝かせる（縦に寝かせると立っているのと見分けにくい）。足は向いていた側
		rot = -PI / 2 if screen_face.x >= 0.0 else PI / 2
	# 体を下げる（歩く）・上げる（よじ登る）・前後にずらす（突き・弓の反動・のけぞり）。本当の画面の1pxにそろえる
	var offset := Vector2(0, anim.bob() - anim.climb_lift()) + screen_face * anim.forward_px()
	offset = (offset * StackCamera.PIXEL_SCALE).round() / StackCamera.PIXEL_SCALE
	_draw_stack(rot, skip, anim.stretch(), offset)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_action_effects(rot, skip, offset)
	if _swing_t > 0.0 and _swing_thrust:
		# 突き：向いている方へまっすぐ伸びる筋
		var k := 1.0 - _swing_t / SWING_SHOW
		var from := Vector2(0, -5) + screen_face * 6.0
		draw_line(from, from + screen_face * (6.0 + 14.0 * k), Color("ffb347") if _swing_fall else Color(1, 1, 1, 0.9), 2.0 if _swing_fall else 1.5)
	elif _swing_t > 0.0:
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

## 模型の点 p（ボクセルの位置）が、今描いている姿でどこに来るか（このノードの中の位置）。
func _model_point(p: Vector3, rot: float, skip: int, offset: Vector2) -> Vector2:
	var half := Vector2(_shown_model.size.x, _shown_model.size.y) * 0.5
	var flat := (Vector2(p.x + 0.5, p.y + 0.5) - half) * voxel_scale
	return flat.rotated(rot) + Vector2(0, (skip - p.z) * voxel_scale * anim.stretch()) + offset

## 動きに合わせた光：杖の先の玉が光る（魔法を使った）、薬のきらめきが上る（回復した）。
func _draw_action_effects(rot: float, skip: int, offset: Vector2) -> void:
	var f := anim.cast_flash()
	if f > 0.0 and anim.pose() == "cast":
		var at := _model_point(HeroModel.CAST_ORB, rot, skip, offset)
		var orb := HeroModel.orb_color(held_look)
		draw_circle(at, 2.0 + 2.5 * f, Color(orb, 0.5 * f))
		draw_circle(at, 1.0 + 1.0 * f, Color(1, 1, 1, 0.8 * f))
	var k := anim.drink_progress()
	if k >= 0.0:
		var c := Color(HEAL_SPARKLE, 1.0 - k)
		for i in 3:
			var p := Vector2(-5.0 + 5.0 * i, -6.0 - 12.0 * fmod(k + 0.33 * i, 1.0)).round()
			var d := 0.5  # 本当の画面の1px
			draw_rect(Rect2(p - Vector2(d * 1.5, d * 0.5), Vector2(d * 3.0, d)), c)
			draw_rect(Rect2(p - Vector2(d * 0.5, d * 1.5), Vector2(d, d * 3.0)), c)
