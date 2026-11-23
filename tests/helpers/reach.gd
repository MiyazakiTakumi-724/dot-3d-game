extends RefCounted
## テスト用の経路探索。4近傍、壁と奈落は通れず、段差は MovementRules で判定する幅優先探索。

static func distance(map: HeightMap, rules: MovementRules, from: Vector2i, to: Vector2i) -> int:
	var dist := {from: 0}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		if c == to:
			return dist[c]
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n: Vector2i = c + d
			if dist.has(n) or map.is_wall(n) or map.is_pit(n):
				continue
			if not rules.can_step(map.get_height(c), map.get_height(n)):
				continue
			dist[n] = dist[c] + 1
			queue.append(n)
	return -1
