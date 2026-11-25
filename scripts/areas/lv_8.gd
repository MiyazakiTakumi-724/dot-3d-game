extends RefCounted
## 灰の丘 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "lv_8"
const TITLE := "灰の丘"
const REGION := "溶岩"
const THEME := "lava"
const ORIGIN := Vector2i(38, 52)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"2223334444444455",
	"2223334444444454",
	"2233334444444444",
	"3333334444444444",
	"3333334444444444",
	"3333346664444444",
	"3333346664333444",
	"4444456666333344",
	"5556666666333333",
	"5544466666333333",
	"5544436663333322",
	"5554436663322222",
	"5544443333332223",
	"4444444333333333",
]
const OBJECTS := [
	".....R...R..R...",
	".RR.R...........",
	"..............R.",
	"R.R............R",
	"................",
	"................",
	"..........R.....",
	"R....RR..R......",
	"..............R.",
	"R...............",
	"................",
	"................",
	"............R...",
	".............R..",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 4, 6, "lv_4", "", false],
	[ExitDef.Edge.NORTH, 6, 8, "lv_7", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(5, 4), Vector2.DOWN, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(12, 9), Vector2.DOWN, EnemyKind.Kind.BEETLE, 3],
	[Vector2i(6, 11), Vector2.DOWN, EnemyKind.Kind.MIMIC, 3],
	[Vector2i(11, 4), Vector2.UP, EnemyKind.Kind.SHOOTER, 3],
	[Vector2i(2, 11), Vector2.DOWN, EnemyKind.Kind.BOMBER, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(8, 11), "seal_lv", 1],
	[Vector2i(8, 7), "potion_m", 1],
	[Vector2i(13, 1), "bomb", 2],
	[Vector2i(3, 1), "obsidian", 2],
	[Vector2i(9, 6), "fire_stone", 3],
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
