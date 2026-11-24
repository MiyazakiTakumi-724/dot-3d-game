extends RefCounted
## テスト用の経路探索。4近傍、壁・奈落・水は通れず、段差は MovementRules で判定する幅優先探索。

static func distance(map: HeightMap, rules: MovementRules, from: Vector2i, to: Vector2i) -> int:
	var dist := {from: 0}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		if c == to:
			return dist[c]
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n: Vector2i = c + d
			if dist.has(n) or map.is_wall(n) or map.is_pit(n) or map.is_water(n):
				continue
			if not rules.can_step(map.get_height(c), map.get_height(n)):
				continue
			dist[n] = dist[c] + 1
			queue.append(n)
	return -1

## from から歩いて行けるマスの集まり。reverse なら「そこから from へ歩いて来られる」マスの集まり。
## 斜めに角をすり抜ける動きは数えない（4近傍だけ）。
static func reachable(map: HeightMap, rules: MovementRules, from: Vector2i, reverse := false) -> Dictionary:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n: Vector2i = c + d
			if seen.has(n) or map.is_wall(n) or map.is_pit(n) or map.is_water(n):
				continue
			var ok := rules.can_step(map.get_height(n), map.get_height(c)) if reverse else rules.can_step(map.get_height(c), map.get_height(n))
			if not ok:
				continue
			seen[n] = true
			queue.append(n)
	return seen
