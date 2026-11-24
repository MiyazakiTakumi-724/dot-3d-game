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
	for held in ["", "ball_1", "ball_2", "sword_1", "bow_1", "staff_none_1", "staff_fire_9", "heal"]:
		var m := HeroModel.build(held, "")
		assert_eq(m.size, HeroModel.SIZE, held)
	assert_eq(HeroModel.SIZE.x % 2, 0)
	assert_eq(HeroModel.SIZE.y % 2, 0)

## 剣は前（+y）へ突き出していて、何も持たないときより前まである
func test_sword_points_forward():
	assert_gt(_front_most(HeroModel.build("sword_1", "")), _front_most(HeroModel.build("", "")))

## 杖は頭の横に立っていて、先の玉の色が杖の種類で違う
func test_staff_stands_up_with_colored_orb():
	var tip := HeroModel.STAFF_TIP
	assert_eq(HeroModel.raw("", "").get_voxel(tip).a, 0.0)
	assert_eq(HeroModel.raw("staff_none_1", "").get_voxel(tip), HeroModel.NONE_ORB)
	assert_eq(HeroModel.raw("staff_fire_3", "").get_voxel(tip), HeroModel.FIRE_ORB)
	assert_eq(HeroModel.orb_color("staff_fire_9"), HeroModel.FIRE_ORB)

## 鉄球は両手で体の前に抱える。強い鉄球（ランク2）は赤黒い
func test_ball_held_in_front_with_both_hands():
	var c := Vector3i(HeroModel.BALL_CENTER)
	assert_eq(HeroModel.raw("ball_1", "").get_voxel(c), HeroModel.BALL)
	assert_eq(HeroModel.raw("ball_2", "").get_voxel(c), HeroModel.STRONG_BALL)
	assert_eq(HeroModel.raw("", "").get_voxel(c).a, 0.0)
	assert_gt(_front_most(HeroModel.build("ball_1", "")), _front_most(HeroModel.build("", "")))

## デザイン案（STYLES）はどれも同じ大きさで作れて、見た目が違う
func test_every_style_builds():
	var keep := HeroModel.style
	var looks := []
	for st in HeroModel.STYLES:
		HeroModel.style = st
		var m := HeroModel.build("ball_1", "")
		assert_eq(m.size, HeroModel.SIZE, st)
		looks.append(m.voxels())
	HeroModel.style = keep
	for i in looks.size():
		for j in range(i + 1, looks.size()):
			assert_ne(looks[i], looks[j])

## 一番前のボクセルの y（x が x_min〜x_max、z が z_max 以下の所だけ見る）
func _front_in(m: VoxelModel, x_min: int, x_max: int, z_max: int) -> int:
	var best := -1
	for p: Vector3i in m.voxels():
		if m.voxels()[p].a > 0.0 and p.x >= x_min and p.x <= x_max and p.z <= z_max:
			best = maxi(best, p.y)
	return best

## 歩く姿：step_l は x の小さい側の足を前へ、もう片方を後ろへ出す。step_r はその逆。大きさは同じ
func test_step_poses_move_legs():
	for held in ["", "sword_1", "ball_1"]:
		var stand := HeroModel.build(held, "")
		var l := HeroModel.build(held, "", "step_l")
		var r := HeroModel.build(held, "", "step_r")
		assert_eq(l.size, HeroModel.SIZE)
		assert_gt(_front_in(l, 9, 12, 3), _front_in(stand, 9, 12, 3), held)
		assert_lt(_front_in(l, 15, 18, 3), _front_in(stand, 15, 18, 3), held)
		assert_gt(_front_in(r, 15, 18, 3), _front_in(stand, 15, 18, 3), held)
		assert_lt(_front_in(r, 9, 12, 3), _front_in(stand, 9, 12, 3), held)

## 何も持たずに歩くときは、腕も足と逆にふる（x の小さい側の足が前なら、同じ側の手は後ろ）
func test_free_arms_swing_when_walking():
	var stand := HeroModel.build("", "")
	var l := HeroModel.build("", "", "step_l")
	assert_lt(_front_in(l, 5, 7, 10), _front_in(stand, 5, 7, 10))
	assert_gt(_front_in(l, 20, 22, 10), _front_in(stand, 20, 22, 10))

## 鉄球を放した姿：両手を前と外へ広げていて、鉄球はもうない
func test_release_pose_has_open_hands_and_no_ball():
	var m := HeroModel.raw("", "", "release")
	assert_eq(m.get_voxel(Vector3i(HeroModel.BALL_CENTER)).a, 0.0)
	assert_gt(_front_in(m, 2, 8, 13), _front_in(HeroModel.raw("", ""), 2, 8, 13))
	assert_eq(m.get_voxel(Vector3i(3, 18, 11)), HeroModel.SKIN)  # 手は体の外へ広げている

## 地面の鉄球は、手に持つ鉄球と同じ細かさ・同じ色
func test_ground_ball_matches_held_ball():
	var m := HeroModel.ball_model(false)
	assert_eq(m.size, Vector3i.ONE * HeroModel.BALL_BOX)
	assert_eq(HeroModel.BALL_BOX % 2, 0)  # 偶数（真ん中に置いたとき半ピクセルずれない）
	assert_gt(HeroModel.BALL_BOX, HeroModel.BALL_RADIUS * 2.0)
	assert_same(HeroModel.ball_model(false), m)  # 使い回す
	assert_ne(HeroModel.ball_model(true), m)

## 防具を着ると、胸に鎧の色が出る
func test_armor_shows_on_body():
	assert_eq(_count(HeroModel.build("", ""), HeroModel.ARMOR_COLOR), 0)
	assert_gt(_count(HeroModel.raw("", "armor_1"), HeroModel.ARMOR_COLOR), 0)

## 同じ姿は作り直さずに使い回す（輪切りの画像を共有する）
func test_same_look_is_cached():
	assert_same(HeroModel.build("bow_1", "armor_1"), HeroModel.build("bow_1", "armor_1"))
	assert_ne(HeroModel.build("bow_1", ""), HeroModel.build("bow_1", "armor_1"))
