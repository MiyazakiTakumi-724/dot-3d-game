extends RefCounted
## 溶岩の川 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "lv_3"
const TITLE := "溶岩の川"
const REGION := "溶岩"
const THEME := "lava"
const ORIGIN := Vector2i(46, 59)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"..55555............",
	"..55555..444.44444.",
	"..5555544444444444.",
	"...555444444444444.",
	"...555444444444444.",
	"..6655444444444444.",
	"666655444444444444.",
	"666555444444444444.",
	"555555555444444444.",
	"555555555554444444.",
	"5555555555544444444",
	"5555555555555444444",
	".555555555555554444",
	"...5555555555554444",
	"...5555555555554444",
	".555555555555554444",
	".655555555555444433",
	".6555555555444443.3",
	".....5555554..443..",
	".....5555554.......",
	".....5555554.......",
]
const OBJECTS := [
	"...................",
	".........RR..RRRRR.",
	".......RRRR..RRRRR.",
	"....RR.RR....R...R.",
	"....RR.RR....R...R.",
	"..R..........R...R.",
	".R..R........R...R.",
	"R............RRYRR.",
	"....R...........R..",
	"..............R....",
	"..................R",
	"R..................",
	"....LL........R....",
	"....LL........R....",
	".....LL......LL....",
	".....LL......LL....",
	"................LLR",
	"..................L",
	"...........R....R..",
	".....R.....R.......",
	".....R.....R.......",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 8, 10, "lv_2", "", false],
	[ExitDef.Edge.SOUTH, 6, 10, "lv_4", "", false],
	[ExitDef.Edge.EAST, 11, 15, "lv_7", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(7, 12), Vector2.DOWN, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(9, 6), Vector2.RIGHT, EnemyKind.Kind.BEETLE, 3],
	[Vector2i(4, 5), Vector2.UP, EnemyKind.Kind.MIMIC, 3],
	[Vector2i(2, 16), Vector2.LEFT, EnemyKind.Kind.SHOOTER, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(14, 3), "staff_fire_3", 1],
	[Vector2i(2, 11), "potion_m", 1],
	[Vector2i(3, 1), "bomb", 2],
	[Vector2i(15, 17), "obsidian", 2],
	[Vector2i(5, 1), "fire_stone", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["lv_3:0", "THORNS", [Vector2i(15, 7)], [Vector2i(15, 7)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
