class_name AreaDef
extends RefCounted
## 1つのエリアのデータ。大陸の上の位置（origin、左上のマス）と、地図・出口・敵・拾いもの。
## 地図は Terrain.parse_layers の2層（heights・objects）。

const ENTRY_SAFE_RADIUS := 3  ## 出口からこのマス数以内には敵を置かず、敵も入らない

var id: String = ""
var title: String = ""  ## 画面に出す名前
var region: String = ""  ## 地方の名前（はじまりの地・山岳・草原・廃城・溶岩・神秘の塔）
var theme: String = "grass"  ## 地面の見た目（Terrain.surface）
var open_flat := false  ## 広場（たき火・町・ボスの間）。広い平地があってよい
var origin: Vector2i = Vector2i.ZERO
var heights: Array = []
var objects: Array = []
## 地図がないとき（テストなど）の大きさ
var map_size: Vector2i = Vector2i.ZERO
var exits: Array[ExitDef] = []
## [cell: Vector2i, dir: Vector2, kind: EnemyKind.Kind]
var enemies: Array = []
## [cell: Vector2i, kind: RunState.PickupKind, amount: int]
var pickups: Array = []
## 武器で開く仕掛け
var gimmicks: Array[Gimmick] = []
## ボスの居場所 [像のマス: Vector2i, 名前: String, 像の色: Color]
var bosses: Array = []

func size() -> Vector2i:
	if heights.is_empty():
		return map_size
	return Vector2i(String(heights[0]).length(), heights.size())

func rect() -> Rect2i:
	return Rect2i(origin, size())

## すべての出口のマスから、チェビシェフ距離3以内のマス。
func entry_safe_cells() -> Dictionary:
	var out := {}
	var s := size()
	for ex in exits:
		for c in ex.cells(s):
			for dy in range(-ENTRY_SAFE_RADIUS, ENTRY_SAFE_RADIUS + 1):
				for dx in range(-ENTRY_SAFE_RADIUS, ENTRY_SAFE_RADIUS + 1):
					var n: Vector2i = c + Vector2i(dx, dy)
					if n.x >= 0 and n.y >= 0 and n.x < s.x and n.y < s.y:
						out[n] = true
	return out

func pickup_id(index: int) -> String:
	return "%s:%d" % [id, index]
