extends RefCounted
## 古い墓地 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "cs_6"
const TITLE := "古い墓地"
const REGION := "廃城"
const THEME := "castle"
const ORIGIN := Vector2i(22, -34)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"333322222333322223",
	"333322222233322222",
	"333322222233323322",
	"333222222233111322",
	"333222222233111322",
	"333332222222111222",
	"333333332222212223",
	"443333333222222223",
	"443333333322222223",
	"443333333333333322",
	"433333333333333322",
	"433333333333333322",
	"333333333322333332",
	"333333333222233333",
	"333333333222233333",
	"223333333222233333",
]
const OBJECTS := [
	"...I...I..........",
	"................I.",
	".......I...WWWWW..",
	".......B.T.W...W..",
	"...........W...W..",
	"..B........W...W..",
	"F....B.....WWXWW..",
	".......B..........",
	".F.........BT.....",
	"..................",
	"B.......B.........",
	"I..............F..",
	".........B........",
	"..................",
	"....F.............",
	"I...............I.",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 12, 14, "cs_1", "", false],
	[ExitDef.Edge.NORTH, 4, 6, "cs_7", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(9, 4), Vector2.DOWN, EnemyKind.Kind.SPEAR, 3],
	[Vector2i(4, 7), Vector2.UP, EnemyKind.Kind.MAGE, 3],
	[Vector2i(13, 9), Vector2.LEFT, EnemyKind.Kind.MIMIC, 3],
	[Vector2i(4, 12), Vector2.RIGHT, EnemyKind.Kind.SHOOTER, 3],
	[Vector2i(12, 13), Vector2.DOWN, EnemyKind.Kind.SHIELD, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(12, 3), "silver", 3],
	[Vector2i(15, 9), "seal_cs", 1],
	[Vector2i(16, 3), "silver", 1],
	[Vector2i(11, 7), "money", 40],
	[Vector2i(2, 4), "potion_m", 1],
	[Vector2i(15, 1), "money", 40],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["cs_6:0", "CRACK", [Vector2i(13, 6)], [Vector2i(13, 6)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
