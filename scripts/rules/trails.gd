class_name Trails
extends RefCounted
## 地面の道（2026-11-26 の4回目の直し。添付の映像の土の道のように、エリアの中に踏み固めた道を描く）。
## 出口の真ん中のマスどうしと、たき火などの真ん中（hub）を、歩けるマスの安い道でつなぐ。
## 道は見た目だけで、歩き方は変わらない。同じ地図からは毎回同じ道になる。

## 段差を1段こえるときの手間。道は平らな所を通りたがる
const CLIMB_COST := 2.5
## 2段以上の段差（登れない）は、とても高くつける（通らないわけではない）
const CLIFF_COST := 40.0
## マスごとのばらつき（道が少し曲がりくねる）
const WOBBLE := 0.7

static func _walkable(map: HeightMap, c: Vector2i) -> bool:
	return map.in_bounds(c) and not map.is_wall(c) and not map.is_water(c) and not map.is_pit(c)

static func _wobble(c: Vector2i) -> float:
	return float(absi((c.x * 73856093) ^ (c.y * 19349663)) % 97) / 97.0 * WOBBLE

## 出口の真ん中の、歩けるマス（なければ出口のマスで歩けるもの）。
static func exit_middle(map: HeightMap, ex: ExitDef) -> Vector2i:
	var cells := ex.cells(map.size)
	if cells.is_empty():
		return Vector2i(-1, -1)
	var mid: Vector2i = cells[cells.size() / 2]
	if _walkable(map, mid):
		return mid
	for c in cells:
		if _walkable(map, c):
			return c
	return Vector2i(-1, -1)

## 道のマス（マス → true）。hub が (-1, -1) なら、出口の真ん中に近い歩けるマスを真ん中にする。
static func cells(map: HeightMap, exits: Array[ExitDef], hub: Vector2i) -> Dictionary:
	var ends: Array[Vector2i] = []
	for ex in exits:
		var c := exit_middle(map, ex)
		if c.x >= 0:
			ends.append(c)
	var out := {}
	if ends.is_empty():
		return out
	if hub.x < 0 or not _walkable(map, hub):
		hub = _center(map, ends, hub)
	if hub.x < 0:
		return out
	var prev := _dijkstra(map, hub)
	for e in ends:
		var c := e
		var guard := map.size.x * map.size.y
		while prev.has(c) and guard > 0:
			out[c] = true
			if c == hub:
				break
			c = prev[c]
			guard -= 1
	return out

## 出口の真ん中の重心に一番近い、歩けるマス。hub が歩けないマスなら、その近くを探す。
static func _center(map: HeightMap, ends: Array[Vector2i], hub: Vector2i) -> Vector2i:
	var target := Vector2.ZERO
	if hub.x >= 0:
		target = Vector2(hub)
	else:
		for e in ends:
			target += Vector2(e)
		target /= ends.size()
	var best := Vector2i(-1, -1)
	var best_d := INF
	for y in map.size.y:
		for x in map.size.x:
			var c := Vector2i(x, y)
			if not _walkable(map, c):
				continue
			var d := Vector2(c).distance_squared_to(target)
			if d < best_d:
				best_d = d
				best = c
	return best

## hub からの安い道（マス → 1つ hub 寄りのマス）。
static func _dijkstra(map: HeightMap, hub: Vector2i) -> Dictionary:
	var dist := {hub: 0.0}
	var prev := {hub: hub}
	var open: Array = [[0.0, hub]]
	while not open.is_empty():
		# 小さなエリア（1000マスまで）なので、いちばん安いものを線形に探す
		var bi := 0
		for i in range(1, open.size()):
			if open[i][0] < open[bi][0]:
				bi = i
		var cur: Array = open[bi]
		open.remove_at(bi)
		var c: Vector2i = cur[1]
		if cur[0] > dist[c]:
			continue
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if not _walkable(map, n):
				continue
			var dh := absi(map.get_height(n) - map.get_height(c))
			var cost := 1.0 + _wobble(n) + (CLIFF_COST if dh > 1 else CLIMB_COST * dh)
			var nd: float = dist[c] + cost
			if not dist.has(n) or nd < dist[n]:
				dist[n] = nd
				prev[n] = c
				open.append([nd, n])
	return prev
