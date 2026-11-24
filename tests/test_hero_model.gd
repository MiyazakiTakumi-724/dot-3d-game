extends GutTest
## 主人公のモデル（HeroModel）。手に持つ物と防具が、姿で分かる。

func _count(m: VoxelModel, c: Color) -> int:
	var n := 0
	for z in m.size.z:
		for y in m.size.y:
			for x in m.size.x:
				if m.get_voxel(Vector3i(x, y, z)).is_equal_approx(c):
					n += 1
	return n

func _front_most(m: VoxelModel) -> int:
	var best := -1
	for z in m.size.z:
		for y in m.size.y:
			for x in m.size.x:
				if m.get_voxel(Vector3i(x, y, z)).a > 0.0:
					best = maxi(best, y)
	return best

func _top_most(m: VoxelModel) -> int:
	var best := -1
	for z in m.size.z:
		for y in m.size.y:
			for x in m.size.x:
				if m.get_voxel(Vector3i(x, y, z)).a > 0.0:
					best = maxi(best, z)
	return best

## どの姿も同じ大きさ（輪切りの数が変わらないので、上に出す鉄球やバーの位置がずれない）。大きさは偶数で、真ん中が体の真ん中
func test_same_size_for_all_looks():
	for held in ["", "sword_1", "bow_1", "staff_none_1", "staff_fire_9", "heal"]:
		var m := HeroModel.build(held, "")
		assert_eq(m.size, HeroModel.SIZE, held)
	assert_eq(HeroModel.SIZE.x % 2, 0)
	assert_eq(HeroModel.SIZE.y % 2, 0)

## 剣は前（+y）へ突き出していて、何も持たないときより前まである
func test_sword_points_forward():
	assert_gt(_front_most(HeroModel.build("sword_1", "")), _front_most(HeroModel.build("", "")))

## 杖は頭の横に、頭のてっぺんの高さまで立っていて、先の玉の色が杖の種類で違う
func test_staff_stands_up_with_colored_orb():
	var tip := Vector3i(11, 8, 16)
	assert_eq(HeroModel.raw("", "").get_voxel(tip).a, 0.0)
	assert_eq(HeroModel.raw("staff_none_1", "").get_voxel(tip), HeroModel.NONE_ORB)
	assert_eq(HeroModel.raw("staff_fire_3", "").get_voxel(tip), HeroModel.FIRE_ORB)
	assert_eq(HeroModel.orb_color("staff_fire_9"), HeroModel.FIRE_ORB)

## 防具を着ると、胸に鎧の色が出る
func test_armor_shows_on_body():
	assert_eq(_count(HeroModel.build("", ""), HeroModel.ARMOR_COLOR), 0)
	assert_gt(_count(HeroModel.raw("", "armor_1"), HeroModel.ARMOR_COLOR), 0)

## 同じ姿は作り直さずに使い回す（輪切りの画像を共有する）
func test_same_look_is_cached():
	assert_same(HeroModel.build("bow_1", "armor_1"), HeroModel.build("bow_1", "armor_1"))
	assert_ne(HeroModel.build("bow_1", ""), HeroModel.build("bow_1", "armor_1"))
