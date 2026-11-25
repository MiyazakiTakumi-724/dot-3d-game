extends RefCounted
## 岩窟 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mt_x"
const TITLE := "岩窟"
const REGION := "山岳"
const THEME := "mountain"
const ORIGIN := Vector2i(-74, -12)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"222333222222222222",
	"222333222222222222",
	"222222222222233222",
	"222222222222233322",
	"222222222222233322",
	"222222222223333333",
	"222222222223444444",
	"222222222223455555",
	"222222222223456666",
	"222222222223456666",
	"222222222222456666",
	"222222222223455555",
	"222222222223444444",
	"222222222223333333",
]
const OBJECTS := [
	"RRRRRRRRRRRRRRRRRR",
	"RRRRRR.......RRRRR",
	"RRRR...........RRR",
	"RRR.............RR",
	"RR...............R",
	"R.................",
	"R.................",
	"R................R",
	"R.................",
	"R.................",
	"RR................",
	"RRR.............RR",
	"RRRR...........RRR",
	"RRRRRR.......RRRRR",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 8, 10, "mt_3", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(13, 4), "iron_ore", 4],
	[Vector2i(11, 10), "money", 50],
	[Vector2i(1, 9), "iron_ore", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
	[Vector2i(6, 7), "岩窟のぬし", Color("6a6c73")],
]
