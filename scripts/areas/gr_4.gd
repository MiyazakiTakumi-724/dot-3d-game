extends RefCounted
## 背高草の野 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_4"
const TITLE := "背高草の野"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(125, 1)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	".......322222...222",
	".......322222...222",
	".......322223...3..",
	".....43322223.333..",
	"33344433333333333..",
	"3334444433333333...",
	"4444444433333344...",
	"4444444433334444...",
	"44444444444744444..",
	"44444577788888444..",
	".4456677877777774..",
	"44677777766666444..",
	"..447777766544444..",
	"..44477773333344444",
	"..44444433333333333",
	"...4443333333333333",
	"..44443333333333333",
	"..43333333333333333",
	"..43333332222233333",
	"..33333333333322223",
	"..333233333333222..",
	"..33223333333322...",
	"..32223333333322...",
	"..33223333332222...",
	"..33332222222222...",
	"33333322222222222..",
	"33333322222222222..",
	"333333222222222222.",
	"333333332222222222.",
	"333333222222222222.",
	"...3332222223333...",
	".....322222222.....",
	".....3333332.......",
	"...................",
]
const OBJECTS := [
	".......P....P...g.g",
	".......g....g...ggg",
	"............g...g..",
	".....ggg....g.ggg..",
	"ggggggggggggggggg..",
	"PPgggggggggggg.....",
	".....ggggggggggg...",
	".....ggggggggggg...",
	".....gggggggggggg..",
	"PPgggg..ggggggggg..",
	".g.......gggggggg..",
	"....ggggggggggggg..",
	"..ggggggggg........",
	"..g..ggggggg..gg..P",
	"..gF.ggggggggg.....",
	"......gggggggg.....",
	"..g...gggggggg.....",
	"..g..ggggggggg.....",
	".....ggggggggg.....",
	".....ggg......ggggP",
	"....gggg......ggg..",
	"....gggg......gg...",
	"...ggggg......gg...",
	"....ggggggg.gggg...",
	"..ggggggggg........",
	"PPggggggggg.....T..",
	".....ggg...........",
	".....ggg~.....gg...",
	".....TTT~TTT.....g.",
	"PPgggT.....T....g..",
	"...ggT..Q..T.......",
	".....T.....T.......",
	".....TTTTTTT.......",
	"...................",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 6, 8, "gr_3", "", false],
	[ExitDef.Edge.WEST, 26, 28, "gr_2", "gr_gate", true],
	[ExitDef.Edge.EAST, 14, 18, "gr_5", "gr_boss", true],
	[ExitDef.Edge.NORTH, 8, 11, "gr_8", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(12, 13), Vector2.LEFT, EnemyKind.Kind.BEETLE, 2],
	[Vector2i(3, 13), Vector2.UP, EnemyKind.Kind.WASP, 2],
	[Vector2i(14, 5), Vector2.UP, EnemyKind.Kind.WEAK, 2],
	[Vector2i(11, 21), Vector2.RIGHT, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(14, 29), Vector2.DOWN, EnemyKind.Kind.SHADOW, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(6, 31), "bow_poison", 1],
	[Vector2i(6, 9), "potion", 1],
	[Vector2i(17, 0), "wood", 2],
	[Vector2i(16, 28), "arrow", 10],
	[Vector2i(11, 23), "herb", 3],
	[Vector2i(11, 27), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_4:0", "TARGET", [Vector2i(8, 28), Vector2i(8, 27)], [Vector2i(8, 30)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
