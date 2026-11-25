extends RefCounted
## 丘陵 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "hills"
const TITLE := "丘陵"
const REGION := "はじまりの地"
const THEME := "grass"
const ORIGIN := Vector2i(24, -8)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"222222112233333333322222",
	"333332222233333333332222",
	"444432222333322233332222",
	"444432333333322223333333",
	"444422333333322222233333",
	"333322222233222222222222",
	"222232222222222222222222",
	"111242112222222222222222",
	"111444222222222222222222",
	"114444422222222222222222",
	"114444433322222222222222",
	"114444433322222222222222",
	"111444223222222222222222",
	"111122222222222222222211",
	"111112222222222222222222",
	"111112222222222222222222",
	"111122222222222222222222",
	"111122222222233322222333",
	"111122222222233322223333",
	"111122222222233322223333",
	"111122222222233332233332",
	"111112222222233333333332",
	"111122222222223333333332",
	"111222222222222233333222",
	"111222222222222223332222",
	"112222222222222223322222",
]
const OBJECTS := [
	"....ggg....B.~gggg......",
	"PF..ggg......~ggg...g...",
	"....ggg....g~~ggg.g.....",
	"....gggg..T.~.gggg......",
	".....ggg....~.gggggggggg",
	"Pggg.gg.TT..~g.ggggg.ggg",
	".ggg.ggg....~F.ggggggggg",
	"T.F..gg.T..==..B.T....gg",
	".........gg=.B.T.......g",
	".F......ggg=gB.........g",
	"..gFg...ggg=~...........",
	".....T..gggg~.......g...",
	".TT.....gggg~.F...Bg....",
	"..g.....Tggg~~....g....P",
	"...g.......F.~gg..g.....",
	"g......g.....~gg.T......",
	"P.....BF.....~~.........",
	"............TT~g.F.T..FP",
	"............g.~...Bgggg.",
	".............~~T..ggggg.",
	"P...T....g...~...gggggg.",
	".........F...~....ggggg.",
	"...FB..TF....~.BB.ggggg.",
	"gg........T.~~.gggggg...",
	"ggg.........~ggggggg.g.g",
	"gggg.......g=ggggggggg.T",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 17, 19, "town", "", false],
	[ExitDef.Edge.WEST, 2, 4, "forest", "", false],
	[ExitDef.Edge.EAST, 14, 16, "gr_1", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(7, 5), Vector2.RIGHT, EnemyKind.Kind.WEAK, 1],
	[Vector2i(12, 22), Vector2.LEFT, EnemyKind.Kind.MELEE, 1],
	[Vector2i(21, 23), Vector2.RIGHT, EnemyKind.Kind.SHOOTER, 1],
	[Vector2i(7, 18), Vector2.DOWN, EnemyKind.Kind.WEAK, 1],
	[Vector2i(20, 5), Vector2.DOWN, EnemyKind.Kind.MELEE, 1],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(5, 22), "sword_bronze", 1],
	[Vector2i(6, 15), "scrap", 2],
	[Vector2i(20, 24), "money", 15],
	[Vector2i(10, 4), "herb", 2],
	[Vector2i(6, 8), "hide", 3],
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
