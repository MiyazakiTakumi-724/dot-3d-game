class_name Ball
extends StackSprite
## 鉄球の見た目。落ちていく間と地面にある間だけ描く。持っている間は、主人公の姿（HeroModel）が両手で抱えて見せる。強い鉄球は赤黒く描く。
## 放すと、主人公の手元から落とした点へ、少し山なりに落ちていく。着くと土ぼこりが立ち、画面が少しゆれる。
## 落とす・拾う操作は各ステージが読む（試作1は X/Z、試作2は左クリックと歩いて拾う）。

## 手元（HeroModel が鉄球を抱える所）。体の真ん中から前へ、足元から上へ（ゲームの座標のpx）
const HAND_FORWARD_PX := (HeroModel.BALL_CENTER.y + 0.5 - HeroModel.SIZE.y / 2.0) * HeroModel.VOXEL_SCALE
const HAND_LIFT_PX := (HeroModel.BALL_CENTER.z - HeroModel.BALL_RADIUS) * HeroModel.VOXEL_SCALE
const TOSS_MAX_PX := 5.0  ## 遠くへ落とすときの山なりの高さの上限
## 着いたときの画面のゆれ：同じ高さでこれだけ、1段落ちるごとに足す（上限 SHAKE_MAX）
const SHAKE_BASE := 0.5
const SHAKE_PER_LEVEL := 0.5
const SHAKE_MAX := 2.0

var rules_ball := IronBall.new()
var player: Player
var map: HeightMap
var rules: MovementRules
var _shown_strong := false
## 放したときの手元の点と高さ（px）
var _start := Vector2.ZERO
var _start_z := 0.0

func setup(p: Player, height_map: HeightMap, movement_rules: MovementRules, cam: StackCamera) -> void:
	player = p
	map = height_map
	rules = movement_rules
	camera = cam
	draw_bias = 3
	sort_by_cell = true
	sort_radius = 3.0
	always_redraw = true  # 落ちていく間、影の位置が毎フレーム変わる
	voxel_scale = HeroModel.VOXEL_SCALE
	outline_color = Player.OUTLINE_COLOR
	set_model(HeroModel.ball_model(false))
	rules_ball.dropped.connect(_on_dropped)
	rules_ball.picked_up.connect(_on_picked_up)
	rules_ball.landed.connect(_on_landed)

func _sort_map() -> HeightMap:
	return map

func _on_dropped() -> void:
	var mv := player.mover
	_start = mv.pos + mv.facing.normalized() * HAND_FORWARD_PX
	_start_z = mv.height * LEVEL_PX + HAND_LIFT_PX
	player.anim.play_release()

func _on_picked_up() -> void:
	player.anim.play_pickup()

func _on_landed(pos: Vector2, _damage: int) -> void:
	var levels := rules_ball.fall_levels
	if camera != null:
		camera.shake(minf(SHAKE_MAX, SHAKE_BASE + SHAKE_PER_LEVEL * levels))
	var parent := get_parent()
	if parent != null and camera != null:
		var dust := ImpactDust.new()
		dust.setup(camera, pos, rules_ball.height, levels)
		parent.add_child(dust)

func _process(delta: float) -> void:
	if rules_ball.strong != _shown_strong:
		_shown_strong = rules_ball.strong
		set_model(HeroModel.ball_model(_shown_strong))
	rules_ball.update(delta, player.mover, map, rules)

	# 落ちていく間と地面にある間は、落ちる場所が分かるように影を出す
	var shadow := 0.0 if rules_ball.state == IronBall.State.HELD else 2.5
	if shadow != shadow_radius:
		shadow_radius = shadow
		queue_redraw()
	force_hidden = rules_ball.state == IronBall.State.HELD
	match rules_ball.state:
		IronBall.State.HELD:
			world_pos = player.mover.pos
			base_height = player.mover.height
			lift_px = 0.0
		IronBall.State.FALLING:
			_place_falling()
		_:
			world_pos = rules_ball.pos
			base_height = rules_ball.height
			lift_px = 0.0
	super._process(delta)

## 手元から落とした点へ。横はまっすぐ、高さはだんだん速く落ち、遠くへ落とすときは少し山なりにする。
func _place_falling() -> void:
	var u := rules_ball.fall_progress()
	var end := rules_ball.pos
	var end_z := float(rules_ball.height * LEVEL_PX)
	world_pos = _start.lerp(end, u)
	var toss := minf(TOSS_MAX_PX, _start.distance_to(end) * 0.3)
	var z := lerpf(_start_z, end_z, u * u) + 4.0 * u * (1.0 - u) * toss
	# 並べる順番は、今いる真下の地面の高さで決める（崖の上から下へ落とすとき、手元では上の段にいる）
	var under := rules_ball.height
	var c := HeightMap.world_to_cell(world_pos)
	if map.in_bounds(c) and not map.is_wall(c):
		under = clampi(map.get_height(c), rules_ball.height, rules_ball.from_height)
	base_height = under
	lift_px = z - under * LEVEL_PX
