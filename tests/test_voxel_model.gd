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
