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
	"3444444....4444444........",
	"344444344444444444...34...",
	"33333333444444433333333...",
	"33333334444444333333333333",
	"33333334444433333333322222",
	"33333334444333333333322222",
	"33333334444333333333322222",
	"33333334443333333332222222",
	"44333233333333333332222233",
	"44442223333333444333333333",
	"..442223333333444333333333",
	"..442223..3333444333333333",
	"..443333..33334..333333333",
	"..........33333..333333333",
	"..........33333...3.......",
]
const OBJECTS := [
	".................~........",
	".................~........",
	"...........g.g...~........",
	"g.....ggg........~...F....",
	".B...gggggggggg~~~........",
	"P....gggggggggg~~....B...P",
	".....ggg.gggggg~~g........",
	".......B.gggggg~~g.gg.....",
	".......B.gggggg~~g.gg.....",
	".........gggggg~~T........",
	"P.TTTXTT.gggggg==........P",
	"ggTT...TT.g.ggg..U.TTTTTTT",
	"..TT...T.Tggggg....TT....T",
	"..TT...T..g...B....EE....T",
	"..TTTTTT..g......=.TT....T",
	"..........g.......~TTTTTTT",
	"..........P...P...~.......",
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
	[Vector2i(24, 12), "herb", 4],
	[Vector2i(17, 5), "potion", 1],
	[Vector2i(1, 10), "wood", 2],
	[Vector2i(8, 6), "arrow", 10],
	[Vector2i(9, 11), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_1:0", "CRACK", [Vector2i(5, 10)], [Vector2i(5, 10)]],
	["gr_1:1", "PLATE", [Vector2i(19, 13), Vector2i(20, 13)], [Vector2i(17, 11)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
