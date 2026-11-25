class_name Buffs
extends RefCounted
## 道具（力の薬・守りの薬・速さの薬）で、少しの間だけ強くなる。同じ種類をもう一度使うと、長い方の時間にそろえる。
## 種類：atk（つよさ＋）・def（守り＋）・speed（足の速さ＋割合）。

var _left := {}  # 種類 → [量, 残り秒]

func add(key: String, amount: float, seconds: float) -> void:
	var cur = _left.get(key, [0.0, 0.0])
	_left[key] = [maxf(amount, cur[0]), maxf(seconds, cur[1])]

func update(delta: float) -> void:
	for k in _left.keys():
		_left[k][1] -= delta
		if _left[k][1] <= 0.0:
			_left.erase(k)

func value(key: String) -> float:
	return _left[key][0] if _left.has(key) else 0.0

func remaining(key: String) -> float:
	return _left[key][1] if _left.has(key) else 0.0

## 効いている種類（画面に出す用）。
func active() -> Array:
	return _left.keys()

func clear() -> void:
	_left.clear()
