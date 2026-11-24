class_name Ball
extends StackSprite
## 鉄球の見た目。持っている間は頭の上に乗せて描く。強い鉄球は赤黒く描く。
## 落とす・拾う操作は各ステージが読む（試作1は X/Z、試作2は左クリックと歩いて拾う）。

const HELD_LIFT_PX := 14.0

var rules_ball := IronBall.new()
var player: Player
var map: HeightMap
var rules: MovementRules
var _shown_strong := false

func setup(p: Player, height_map: HeightMap, movement_rules: MovementRules, cam: StackCamera) -> void:
	player = p
	map = height_map
	rules = movement_rules
	camera = cam
	draw_bias = 3
	sort_by_cell = true
	always_redraw = true  # 落ちていく間、影の位置が毎フレーム変わる
	set_model(VoxelModel.sphere(4, Color("6b6f78")))

func _process(delta: float) -> void:
	if rules_ball.strong != _shown_strong:
		_shown_strong = rules_ball.strong
		set_model(VoxelModel.sphere(4, Color("7a2230") if _shown_strong else Color("6b6f78")))
	rules_ball.update(delta, player.mover, map, rules)

	# 落ちていく間と地面にある間は、落ちる場所が分かるように影を出す
	var shadow := 0.0 if rules_ball.state == IronBall.State.HELD else 3.0
	if shadow != shadow_radius:
		shadow_radius = shadow
		queue_redraw()
	if rules_ball.state == IronBall.State.HELD:
		world_pos = player.mover.pos
		base_height = player.mover.height
		lift_px = HELD_LIFT_PX
	else:
		world_pos = rules_ball.pos
		base_height = rules_ball.height
		lift_px = rules_ball.remaining_fall_levels() * LEVEL_PX
	super._process(delta)
