extends RefCounted
## 岩場 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "rocks"
const TITLE := "岩場"
const REGION := "はじまりの地"
const THEME := "grass"
const ORIGIN := Vector2i(-13, 20)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"........................222..",
	"........555555555.......222..",
	"..555555555555555.33....222..",
	"..55555555555555533333..332..",
	".5555555555555555444443333...",
	".555555555555555544444443....",
	".555555555555555544444443.333",
	".5.55555555555555544444443333",
	".5.55566666655555554444444444",
	"45556666666666666655544444444",
	"55556666666666666665555554444",
	"55556666666666777766555555444",
	"55556666666666777776555555444",
	"44566666666666677766544445444",
	"....6666556666666655444445555",
	".45566...555555666555444455..",
	".455.............5555555555..",
	".455.............555.........",
	".............................",
]
const OBJECTS := [
	"........................B....",
	"........TTTTTTTTT............",
	"...FBB..TT.....TT.g..........",
	"........TT.....TTgB.......R..",
	".g....RRTT.....TTg...F...B...",
	"......RRTTTTEETTTg...........",
	"......RRTTTTEETTTg.........B.",
	"...TRR........Rggg.BB.......P",
	".g........PP...U.gg.R........",
	"Pg............ggggg.g...R....",
	"..............gggggg.........",
	"..............Rgggggg...g...P",
	"..........BB..ggggggTTTTTT...",
	"Pgg.FF........ggggggT....T..T",
	"............RRgBBg..X....T.F.",
	".g..........BBggggggT....T...",
	".g...............g.gTTTTTT...",
	".gg..............ggg.........",
	".............................",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 8, 10, "town", "", false],
	[ExitDef.Edge.WEST, 10, 12, "mt_1", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(18, 16), Vector2.UP, EnemyKind.Kind.SHOOTER, 1],
	[Vector2i(21, 11), Vector2.DOWN, EnemyKind.Kind.WEAK, 1],
	[Vector2i(2, 5), Vector2.UP, EnemyKind.Kind.MELEE, 1],
	[Vector2i(2, 16), Vector2.DOWN, EnemyKind.Kind.SHOOTER, 1],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(24, 13), "money", 30],
	[Vector2i(10, 2), "bomb", 2],
	[Vector2i(10, 7), "herb", 2],
	[Vector2i(27, 13), "wood", 2],
	[Vector2i(25, 1), "potion", 1],
	[Vector2i(6, 3), "money", 30],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["rocks:0", "CRACK", [Vector2i(20, 14)], [Vector2i(20, 14)]],
	["rocks:1", "PLATE", [Vector2i(12, 5), Vector2i(12, 6), Vector2i(13, 5), Vector2i(13, 6)], [Vector2i(15, 8)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
