extends RefCounted
## 山小屋 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mt_2"
const TITLE := "山小屋"
const REGION := "山岳"
const THEME := "mountain"
const ORIGIN := Vector2i(-40, -12)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"4444444433444333",
	"4444444443444333",
	"4444444444444333",
	"4444344444444333",
	"4443344444444333",
	"4444444444444443",
	"5555444444444444",
	"5555444444444444",
	"5555444444444444",
	"4444444444444444",
	"3333344444444444",
	"2233344444444444",
	"2233334444444444",
	"2233333444444444",
	"2233333344444444",
	"3333333344444444",
]
const OBJECTS := [
	".B...P...R...R..",
	"................",
	"..............RR",
	"...R..R......P..",
	"......R.......R.",
	"R.......P.......",
	"..........P.....",
	"......M......B..",
	"................",
	"R...R...C.......",
	"................",
	"..R.............",
	".P..............",
	"....R.......R...",
	"..R...R....R....",
	"...R.B.R...R....",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 8, 10, "mt_1", "", false],
	[ExitDef.Edge.WEST, 6, 8, "mt_3", "", false],
	[ExitDef.Edge.NORTH, 10, 12, "mt_4", "mt_gate", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(8, 4), Vector2.RIGHT, EnemyKind.Kind.SPEAR, 2],
	[Vector2i(3, 13), Vector2.RIGHT, EnemyKind.Kind.WASP, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(7, 2), "potion", 1],
	[Vector2i(14, 7), "bone", 2],
	[Vector2i(3, 2), "iron_ore", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
	[Vector2i(6, 7), "山岳"],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
