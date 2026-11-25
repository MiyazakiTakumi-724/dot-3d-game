extends RefCounted
## 王の間 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "cs_5"
const TITLE := "王の間"
const REGION := "廃城"
const THEME := "castle"
const ORIGIN := Vector2i(-8, -184)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"111111111111111111111111111111111111111111111111",
	"111111111111111111111111111111111111111111111111",
	"111111111111111111111111111111111111111111111111",
	"111133333333333333333333333333333333333333331111",
	"111133333333333333333333333333333333333333331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133111111111111111111111111111111111111331111",
	"111133222111111111112222222211111111111222331111",
	"111133111111111111112333333211111111111111331111",
	"111133111111111111112344443211111111111111331111",
	"111111111111111111112344443211111111111111111111",
	"111111111111111111112344443211111111111111111111",
	"111111111111111111112344443211111111111111111111",
]
const OBJECTS := [
	"................................................",
	"................................................",
	"...WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW...",
	"...W........................................W...",
	"...W........................................W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssKsssssssssssssssss..W...",
	"...W..ssssssIssssssssssssssssssssssIssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssIssssssssssssssssssssssIssssss..W...",
	"...W..ssss.sssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssIssssssssssssssssssssssIssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssssssssssss.sssssss..W...",
	"...W..ssssssIssssssssssssssssssssssIssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssIssssssssssssssssssssssIssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssIssssssssssssssssssssssIssssss..W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W......ssssssssssssssssssssssssssss......W...",
	"...W..ssssssssssssssssssssssssssssssssssss..W...",
	"...W..ssssssssssssssss....ssssssssssssssss..W...",
	"...WWWWWWWWWWWWWWWWWWs....sWWWWWWWWWWWWWWWWWW...",
	"................................................",
	".....................I....I.....................",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 22, 25, "cs_4", "", false],
]
const ENEMIES := [
]
const PICKUPS := [
	[Vector2i(10, 13), RunState.PickupKind.MONEY, 20],
	[Vector2i(34, 19), RunState.PickupKind.MATERIAL, 2],
	[Vector2i(25, 1), RunState.PickupKind.MONEY, 40],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [像のマス, 名前, 像の色]（ボスはまだいないので像を置く）
const BOSSES := [
	[Vector2i(24, 7), "廃城の主", Color("8a7f9a")],
]
