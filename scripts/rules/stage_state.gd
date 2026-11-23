class_name StageState
extends RefCounted
## エリアのクリア・ゲームオーバー判定。一度決まった結果は変わらない。

enum Result { PLAYING, CLEAR, GAME_OVER }

var result: Result = Result.PLAYING
var enemies_left: int

func _init(enemy_count: int) -> void:
	enemies_left = enemy_count

func on_enemy_died() -> void:
	if result != Result.PLAYING:
		return
	enemies_left -= 1
	if enemies_left <= 0:
		result = Result.CLEAR

func on_player_hp(hp: int) -> void:
	if result != Result.PLAYING:
		return
	if hp <= 0:
		result = Result.GAME_OVER
