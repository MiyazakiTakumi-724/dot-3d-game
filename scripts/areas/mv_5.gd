extends RefCounted
## 闇の砦 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mv_5"
const TITLE := "闇の砦"
const REGION := "霧の谷"
const THEME := "mist"
const ORIGIN := Vector2i(100, 109)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"..........2344443...........",
	"..........2344443...........",
	"...555.2..2344443..2........",
	"..255522222344443.2222255...",
	"...5552222233333322222255...",
	"...5552222233333322222255...",
	"....55222222222222222225....",
	"....55222222222222222225....",
	"...5552222222222222222255...",
	"...5552222222222222222255...",
	"...555222222222222222225....",
	"...555222222222222222225....",
	"...555222222222222222225....",
	"...555222222222222222225....",
	"...555222222222222222225....",
	"..2555222222222222222225....",
	"..2555222222222222222225....",
	"...555222222222222222225....",
	"...555222222222222222225....",
	"....55222222222222222225....",
	"....55222222222222222225....",
	"....55432222222222223445....",
	"...5554322222222222234455...",
	"...5552222222222222222255...",
	"...5552222222.....2222255...",
	"..2..222222.2...............",
	"...........222..............",
	"...........222..............",
]
const OBJECTS := [
	"...........k....k...........",
	"..........Ws....s...........",
	"...sss.s..ss....s..s........",
	"..Wsssssssss....s.sssssss...",
	"...ssssssssssssssssssssss...",
	"...ssssssssssssssssssssss...",
	"....sss.sIssssssssIsssss....",
	"....ssssssssssssssssssss....",
	"...ssssssssssssssssssssss...",
	"...ssssssssssssssssssssss...",
	"...ssssssIssssssssIsssss....",
	"...ssssssIssssssssIsssss....",
	"...sssssssssss.sssssssss....",
	"...sssssssssssssssssssss....",
	"...sssssssssssssssssssss....",
	"..Wsssssssssssssssssssss....",
	"..Wsssssssssssssssssssss....",
	"...ssssssIssssssssIsssss....",
	"...ssssssIssssssssIsssss....",
	"....ssssssssssssssssssss....",
	"....sssssssssssssssss..s....",
	".........ssssssssss.........",
	"...s.....ssssssssss.....s...",
	"...ssssssssssssssssssssss...",
	"...ssssssssss.....sssssss...",
	"..W..WWWWWW.................",
	"...........W.W..............",
	"............................",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 12, 15, "mv_4", "mv_boss", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(12, 27), "dark_shard", 2],
	[Vector2i(7, 6), "potion_m", 2],
	[Vector2i(21, 20), "dark_shard", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
	[Vector2i(14, 12), "闇の王", Color("3a3448")],
]
