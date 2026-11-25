extends RefCounted
## 黒い森 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "lv_6"
const TITLE := "黒い森"
const REGION := "溶岩"
const THEME := "lava"
const ORIGIN := Vector2i(48, 39)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"....................",
	"...........455......",
	"..444......555......",
	"..4444....45555554..",
	"..5555555555544444..",
	"..5555555555333444..",
	"....5555555533344...",
	"....55555555333333..",
	"..5555555554433333..",
	"..5555555554433333..",
	"..55544444443333....",
	"555554444443322233..",
	"455554444333222223..",
	"555554444332222223..",
	"555544444333322223..",
	"555544444444333322..",
	"555544444....33322..",
	"65544444............",
	"....................",
	"....................",
]
const OBJECTS := [
	"....................",
	"....................",
	"...R................",
	"...R.............R..",
	"...........RRRRR.R..",
	"...........R...R....",
	"...........R...R....",
	"...........R...R....",
	".....RR....RRYRR....",
	"....R..RR...........",
	"..R............R....",
	"...........R.RRRRR..",
	"R............R...R..",
	".............N...R..",
	".............R...R..",
	".............RRRRR..",
	".............RRRRR..",
	"R...................",
	"....................",
	"....................",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 13, 16, "lv_1", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(9, 14), Vector2.UP, EnemyKind.Kind.BOMBER, 3],
	[Vector2i(5, 5), Vector2.RIGHT, EnemyKind.Kind.FLYER, 3],
	[Vector2i(12, 9), Vector2.RIGHT, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(3, 9), Vector2.LEFT, EnemyKind.Kind.BEETLE, 3],
	[Vector2i(16, 8), Vector2.UP, EnemyKind.Kind.MIMIC, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(12, 5), "obsidian", 3],
	[Vector2i(16, 12), "potion_l", 1],
	[Vector2i(16, 4), "seal_lv", 1],
	[Vector2i(14, 9), "potion_m", 1],
	[Vector2i(4, 14), "bomb", 2],
	[Vector2i(3, 4), "obsidian", 2],
	[Vector2i(12, 2), "fire_stone", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["lv_6:0", "THORNS", [Vector2i(13, 8)], [Vector2i(13, 8)]],
	["lv_6:1", "BRITTLE", [Vector2i(13, 13)], [Vector2i(13, 13)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
