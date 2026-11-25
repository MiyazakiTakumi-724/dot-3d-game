extends RefCounted
## 凍った湖 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mt_6"
const TITLE := "凍った湖"
const REGION := "山岳"
const THEME := "mountain"
const ORIGIN := Vector2i(-66, 4)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"3333333333333333444444",
	"3333333333333333444444",
	"3333336663333334444455",
	"3333366666333334445555",
	"3344566666443344445555",
	"3334466666444444444444",
	"4444446664444444444444",
	"4444444444444444444444",
	"4444444444444444445555",
	"4444454444444444445555",
	"4455555444444444445555",
	"4455555444444444444444",
	"4444444444444333444444",
	"4444444544443333444443",
	"4444444544444333444433",
	"4444444444444444444433",
]
const OBJECTS := [
	"...................R.R",
	"....R.................",
	".......R..............",
	"..........P...B...R..B",
	"..........P.R...R....R",
	".R.P....R.............",
	"..........P.~...R.....",
	"........R.~~~.R......R",
	".................~....",
	"...............R......",
	".............R.R......",
	".B....R.....RRRRR....R",
	"............R...R..B..",
	"............X...R.....",
	"........P...R...R.....",
	"............RRRRR.....",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 8, 10, "mt_1", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(6, 12), Vector2.LEFT, EnemyKind.Kind.MELEE, 2],
	[Vector2i(3, 8), Vector2.UP, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(14, 10), Vector2.RIGHT, EnemyKind.Kind.LOBBER, 2],
	[Vector2i(9, 6), Vector2.UP, EnemyKind.Kind.FLYER, 2],
	[Vector2i(17, 6), Vector2.UP, EnemyKind.Kind.SPEAR, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(15, 12), "snow", 4],
	[Vector2i(6, 2), "seal_mt", 1],
	[Vector2i(3, 1), "arrow", 10],
	[Vector2i(1, 12), "iron_ore", 2],
	[Vector2i(17, 4), "snow", 2],
	[Vector2i(4, 3), "iron_ore", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["mt_6:0", "CRACK", [Vector2i(12, 13)], [Vector2i(12, 13)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
