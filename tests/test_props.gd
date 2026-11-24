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
