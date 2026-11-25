extends RefCounted
## 城下の跡 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "cs_1"
const TITLE := "城下の跡"
const REGION := "廃城"
const THEME := "castle"
const ORIGIN := Vector2i(0, -34)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"1111222333343333333333",
	"1111122333343333333333",
	"1111122333343333333333",
	"2211122333343333333333",
	"2211222333343333333333",
	"2221222333333333333333",
	"2222222333333333333333",
	"2222222333333333333333",
	"2222222233333333333333",
	"2222222233333333333333",
	"2222322233333333333333",
	"2222322234444432223333",
	"2222222234555432333333",
	"2222222234555433333333",
	"2222222234555433333333",
	"2222222334555433333333",
]
const OBJECTS := [
	".......I...I........B.",
	"B.....T....T.....F....",
	"T..........B..........",
	"................F.....",
	"......................",
	"...............WWWWW..",
	"...F.........B.W...W..",
	"..T............V...W..",
	"...............W...W..",
	"...............WWWWWB.",
	"............I......T..",
	".....................I",
	"......................",
	"......................",
	"..............B.......",
	".........I...I.......I",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 10, 12, "forest", "", false],
	[ExitDef.Edge.NORTH, 8, 10, "cs_2", "", false],
	[ExitDef.Edge.EAST, 12, 14, "cs_6", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(6, 11), Vector2.DOWN, EnemyKind.Kind.SPEAR, 3],
	[Vector2i(4, 4), Vector2.RIGHT, EnemyKind.Kind.MAGE, 3],
	[Vector2i(8, 4), Vector2.RIGHT, EnemyKind.Kind.MIMIC, 3],
	[Vector2i(14, 3), Vector2.DOWN, EnemyKind.Kind.SHOOTER, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(18, 6), "armor_mage", 1],
	[Vector2i(20, 11), "silver", 1],
	[Vector2i(14, 10), "money", 40],
	[Vector2i(6, 0), "potion_m", 1],
	[Vector2i(19, 4), "money", 40],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["cs_1:0", "VINES", [Vector2i(15, 7)], [Vector2i(15, 7)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
