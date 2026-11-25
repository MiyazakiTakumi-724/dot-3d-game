extends RefCounted
## 岩窟 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mt_x"
const TITLE := "岩窟"
const REGION := "山岳"
const THEME := "mountain"
const ORIGIN := Vector2i(-156, -40)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"2333333333333333333333333322",
	"2333333333333333333333333322",
	"3333333333333333333333333322",
	"3333333333333333333333333332",
	"3333333333333333333333333332",
	"2233333333223333333333333333",
	"2233333333223333333333333333",
	"2233333332223333333333333333",
	"2233333332223333333333333333",
	"2333333332222333333333344444",
	"3333333322222223333333345555",
	"3333333322222223333333345555",
	"3333333322222333333333345555",
	"2223333333223333333333344444",
	"2222333333223333333333333333",
	"2222233333333333333333333333",
	"2222222233333333333332333333",
	"3322222223333333332222233333",
	"3322222223333333322222223333",
	"2222222223333333222222222223",
	"2222222222333333222222222222",
	"2222222222223333222222222222",
	"2222222222333333222222222222",
	"2222222223333332222222222223",
]
const OBJECTS := [
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRR.RRRRRRRRRRRRRRR",
	"RRRRRRRR.........RRRRRRRRRRR",
	"RRRRRR.............RRRRRRRRR",
	"RRRR.................RRRRRRR",
	"RRRR.................RRRRRRR",
	"RRR...................RRRRRR",
	"RR.....................RRRRR",
	"RR.....................RRRRR",
	"RR.....................R....",
	"RR......K..............R....",
	"RR..........................",
	"RR.....................RRRRR",
	"RR.....................RRRRR",
	"RR.....................RRRRR",
	"RRR...................RRRRRR",
	"RRRR.................RRRRRRR",
	"RRRR.................RRRRRRR",
	"RRRRRR.............RRRRRRRRR",
	"RRRRRRRR.........RRRRRRRRRRR",
	"RRRRRRRRRRRR.RRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRR",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 10, 12, "mt_3", "", false],
]
const ENEMIES := [
]
const PICKUPS := [
	[Vector2i(16, 14), RunState.PickupKind.MATERIAL, 5],
	[Vector2i(8, 20), RunState.PickupKind.MONEY, 50],
	[Vector2i(4, 18), RunState.PickupKind.MATERIAL, 3],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [像のマス, 名前, 像の色]（ボスはまだいないので像を置く）
const BOSSES := [
	[Vector2i(8, 11), "岩窟のぬし", Color("6a6c73")],
]
