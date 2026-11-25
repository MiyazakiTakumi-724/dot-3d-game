extends RefCounted
## 塔の最上階 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "tw_4"
const TITLE := "塔の最上階"
const REGION := "神秘の塔"
const THEME := "tower"
const ORIGIN := Vector2i(-34, 56)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"........888.........",
	"........888.........",
	"......88888888......",
	".....8888888888.....",
	"....888888888888....",
	"...88888888888888...",
	"...88888888888888...",
	"...88888888888888...",
	"..8888888888888888..",
	"..8888888888888888..",
	"...88888888888888...",
	"...88888888888888...",
	"...88888888888888...",
	"....888888888888....",
	".....8888888888.....",
	"......88888888......",
]
const OBJECTS := [
	"........sss.........",
	"........sss.........",
	"......ssssssss......",
	".....ssssssssss.....",
	"....sIssssssssIs....",
	"...ssssssssssssss...",
	"...ssssssssssssss...",
	"...ssssssssssssss...",
	"..sIssssssssssssIs..",
	"..sIsssss.ssssssIs..",
	"...ssssssssssssss...",
	"...ssssssssssssss...",
	"...ssssssssssssss...",
	"....sIssssssssIs....",
	".....ssssssssss.....",
	"......sssIIsss......",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 8, 10, "tw_3", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
	[Vector2i(9, 9), "ブライト", Color("e8e2f0")],
]
