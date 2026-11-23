class_name MovementRules
extends Resource
## 何段まで登れるか・飛び降りられるか。アイテムで変えられるように Resource にしている。

@export var max_climb: int = 1
@export var max_drop: int = 3

func can_step(from_h: int, to_h: int) -> bool:
	var diff := to_h - from_h
	if diff > 0:
		return diff <= max_climb
	return -diff <= max_drop
