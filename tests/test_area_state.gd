extends GutTest

func test_death_then_respawn_after_delay():
	var s := AreaState.new()
	assert_true(s.on_player_died(false))
	assert_eq(s.result, AreaState.Result.DYING)
	assert_false(s.update(1.4))
	assert_true(s.update(0.2))
	assert_eq(s.result, AreaState.Result.PLAYING)

func test_fall_adds_fall_time():
	var s := AreaState.new()
	s.on_player_died(true)
	assert_true(s.is_falling())
	assert_false(s.update(1.9))
	assert_false(s.is_falling())
	assert_true(s.update(0.2))

func test_not_falling_when_died_by_damage():
	var s := AreaState.new()
	s.on_player_died(false)
	assert_false(s.is_falling())

func test_second_death_while_dying_is_ignored():
	var s := AreaState.new()
	assert_true(s.on_player_died(true))
	assert_false(s.on_player_died(false))
	assert_false(s.update(1.9))   # 1回目の待ち時間（2.0秒）のまま
	assert_true(s.update(0.2))

func test_goal_clears_and_is_final():
	var s := AreaState.new()
	s.on_goal()
	assert_eq(s.result, AreaState.Result.CLEAR)
	assert_false(s.on_player_died(false))
	assert_eq(s.result, AreaState.Result.CLEAR)

func test_goal_ignored_while_dying():
	var s := AreaState.new()
	s.on_player_died(false)
	s.on_goal()
	assert_eq(s.result, AreaState.Result.DYING)
