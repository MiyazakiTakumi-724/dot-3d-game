extends RefCounted
## 城壁の道 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "cs_3"
const TITLE := "城壁の道"
const REGION := "廃城"
const THEME := "castle"
const ORIGIN := Vector2i(-14, -50)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"2223323332222233",
	"2223323332222233",
	"2222223332222333",
	"2222223333333333",
	"2222223333333333",
	"2222223333333333",
	"3322223333333333",
	"3322223333333333",
	"3322223332223333",
	"3322223322222222",
	"3321112222222222",
	"3321111222222222",
	"2231112222222222",
	"2233332222222233",
	"2233332222222333",
	"3333332222222233",
]
const OBJECTS := [
	".B...I...II.....",
	"...........I....",
	"................",
	"..............B.",
	"....B...........",
	"...............I",
	"........B.F.....",
	"I...............",
	".......T........",
	"..WWWWW..B...B.I",
	".BW...W.........",
	"..W...X......F.T",
	"..W...W.........",
	"..WWWWW.........",
	"..............F.",
	"I...............",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 6, 8, "cs_2", "", false],
	[ExitDef.Edge.NORTH, 6, 8, "cs_4", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(13, 2), Vector2.UP, EnemyKind.Kind.MIMIC, 3],
	[Vector2i(5, 6), Vector2.UP, EnemyKind.Kind.SHOOTER, 3],
	[Vector2i(7, 10), Vector2.DOWN, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(11, 7), Vector2.LEFT, EnemyKind.Kind.GHOST, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(3, 10), "silver", 4],
	[Vector2i(0, 3), "potion_m", 1],
	[Vector2i(15, 2), "scrap", 3],
	[Vector2i(11, 15), "ether", 1],
	[Vector2i(2, 8), "money", 40],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["cs_3:0", "CRACK", [Vector2i(6, 11)], [Vector2i(6, 11)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
