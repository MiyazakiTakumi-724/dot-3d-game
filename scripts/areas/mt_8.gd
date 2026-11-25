extends RefCounted
## 吹雪の谷 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mt_8"
const TITLE := "吹雪の谷"
const REGION := "山岳"
const THEME := "mountain"
const ORIGIN := Vector2i(-74, -12)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"...........5.444...",
	"...........6.4.4...",
	"...........654.44..",
	"..66666.5556..555..",
	"..666665555655555..",
	"..66666655575666666",
	"..66666655575666666",
	"..66666665575677777",
	"..66666555485677777",
	"..66666555888677777",
	"...6665558888866666",
	"...66665588888555..",
	"..76666658888855...",
	".77666666....555566",
	".7766.6666...555555",
	".766..6666666555555",
	".........666.......",
]
const OBJECTS := [
	"...................",
	"...................",
	"...................",
	"..RRRRR............",
	"..RRRRR......R.....",
	"..R...R..R..R..R.RR",
	"..R...R..R..R..R.RR",
	"..R...V............",
	"..R...R............",
	"..RRRRR............",
	"....R.........BR.RR",
	"...................",
	"..R.B..........R...",
	"........P.....R....",
	"....R..............",
	"..............R....",
	"...................",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 7, 9, "mt_4", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(7, 14), Vector2.LEFT, EnemyKind.Kind.LOBBER, 2],
	[Vector2i(14, 14), Vector2.DOWN, EnemyKind.Kind.FLYER, 2],
	[Vector2i(3, 13), Vector2.DOWN, EnemyKind.Kind.SPEAR, 2],
	[Vector2i(10, 10), Vector2.DOWN, EnemyKind.Kind.WASP, 2],
	[Vector2i(7, 5), Vector2.LEFT, EnemyKind.Kind.MELEE, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(3, 5), "potion_m", 2],
	[Vector2i(2, 14), "seal_mt", 1],
	[Vector2i(17, 14), "snow", 2],
	[Vector2i(12, 11), "money", 30],
	[Vector2i(10, 16), "potion", 1],
	[Vector2i(9, 9), "iron_ore", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["mt_8:0", "VINES", [Vector2i(6, 7)], [Vector2i(6, 7)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
