extends RefCounted
## 背高草の野 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_4"
const TITLE := "背高草の野"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(86, -16)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"22333322222221",
	"22333322222221",
	"22333322222222",
	"22333322222222",
	"22333322223322",
	"22333322233333",
	"33333332233333",
	"33333332333333",
	"33333333733333",
	"33334557773333",
	"33345676666333",
	"34555555553333",
	"33355555433333",
	"33335552233333",
	"33333322222222",
	"33333322222222",
	"33333322222222",
	"33333322222222",
	"33222222222222",
	"22222222222122",
	"22222222221112",
	"22222222221111",
	"22222222221111",
	"22222222211112",
	"22222221111122",
	"22222221111122",
	"22222222222222",
	"22222222222222",
	"22222222222222",
	"33222222222222",
	"33322222222222",
	"33322222221122",
]
const OBJECTS := [
	"B...gP...Pgggg",
	"....gg...ggggg",
	"...F.....ggggg",
	"...ggg...ggggg",
	"gggggggggggggg",
	"Pgggggggg....g",
	"....ggg.g....g",
	"....ggg.g....g",
	"....ggggg....g",
	"Pggggggggggg.g",
	"gg.....ggggg..",
	"...gggggggggB.",
	"gggggggg......",
	"ggg.ggggg.g..P",
	"gg....gggg....",
	"gg....gggg....",
	"gg....gggg....",
	"......gggg....",
	"....gg....gggP",
	"...ggg....gggg",
	"...ggg....gggg",
	"..gggg....gg.g",
	"...gggggggggg.",
	"Pggggggg...T..",
	"....gg........",
	"....gg~...g...",
	"....TT~TT...g.",
	"PgggT...T..g.g",
	"ggggT.Q.T.....",
	"..ggT...T.....",
	"..ggTTTTT.....",
	"..gggggg...g..",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 6, 8, "gr_3", "", false],
	[ExitDef.Edge.WEST, 24, 26, "gr_2", "gr_gate", true],
	[ExitDef.Edge.EAST, 14, 17, "gr_5", "gr_boss", true],
	[ExitDef.Edge.NORTH, 6, 8, "gr_8", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(4, 16), Vector2.RIGHT, EnemyKind.Kind.BEETLE, 2],
	[Vector2i(9, 13), Vector2.LEFT, EnemyKind.Kind.WASP, 2],
	[Vector2i(8, 20), Vector2.RIGHT, EnemyKind.Kind.WEAK, 2],
	[Vector2i(11, 7), Vector2.LEFT, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(7, 7), Vector2.LEFT, EnemyKind.Kind.SHADOW, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(5, 29), "bow_poison", 1],
	[Vector2i(0, 19), "potion", 1],
	[Vector2i(7, 6), "wood", 2],
	[Vector2i(12, 28), "arrow", 10],
	[Vector2i(12, 21), "herb", 3],
	[Vector2i(8, 25), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_4:0", "TARGET", [Vector2i(6, 26), Vector2i(6, 25)], [Vector2i(6, 28)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
