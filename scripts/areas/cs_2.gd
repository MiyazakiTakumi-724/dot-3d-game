extends RefCounted
## 崩れた兵舎 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "cs_2"
const TITLE := "崩れた兵舎"
const REGION := "廃城"
const THEME := "castle"
const ORIGIN := Vector2i(2, -50)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"2222222233322333",
	"2222222233322333",
	"2222222233322222",
	"2222222233322222",
	"2222222222222222",
	"2222222222222222",
	"3333222222222222",
	"3333222222222222",
	"3333222222222222",
	"2222222222222222",
	"2222222222222222",
	"2222222222222222",
	"2222223332222222",
	"2223333333222222",
	"2233333333322222",
	"2222233332222222",
]
const OBJECTS := [
	"......BI...I....",
	"T....T..........",
	"................",
	"..............F.",
	"...............B",
	"I.......B.....F.",
	".....F..........",
	"......sssssMs.B.",
	"......sssss.sF..",
	"I.....sssCsss...",
	".I...Bsssssss...",
	"......sssssss...",
	"................",
	"...............F",
	"................",
	".....I...I......",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 6, 8, "cs_1", "", false],
	[ExitDef.Edge.WEST, 6, 8, "cs_3", "", false],
	[ExitDef.Edge.NORTH, 8, 10, "cs_4", "cs_gate", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(4, 4), Vector2.RIGHT, EnemyKind.Kind.SHOOTER, 3],
	[Vector2i(4, 8), Vector2.RIGHT, EnemyKind.Kind.MELEE, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(14, 12), "ether", 1],
	[Vector2i(1, 14), "old_steel", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
	[Vector2i(11, 7), "廃城"],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
