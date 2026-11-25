extends RefCounted
## 風車の跡 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_7"
const TITLE := "風車の跡"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(70, 16)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"4333333322232221",
	"3333333322222222",
	"3333333222222222",
	"3333332222222222",
	"3333333222222222",
	"3333333333323322",
	"3333333333333333",
	"3333333333333333",
	"3333333333333333",
	"3333333333333333",
	"4433333333333333",
	"4433333333433333",
	"4333333333444333",
	"3333333333444333",
]
const OBJECTS := [
	"g....ggP...P.g.g",
	"g....gg.....g...",
	"................",
	"..............T.",
	"................",
	"P...........T...",
	".....B..gB......",
	"......g........g",
	"........g.TTTTT.",
	"P.gggggT..T...TT",
	".gggggg...Y...T.",
	"..ggggg...T...T.",
	"..........TTTTT.",
	".g...........ggg",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 6, 8, "gr_6", "", false],
	[ExitDef.Edge.NORTH, 8, 10, "gr_2", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(7, 8), Vector2.UP, EnemyKind.Kind.SHADOW, 2],
	[Vector2i(11, 4), Vector2.UP, EnemyKind.Kind.LOBBER, 2],
	[Vector2i(3, 2), Vector2.DOWN, EnemyKind.Kind.BEETLE, 2],
	[Vector2i(7, 4), Vector2.UP, EnemyKind.Kind.WASP, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(13, 9), "scale", 4],
	[Vector2i(9, 11), "seal_gr", 1],
	[Vector2i(6, 4), "scale", 2],
	[Vector2i(9, 8), "money", 30],
	[Vector2i(11, 13), "potion", 1],
	[Vector2i(14, 2), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_7:0", "THORNS", [Vector2i(10, 10)], [Vector2i(10, 10)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
