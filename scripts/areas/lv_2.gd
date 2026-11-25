extends RefCounted
## 湯けむりの休み場 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "lv_2"
const TITLE := "湯けむりの休み場"
const REGION := "溶岩"
const THEME := "lava"
const ORIGIN := Vector2i(6, 36)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"2333323332222233",
	"3333323332222233",
	"3333223332222223",
	"3333223332222223",
	"3333233322222233",
	"3333233332233333",
	"3333333333334444",
	"3333333333334444",
	"3333333333334444",
	"3333333333333333",
	"3333333333333333",
	"3333333333333333",
	"3333334443333333",
	"3333334443223333",
	"3333334443223333",
	"3333334443333333",
]
const OBJECTS := [
	".....R...R...R..",
	"................",
	"............R...",
	"................",
	"................",
	"......R.R......R",
	"................",
	"...........M....",
	"................",
	"...R.....C.....R",
	"...R............",
	"................",
	"....R........R..",
	"..R.............",
	".R..............",
	".....R...R......",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 6, 8, "lv_1", "", false],
	[ExitDef.Edge.EAST, 6, 8, "lv_3", "", false],
	[ExitDef.Edge.SOUTH, 6, 8, "lv_4", "lv_gate", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(2, 8), Vector2.LEFT, EnemyKind.Kind.MIMIC, 3],
	[Vector2i(2, 4), Vector2.LEFT, EnemyKind.Kind.SHOOTER, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(10, 12), "potion_m", 1],
	[Vector2i(2, 9), "bomb", 2],
	[Vector2i(1, 13), "fire_stone", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
	[Vector2i(11, 7), "溶岩"],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
