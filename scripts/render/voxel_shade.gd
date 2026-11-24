class_name VoxelShade
extends RefCounted
## ボクセルの形に影をつける（主人公・小物・地形で共通）。まわり（26方向）の空いている向きから面の向きを出し、
## 光の当たり方で4段階に塗る（明るい・ふつう・影・濃い影）。影は青紫へ、明るい所は暖かい白へ寄せる
## （色相をずらして、暗い所も濁らないように）。輪切りのふちごとに縞が出ないよう、上下だけでなくまわり全部で向きを決める。
## うまっているかどうかを1つの配列にして調べるので、辞書で調べるより何倍も速い（主人公1体で約10ms）。

## 光の向き（上から、少し前と左から）
const LIGHT_DIR := Vector3(-0.3, 0.45, 1.0)
const SHADOW := Color("2b1d47")
const LIGHT := Color("fff3d6")

static var _offsets := PackedInt32Array()
static var _dirs: Array[Vector3] = []
static var _offsets_for := Vector2i(-1, -1)

## 影をつけた写しを返す（元はそのまま）。
static func apply(src: VoxelModel, light_dir := LIGHT_DIR) -> VoxelModel:
	# まわりに1つずつ余白をつけた、うまっているかどうかの表（端で調べる範囲の外に出ないように）
	var sx := src.size.x + 2
	var sy := src.size.y + 2
	var sz := src.size.z + 2
	var occ := PackedByteArray()
	occ.resize(sx * sy * sz)
	var vox := src.voxels()
	for p: Vector3i in vox:
		if vox[p].a > 0.0:
			occ[((p.z + 1) * sy + p.y + 1) * sx + p.x + 1] = 1
	_prepare_offsets(sx, sy)
	var light := light_dir.normalized()
	var m := VoxelModel.new()
	m.size = src.size
	var out_vox := m.voxels()
	for p: Vector3i in vox:
		var c: Color = vox[p]
		if c.a <= 0.0:
			continue
		var i := ((p.z + 1) * sy + p.y + 1) * sx + p.x + 1
		var n := Vector3.ZERO
		for k in 26:
			if occ[i + _offsets[k]] == 0:
				n += _dirs[k]
		out_vox[p] = band(c, n, light)
	return m

## 面の向き n（長さは問わない、0なら中）と光から、4段階の色。
static func band(c: Color, n: Vector3, light: Vector3) -> Color:
	if n == Vector3.ZERO:
		return c.lerp(SHADOW, 0.2)
	var k := n.normalized().dot(light)
	if k > 0.72:
		return c.lerp(LIGHT, 0.35)
	elif k > 0.3:
		return c.lerp(LIGHT, 0.08)
	elif k > -0.15:
		return c.lerp(SHADOW, 0.2)
	return c.lerp(SHADOW, 0.38)

static func _prepare_offsets(sx: int, sy: int) -> void:
	if _offsets_for == Vector2i(sx, sy):
		return
	_offsets_for = Vector2i(sx, sy)
	_offsets = PackedInt32Array()
	_dirs = []
	for dz in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dy == 0 and dz == 0:
					continue
				_offsets.append((dz * sy + dy) * sx + dx)
				_dirs.append(Vector3(dx, dy, dz))
