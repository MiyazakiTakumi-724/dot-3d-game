extends RefCounted
## 草原の入口 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_1"
const TITLE := "草原の入口"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(82, 18)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"4444444..........5........",
	"4444444..........4........",
	"3444444...44444444........",
	"344444344444444444...34...",
	"33333333444444433333333...",
	"33333334444444333333333333",
	"33333334444433333333322222",
	"33333334444333333333322222",
	"33333334444333333333322222",
	"33333334443333333332222222",
	"44333233333333333332222233",
	"..442223333333444332222...",
	"..4422233333334443322222..",
	"..4422233333334443..2222..",
	"..4433333.33334..3..222...",
	"444433333.33333...3.......",
	"444.......33333...3.......",
]
const OBJECTS := [
	".................~........",
	".................~........",
	"...........g.g...~........",
	"g.....ggg........~...F....",
	".B...gggggggggg~~~........",
	"P....gggggggggg~~g...B...P",
	".....gggggggggg~~g........",
	".......B.gggggg~~g.gg.....",
	".......B.gggggg~~g.gg.....",
	".........gggggg~~T........",
	"PgTTTXTT.gggggg==........P",
	"..TT...TT.g.ggg..=...T....",
	"..TT...TB.ggggg..=.gg.....",
	"..TT...T.gg......=........",
	"..TTTTTT..g......=...T....",
	"gggg......g.......~.......",
	"g.g.......P...P...~.......",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 6, 9, "hills", "", false],
	[ExitDef.Edge.EAST, 6, 9, "gr_2", "", false],
	[ExitDef.Edge.SOUTH, 11, 13, "gr_6", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(11, 11), Vector2.RIGHT, EnemyKind.Kind.BEETLE, 2],
	[Vector2i(18, 10), Vector2.DOWN, EnemyKind.Kind.WASP, 2],
	[Vector2i(12, 3), Vector2.LEFT, EnemyKind.Kind.WEAK, 2],
	[Vector2i(4, 2), Vector2.DOWN, EnemyKind.Kind.CHARGER, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(4, 13), "money", 40],
	[Vector2i(9, 11), "potion", 1],
	[Vector2i(1, 16), "wood", 2],
	[Vector2i(11, 3), "arrow", 10],
	[Vector2i(21, 13), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_1:0", "CRACK", [Vector2i(5, 10)], [Vector2i(5, 10)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
