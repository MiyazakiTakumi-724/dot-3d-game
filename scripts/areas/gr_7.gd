extends RefCounted
## 風車の跡 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_7"
const TITLE := "風車の跡"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(108, 35)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	".......43333.....",
	"..444..33333.....",
	"..444.333333322..",
	"..444433333332222",
	"....4433333333323",
	"....4433333333323",
	"44444444333344444",
	"44444444333344444",
	"44444444443344444",
	"44444445444444444",
	"44444445445555554",
	"5444444444555555.",
	"5544444455555555.",
	"......4445555555.",
	"........45555555.",
	".................",
]
const OBJECTS := [
	".......P...P.....",
	"..ggg............",
	".................",
	"...............T.",
	"................P",
	"................P",
	"P................",
	"P................",
	"....T....B.......",
	"....gB...........",
	"......g...TTTTTTP",
	"P.ggggg..gT....T.",
	".gggggg...Y....T.",
	"......g...T....T.",
	"..........TTTTTT.",
	".................",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 8, 10, "gr_6", "", false],
	[ExitDef.Edge.NORTH, 8, 10, "gr_2", "", false],
	[ExitDef.Edge.EAST, 6, 9, "gr_t", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(7, 10), Vector2.UP, EnemyKind.Kind.SHADOW, 2],
	[Vector2i(11, 4), Vector2.UP, EnemyKind.Kind.LOBBER, 2],
	[Vector2i(3, 2), Vector2.DOWN, EnemyKind.Kind.BEETLE, 2],
	[Vector2i(7, 4), Vector2.UP, EnemyKind.Kind.WASP, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(13, 11), "scale", 4],
	[Vector2i(9, 13), "seal_gr", 1],
	[Vector2i(5, 4), "scale", 2],
	[Vector2i(15, 4), "money", 30],
	[Vector2i(1, 11), "potion", 1],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_7:0", "THORNS", [Vector2i(10, 12)], [Vector2i(10, 12)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
