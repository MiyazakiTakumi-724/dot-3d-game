extends RefCounted
## 岩場 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "rocks"
const TITLE := "岩場"
const REGION := "はじまりの地"
const THEME := "grass"
const ORIGIN := Vector2i(-22, 2)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"3344433322111122222222",
	"3344433332212222222222",
	"4444443332222222222222",
	"4444443333333333222222",
	"4444444444333333322222",
	"4444444444333333332222",
	"4444444444333333333333",
	"3344444444443333333333",
	"3344444444444433333333",
	"4444444445554443443333",
	"4444444445555444443333",
	"4444444445555444444333",
	"3344444445554443333333",
	"3333444444444433333344",
	"3333444444444443333444",
	"3333444444444433333444",
	"3333433333444444333444",
	"4433333333333444333444",
]
const OBJECTS := [
	"...RTRRRgggggggggB....",
	"...F..Rggggg.ggg...T..",
	"g.FB..B.gggggT.....B.g",
	"....R..BggggR.B....g..",
	"....F.....gg..FP......",
	".....R....gg...T....RB",
	"..........gg.........P",
	"gg........ggg.g.......",
	"Pg......Rgggg.........",
	"........gggggg........",
	"......P.Bgggggg.....FP",
	".........ggggRTTTTTTB.",
	"Pgg.....FgggggT...T...",
	".......B.ggg..X...T...",
	"....B....gggggT...T...",
	".........RgR.gTTTTTP..",
	".........ggggR..P.BBB.",
	"gggggg.ggRgg.g...RB...",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 7, 9, "town", "", false],
	[ExitDef.Edge.WEST, 9, 11, "mt_1", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(2, 5), Vector2.UP, EnemyKind.Kind.SHOOTER, 1],
	[Vector2i(2, 15), Vector2.DOWN, EnemyKind.Kind.WEAK, 1],
	[Vector2i(12, 15), Vector2.UP, EnemyKind.Kind.MELEE, 1],
	[Vector2i(8, 6), Vector2.LEFT, EnemyKind.Kind.SHOOTER, 1],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(17, 12), "money", 30],
	[Vector2i(6, 17), "herb", 2],
	[Vector2i(12, 1), "wood", 2],
	[Vector2i(2, 7), "potion", 1],
	[Vector2i(4, 2), "money", 30],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["rocks:0", "CRACK", [Vector2i(14, 13)], [Vector2i(14, 13)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
