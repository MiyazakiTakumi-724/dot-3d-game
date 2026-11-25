extends RefCounted
## 地下牢 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "cs_8"
const TITLE := "地下牢"
const REGION := "廃城"
const THEME := "castle"
const ORIGIN := Vector2i(-30, -64)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"2222222222222222",
	"2222222222222222",
	"2222222222222233",
	"2222222222222233",
	"2222222222123333",
	"2222222222223333",
	"3333222222223333",
	"3333322114442222",
	"3333322144444222",
	"2233222244444332",
	"2222222244444222",
	"2222222224442222",
	"3322222222222222",
	"3332222221112222",
]
const OBJECTS := [
	"....~~..........",
	"....~~.......I..",
	"....~~..........",
	"..B.~~.........I",
	"....~~..........",
	"I..F~~..........",
	".....V..........",
	"....~~.B.......I",
	"....~~...F......",
	"IF..~~..........",
	"....~~.B.......I",
	"....~~.I........",
	".F..~~.F........",
	"..B.~~.........T",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 4, 6, "cs_4", "", false],
	[ExitDef.Edge.WEST, 6, 8, "cs_x", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(11, 6), Vector2.DOWN, EnemyKind.Kind.MIMIC, 3],
	[Vector2i(6, 5), Vector2.UP, EnemyKind.Kind.SHOOTER, 3],
	[Vector2i(9, 10), Vector2.UP, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(10, 2), Vector2.RIGHT, EnemyKind.Kind.GHOST, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(9, 11), "seal_cs", 1],
	[Vector2i(9, 1), "potion_m", 1],
	[Vector2i(11, 10), "scrap", 3],
	[Vector2i(6, 7), "ether", 1],
	[Vector2i(8, 7), "money", 40],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["cs_8:0", "VINES", [Vector2i(5, 6)], [Vector2i(5, 6)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
