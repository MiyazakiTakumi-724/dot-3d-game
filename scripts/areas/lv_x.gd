extends RefCounted
## 溶岩洞 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "lv_x"
const TITLE := "溶岩洞"
const REGION := "溶岩"
const THEME := "lava"
const ORIGIN := Vector2i(-28, 104)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"2223333333333333333332222222",
	"2222333333333333333333222222",
	"2222223333333333333333222222",
	"2222223333333333333333222222",
	"2222223333333333333333222222",
	"3222223333333333322233322222",
	"3332233333333322222233322222",
	"3333333333332222222233322222",
	"3333333333333222222233322222",
	"3333333333333333222222222222",
	"3333222233333333332222222222",
	"3333322223333333333222222222",
	"3333332223333333332222223333",
	"3333333222222222222222223333",
	"3333332222222222222222223333",
	"3333333222222222222222222222",
	"3333333333222333332222222222",
	"3333333333333333332222222222",
	"3333333333333333332222222222",
	"2233333333323333333222222222",
	"2222333333222222333222222222",
	"2222333333222222233222222222",
	"2222223333222222233222222222",
	"2222222222222222233222222222",
]
const OBJECTS := [
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRR.......RRRRRRRRRRR",
	"RRRRRRR.............RRRRRRRR",
	"RRRRRR........LLL....RRRRRRR",
	"RRRRR........LLLLL....RRRRRR",
	"RRRR.........LLLLL.....RRRRR",
	"RRR..........LLLLL......RRRR",
	"RR............LLL........RRR",
	"RR.......................RRR",
	"RR.......................RRR",
	"RR.......................RRR",
	"R.......K...................",
	"RR..........................",
	"RR..........................",
	"RR.......................RRR",
	"RR..............L........RRR",
	"RRR............LLL......RRRR",
	"RRRR..........LLLLL....RRRRR",
	"RRRRR..........LLL....RRRRRR",
	"RRRRRR..........L....RRRRRRR",
	"RRRRRRR.............RRRRRRRR",
	"RRRRRRRRRR.......RRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRR",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 12, 14, "lv_4", "", false],
]
const ENEMIES := [
]
const PICKUPS := [
	[Vector2i(7, 14), RunState.PickupKind.MATERIAL, 5],
	[Vector2i(18, 7), RunState.PickupKind.HEAL, 3],
	[Vector2i(2, 16), RunState.PickupKind.MATERIAL, 3],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [像のマス, 名前, 像の色]（ボスはまだいないので像を置く）
const BOSSES := [
	[Vector2i(8, 12), "溶岩洞のぬし", Color("9a3a2a")],
]
