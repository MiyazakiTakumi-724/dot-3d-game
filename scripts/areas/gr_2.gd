extends RefCounted
## 風見の休み場 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_2"
const TITLE := "風見の休み場"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(70, 0)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"2211123332112222",
	"2211123332112222",
	"2211123332111122",
	"2222223332111122",
	"2222222222111122",
	"2222222122111122",
	"2222222222222211",
	"2222222222222111",
	"2222222222222222",
	"2222222222222222",
	"2222222222222222",
	"2222222222222222",
	"2222222222222222",
	"2222222222221222",
	"2222221111111222",
	"2222222111111222",
]
const OBJECTS := [
	".F.ggP...Pgg....",
	"....gg...ggg...g",
	"..F.gg...g.....g",
	"....Tg...g......",
	".F......gg......",
	"P..gF...gg......",
	"........ggggg.g.",
	"........gggggg.P",
	"....gggggggg....",
	"P.ggg.M.........",
	"..ggg...........",
	"...gg...C......P",
	"..F.g...........",
	".g.B........g.F.",
	"........gggggg..",
	"........gggggg..",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 6, 8, "gr_1", "", false],
	[ExitDef.Edge.NORTH, 6, 8, "gr_3", "", false],
	[ExitDef.Edge.EAST, 8, 10, "gr_4", "gr_gate", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(6, 6), Vector2.RIGHT, EnemyKind.Kind.SHADOW, 2],
	[Vector2i(12, 4), Vector2.RIGHT, EnemyKind.Kind.SHOOTER, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(3, 2), "scale", 2],
	[Vector2i(15, 14), "money", 30],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
	[Vector2i(6, 9), "草原"],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
