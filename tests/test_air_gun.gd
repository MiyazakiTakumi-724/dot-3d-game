extends GutTest
## エアガン（design.md 5章・7章、17.5）。狙った高さへまっすぐ飛ぶ。1秒に4発。

func _flat(w := 20, h := 5) -> HeightMap:
	return HeightMap.new(Vector2i(w, h))

func _fly(p: Pellet, m: HeightMap, seconds := 1.0) -> void:
	var t := 0.0
	while t < seconds and p.alive:
		p.step(1.0 / 60, m)
		t += 1.0 / 60

func test_flies_straight_at_same_height():
	var m := _flat()
	var p := Pellet.new()
	p.aim(Vector2(8, 40), 4.0, Vector2(100, 40), 4.0)
	_fly(p, m, 0.2)
	assert_true(p.alive)
	assert_almost_eq(p.pos.y, 40.0, 0.01)
	assert_almost_eq(p.z, 4.0, 0.01)

func test_hits_body_only_at_its_height():
	var p := Pellet.new()
	p.aim(Vector2(0, 0), 4.0, Vector2(100, 0), 4.0)
	assert_true(p.hits_body(Vector2(3, 0), 0))
	assert_false(p.hits_body(Vector2(3, 0), 1))
	assert_false(p.hits_body(Vector2(20, 0), 0))

func test_stopped_by_higher_ground():
	var m := _flat()
	for y in 5:
		m.set_height(Vector2i(4, y), 1)
	var p := Pellet.new()
	p.aim(Vector2(8, 40), 4.0, Vector2(150, 40), 4.0)
	_fly(p, m)
	assert_false(p.alive)
	assert_lt(p.pos.x, 64.0 + 0.1)

func test_shooting_down_from_a_ledge_reaches_lower_target():
	var m := _flat()
	for y in 5:
		m.set_height(Vector2i(0, y), 2)
	var p := Pellet.new()
	# 2段の上から、6マス先の高さ0の敵の体（4px）を狙う
	p.aim(Vector2(8, 40), 2 * 8 + 4.0, Vector2(104, 40), 4.0)
	var hit := false
	for i in 120:
		p.step(1.0 / 60, m)
		if p.hits_body(Vector2(104, 40), 0):
			hit = true
			break
	assert_true(hit)

func test_stopped_by_wall_without_ricochet():
	var m := _flat()
	m.set_wall(Vector2i(5, 2), true)
	var p := Pellet.new()
	p.aim(Vector2(8, 40), 4.0, Vector2(150, 40), 4.0)
	_fly(p, m)
	assert_false(p.alive)

func test_ricochet_once_off_wall():
	var m := _flat()
	for y in 5:
		m.set_wall(Vector2i(6, y), true)
	var p := Pellet.new()
	p.aim(Vector2(8, 40), 4.0, Vector2(150, 40), 4.0, 1)
	_fly(p, m, 0.5)
	assert_true(p.alive)
	assert_lt(p.vel.x, 0.0)  # はね返って戻ってくる
	assert_eq(p.bounces, 0)

func test_grave_is_hit():
	var m := _flat()
	m.set_blocker(Vector2i(5, 2), HeightMap.Blocker.GRAVE)
	var p := Pellet.new()
	p.aim(Vector2(8, 40), 4.0, Vector2(150, 40), 4.0, 1)
	_fly(p, m)
	assert_false(p.alive)
	assert_eq(p.hit_grave, Vector2i(5, 2))

func test_range_limit():
	var m := _flat(40)
	var p := Pellet.new()
	p.aim(Vector2(8, 40), 4.0, Vector2(600, 40), 4.0)
	_fly(p, m, 3.0)
	assert_false(p.alive)
	assert_lt(p.pos.x, 8.0 + Pellet.RANGE + 3.0)

func test_fire_rate_four_and_six_per_second():
	var g := AirGun.new()
	assert_true(g.try_fire(false))
	assert_false(g.try_fire(false))
	g.update(0.25)
	assert_true(g.try_fire(false))
	var fast := AirGun.new()
	assert_true(fast.try_fire(true))
	fast.update(1.0 / 6 + 0.001)
	assert_true(fast.try_fire(true))
