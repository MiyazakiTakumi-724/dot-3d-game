extends RefCounted
## 王の間 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "cs_5"
const TITLE := "王の間"
const REGION := "廃城"
const THEME := "castle"
const ORIGIN := Vector2i(-10, -84)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"111111111111111111111111",
	"111111111111111111111111",
	"111333333333333333333111",
	"111331111111111111133111",
	"111331111111111111133111",
	"111331111111111111133111",
	"111331111111111111133111",
	"111331111111111111133111",
	"111331111111111111133111",
	"111331111111111111133111",
	"111331111111111111133111",
	"111331111111111111133111",
	"111331111111111111133111",
	"111331111111111111133111",
	"111331111111111111133111",
	"111331111122222211133111",
	"111332211123333212233111",
	"111111111123333211111111",
	"111111111123333211111111",
	"111111111123333211111111",
]
const OBJECTS := [
	"........................",
	"..WWWWWWWWWWWWWWWWWWWW..",
	"..W..................W..",
	"..W..ssssssssssssss..W..",
	"..W..ssssssssssssss..W..",
	"..W..sssIssssssIsss..W..",
	"..W..sssssss.ssssss..W..",
	"..W..ssssssssssssss..W..",
	"..W..ssssssssssssss..W..",
	"..W..sssIssssssIsss..W..",
	"..W..ssssssssssssss..W..",
	"..W..ssssssssssssss..W..",
	"..W..ssssssssssssss..W..",
	"..W..sssIssssssIsss..W..",
	"..W..ssssssssssssss..W..",
	"..W..ssssssssssssss..W..",
	"..W.....sss....s.....W..",
	"...ssssssss....sss.ssW..",
	"..WWWWWWWWs....sWWWWWW..",
	"..........I....I........",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 11, 14, "cs_4", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(1, 2), "scrap", 3],
	[Vector2i(1, 11), "ether", 1],
	[Vector2i(18, 17), "money", 40],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
	[Vector2i(12, 6), "廃城の主", Color("8a7f9a")],
]
