class_name Ball
extends StackSprite
## 鉄球の見た目と操作。X で落とす、Z で拾う。持っている間は頭の上に乗せて描く。強い鉄球は赤黒く描く。

const HELD_LIFT_PX := 14.0

var rules_ball := IronBall.new()
var player: Player
var map: HeightMap
var rules: MovementRules
var _x_was_down := false
var _z_was_down := false
## true にすると、そのフレームの Z では拾わない（扉を開けたフレームなど）。
var skip_pick_up := false
var _shown_strong := false

func setup(p: Player, height_map: HeightMap, movement_rules: MovementRules, cam: StackCamera) -> void:
	player = p
	map = height_map
	rules = movement_rules
	camera = cam
	draw_bias = 3
	sort_by_cell = true
	set_model(VoxelModel.sphere(4, Color("6b6f78")))

func _process(delta: float) -> void:
	var x_down := Input.is_physical_key_pressed(KEY_X)
	var z_down := Input.is_physical_key_pressed(KEY_Z)
	if player.hp > 0 and player.controllable:
		if x_down and not _x_was_down:
			rules_ball.drop(player.mover, map)
		if z_down and not _z_was_down and not skip_pick_up:
			rules_ball.try_pick_up(player.mover)
	skip_pick_up = false
	if rules_ball.strong != _shown_strong:
		_shown_strong = rules_ball.strong
		set_model(VoxelModel.sphere(4, Color("7a2230") if _shown_strong else Color("6b6f78")))
	_x_was_down = x_down
	_z_was_down = z_down
	rules_ball.update(delta, player.mover, map, rules)

	if rules_ball.state == IronBall.State.HELD:
		world_pos = player.mover.pos
		base_height = player.mover.height
		lift_px = HELD_LIFT_PX
	else:
		world_pos = HeightMap.cell_center(rules_ball.cell)
		base_height = rules_ball.height
		lift_px = rules_ball.remaining_fall_levels() * LEVEL_PX
	super._process(delta)
