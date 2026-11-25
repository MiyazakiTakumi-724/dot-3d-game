extends RefCounted
## 凍った湖 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mt_6"
const TITLE := "凍った湖"
const REGION := "山岳"
const THEME := "mountain"
const ORIGIN := Vector2i(-66, 22)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"..........................",
	".....44444.334...88888888.",
	".4444488844444...88888888.",
	".444488888844444588888888.",
	".444488888844444588888888.",
	"4566788888844444588888888.",
	"...44888888555445888855886",
	"...55588855555555555555555",
	"..555555555555555556655556",
	"..555566655555555555577777",
	"55666666655555555556677777",
	"55556666655555555556677777",
	"55556666666555555556666666",
	"5555666666655544455..66...",
	"55555566...55444455...6544",
	"65555......55544455.....44",
	"...........55555555.....44",
]
const OBJECTS := [
	"..........................",
	".................RRRRRRRR.",
	".............R...RR.....R.",
	".................RR.....R.",
	".................RR.....R.",
	".........PP...B..RR.....R.",
	"...B.....PP.R...RRRRR..RR.",
	"...R.R.P.....~R...........",
	".......P...~~~..........ZR",
	".....R.............~~.....",
	"..R..R.......B............",
	".................PP.......",
	".........RR..RRRRRR......R",
	"........R..R.R...RR.......",
	".............X...RR.......",
	".............R...RR.......",
	".............RRRRRR.......",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 9, 11, "mt_1", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(6, 13), Vector2.LEFT, EnemyKind.Kind.MELEE, 2],
	[Vector2i(2, 13), Vector2.LEFT, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(3, 9), Vector2.UP, EnemyKind.Kind.LOBBER, 2],
	[Vector2i(15, 11), Vector2.RIGHT, EnemyKind.Kind.FLYER, 2],
	[Vector2i(9, 7), Vector2.UP, EnemyKind.Kind.SPEAR, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(16, 13), "snow", 4],
	[Vector2i(19, 2), "ether", 2],
	[Vector2i(6, 2), "seal_mt", 1],
	[Vector2i(13, 11), "arrow", 10],
	[Vector2i(12, 2), "iron_ore", 2],
	[Vector2i(25, 15), "snow", 2],
	[Vector2i(2, 3), "iron_ore", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["mt_6:0", "CRACK", [Vector2i(13, 14)], [Vector2i(13, 14)]],
	["mt_6:1", "CRYSTAL", [Vector2i(21, 7), Vector2i(22, 7), Vector2i(21, 6), Vector2i(22, 6)], [Vector2i(24, 8)], [6, 6, 7, 7]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
