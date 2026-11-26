extends RefCounted
## 霧の湖 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mv_6"
const TITLE := "霧の湖"
const REGION := "霧の谷"
const THEME := "mist"
const ORIGIN := Vector2i(114, 51)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"555................",
	"55444455...777777..",
	"44444455...777777..",
	"..444445555777777..",
	"..444445555777777..",
	"...44444455777777..",
	"33444444445777477..",
	"3344444444577747744",
	"4444444444444444444",
	"4444444444444444433",
	"4444444444444444433",
	"4444444444444444444",
	"44444444444444444..",
	"33344444445555544..",
	"..334445555555555..",
	"...34445555555555..",
	"...34444445555555..",
	".....444444........",
	".....444444........",
	".....444444........",
]
const OBJECTS := [
	"ggg................",
	"g...R.k....kkkkkk..",
	"..R..k.....kk...k..",
	".....R.....kk...k..",
	".....R.....kk...k..",
	"...Pg.g..B.kk...k..",
	"kB..ggg....kkk.kk..",
	"kB..ggg....kkk.kkgg",
	"....ggg............",
	"....gg.......P..Z..",
	"....gg.......P.....",
	"....ggg..~~~~..k...",
	"....ggg..~~~~..k...",
	"kgggggg~~~~~~~.R...",
	"..gggg~~~~~~~~~....",
	"...g...~~~~~~~.....",
	"..........~~~..P...",
	"...................",
	"...................",
	".....k....k........",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 8, 12, "mv_1", "", false],
	[ExitDef.Edge.SOUTH, 6, 9, "mv_3", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(6, 9), Vector2.DOWN, EnemyKind.Kind.WOLF, 4],
	[Vector2i(6, 2), Vector2.RIGHT, EnemyKind.Kind.DARK_KNIGHT, 4],
	[Vector2i(6, 15), Vector2.DOWN, EnemyKind.Kind.GHOST, 4],
	[Vector2i(15, 8), Vector2.UP, EnemyKind.Kind.WOLF, 4],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(13, 2), "mist_moss", 4],
	[Vector2i(5, 5), "arrow", 10],
	[Vector2i(1, 1), "mist_moss", 2],
	[Vector2i(4, 15), "dark_shard", 1],
	[Vector2i(15, 15), "dark_shard", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["mv_6:0", "CRYSTAL", [Vector2i(14, 8), Vector2i(14, 6), Vector2i(14, 7)], [Vector2i(16, 9)], [5, 6, 6]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
