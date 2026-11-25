extends RefCounted
## 岩の尾根 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mt_3"
const TITLE := "岩の尾根"
const REGION := "山岳"
const THEME := "mountain"
const ORIGIN := Vector2i(-56, -12)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"4445555556666666",
	"4445555556666666",
	"4445555556666666",
	"4445555556666655",
	"4455555555666555",
	"5555555555665555",
	"5555555555555555",
	"6655555555555555",
	"6666555555555555",
	"6666555555766555",
	"6666655555777545",
	"6566655558888865",
	"6665555555888555",
	"5555555555888555",
	"5555555444455555",
	"5555555555455555",
]
const OBJECTS := [
	"....~~...R......",
	"....~~..........",
	"....~~..........",
	"....~~.....R....",
	"..RR~~.B.R......",
	".R..~~.........R",
	"....~~..B..R....",
	"R...~~.....R....",
	"....~~..........",
	"....~~..R..B...R",
	"....~~.....P..RP",
	"RQ.R~~..........",
	"....~~R.....R...",
	"....~~..R.......",
	"....~~..R..B....",
	"...R~~.......P..",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 6, 8, "mt_2", "", false],
	[ExitDef.Edge.NORTH, 6, 8, "mt_4", "", false],
	[ExitDef.Edge.WEST, 8, 10, "mt_x", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(8, 4), Vector2.RIGHT, EnemyKind.Kind.LOBBER, 2],
	[Vector2i(11, 11), Vector2.LEFT, EnemyKind.Kind.FLYER, 2],
	[Vector2i(7, 11), Vector2.LEFT, EnemyKind.Kind.SPEAR, 2],
	[Vector2i(12, 2), Vector2.LEFT, EnemyKind.Kind.WASP, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(10, 3), "snow", 2],
	[Vector2i(13, 10), "money", 30],
	[Vector2i(7, 8), "potion", 1],
	[Vector2i(9, 10), "iron_ore", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["mt_3:0", "TARGET", [Vector2i(4, 13), Vector2i(5, 13)], [Vector2i(1, 11)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
