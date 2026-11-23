extends GutTest

func test_clear_when_all_dead():
	var s := StageState.new(2)
	s.on_enemy_died()
	s.on_enemy_died()
	assert_eq(s.result, StageState.Result.CLEAR)

func test_still_playing_with_enemies_left():
	var s := StageState.new(2)
	s.on_enemy_died()
	assert_eq(s.result, StageState.Result.PLAYING)

func test_game_over_at_zero_hp():
	var s := StageState.new(2)
	s.on_player_hp(0)
	assert_eq(s.result, StageState.Result.GAME_OVER)

func test_result_is_final():
	var s := StageState.new(1)
	s.on_enemy_died()
	s.on_player_hp(0)
	assert_eq(s.result, StageState.Result.CLEAR)
