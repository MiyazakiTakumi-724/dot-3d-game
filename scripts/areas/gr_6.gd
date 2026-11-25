extends RefCounted
## 沼の小道 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_6"
const TITLE := "沼の小道"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(48, 16)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"2221111112222333333333",
	"2221111122222333333333",
	"2221112222222233333333",
	"2221122222222233333332",
	"2221122222222222223222",
	"2222222222222222233322",
	"2222222222222222333333",
	"2222222222222222333333",
	"2222222222222222233333",
	"2222222222222222233322",
	"2222222222222222222333",
	"2222222222222222222233",
	"2222222222222222222222",
	"2222222222222222222222",
]
const OBJECTS := [
	"gggggggggP...P....g.gg",
	"gggggggg.g...g....gggg",
	"gggggggggF........gggg",
	"gg~~gggg..........gggg",
	"ggg~~=g.......Fggggggg",
	"ggggg===...~~~.ggggggP",
	"ggggggg=~~~F..==gg....",
	"gggggggg........==....",
	"ggggg......g..........",
	"ggggg.............gg~P",
	"ggg.g.............gggg",
	"gg.gg.....g........ggg",
	"ggggggggg.gB........g.",
	"ggg.gggggggg..B...gggg",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 10, 12, "gr_1", "", false],
	[ExitDef.Edge.EAST, 6, 8, "gr_7", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(7, 10), Vector2.DOWN, EnemyKind.Kind.BEETLE, 2],
	[Vector2i(7, 4), Vector2.UP, EnemyKind.Kind.WASP, 2],
	[Vector2i(14, 9), Vector2.UP, EnemyKind.Kind.WEAK, 2],
	[Vector2i(16, 2), Vector2.LEFT, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(3, 10), Vector2.DOWN, EnemyKind.Kind.SHADOW, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(2, 11), "seal_gr", 1],
	[Vector2i(3, 13), "potion", 1],
	[Vector2i(19, 0), "wood", 2],
	[Vector2i(14, 5), "arrow", 10],
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
