extends RefCounted
## はじまりの町 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "town"
const TITLE := "はじまりの町"
const REGION := "はじまりの地"
const THEME := "town"
const ORIGIN := Vector2i(16, 18)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const START := Vector2i(16, 12)
const HEIGHTS := [
	"11111222221123333211111111111111",
	"11111111111123333211111111111111",
	"11111111111123333211111111111111",
	"11111111111123333211111111111111",
	"11111111111122222211111111111112",
	"11111111111111111111111111111112",
	"11111111111111111111111111111112",
	"22222222211111111111111111111111",
	"22222222211111111111111111111111",
	"33333333211111111111111111111111",
	"44444443211111111111111111111111",
	"44444443211111111111111111111111",
	"44444443211111111111111111111111",
	"33333333211111111111111122221111",
	"22222221211111111111111133221111",
	"11111111111111114444444111111111",
	"11111111111111114555555111111111",
	"11111111111111114566666111111111",
	"11111111111111114566666111111111",
	"22111111111111114566666111111111",
	"22211111111112334566666543221111",
]
const OBJECTS := [
	"PPTTTBBBBTTTB....TPPPBBTTBPPPPBT",
	"BB.............................P",
	"TT.HHHHHHH...........HHHHHHHHH.T",
	"TT.HHHHHHH.......F...HHHHHHHHH.B",
	"TT.HHHHHHH........F..HHHHHHHHH.P",
	"TT.HHHHHHH...F..T....HHHHHHHHH.B",
	"TT.............................T",
	"PP........sMssssMssssM.s.......T",
	"PP........s.ssss.ssss..s.......T",
	"TT.TT....Fs.ssss.ssss..s.......T",
	"..........ssssssssssssss........",
	"..........ssssssCsssssss........",
	".......F..ssssssssssssss........",
	"BB........ss.ssssss..sss.......P",
	"TT.....O..ssssssssssssss.......T",
	"TT..............T.F............P",
	"TT........HHHH..........HHHHHH.T",
	"BB........HHHH..FB......HHHHHH.T",
	"TT........HHHH..........HHHHHH.T",
	"TT......F.......F..............T",
	"TTP..............B.....BBTPPPPPP",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 10, 12, "rocks", "", false],
	[ExitDef.Edge.EAST, 10, 12, "hills", "", false],
	[ExitDef.Edge.NORTH, 13, 16, "forest", "forest_gate", false],
	[ExitDef.Edge.SOUTH, 18, 22, "lv_1", "", false],
	[ExitDef.Edge.SOUTH, 3, 7, "tw_1", "tower_seal", true],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(12, 13), "money", 30],
	[Vector2i(19, 13), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
	[Vector2i(11, 7), "tool"],
	[Vector2i(16, 7), "weapon"],
	[Vector2i(21, 7), "smith"],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
