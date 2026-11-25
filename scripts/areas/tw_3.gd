extends RefCounted
## 塔の外周 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "tw_3"
const TITLE := "塔の外周"
const REGION := "神秘の塔"
const THEME := "tower"
const ORIGIN := Vector2i(-26, 62)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := true
const HEIGHTS := [
	".........111.............",
	".........111.............",
	"..7665...1110............",
	"..7665...111000011111....",
	"..76654..111000111111....",
	"..788543...0001111111....",
	"..766543...0001111111....",
	"..7665440000001111111....",
	"..7665551111111122222....",
	"..7666662222222222222....",
	"..7666662222222222222....",
	"..7777773333333332222....",
	"...777773333333332222....",
	"...777664444444432222....",
	"...666665555555433333....",
	"...666666666665433333....",
	"...666667777765433333....",
	"...666667777765433333....",
	"...666667888765433333....",
	"...666667888765433333....",
	"...6665678887.5433333....",
	"......5678887............",
	"........78887............",
	".........888.............",
]
const OBJECTS := [
	".........sss.............",
	".........sss.............",
	"..ssss...ssss............",
	"..ssss.....ssssssssss....",
	"..s..ss....ssssssssss....",
	"..s..sss...ssssssssss....",
	"..ssssss...ssssssssss....",
	"..ssssssWWWWWWsssssss....",
	"..ssssssWWWWWWsssssss....",
	"..ssssssWWWWWWsssssss....",
	"..ssssssWWWWWWsssssss....",
	"..ssssssWWWWWWsssssss....",
	"...sssssWWWWWWsssssss....",
	"...sssssWWWWWWsssssss....",
	"...sssssWWWWWWsssssss....",
	"...ssssssssssssssssss....",
	"...ssssssssssssssssss....",
	"...ssssssssssssssssss....",
	"...ssssssssssssssssss....",
	"...ssssssssssssssssss....",
	"...ssssssssss.sssssss....",
	"......sssssss............",
	"........sssss............",
	".........sss.............",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 9, 11, "tw_2", "", false],
	[ExitDef.Edge.SOUTH, 9, 11, "tw_4", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(3, 4), "star_shard", 1],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
	[Vector2i(3, 5), "らせん塔の番人", Color("b8b2a4")],
]
