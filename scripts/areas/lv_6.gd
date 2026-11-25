extends RefCounted
## 黒い森 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "lv_6"
const TITLE := "黒い森"
const REGION := "溶岩"
const THEME := "lava"
const ORIGIN := Vector2i(24, 20)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"3333333334444444",
	"3333333334444433",
	"3344444444333333",
	"3444444443333333",
	"3444444443333333",
	"4444444443333333",
	"4444444433333322",
	"4444444433322222",
	"4444443333322222",
	"4444433332222222",
	"3344433322222232",
	"4444433222222232",
	"4444333332222222",
	"4444333333222222",
	"4443333333332222",
	"4433333333333222",
]
const OBJECTS := [
	".............R..",
	"...R..........R.",
	"........RRRRR.R.",
	".R......R...R...",
	".R......R...R...",
	"........R...R...",
	".....R..RRYRR...",
	"R...R.R.........",
	"..R.........R..R",
	"........R..R....",
	"R....R....R.....",
	"................",
	"........R.......",
	".......R........",
	"R.R............R",
	".............R..",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 11, 13, "lv_1", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(11, 10), Vector2.DOWN, EnemyKind.Kind.BOMBER, 3],
	[Vector2i(7, 12), Vector2.UP, EnemyKind.Kind.FLYER, 3],
	[Vector2i(5, 3), Vector2.RIGHT, EnemyKind.Kind.SHIELD, 3],
	[Vector2i(3, 7), Vector2.LEFT, EnemyKind.Kind.BEETLE, 3],
	[Vector2i(13, 6), Vector2.UP, EnemyKind.Kind.MIMIC, 3],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(9, 3), "obsidian", 3],
	[Vector2i(13, 2), "seal_lv", 1],
	[Vector2i(1, 6), "potion_m", 1],
	[Vector2i(12, 13), "bomb", 2],
	[Vector2i(6, 11), "obsidian", 2],
	[Vector2i(9, 1), "fire_stone", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["lv_6:0", "THORNS", [Vector2i(10, 6)], [Vector2i(10, 6)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
