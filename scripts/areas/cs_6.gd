extends RefCounted
## 古い墓地 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "cs_6"
const TITLE := "古い墓地"
const REGION := "廃城"
const THEME := "castle"
const ORIGIN := Vector2i(46, -21)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"...43333..............",
	"...43333..............",
	"...43333......333333..",
	"...43333333333333333..",
	"...33333333333322233..",
	"...33333333333322233..",
	"...4333333333332223333",
	"...4444333333333233344",
	"...4444443333333333344",
	"...44444444333333333..",
	"...44444444443777773..",
	"...44444444443777773..",
	"...44444444444777773..",
	"...44444444444777773..",
	"55444444444444477773..",
	"55444444444444477773..",
	"44444444444333777773..",
	"44444444444333777774..",
	"44444444..4...........",
	"33344444..............",
]
const OBJECTS := [
	"...I...I..............",
	"......................",
	".......I......WWWWW...",
	".......II.....WWWWW...",
	".......BB..TT.W...W...",
	"..............W...W...",
	"..............W...W...",
	".....B........WWXWW...",
	".......BB.............",
	"..............BT......",
	"...........Z..WWWWW...",
	"..............WWWWW...",
	"......B.......W...W...",
	"......B.......W...W...",
	"I.B...............W...",
	"I.B...............W...",
	"..............W...W...",
	"..............WWWWWF..",
	"......................",
	"I.....................",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 16, 18, "cs_1", "", false],
	[ExitDef.Edge.NORTH, 4, 6, "cs_7", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(11, 5), Vector2.DOWN, EnemyKind.Kind.SPEAR, 3],
	[Vector2i(4, 8), Vector2.UP, EnemyKind.Kind.MAGE, 3],
	[Vector2i(4, 16), Vector2.RIGHT, EnemyKind.Kind.MIMIC, 3],
	[Vector2i(9, 12), Vector2.LEFT, EnemyKind.Kind.SHOOTER, 3],
	[Vector2i(18, 8), Vector2.LEFT, EnemyKind.Kind.SHIELD, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(15, 4), "silver", 3],
	[Vector2i(17, 12), "money", 60],
	[Vector2i(18, 9), "seal_cs", 1],
	[Vector2i(4, 5), "silver", 1],
	[Vector2i(20, 7), "money", 40],
	[Vector2i(4, 19), "potion_m", 1],
	[Vector2i(17, 9), "money", 40],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["cs_6:0", "CRACK", [Vector2i(16, 7)], [Vector2i(16, 7)]],
	["cs_6:1", "CRYSTAL", [Vector2i(13, 14), Vector2i(13, 15), Vector2i(14, 14), Vector2i(14, 15)], [Vector2i(11, 10)], [5, 5, 6, 6]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
