extends RefCounted
## 草原の入口 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_1"
const TITLE := "草原の入口"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(48, 0)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"3333333433333333333333",
	"3333333333333333333333",
	"3333333333333333333333",
	"2223333333333333333333",
	"2222222333333322222333",
	"3222223333333222222223",
	"2222223333332222222222",
	"2222223333222222222222",
	"2222223322222222222222",
	"3332122222222222222222",
	"3331112222222332222222",
	"3331112222222332222222",
	"3331112222222332222222",
	"3333222222222332222211",
	"3332222222222332222111",
	"3333222222222222222211",
]
const OBJECTS := [
	"............T..~..gggg",
	"...............~...ggg",
	".F.............~......",
	"g......g.......~..F...",
	".B..ggggg....g~~......",
	"P...gggggggggg~g..B..P",
	"....gggggggggg~g......",
	"......B.gggggg~g.g....",
	"............gg~T......",
	"PgTTXTT.....gg=......P",
	"ggT...TT....gg.=..T...",
	"ggT...TB....gg.=.g....",
	"ggT...T.ggggg..=......",
	"ggTTTTT.ggggg..=..T...",
	"ggg.....ggggg...~.....",
	"ggg.....ggggg.B.~g....",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 6, 8, "hills", "", false],
	[ExitDef.Edge.EAST, 6, 8, "gr_2", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(10, 10), Vector2.RIGHT, EnemyKind.Kind.WEAK, 2],
	[Vector2i(11, 3), Vector2.LEFT, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(16, 9), Vector2.DOWN, EnemyKind.Kind.SHADOW, 2],
	[Vector2i(5, 2), Vector2.UP, EnemyKind.Kind.SHOOTER, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(3, 12), "money", 40],
	[Vector2i(7, 7), "potion", 1],
	[Vector2i(13, 12), "wood", 2],
	[Vector2i(16, 8), "arrow", 10],
	[Vector2i(18, 12), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_1:0", "CRACK", [Vector2i(4, 9)], [Vector2i(4, 9)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
