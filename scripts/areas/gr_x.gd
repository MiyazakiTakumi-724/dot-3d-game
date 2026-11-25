extends RefCounted
## 女王の巣 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_x"
const TITLE := "女王の巣"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(50, -32)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111112222",
	"11111111111111112222",
	"11111111111111112222",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
	"11111111111111111111",
]
const OBJECTS := [
	".TTTTBTBT.TF....B.TT",
	"T.TBB.T..FFTTF.TBBT.",
	".F.FTT..F.....FBTTBF",
	"F.T...F..F.F.....F.F",
	".T..F...F.........F.",
	"BF...F..F..F..F.FF.P",
	".B...F...F..........",
	"BB.FF.....F.........",
	".B.....FF....FF.....",
	"F.F...........F....P",
	"TB.F.F...FF........F",
	".T..F.......F..F..F.",
	"TTB.FFF.......FF.FTF",
	"T..FFF..F.FF..F.FTBF",
	"BTFB..F...F......T..",
	"T.B...T..T..FBFFF.BT",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 6, 8, "gr_8", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(12, 4), "herb", 4],
	[Vector2i(7, 11), "potion_m", 2],
	[Vector2i(1, 3), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
	[Vector2i(12, 7), "女王蜂", Color("f0c030")],
]
