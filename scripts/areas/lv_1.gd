extends RefCounted
## 灰の道 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "lv_1"
const TITLE := "灰の道"
const REGION := "溶岩"
const THEME := "lava"
const ORIGIN := Vector2i(6, 20)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"333444444444444333",
	"333344444444444333",
	"333333444444444333",
	"333333444444433333",
	"223333444444333333",
	"222333344444433333",
	"222233344333333334",
	"222223343333333344",
	"222333333333333344",
	"333333333333333344",
	"333333333333333344",
	"333333333333334444",
	"333333333333334444",
	"233333333322234444",
	"223333333322233333",
	"223333333333333333",
]
const OBJECTS := [
	".......R...R......",
	".......R..........",
	"R...........RRRRR.",
	"............R...R.",
	".....R......X...R.",
	"R...........R...R.",
	".....R.RR...RRRRR.",
	"...RR..RRR........",
	"........R.R.......",
	"..R....L........L.",
	"LLL.....LLL.RLLLLR",
	"...........LLL....",
	".....R............",
	"..................",
	".................R",
	"....RR...R..R.....",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 8, 10, "town", "", false],
	[ExitDef.Edge.SOUTH, 6, 8, "lv_2", "", false],
	[ExitDef.Edge.EAST, 11, 13, "lv_6", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(11, 7), Vector2.LEFT, EnemyKind.Kind.BOMBER, 3],
	[Vector2i(3, 2), Vector2.DOWN, EnemyKind.Kind.FLYER, 3],
	[Vector2i(13, 12), Vector2.DOWN, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(5, 10), Vector2.UP, EnemyKind.Kind.BEETLE, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(15, 3), "fire_stone", 3],
	[Vector2i(15, 15), "potion_m", 1],
	[Vector2i(4, 2), "bomb", 2],
	[Vector2i(10, 9), "obsidian", 2],
	[Vector2i(2, 8), "fire_stone", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["lv_1:0", "CRACK", [Vector2i(12, 4)], [Vector2i(12, 4)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
