extends RefCounted
## 沼の小道 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_6"
const TITLE := "沼の小道"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(82, 35)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	".........223333...........",
	".222.....223333..444......",
	".22222...233333..334..44..",
	".22222223333333..333.444..",
	"....22223333333333333333..",
	"....22223333333333333333..",
	"....22222333333333344433..",
	"....2222233333333334443333",
	".2222222223333333334444444",
	"22333322223333333334444444",
	"22222222223333333334444444",
	"22222222223344422433333333",
	"2222222222..45555433333...",
	"2222222222..455554........",
	"3222222.....455554........",
	"............455554........",
]
const OBJECTS := [
	".........gP...P...........",
	".ggg......g...g..g.g......",
	".g..gg...gF........g..gg..",
	".g~~~gggg.........gg.ggg..",
	"....~~=g.......FFggggggg..",
	"....~~=g.......FFggggggg..",
	"....gg===...~~~..gggg.gg..",
	"....gg===...~~~..gggg.gggP",
	".ggggggg=~~~F..===ggg.....",
	"gg..gg.gg.........===.....",
	"g.....ggg...g.............",
	"g.....ggg............ggg~P",
	"g.....gg.g.......F...gg...",
	"g.....gggg................",
	"ggggggg...................",
	"............P....P........",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 11, 13, "gr_1", "", false],
	[ExitDef.Edge.EAST, 8, 10, "gr_7", "", false],
	[ExitDef.Edge.SOUTH, 13, 16, "mv_1", "mist_gate", true],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(8, 4), Vector2.UP, EnemyKind.Kind.BEETLE, 2],
	[Vector2i(8, 12), Vector2.DOWN, EnemyKind.Kind.WASP, 2],
	[Vector2i(15, 11), Vector2.UP, EnemyKind.Kind.WEAK, 2],
	[Vector2i(4, 12), Vector2.DOWN, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(18, 2), Vector2.LEFT, EnemyKind.Kind.SHADOW, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(2, 9), "seal_gr", 1],
	[Vector2i(21, 6), "potion", 1],
	[Vector2i(2, 2), "wood", 2],
	[Vector2i(6, 9), "arrow", 10],
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
