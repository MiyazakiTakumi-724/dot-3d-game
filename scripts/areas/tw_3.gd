extends RefCounted
## 塔の外周 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "tw_3"
const TITLE := "塔の外周"
const REGION := "神秘の塔"
const THEME := "tower"
const ORIGIN := Vector2i(-34, 38)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	"........111.........",
	"..765...1110000111..",
	"..765...1110000111..",
	"..7654..1110001111..",
	"..78543...00011111..",
	"..76543...00011111..",
	"..7654400000011111..",
	"..7655511111111222..",
	"..7666622222222222..",
	"..7777733333333322..",
	"..7776644444444322..",
	"..6666655555554333..",
	"..6666666666654333..",
	"..6666677777654333..",
	"..6666678887654333..",
	"..6665678887654333..",
	"..6665678887654333..",
	"........888.........",
]
const OBJECTS := [
	"........sss.........",
	"..sss...ssssssssss..",
	"..sss.....ssssssss..",
	"..s.ss....ssssssss..",
	"..s.sss...ssssssss..",
	"..sssss...ssssssss..",
	"..sssssWWWWWWsssss..",
	"..sssssWWWWWWsssss..",
	"..sssssWWWWWWsssss..",
	"..sssssWWWWWWsssss..",
	"..sssssWWWWWWsssss..",
	"..sssssWWWWWWsssss..",
	"..ssssssssssssssss..",
	"..ssssssssssssssss..",
	"..ssssssssssssssss..",
	"..ssssssssssssssss..",
	"..ssssssssssssssss..",
	"........sss.........",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 8, 10, "tw_2", "", false],
	[ExitDef.Edge.SOUTH, 8, 10, "tw_4", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(3, 3), "star_shard", 1],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
	[Vector2i(3, 4), "らせん塔の番人", Color("b8b2a4")],
]
