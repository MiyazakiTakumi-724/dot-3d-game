extends RefCounted
## 大蛇の草むら のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_5"
const TITLE := "大蛇の草むら"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(100, -10)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"222222211111122211111112",
	"222222211111122211111112",
	"222222111122111111111112",
	"222222111222111112221112",
	"222211111222111112221112",
	"222211111222211112221122",
	"222221111222221111122222",
	"222111111222222211122222",
	"222211111122222221122222",
	"222211111112222222222222",
	"222211111111222222222222",
	"222211111111222222222222",
	"111111111111222222222222",
	"111111111111111222222222",
	"111111111111111122222222",
	"111111111111111122222222",
	"111111122111111122222222",
	"111111222211111122222222",
	"111111222111111112222222",
	"111111221111111111122222",
]
const OBJECTS := [
	"....B...........T..T..B.",
	".BB.....F...............",
	"B.......B......TF....T.T",
	"F...FT....ggggg.ggF.....",
	"B...T..gg..ggg.gg.gg..FF",
	".F..T.ggg.gg.g.gg.ggg..B",
	"..F..gggggggg..gggg.gg..",
	"PT..g.gggg.gggggggggggg.",
	"....gg.gg.ggg.g..g..gggF",
	".....gggggg..g.ggg.g.g..",
	"....gggggggg.g..ggg.g.g.",
	"....ggg.gg.g.gg.gggg.g..",
	"PT..ggg.g.g..gggggg.ggg.",
	"B.T.gggg.g..ggg.gggggg.B",
	".......g.ggg.gg.gggggg..",
	"..F.BB.ggg.ggggg.gggg.B.",
	"...BB..ggggggg.gg.g....F",
	"...T......g.g..gg.T.....",
	".....T..TF......B...F...",
	"..........T..F.B....FT.F",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 8, 11, "gr_4", "gr_boss", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(18, 9), "herb", 3],
	[Vector2i(23, 15), "scale", 2],
	[Vector2i(21, 18), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
	[Vector2i(14, 10), "草むらの大蛇", Color("6f9a5a")],
]
