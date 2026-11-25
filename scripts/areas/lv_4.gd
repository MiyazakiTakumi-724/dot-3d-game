extends RefCounted
## 火口のふち のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "lv_4"
const TITLE := "火口のふち"
const REGION := "溶岩"
const THEME := "lava"
const ORIGIN := Vector2i(6, 52)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"44444444455555544443323333333333",
	"44444444445555555443333334333333",
	"44444444445555555444333334333333",
	"44444444445555555444443334333333",
	"44433333445555555444444444433333",
	"44433333444444444444444444443333",
	"44444333344444344444444444443333",
	"44443333333333333344444474444433",
	"44443333333333333444447776544443",
	"33333333333333444444447776766543",
	"23333333333334444444557777744443",
	"22333333333334444444555574444443",
	"23333333333344444444555555544443",
	"33333333333344444444455555554444",
]
const OBJECTS := [
	".R..LL...R.....R.....R...R......",
	"....LL..........................",
	"....LL....................R.R...",
	"....LL...R.....................R",
	"...RLL.................R........",
	"R...LL...........R..............",
	"....LL....LL.......R.L....R.....",
	"....LL......R.....LLL..R..LLL..R",
	"....LL...RR...R..L..R.......LLL.",
	"R...LL...R...........R..........",
	"R....V.......R......RB..R.......",
	"....LLR..............R........R.",
	"....LL.......R........R.........",
	"RR..LL.R..R..R....R.........R..R",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 22, 24, "lv_3", "", false],
	[ExitDef.Edge.NORTH, 6, 8, "lv_2", "lv_gate", true],
	[ExitDef.Edge.SOUTH, 14, 17, "lv_5", "lv_boss", true],
	[ExitDef.Edge.EAST, 4, 6, "lv_8", "", false],
	[ExitDef.Edge.WEST, 6, 8, "lv_x", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(20, 9), Vector2.DOWN, EnemyKind.Kind.BOMBER, 3],
	[Vector2i(8, 7), Vector2.UP, EnemyKind.Kind.FLYER, 3],
	[Vector2i(24, 5), Vector2.DOWN, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(15, 3), Vector2.LEFT, EnemyKind.Kind.BEETLE, 3],
	[Vector2i(25, 11), Vector2.RIGHT, EnemyKind.Kind.MIMIC, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(11, 11), "potion_m", 1],
	[Vector2i(26, 13), "bomb", 2],
	[Vector2i(14, 7), "obsidian", 2],
	[Vector2i(19, 2), "fire_stone", 2],
	[Vector2i(26, 8), "fire_stone", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["lv_4:0", "VINES", [Vector2i(5, 10)], [Vector2i(5, 10)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
