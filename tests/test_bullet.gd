extends GutTest

func _map_with_wall() -> HeightMap:
	var map := HeightMap.new(Vector2i(8, 8))
	map.set_wall(Vector2i(2, 0), true)
	return map

func test_bullet_stops_at_wall():
	var map := _map_with_wall()
	var b := Bullet.new()
	b.pos = Vector2(8, 8)
	b.vel = Vector2(80, 0)
	for i in 30:
		b.step(0.016, map)
	assert_false(b.alive)

func test_fast_bullet_does_not_tunnel_wall():
	var map := _map_with_wall()
	var b := Bullet.new()
	b.pos = Vector2(8, 8)
	b.vel = Vector2(2000, 0)
	b.step(0.05, map)
	assert_false(b.alive)

func test_bullet_flies_in_open():
	var map := HeightMap.new(Vector2i(8, 8))
	var b := Bullet.new()
	b.pos = Vector2(8, 8)
	b.vel = Vector2(80, 0)
	b.step(0.5, map)
	assert_true(b.alive)
	assert_almost_eq(b.pos.x, 48.0, 0.01)

func test_bullet_ignores_height_differences():
	var map := HeightMap.new(Vector2i(8, 8))
	map.set_height(Vector2i(1, 0), 3)
	var b := Bullet.new()
	b.pos = Vector2(8, 8)
	b.vel = Vector2(80, 0)
	b.step(0.5, map)
	assert_true(b.alive)
