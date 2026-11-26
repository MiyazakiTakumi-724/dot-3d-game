extends RefCounted
## 沈んだ街道 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mv_4"
const TITLE := "沈んだ街道"
const REGION := "霧の谷"
const THEME := "mist"
const ORIGIN := Vector2i(91, 94)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	".....433334............234443........",
	".....433334............2344433333333.",
	".....433334.444.......22344433333333.",
	".....433334.444...888872344433333333.",
	"....54333344444448888876344433333333.",
	"..4554443444566678888876333333333333.",
	"..4554444444444558888876222223333333.",
	"..455444444444455588887333322333333..",
	"...45444444445555554433333322333333..",
	"....554444555555555444333333333333...",
	"4445555555555555555444444433333333...",
	"...555..5555..55555444444444333333222",
	"...555...666..5555..444444...........",
	"44555....555..555...444444...........",
	"555.................444444...........",
]
const OBJECTS := [
	".....k....k.............k...k........",
	"..........g.................gkkkkkkk.",
	"..........g.ggg.............gkkkkkkk.",
	"..................gg.R......gk....kk.",
	"....k...........k.....P.....gk....kk.",
	"..ggggkk....................gk....kk.",
	"..gggg...............k......gkkkNkkk.",
	"..gggg.........kk.B...........kk..k..",
	"....gg................P..............",
	"....~~~~~~==.....ggg.................",
	"~~~~~g......=====ggg.k.~~~~~~~~~Pg...",
	".....g..........g~~~~......P.k..~~~~=",
	"...k.g..........gg...................",
	"....................P................",
	"....................k....k...........",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 25, 27, "mv_3", "", false],
	[ExitDef.Edge.NORTH, 6, 9, "mv_2", "mv_gate", true],
	[ExitDef.Edge.SOUTH, 21, 24, "mv_5", "mv_boss", true],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(8, 7), Vector2.DOWN, EnemyKind.Kind.WOLF, 4],
	[Vector2i(26, 7), Vector2.DOWN, EnemyKind.Kind.DARK_KNIGHT, 4],
	[Vector2i(4, 11), Vector2.LEFT, EnemyKind.Kind.GHOST, 4],
	[Vector2i(18, 8), Vector2.LEFT, EnemyKind.Kind.WOLF, 4],
	[Vector2i(10, 12), Vector2.RIGHT, EnemyKind.Kind.SHADOW, 4],
	[Vector2i(22, 9), Vector2.UP, EnemyKind.Kind.LOBBER, 4],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(30, 3), "potion_l", 1],
	[Vector2i(15, 12), "arrow", 10],
	[Vector2i(13, 3), "mist_moss", 2],
	[Vector2i(20, 4), "dark_shard", 1],
	[Vector2i(1, 14), "money", 50],
	[Vector2i(13, 4), "dark_shard", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["mv_4:0", "BRITTLE", [Vector2i(32, 6)], [Vector2i(32, 6)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
