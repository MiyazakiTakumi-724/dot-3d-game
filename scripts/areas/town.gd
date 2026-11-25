extends RefCounted
## 町 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "town"
const TITLE := "町"
const REGION := "はじまりの地"
const THEME := "town"
const ORIGIN := Vector2i(0, 20)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"111222211111111111111111",
	"111111111111111111111111",
	"111111111111111111111111",
	"111111111111111111111111",
	"111111111111111111111122",
	"111111111111111111111122",
	"111111111111111111111122",
	"111111111111111111111111",
	"111111111111111111111111",
	"111111111111111111111111",
	"111111111111111111111111",
	"111111111111111111111111",
	"222211111111111111111111",
	"222211111111111111111111",
	"222211111111111111111111",
	"111111111111111111111111",
	"111111111111111111111111",
	"111111111211111111111111",
	"211111113333333111111111",
	"211111113444443111111111",
	"211111113455543111111111",
	"211111113455543111111111",
	"111111113455543111111111",
	"111111123455543211111111",
]
const OBJECTS := [
	"PTTBBBTTTB...TPPBTTBPPBT",
	"B......................P",
	"T.HHHHH........HHHHHH..T",
	"T.HHHHH......F.HHHHHH..B",
	"T.HHHHH........HHHHHH.FP",
	"T.HHHHH...F.T..HHHHHH..B",
	"T......................T",
	"P....sssssssssssssss...T",
	"T....sssssssssssssss.T.T",
	"B..F.sssOsssssssMsss...P",
	"T....sssssssssss.sss...T",
	"T....sssssssssssssssF..P",
	".....sssssssCsssssss...T",
	".....sssssssssssssss...T",
	".....ssMssssssssssss...B",
	"T....ss.ssssssssssss...T",
	"T....sssssssssssssss...T",
	"T.......sssssss........T",
	"P.HHHHH...T.F...HHHHHH.T",
	"T.HHHHH.........HHHHHH.T",
	"T.HHHHH.........HHHHHH.P",
	"T.HHHHH..F...B..HHHHHH.T",
	"B......................B",
	"BBTPPPPPBT...TPTPPTTTTTP",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 10, 12, "camp", "", false],
	[ExitDef.Edge.SOUTH, 10, 12, "lv_1", "", false],
	[ExitDef.Edge.WEST, 12, 14, "tw_1", "tower_seal", true],
]
const ENEMIES := [
]
const PICKUPS := [
	[Vector2i(21, 7), RunState.PickupKind.MONEY, 30],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [像のマス, 名前, 像の色]（ボスはまだいないので像を置く）
const BOSSES := [
]
