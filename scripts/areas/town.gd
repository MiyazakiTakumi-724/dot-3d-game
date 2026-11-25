extends RefCounted
## はじまりの町 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "town"
const TITLE := "はじまりの町"
const REGION := "はじまりの地"
const THEME := "town"
const ORIGIN := Vector2i(0, 0)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const START := Vector2i(12, 11)
const HEIGHTS := [
	"111222211233321111111111",
	"111111111233321111111111",
	"111111111233321111111111",
	"111111111233321111111111",
	"111111111222221111111112",
	"111111111111111111111112",
	"111111111111111111111112",
	"111111111111111111111111",
	"222221111111111111111111",
	"333321111111111111111111",
	"333321111111111111111111",
	"333321111111111111111111",
	"222221111111111111111111",
	"111111111111111111111111",
	"111111111111222221111111",
	"111111111111233331111111",
	"111111111111234441111111",
	"111111111111234441111111",
	"211111111111234441111111",
	"221111111121234443211111",
]
const OBJECTS := [
	"PTTBBBTTTB...TPPBTTBPPBT",
	"B......................P",
	"T.HHHHH.........HHHHHH.T",
	"T.HHHHH......F..HHHHHH.B",
	"T.HHHHH.......F.HHHHHH.P",
	"T.HHHHH...F.T...HHHHHH.B",
	"T......................T",
	"P......sMsssMsssMs.....T",
	"T.T...Fs.sss.sss.s.....T",
	".......sssssssssss......",
	".......sssssCsssss......",
	"....F..sssssssssss......",
	"B......ss.sssss.ss.....P",
	"T...O..sssssssssss.....T",
	"T...........T.F........P",
	"T......HHHH.......HHHH.T",
	"B......HHHH.FB....HHHH.T",
	"T......HHHH.......HHHH.T",
	"T....F......F..........T",
	"TP...TTTTPTTBB...BBTPPPP",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 9, 11, "rocks", "", false],
	[ExitDef.Edge.EAST, 9, 11, "hills", "", false],
	[ExitDef.Edge.NORTH, 10, 12, "forest", "forest_gate", false],
	[ExitDef.Edge.SOUTH, 14, 16, "lv_1", "", false],
	[ExitDef.Edge.SOUTH, 2, 4, "tw_1", "tower_seal", true],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(9, 12), "money", 30],
	[Vector2i(15, 12), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
	[Vector2i(8, 7), "tool"],
	[Vector2i(12, 7), "weapon"],
	[Vector2i(16, 7), "smith"],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
