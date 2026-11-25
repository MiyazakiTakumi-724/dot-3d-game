extends RefCounted
## 花の丘 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_3"
const TITLE := "花の丘"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(108, 1)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"..3444333333.....",
	".33443333333.....",
	".33333.3333333...",
	".4333344333333...",
	".4333344433333...",
	".4333334333333333",
	".4333666333344444",
	".3333666334444444",
	"44566666633344444",
	".3.33666333333344",
	"333336663333333..",
	"444433333333333..",
	"444433444333333..",
	"44443444433333...",
	"4444444444.......",
	"4444444444.......",
	"....444444.......",
]
const OBJECTS := [
	"..F....P...P.....",
	".TTTTT.....g.....",
	".T...T.....g.....",
	".T...TF....FFF...",
	".T...T..FFFFFF...",
	".TTYTTT.FFFFFFFFP",
	".gg.g..FFFF......",
	".g...FFFFFFF.....",
	".....F.FFFFF.....",
	"...FFFFFFFgFFFFFP",
	"...FFFF.FggFFFF..",
	"....FFFFFgggF....",
	"....FF.......FF..",
	"............B....",
	".....g...........",
	"FF...P...P.......",
	".....P...P.......",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 6, 8, "gr_2", "", false],
	[ExitDef.Edge.EAST, 6, 8, "gr_4", "", false],
	[ExitDef.Edge.NORTH, 8, 10, "gr_8", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(6, 8), Vector2.LEFT, EnemyKind.Kind.WEAK, 2],
	[Vector2i(2, 13), Vector2.UP, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(11, 6), Vector2.DOWN, EnemyKind.Kind.SHADOW, 2],
	[Vector2i(2, 7), Vector2.DOWN, EnemyKind.Kind.LOBBER, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(2, 2), "potion_m", 2],
	[Vector2i(3, 0), "arrow", 10],
	[Vector2i(7, 10), "herb", 3],
	[Vector2i(13, 11), "scale", 2],
	[Vector2i(4, 7), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_3:0", "THORNS", [Vector2i(3, 5)], [Vector2i(3, 5)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
