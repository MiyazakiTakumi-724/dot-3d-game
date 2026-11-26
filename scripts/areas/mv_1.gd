extends RefCounted
## 霧の入口 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mv_1"
const TITLE := "霧の入口"
const REGION := "霧の谷"
const THEME := "mist"
const ORIGIN := Vector2i(89, 51)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"....5555556.776555544433.",
	"..555555556.88...5544433.",
	"..555555556.888665533333.",
	"..5555555567888886533333.",
	".55555555567888886533333.",
	".45555555567888885533332.",
	".44444557777888888543333.",
	"...4445577778888885433333",
	"...4444488888888855444444",
	"....344888888888854444444",
	"....344888888888854444444",
	"..34567888888885554444444",
	"..34567888888885554444444",
	"....344777787755554433333",
	"...4444466665555554322...",
	"44444444444455555543222..",
	".......444444455554322222",
	".......44444444....3322..",
	".......444444.4...43.222.",
	".......444444.44444..222.",
]
const OBJECTS := [
	".....k....k...g......ggg.",
	"....k.....g.......kkkkkg.",
	"....P.....g...gRR.k...kg.",
	"..........gggg.kk.k...k..",
	"..........gggg.kk.k...k..",
	"....P.....gggg....k...k..",
	".....k....gg......kkXkk..",
	".....k....gg......kkXkk.k",
	"..........gggg...........",
	"......PkPP...............",
	"......PkPP...............",
	"...........P......g......",
	"...........P......g......",
	".......k.......ggggg.R..k",
	"...~~~==kkP....ggggg.....",
	"~~~~....====...ggg~~~~~..",
	"............~~~~~~gg..~~~",
	"....................P....",
	".......g....g............",
	".......k....k.g..........",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 6, 9, "gr_6", "mist_gate", false],
	[ExitDef.Edge.SOUTH, 8, 11, "mv_2", "", false],
	[ExitDef.Edge.EAST, 8, 12, "mv_6", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(11, 13), Vector2.UP, EnemyKind.Kind.WOLF, 4],
	[Vector2i(12, 6), Vector2.RIGHT, EnemyKind.Kind.DARK_KNIGHT, 4],
	[Vector2i(6, 13), Vector2.UP, EnemyKind.Kind.GHOST, 4],
	[Vector2i(21, 16), Vector2.LEFT, EnemyKind.Kind.WOLF, 4],
	[Vector2i(2, 5), Vector2.LEFT, EnemyKind.Kind.SHADOW, 4],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(19, 2), "mist_moss", 3],
	[Vector2i(3, 2), "arrow", 10],
	[Vector2i(17, 11), "mist_moss", 2],
	[Vector2i(22, 19), "dark_shard", 1],
	[Vector2i(17, 5), "dark_shard", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["mv_1:0", "CRACK", [Vector2i(20, 6), Vector2i(20, 7)], [Vector2i(20, 6)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
