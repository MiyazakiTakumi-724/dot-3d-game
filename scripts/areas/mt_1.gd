extends RefCounted
## 山すそ のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mt_1"
const TITLE := "山すそ"
const REGION := "山岳"
const THEME := "mountain"
const ORIGIN := Vector2i(-44, 4)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"5544445544444444333222",
	"5544444544444444332222",
	"5544444444444444332222",
	"5444444444444444322222",
	"5444444444444444322222",
	"5554444444444444333222",
	"5555444444444444333333",
	"5555554444666663334444",
	"5555544444666663334444",
	"5555544456666663334444",
	"5555544333666664333333",
	"5555544333666664333322",
	"5555444333333333333332",
	"5544444334444333333333",
	"4444444444444333333333",
	"4444444444444333333333",
]
const OBJECTS := [
	"..P........R...R......",
	"......................",
	"..RRRRRP...........R..",
	"..R...R.........R.....",
	"B.R...R.......R.......",
	"..R...R......RP.......",
	"..RRXRR..............R",
	".....R......B.........",
	".....B................",
	"....R.................",
	".....R........R......R",
	".....R.............R..",
	"...B....R.R.......RP..",
	"..R...P.......R..B....",
	"................R...R.",
	"...........R.....P....",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 7, 9, "rocks", "", false],
	[ExitDef.Edge.NORTH, 12, 14, "mt_2", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(7, 11), Vector2.LEFT, EnemyKind.Kind.MELEE, 2],
	[Vector2i(2, 9), Vector2.UP, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(9, 5), Vector2.LEFT, EnemyKind.Kind.SHOOTER, 2],
	[Vector2i(11, 13), Vector2.RIGHT, EnemyKind.Kind.FLYER, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(3, 3), "iron_ore", 4],
	[Vector2i(1, 4), "arrow", 10],
	[Vector2i(11, 6), "iron_ore", 2],
	[Vector2i(19, 15), "snow", 2],
	[Vector2i(9, 8), "iron_ore", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["mt_1:0", "CRACK", [Vector2i(4, 6)], [Vector2i(4, 6)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
