extends RefCounted
## 硫黄の谷 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "lv_7"
const TITLE := "硫黄の谷"
const REGION := "溶岩"
const THEME := "lava"
const ORIGIN := Vector2i(38, 36)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"3322222222233333",
	"3322222222223333",
	"2222222222223333",
	"2222222332666333",
	"2222233336666633",
	"2233334456666633",
	"3333333346666644",
	"3334444444666444",
	"3334444444444444",
	"3333344444444444",
	"3333334444444444",
	"3333334444444444",
	"4443344444444444",
	"4444444444444444",
	"4444444444444444",
	"4444444444444444",
]
const OBJECTS := [
	"...............R",
	"R....RR.........",
	"...L.R..........",
	"....L........R..",
	"....LR........R.",
	"................",
	"..........R.....",
	".......R...R....",
	"R...R..L........",
	".......L...R....",
	"......L....R....",
	".....RL.........",
	"R...............",
	"...........R..R.",
	"................",
	".....R...RL.RR..",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 9, 11, "lv_3", "", false],
	[ExitDef.Edge.SOUTH, 6, 8, "lv_8", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(8, 9), Vector2.DOWN, EnemyKind.Kind.MIMIC, 3],
	[Vector2i(9, 2), Vector2.UP, EnemyKind.Kind.SHOOTER, 3],
	[Vector2i(2, 5), Vector2.UP, EnemyKind.Kind.BOMBER, 3],
	[Vector2i(4, 11), Vector2.UP, EnemyKind.Kind.FLYER, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(13, 4), "seal_lv", 1],
	[Vector2i(13, 2), "potion_m", 1],
	[Vector2i(12, 11), "bomb", 2],
	[Vector2i(5, 12), "obsidian", 2],
	[Vector2i(12, 2), "fire_stone", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
