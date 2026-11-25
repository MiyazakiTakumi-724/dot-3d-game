extends RefCounted
## 見張りの塔 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "cs_7"
const TITLE := "見張りの塔"
const REGION := "廃城"
const THEME := "castle"
const ORIGIN := Vector2i(18, -50)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"4444433332222223",
	"4444433333222223",
	"4444433333222233",
	"4444433333322333",
	"4444437773323333",
	"4444477777552333",
	"4566777777755233",
	"4444466777555533",
	"4444436675555543",
	"4443333555555533",
	"3333333244444223",
	"3333333223332223",
	"3333332222222233",
	"3333332222222233",
	"3333332222222333",
	"3333332222222333",
]
const OBJECTS := [
	"...BF....B......",
	"...F..T......F..",
	"F...............",
	"...........B....",
	"..T.....I..F....",
	".......B........",
	"................",
	"................",
	"B...............",
	"I...F...........",
	".....I..........",
	".........B....F.",
	"................",
	"I...............",
	"................",
	".......I...I.F.I",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 8, 10, "cs_6", "", false],
	[ExitDef.Edge.WEST, 10, 12, "cs_2", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(8, 8), Vector2.RIGHT, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(4, 11), Vector2.UP, EnemyKind.Kind.GHOST, 3],
	[Vector2i(5, 3), Vector2.RIGHT, EnemyKind.Kind.SPEAR, 3],
	[Vector2i(13, 5), Vector2.LEFT, EnemyKind.Kind.MAGE, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(6, 4), "seal_cs", 1],
	[Vector2i(5, 9), "ether", 1],
	[Vector2i(15, 9), "old_steel", 2],
	[Vector2i(8, 5), "silver", 1],
	[Vector2i(5, 4), "money", 40],
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
