class_name VoxelDraw
extends RefCounted
## ボクセルの形を組む道具（箱・だ円の玉・棒・円柱）。小物と地形の飾りで使う。範囲の外は VoxelModel が捨てる。

## 箱 from〜to（両端を含む）を塗る。
static func fill(m: VoxelModel, from: Vector3i, to: Vector3i, c: Color) -> void:
	for z in range(from.z, to.z + 1):
		for y in range(from.y, to.y + 1):
			for x in range(from.x, to.x + 1):
				m.set_voxel(Vector3i(x, y, z), c)

## だ円の玉。keep があれば、keep.call(位置) が true の所だけ塗る。
static func ellipsoid(m: VoxelModel, center: Vector3, radius: Vector3, c: Color, keep := Callable()) -> void:
	for z in range(floori(center.z - radius.z), ceili(center.z + radius.z) + 1):
		for y in range(floori(center.y - radius.y), ceili(center.y + radius.y) + 1):
			for x in range(floori(center.x - radius.x), ceili(center.x + radius.x) + 1):
				var p := Vector3i(x, y, z)
				var d := (Vector3(p) - center) / radius
				if d.length_squared() <= 1.0 and (not keep.is_valid() or keep.call(p)):
					m.set_voxel(p, c)

## a から b までの棒（太さ w のボクセルを並べる）。
static func rod(m: VoxelModel, a: Vector3, b: Vector3, c: Color, w := 2) -> void:
	var n := maxi(1, ceili(a.distance_to(b) * 3.0))
	var half := (w - 1) * 0.5
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		var lo := Vector3i((p - Vector3.ONE * half).round())
		fill(m, lo, lo + Vector3i.ONE * (w - 1), c)

## 立てた円柱（真ん中 center_xy、半径 r、高さ z0〜z1）。
static func cylinder(m: VoxelModel, center_xy: Vector2, r: float, z0: int, z1: int, c: Color) -> void:
	for z in range(z0, z1 + 1):
		for y in range(floori(center_xy.y - r), ceili(center_xy.y + r) + 1):
			for x in range(floori(center_xy.x - r), ceili(center_xy.x + r) + 1):
				if Vector2(x, y).distance_to(center_xy) <= r:
					m.set_voxel(Vector3i(x, y, z), c)

## 位置から決まる 0〜n-1 の値（ばらつき用。毎回同じ）。
static func hash3(x: int, y: int, z: int, n: int) -> int:
	return absi((x * 92837111) ^ (y * 689287499) ^ (z * 283923481)) % n
