class_name EnemyRoster
extends RefCounted
## 倒した敵の復活の時間。倒してから RESPAWN_SECONDS たつと戻る。
## 戻るかどうかはエリアに入ったときにだけ調べるので、今いるエリアで目の前に急に湧くことはない。
## 死んでも敵は復活しない（ここは死んでも変わらない）。

const RESPAWN_SECONDS := 300.0

## ゲームの中の時間（秒）。インベントリを開いて止まっている間は進めない
var clock := 0.0
var _killed_at := {}  # "エリア:番号" → 倒した時刻

func tick(delta: float) -> void:
	clock += delta

func kill(area_id: String, index: int) -> void:
	_killed_at[_key(area_id, index)] = clock

## その敵がいるか。倒されていないか、倒してから300秒以上たった（たっていたら記録を消す）。
func present(area_id: String, index: int) -> bool:
	var k := _key(area_id, index)
	if not _killed_at.has(k):
		return true
	if clock - float(_killed_at[k]) >= RESPAWN_SECONDS:
		_killed_at.erase(k)
		return true
	return false

static func _key(area_id: String, index: int) -> String:
	return "%s:%d" % [area_id, index]
