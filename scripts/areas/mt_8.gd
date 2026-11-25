extends RefCounted
## 吹雪の谷 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mt_8"
const TITLE := "吹雪の谷"
const REGION := "山岳"
const THEME := "mountain"
const ORIGIN := Vector2i(-74, -26)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"544444444444433333",
	"544444444444443333",
	"555555554445444433",
	"555555554446444444",
	"555555555446445555",
	"555555544447445555",
	"555555544477745555",
	"455555444777764444",
	"555555444777774444",
	"555555554777774444",
	"665555555577744445",
	"665555555557544444",
	"555555555555544444",
	"555555555555544444",
]
const OBJECTS := [
	".......R..........",
	".............P..B.",
	"..RRRRR.....R.....",
	"R.R...R.R.R...R..R",
	"..R...V...........",
	"..R...R...........",
	"..RRRRR...R.......",
	".R.R.........BR..R",
	"R.................",
	"RR.B..........RRRP",
	".......P..PR.R....",
	"...R..............",
	".............R....",
	"...........R......",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 4, 6, "mt_4", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(7, 11), Vector2.LEFT, EnemyKind.Kind.LOBBER, 2],
	[Vector2i(14, 11), Vector2.DOWN, EnemyKind.Kind.FLYER, 2],
	[Vector2i(2, 7), Vector2.DOWN, EnemyKind.Kind.SPEAR, 2],
	[Vector2i(13, 2), Vector2.UP, EnemyKind.Kind.WASP, 2],
	[Vector2i(10, 7), Vector2.DOWN, EnemyKind.Kind.MELEE, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(3, 3), "potion_m", 2],
	[Vector2i(2, 11), "seal_mt", 1],
	[Vector2i(16, 11), "snow", 2],
	[Vector2i(12, 8), "money", 30],
	[Vector2i(10, 13), "potion", 1],
	[Vector2i(9, 6), "iron_ore", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["mt_8:0", "VINES", [Vector2i(6, 4)], [Vector2i(6, 4)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
