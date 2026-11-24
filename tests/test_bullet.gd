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

## 低い所から撃った弾は、高い段の側面（崖）で止まる
func test_bullet_stops_at_higher_ground():
	var map := HeightMap.new(Vector2i(8, 8))
	map.set_height(Vector2i(2, 0), 1)
	var b := Bullet.new()
	b.pos = Vector2(8, 8)
	b.vel = Vector2(80, 0)
	b.step(0.5, map)
	assert_false(b.alive)
	assert_almost_eq(b.pos.x, 32.0, 0.01)

## 高い所から撃った弾は、低い所の上をそのまま飛ぶ
func test_bullet_flies_over_lower_ground():
	var map := HeightMap.new(Vector2i(8, 8))
	for x in 8:
		map.set_height(Vector2i(x, 0), 2)
	map.set_height(Vector2i(2, 0), 0)
	var b := Bullet.new()
	b.pos = Vector2(8, 8)
	b.vel = Vector2(80, 0)
	b.height = 2
	b.step(0.5, map)
	assert_true(b.alive)
	assert_almost_eq(b.pos.x, 48.0, 0.01)

## 同じ段に立っているときだけ当たる
func test_bullet_hits_only_same_height():
	var b := Bullet.new()
	b.pos = Vector2(8, 8)
	b.height = 2
	assert_true(b.hits(Vector2(10, 8), 2, 6.0))
	assert_false(b.hits(Vector2(10, 8), 0, 6.0))
	assert_false(b.hits(Vector2(20, 8), 2, 6.0))

func test_dead_bullet_hits_nothing():
	var b := Bullet.new()
	b.alive = false
	assert_false(b.hits(b.pos, 0, 6.0))

func test_bullet_does_not_graze_through_wall_corner():
	var map := HeightMap.new(Vector2i(8, 8))
	map.set_wall(Vector2i(2, 1), true)
	var b := Bullet.new()
	b.pos = Vector2(40.5, 7.8)  # 壁マス(2,1)の左上の角をわずかにかすめる斜めの軌道
	b.vel = Vector2(-320, 320)
	b.step(0.05, map)
	assert_false(b.alive)

func test_bullet_flies_over_water():
	var map := HeightMap.new(Vector2i(8, 8))
	map.set_water(Vector2i(2, 0), true)
	var b := Bullet.new()
	b.pos = Vector2(8, 8)
	b.vel = Vector2(80, 0)
	for i in 10:
		b.step(0.1, map)
	assert_true(b.alive)
	assert_gt(b.pos.x, 48.0)

## 狙って撃つ弾：高い所から、下に立つ相手へ届く（崖のふちから撃つとき）
func test_aimed_bullet_reaches_lower_target():
	var map := HeightMap.new(Vector2i(8, 8))
	map.set_height(Vector2i(0, 0), 2)
	var b := Bullet.new()
	var target := HeightMap.cell_center(Vector2i(4, 0))
	b.aim(HeightMap.cell_center(Vector2i(0, 0)) + Vector2(6, 0), 2, target, 0, 80.0)
	var hit := false
	for i in 100:
		b.step(0.016, map)
		if b.hits(target, 0, 6.0):
			hit = true
			break
	assert_true(hit)

## 狙って撃つ弾：下から高い所の相手を狙うと、崖の側面に当たって止まる
func test_aimed_bullet_from_below_hits_cliff():
	var map := HeightMap.new(Vector2i(8, 8))
	for x in range(2, 8):
		map.set_height(Vector2i(x, 0), 2)
	var b := Bullet.new()
	var target := HeightMap.cell_center(Vector2i(5, 0))
	b.aim(HeightMap.cell_center(Vector2i(0, 0)), 0, target, 2, 80.0)
	for i in 100:
		b.step(0.016, map)
	assert_false(b.alive)
	assert_lt(b.pos.x, 40.0)

## 弾は自分の高さ（z）で当たりを決める。体の高さの外を通る弾は当たらない
func test_bullet_hits_by_z():
	var b := Bullet.new()
	b.pos = Vector2(8, 8)
	b.height = 0
	b.z = 20.0  # 2段の高さ（地面0に立つ相手の頭の上）
	assert_false(b.hits(Vector2(8, 8), 0, 6.0))
	assert_true(b.hits(Vector2(8, 8), 2, 6.0))
