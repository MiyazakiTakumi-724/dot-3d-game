extends RefCounted
## 宝物庫 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "cs_x"
const TITLE := "宝物庫"
const REGION := "廃城"
const THEME := "castle"
const ORIGIN := Vector2i(-48, -64)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"111111111111111111",
	"111111111111111111",
	"111111111111111111",
	"111111111111111111",
	"111111111111111111",
	"111111111111122222",
	"111111111111123333",
	"111111111111123333",
	"111111111111123333",
	"111111111111122222",
	"111111111111111111",
	"111111111111111111",
	"111111111111111111",
	"111111111111111111",
]
const OBJECTS := [
	"..................",
	".ssssssssssssssss.",
	".ssssssssssssssss.",
	".sssIssssssssIsss.",
	".ssssssssssssssss.",
	".ssssssssssssssssI",
	".ssssssss.ssss....",
	".sssssssss.sss....",
	".sssssssssssss....",
	".ssssssssssssssssI",
	".sssIssssssssIsss.",
	".ssssssssssssssss.",
	".ssssssssssssssss.",
	"..................",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.EAST, 6, 8, "cs_8", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(10, 7), "money", 80],
	[Vector2i(13, 0), "silver", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
	[Vector2i(9, 6), "宝箱の王", Color("e8b83a")],
]
