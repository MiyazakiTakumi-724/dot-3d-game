extends RefCounted
## 野営地 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "camp"
const TITLE := "野営地"
const REGION := "はじまりの地"
const THEME := "grass"
const ORIGIN := Vector2i(0, 0)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const START := Vector2i(12, 11)
const HEIGHTS := [
	"111111112344432111111111",
	"111111112344432111111111",
	"111111112344432111111111",
	"111111112344432111111111",
	"111111112333332111111111",
	"111111111111111111222111",
	"222222111111111111222222",
	"333332111111111111233333",
	"444432111111111111234444",
	"444432111111111111234444",
	"444432111111111111234444",
	"333332111111111111233333",
	"222222111111111111222222",
	"221111111111111111111111",
	"222111111111111111111111",
	"222111111111111111111112",
	"221111111111111111111112",
	"111111111111111111111112",
	"111111111111111111112222",
	"111111111111111111222222",
]
const OBJECTS := [
	"PPTBTTBTPP...BBBPPPBTTPT",
	"TTTBBBBBPT...TTPBPTBTBBT",
	"BP......F...........F.TT",
	"TP.......B............TT",
	"PT........F.T.......BTTT",
	"TB.T..............F...BT",
	"TT....................BP",
	"TT...B............F...BB",
	"........................",
	".....F..................",
	".....B......C...........",
	"TT.................BF.TB",
	"TT....................PT",
	"TT....................TT",
	"TP....................BT",
	"TP...F................TT",
	"TT..F.................PB",
	"BB....................BT",
	"TBPTBTTTTB...TTBPTTBTTTB",
	"TTTTTBTTPT...PTTTTBTTPTP",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 8, 10, "rocks", "", false],
	[ExitDef.Edge.EAST, 8, 10, "hills", "", false],
	[ExitDef.Edge.NORTH, 10, 12, "forest", "forest_gate", false],
	[ExitDef.Edge.SOUTH, 10, 12, "town", "", false],
]
const ENEMIES := [
]
const PICKUPS := [
	[Vector2i(9, 8), RunState.PickupKind.SWORD, 1],
	[Vector2i(15, 8), RunState.PickupKind.BOW, 1],
	[Vector2i(15, 12), RunState.PickupKind.ARROWS, 50],
	[Vector2i(9, 12), RunState.PickupKind.POISON_ARROWS, 10],
	[Vector2i(12, 6), RunState.PickupKind.STAFF_FIRE, 3],
	[Vector2i(10, 6), RunState.PickupKind.STAFF_FIRE, 9],
	[Vector2i(14, 6), RunState.PickupKind.HEAL, 3],
	[Vector2i(8, 10), RunState.PickupKind.ARMOR, 1],
	[Vector2i(21, 3), RunState.PickupKind.HEAL, 2],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [像のマス, 名前, 像の色]（ボスはまだいないので像を置く）
const BOSSES := [
]
