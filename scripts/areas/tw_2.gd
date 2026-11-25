extends RefCounted
## 塔の中 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "tw_2"
const TITLE := "塔の中"
const REGION := "神秘の塔"
const THEME := "tower"
const ORIGIN := Vector2i(-26, 39)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	".........................",
	".........................",
	"................1........",
	"...111111111..11111111...",
	"...1111111111111111111...",
	"...1111111111111111111...",
	"...1111111111111111111...",
	"...1111111111111111111111",
	"...1111111111111111111111",
	"...1111111111111111111111",
	"...1111111111111111111111",
	"...1111111111111111111111",
	"...1111111111111111111111",
	"...1111111111111111111...",
	"...1111111111111111111...",
	"....1111111111111111111..",
	"....1111111111111111111..",
	"....1111111111111111111..",
	"....1111111111111111111..",
	"11111...1111111111...1...",
	"111.....1111111..........",
	"111.....11111............",
	"........11111............",
]
const OBJECTS := [
	".........................",
	".........................",
	"................s........",
	"...sssssssss..ssssssss...",
	"...sssssssssssssssssss...",
	"...sssssssssssssssssss...",
	"...ssIsssIsssIsssIIsss...",
	"...ssssssssssssssssssssWW",
	"...ssssssssssssssssssssII",
	"...ssssssssssssss........",
	"...sssss.ssss.sss........",
	"...ssssssssssssss........",
	"...ssssssssssssssssssssII",
	"...sssssssssssssssssss...",
	"...sssssssssssssssssss...",
	"....sIsssIsssIsssIIssss..",
	"....sIsssIsssIsssIIssss..",
	"....sssss...sssssssssss..",
	"....sssss...sssssssssss..",
	"Wssss...s...ssssss...s...",
	"W.s.....s...sss..........",
	"WWW.....I...I............",
	"........I...I............",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 9, 11, "tw_1", "", false],
	[ExitDef.Edge.SOUTH, 9, 11, "tw_3", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(1, 20), "star_shard", 1],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
	[Vector2i(8, 10), "双子（左）", Color("c9c3b6")],
	[Vector2i(13, 10), "双子（右）", Color("c9c3b6")],
]
