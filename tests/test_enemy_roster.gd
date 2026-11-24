extends GutTest

func test_killed_enemy_returns_after_300s():
	var r := EnemyRoster.new()
	r.kill("hills", 2)
	assert_false(r.present("hills", 2))
	r.tick(299.0)
	assert_false(r.present("hills", 2))
	r.tick(1.0)
	assert_true(r.present("hills", 2))

func test_other_area_same_index_is_separate():
	var r := EnemyRoster.new()
	r.kill("hills", 2)
	assert_true(r.present("rocks", 2))

func test_never_killed_is_present():
	assert_true(EnemyRoster.new().present("hills", 0))
