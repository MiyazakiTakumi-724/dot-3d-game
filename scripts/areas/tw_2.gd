extends RefCounted
## 塔の中 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "tw_2"
const TITLE := "塔の中"
const REGION := "神秘の塔"
const THEME := "tower"
const ORIGIN := Vector2i(-32, 54)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
	"11111111111111111111111111111111",
]
const OBJECTS := [
	"WWWWWWWWWWWWWI...IWWWWWWWWWWWWWW",
	"Wsssssssssssss...ssssssssssssssW",
	"Wsssssssssssss...ssssssssssssssW",
	"Wsssssssssssss...ssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssIssssIssssIssssIssssIsssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssKssssssssKssssssssssW",
	"Issssssssss.ssssssss.ssssssssssW",
	"....sssssssssssssssssssssssssssW",
	"....sssssssssssssssssssssssssssW",
	"....sssssssssssssssssssssssssssW",
	"IssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssIssssIssssIssssIssssIsssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"WssssssssssssssssssssssssssssssW",
	"Wsssssssssssssssssssssssssssss.W",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 14, 16, "tw_1", "", false],
	[ExitDef.Edge.WEST, 16, 18, "tw_3", "", false],
]
const ENEMIES := [
]
const PICKUPS := [
	[Vector2i(30, 30), RunState.PickupKind.HEAL, 3],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [像のマス, 名前, 像の色]（ボスはまだいないので像を置く）
const BOSSES := [
	[Vector2i(11, 14), "双子（左）", Color("c9c3b6")],
	[Vector2i(20, 14), "双子（右）", Color("c9c3b6")],
]
