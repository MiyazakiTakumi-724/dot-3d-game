extends RefCounted
## 霧の森 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mv_3"
const TITLE := "霧の森"
const REGION := "霧の谷"
const THEME := "mist"
const ORIGIN := Vector2i(110, 71)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"....344..544445...",
	"....344..544445...",
	"......444544445...",
	"...334444544445...",
	"33.334444444445...",
	"33.333444444445...",
	"33.3344444444445..",
	"4444444444444444..",
	"4444444444444444..",
	"5555444444444444..",
	"5555444444444444..",
	"5555444444444333..",
	"5555544444333333..",
	"5555544444333333..",
	"55555544433333333.",
	"...55544433333333.",
	"...55544333333333.",
	"...55444433333333.",
	".5555444433333333.",
	".5555444433333344.",
	".5554444443334....",
	"....444444........",
	".....44444........",
]
const OBJECTS := [
	".........k....k...",
	".........k....k...",
	".......k......k...",
	".....g.k......k...",
	"....ggg..R........",
	"...gggg...........",
	"...gggg...........",
	"k..g.gg.k..kk.....",
	"k..g.gg.k..kk.....",
	"....gPg.k.BPP..R..",
	"....gPg.k.BPP..R..",
	".....P.....kk..k..",
	"....k.............",
	"....k.............",
	"k...B....kkkkkkkk.",
	".......k..k....kk.",
	".....R....V....kk.",
	"....k.....k....kk.",
	".Pk.k.....k....kk.",
	".k.P......kkkkkkk.",
	"...........kk.....",
	"....Bk...k........",
	".....k...k........",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 9, 13, "mv_2", "", false],
	[ExitDef.Edge.NORTH, 10, 13, "mv_6", "", false],
	[ExitDef.Edge.SOUTH, 6, 8, "mv_4", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(4, 7), Vector2.DOWN, EnemyKind.Kind.GHOST, 4],
	[Vector2i(14, 9), Vector2.UP, EnemyKind.Kind.WOLF, 4],
	[Vector2i(6, 16), Vector2.DOWN, EnemyKind.Kind.SHADOW, 4],
	[Vector2i(9, 11), Vector2.RIGHT, EnemyKind.Kind.LOBBER, 4],
	[Vector2i(2, 19), Vector2.UP, EnemyKind.Kind.WOLF, 4],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(14, 15), "dark_shard", 2],
	[Vector2i(5, 20), "dark_shard", 1],
	[Vector2i(5, 0), "money", 50],
	[Vector2i(0, 5), "potion_m", 1],
	[Vector2i(14, 12), "dark_shard", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["mv_3:0", "VINES", [Vector2i(10, 16)], [Vector2i(10, 16)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
