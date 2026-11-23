extends GutTest

var stage

func before_each():
	stage = load("res://scenes/stage_01.tscn").instantiate()
	add_child_autofree(stage)

func test_stage_has_three_enemies():
	assert_eq(stage.state.enemies_left, 3)

func test_ball_from_plateau_kills_enemy_below():
	var e: Enemy = stage.enemies[0]
	e.walker.pos = HeightMap.cell_center(Vector2i(5, 4))
	var p: PlayerMover = stage.player.mover
	p.pos = HeightMap.cell_center(Vector2i(5, 3))
	p.height = 3
	p.facing = Vector2.DOWN
	var b: IronBall = stage.ball.rules_ball
	assert_true(b.drop(p, stage.map))
	b.update(1.0, p, stage.map, stage.rules)
	assert_false(e.walker.alive)
	assert_eq(stage.state.enemies_left, 2)

func test_ball_on_same_level_only_hurts():
	var e: Enemy = stage.enemies[1]
	e.walker.pos = HeightMap.cell_center(Vector2i(5, 6))
	var p: PlayerMover = stage.player.mover
	p.pos = HeightMap.cell_center(Vector2i(4, 6))
	p.height = 0
	p.facing = Vector2.RIGHT
	var b: IronBall = stage.ball.rules_ball
	b.drop(p, stage.map)
	b.update(1.0, p, stage.map, stage.rules)
	assert_true(e.walker.alive)
	assert_eq(e.walker.hp, 2)

func test_plateau_is_reachable_by_stairs():
	var p: PlayerMover = stage.player.mover
	p.pos = HeightMap.cell_center(Vector2i(0, 1))
	p.height = 0
	for i in 5:
		p.move(Vector2(16, 0))
	assert_eq(p.height, 3)
