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
	".........2233334444444....",
	".........2233334444444....",
	".........2333334444444....",
	"22222..233333334444444....",
	"32..222233333333333333....",
	"3222222233333333333333....",
	"...2222223333333333444....",
	"...22222233333333334443333",
	"...22222223333333334444444",
	"...33322223333333334444444",
	"...33322223333322334444444",
	"...22222223333222333333333",
	".22222.222....2222333..334",
	".22222.222..............34",
	".222......................",
	"..........................",
]
const OBJECTS := [
	".........gP...P......g....",
	"..........g...g......g....",
	".........gF..........g....",
	"gg~~~..gg............g....",
	".g..~~=g.......FFggggg....",
	".ggg~~=g.......FFggggg....",
	"...ggg===...~~~..ggggg....",
	"...ggg===...~~~..ggggggggP",
	"...ggggg=~~~F..===ggg.....",
	"...gggggg.........===.....",
	"...gggg.g...g.............",
	"...gggggg............ggg~P",
	".ggg.g.g.g.............gg.",
	".g..gg.ggg..............gg",
	".ggg......................",
	"..........................",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 11, 13, "gr_1", "", false],
	[ExitDef.Edge.EAST, 8, 10, "gr_7", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(8, 4), Vector2.UP, EnemyKind.Kind.BEETLE, 2],
	[Vector2i(8, 12), Vector2.DOWN, EnemyKind.Kind.WASP, 2],
	[Vector2i(15, 11), Vector2.UP, EnemyKind.Kind.WEAK, 2],
	[Vector2i(18, 2), Vector2.LEFT, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(4, 12), Vector2.DOWN, EnemyKind.Kind.SHADOW, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(2, 13), "seal_gr", 1],
	[Vector2i(0, 4), "potion", 1],
	[Vector2i(7, 10), "wood", 2],
	[Vector2i(25, 12), "arrow", 10],
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
