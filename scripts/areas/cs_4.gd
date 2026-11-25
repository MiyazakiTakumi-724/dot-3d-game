extends RefCounted
## 城の中庭 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "cs_4"
const TITLE := "城の中庭"
const REGION := "廃城"
const THEME := "castle"
const ORIGIN := Vector2i(-14, -64)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"22222333445544433332111122222233",
	"22222233344544433332211222222233",
	"32222243344444433332222222333333",
	"33222243344444433333222233333333",
	"33222253334444444333322333333333",
	"33336666644444444333333333333333",
	"44446666644444444333333222333334",
	"44446666644444334433555322233344",
	"44445555544444333335555533333344",
	"44445444434443344455555443333333",
	"44444433333333333335555433333333",
	"44444433333333333333555333333333",
	"44444433334433333333333333333333",
	"44444433334433333333333333333334",
]
const OBJECTS := [
	"......T..I....I....II...........",
	"........................B.......",
	"..........................WWWWW.",
	"......................FF..W...W.",
	"..........................Y...W.",
	".........F.........T......W...W.",
	".......T..................WWWWW.",
	"B...............................",
	".............B.....T........I...",
	"................................",
	"T...........BB........B.........",
	"............F.....F.............",
	"..F.......II....................",
	".....I...II...........FI...I...B",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 6, 8, "cs_3", "", false],
	[ExitDef.Edge.SOUTH, 24, 26, "cs_2", "cs_gate", true],
	[ExitDef.Edge.NORTH, 15, 18, "cs_5", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(4, 3), Vector2.UP, EnemyKind.Kind.SHOOTER, 3],
	[Vector2i(22, 9), Vector2.UP, EnemyKind.Kind.MELEE, 3],
	[Vector2i(23, 5), Vector2.RIGHT, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(17, 8), Vector2.DOWN, EnemyKind.Kind.GHOST, 3],
	[Vector2i(12, 4), Vector2.RIGHT, EnemyKind.Kind.SHOOTER, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(29, 3), "potion_l", 1],
	[Vector2i(24, 8), "silver", 1],
	[Vector2i(10, 10), "money", 40],
	[Vector2i(16, 12), "potion_m", 1],
	[Vector2i(25, 0), "scrap", 3],
	[Vector2i(22, 6), "money", 40],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["cs_4:0", "THORNS", [Vector2i(26, 4)], [Vector2i(26, 4)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
