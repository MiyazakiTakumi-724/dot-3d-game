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
