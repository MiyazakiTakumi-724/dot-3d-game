extends GutTest

func test_slice_count_equals_height():
	assert_eq(VoxelModel.box(Vector3i(16, 16, 8), Color.RED).slices().size(), 8)

func test_slice_pixel_color():
	var img: Image = VoxelModel.box(Vector3i(4, 4, 2), Color.RED).slices()[0]
	assert_eq(img.get_pixel(1, 1), Color.RED)

func test_empty_voxel_is_transparent():
	var m := VoxelModel.new()
	m.size = Vector3i(4, 4, 1)
	assert_eq(m.slices()[0].get_pixel(0, 0).a, 0.0)

func test_sphere_top_slice_smaller_than_middle():
	var s := VoxelModel.sphere(4, Color.GRAY).slices()
	assert_eq(s.size(), 8)
	assert_true(s[7].get_used_rect().size.x < s[4].get_used_rect().size.x)

func test_changing_model_does_not_empty_shared_textures():
	var m := VoxelModel.box(Vector3i(2, 2, 2), Color.RED)
	var t := m.textures()
	m.set_voxel(Vector3i(0, 0, 0), Color.BLUE)
	assert_eq(t.size(), 2)
	assert_ne(m.textures(), t)

func test_resizing_model_rebuilds_textures():
	var m := VoxelModel.box(Vector3i(2, 2, 2), Color.RED)
	m.textures()
	m.size = Vector3i(2, 2, 3)
	assert_eq(m.textures().size(), 3)

## 写しは元と同じ形で、写しを変えても元は変わらない
func test_copy_is_independent():
	var m := VoxelModel.box(Vector3i(2, 2, 2), Color.RED)
	var c := m.copy()
	assert_eq(c.size, m.size)
	c.set_voxel(Vector3i(0, 0, 0), Color.BLUE)
	assert_eq(m.get_voxel(Vector3i(0, 0, 0)), Color.RED)

## 箱の中のボクセルだけをずらす（元の場所は空く）
func test_move_box_shifts_only_inside():
	var m := VoxelModel.new()
	m.size = Vector3i(4, 4, 1)
	m.set_voxel(Vector3i(0, 0, 0), Color.RED)
	m.set_voxel(Vector3i(3, 0, 0), Color.BLUE)
	m.move_box(Vector3i(0, 0, 0), Vector3i(1, 3, 0), Vector3i(0, 2, 0))
	assert_eq(m.get_voxel(Vector3i(0, 0, 0)).a, 0.0)
	assert_eq(m.get_voxel(Vector3i(0, 2, 0)), Color.RED)
	assert_eq(m.get_voxel(Vector3i(3, 0, 0)), Color.BLUE)

## 輪切りの画像から直接作った模型も、色を読める（範囲の外は透明）
func test_model_from_images():
	var a := Image.create(4, 2, false, Image.FORMAT_RGBA8)
	var b := Image.create(4, 2, false, Image.FORMAT_RGBA8)
	b.set_pixel(1, 1, Color.RED)
	var m := VoxelModel.from_images([a, b])
	assert_eq(m.size, Vector3i(4, 2, 2))
	assert_eq(m.get_voxel(Vector3i(1, 1, 1)), Color.RED)
	assert_eq(m.get_voxel(Vector3i(1, 1, 0)).a, 0.0)
	assert_eq(m.get_voxel(Vector3i(9, 1, 1)).a, 0.0)
	assert_eq(m.textures().size(), 2)
