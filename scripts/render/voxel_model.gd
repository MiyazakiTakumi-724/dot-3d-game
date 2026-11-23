class_name VoxelModel
extends RefCounted
## ボクセルの形。slices() で下から順の輪切り画像を作る。

var size: Vector3i:
	set(v):
		size = v
		_voxels.clear()
var _voxels: Dictionary = {}  # Vector3i -> Color

func set_voxel(p: Vector3i, c: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.z >= 0 and p.x < size.x and p.y < size.y and p.z < size.z:
		_voxels[p] = c

func slices() -> Array[Image]:
	var out: Array[Image] = []
	for z in size.z:
		var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		out.append(img)
	for p: Vector3i in _voxels:
		out[p.z].set_pixel(p.x, p.y, _voxels[p])
	return out

static func box(box_size: Vector3i, c: Color) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = box_size
	for z in box_size.z:
		for y in box_size.y:
			for x in box_size.x:
				m.set_voxel(Vector3i(x, y, z), c)
	return m

static func sphere(radius: int, c: Color) -> VoxelModel:
	var m := VoxelModel.new()
	var d := radius * 2
	m.size = Vector3i(d, d, d)
	var center := Vector3(radius, radius, radius) - Vector3(0.5, 0.5, 0.5)
	for z in d:
		for y in d:
			for x in d:
				if Vector3(x, y, z).distance_to(center) <= radius - 0.25:
					# 上の段ほど少し明るくして立体感を出す
					m.set_voxel(Vector3i(x, y, z), c.lightened(0.04 * z))
	return m
