extends RefCounted
## 塔の中 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "tw_2"
const TITLE := "塔の中"
const REGION := "神秘の塔"
const THEME := "tower"
const ORIGIN := Vector2i(-34, 20)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
]
const OBJECTS := [
	"WWWWWWWWWWWWWWWWWWWW",
	"WssssssssssssssssssW",
	"WssssssssssssssssssW",
	"WssssssssssssssssssW",
	"WsssIsssIsssIsssIssW",
	"WssssssssssssssssssW",
	"WssssssssssssssssssI",
	"Wsssssssssssssss....",
	"Wssssss.ssss.sss....",
	"Wsssssssssssssss....",
	"WssssssssssssssssssI",
	"WssssssssssssssssssW",
	"WssssssssssssssssssW",
	"WsssIsssIsssIsssIssW",
	"Wsssssss...ssssssssW",
	"Wsssssss...ssssssssW",
	"W.ssssss...ssssssssW",
	"WWWWWWWI...IWWWWWWWW",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 7, 9, "tw_1", "", false],
	[ExitDef.Edge.SOUTH, 8, 10, "tw_3", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(1, 16), "star_shard", 1],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
	[Vector2i(7, 8), "双子（左）", Color("c9c3b6")],
	[Vector2i(12, 8), "双子（右）", Color("c9c3b6")],
]
