extends RefCounted
## 灰の道 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "lv_1"
const TITLE := "灰の道"
const REGION := "溶岩"
const THEME := "lava"
const ORIGIN := Vector2i(25, 39)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	".......55666666........",
	"44445..55666666.555....",
	"44445..55666666.555....",
	"444455.5566666655554...",
	".444444556666665555444.",
	".333333556666665444444.",
	".333333455555554444444.",
	"3333333455555555444444.",
	"3.33344454444444444444.",
	"33333444444433344444...",
	"..333444444433334444...",
	"...33444444433334444.4.",
	"44444444444433334444445",
	"44444444443333334555555",
	"33444444443333333555555",
	"...44444443333334555555",
	"...44444443333334555555",
	"......44443..3.34444444",
	"......44443............",
	"......44443............",
]
const OBJECTS := [
	"........R.....R........",
	"........R.....R........",
	"........R..............",
	"........R..............",
	"..RRRRRR.......RRRRRRR.",
	"..R....R.......R.....R.",
	"..R....R.......X.....R.",
	"..R....R.......R.....R.",
	"..RRNRRR.......RRRRRRR.",
	".......................",
	"..RR...........RR......",
	"........L..........R.L.",
	"LLL.R..R.LLLLL..LLLLLLR",
	".....RR.......LLL......",
	".......................",
	"...RR..................",
	"...RR..................",
	"................R.....R",
	"......R...R............",
	"......R...R............",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 9, 13, "town", "", false],
	[ExitDef.Edge.SOUTH, 7, 9, "lv_2", "", false],
	[ExitDef.Edge.EAST, 13, 16, "lv_6", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(14, 9), Vector2.LEFT, EnemyKind.Kind.BOMBER, 3],
	[Vector2i(16, 14), Vector2.DOWN, EnemyKind.Kind.FLYER, 3],
	[Vector2i(2, 13), Vector2.DOWN, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(8, 9), Vector2.LEFT, EnemyKind.Kind.BEETLE, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(19, 5), "fire_stone", 3],
	[Vector2i(3, 5), "obsidian", 2],
	[Vector2i(1, 2), "potion_m", 1],
	[Vector2i(17, 2), "bomb", 2],
	[Vector2i(0, 13), "obsidian", 2],
	[Vector2i(3, 2), "fire_stone", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["lv_1:0", "CRACK", [Vector2i(15, 6)], [Vector2i(15, 6)]],
	["lv_1:1", "BRITTLE", [Vector2i(4, 8)], [Vector2i(4, 8)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
