extends RefCounted
## 溶岩の川 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "lv_3"
const TITLE := "溶岩の川"
const REGION := "溶岩"
const THEME := "lava"
const ORIGIN := Vector2i(22, 36)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"4444444433333333",
	"4444444333333333",
	"4444443333333333",
	"5544443333333333",
	"5544443333333333",
	"4444443333333333",
	"4444444433333333",
	"4444444443333333",
	"4444444443333333",
	"4444444444333333",
	"4444444444443333",
	"4444444444443333",
	"4444443334433333",
	"4444443333333333",
	"5444333333333333",
	"4444433333333333",
]
const OBJECTS := [
	"...............R",
	"R......RR.RRRRRR",
	"....RR.R..R...R.",
	"..R.......R...R.",
	".R..R.....R...R.",
	"R.........RRYRR.",
	"....R........R..",
	"...........R....",
	"...............R",
	"R...............",
	"....LL.....R....",
	".....LL...LL....",
	".............LLR",
	"..............RL",
	".........R...R..",
	".....R...R..R...",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 6, 8, "lv_2", "", false],
	[ExitDef.Edge.SOUTH, 6, 8, "lv_4", "", false],
	[ExitDef.Edge.EAST, 9, 11, "lv_7", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(7, 10), Vector2.DOWN, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(8, 4), Vector2.RIGHT, EnemyKind.Kind.BEETLE, 3],
	[Vector2i(4, 3), Vector2.UP, EnemyKind.Kind.MIMIC, 3],
	[Vector2i(2, 12), Vector2.LEFT, EnemyKind.Kind.SHOOTER, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(11, 2), "staff_fire_3", 1],
	[Vector2i(2, 9), "potion_m", 1],
	[Vector2i(3, 1), "bomb", 2],
	[Vector2i(12, 13), "obsidian", 2],
	[Vector2i(5, 1), "fire_stone", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["lv_3:0", "THORNS", [Vector2i(12, 5)], [Vector2i(12, 5)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
