extends GutTest
## 主人公以外の物の模型（Props）。主人公と同じ細かさで、同じ影の付け方。

func _extent(m: VoxelModel, c: Color) -> Array:
	var lo := Vector3i(999, 999, 999)
	var hi := Vector3i(-1, -1, -1)
	for p: Vector3i in m.voxels():
		if m.voxels()[p].is_equal_approx(c):
			lo = Vector3i(mini(lo.x, p.x), mini(lo.y, p.y), mini(lo.z, p.z))
			hi = Vector3i(maxi(hi.x, p.x), maxi(hi.y, p.y), maxi(hi.z, p.z))
	return [lo, hi]

## 矢：矢じりは前（+y）、羽根は後ろ。傾き（ピッチ）を上げると、矢じりが羽根より高くなる。大きさは偶数
func test_arrow_points_forward_and_tilts():
	var flat := Props.arrow_raw(Arrow.Kind.NORMAL, 0.0)
	var head: Array = _extent(flat, Props.ARROW_HEAD)
	var feather: Array = _extent(flat, Props.FEATHER)
	assert_gt(head[0].y, feather[1].y)
	assert_eq(flat.size.x % 2, 0)
	assert_eq(flat.size.y % 2, 0)
	assert_eq(flat.size.z % 2, 0)
	var up := Props.arrow_raw(Arrow.Kind.NORMAL, deg_to_rad(45.0))
	assert_gt(_extent(up, Props.ARROW_HEAD)[0].z, _extent(up, Props.FEATHER)[1].z)
	var down := Props.arrow_raw(Arrow.Kind.NORMAL, deg_to_rad(-45.0))
	assert_lt(_extent(down, Props.ARROW_HEAD)[1].z, _extent(down, Props.FEATHER)[0].z)

## 毒矢は矢じりの色が違う
func test_poison_arrow_head_color():
	assert_eq(_extent(Props.arrow_raw(Arrow.Kind.POISON, 0.0), Props.ARROW_HEAD)[1], Vector3i(-1, -1, -1))
	assert_ne(_extent(Props.arrow_raw(Arrow.Kind.POISON, 0.0), Props.POISON_HEAD)[1], Vector3i(-1, -1, -1))

## 傾きは決まった数の段に分けて作り、同じ段は使い回す
func test_arrow_models_are_quantized_and_cached():
	var a := Props.arrow_model(Arrow.Kind.NORMAL, 0.01)
	assert_same(a, Props.arrow_model(Arrow.Kind.NORMAL, 0.0))
	assert_ne(a, Props.arrow_model(Arrow.Kind.NORMAL, 0.6))
	assert_same(Props.arrow_model(Arrow.Kind.NORMAL, 5.0), Props.arrow_model(Arrow.Kind.NORMAL, PI / 2))

## 出口の矢印は平たく、北向きなら先が上（y=0）の真ん中にある。向きごとに回して作る
func test_exit_arrow_points_its_way():
	var n := Props.exit_arrow(Vector2i(0, -1))
	assert_eq(n.size.z, 1)
	assert_ne(n.get_voxel(Vector3i(n.size.x / 2, 0, 0)).a, 0.0)
	assert_eq(n.get_voxel(Vector3i(0, 0, 0)).a, 0.0)
	var e := Props.exit_arrow(Vector2i(1, 0))
	assert_ne(e.get_voxel(Vector3i(e.size.x - 1, e.size.y / 2, 0)).a, 0.0)

## 小物はみな主人公と同じ細かさの模型で、大きさは偶数（真ん中に置いても半ピクセルずれない）。同じものは使い回す
func test_props_are_even_sized_and_cached():
	var models := [Props.bonfire(0), Props.bonfire(2), Props.chest(), Props.grave(), Props.gate(), Props.bolt(true), Props.bolt(false),
		Props.bullet(), Props.flame(1), Props.pillar(), Props.rain_ring(13.0), Props.aim_shadow(), Props.aim_ring()]
	for k in [RunState.PickupKind.MONEY, RunState.PickupKind.MATERIAL, RunState.PickupKind.HEAL, RunState.PickupKind.ARROWS, RunState.PickupKind.POISON_ARROWS]:
		models.append(Props.pickup(k))
	for m: VoxelModel in models:
		assert_gt(m.voxels().size(), 0)
		assert_eq(m.size.x % 2, 0, str(m.size))
		assert_eq(m.size.y % 2, 0, str(m.size))
	assert_same(Props.chest(), Props.pickup(RunState.PickupKind.SWORD))
	assert_same(Props.grave(), Props.grave())
	assert_ne(Props.bonfire(0), Props.bonfire(1))

## 墓石は背が高く（遠くから見つけやすい）、前に彫った印がある
func test_grave_is_tall_with_mark():
	var g := Props.grave()
	assert_gt(g.size.z, 40)
