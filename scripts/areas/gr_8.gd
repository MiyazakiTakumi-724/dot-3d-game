extends RefCounted
## 果ての草原 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_8"
const TITLE := "果ての草原"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(70, -32)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"112222222234444444444444443333",
	"112222222233344444444444443333",
	"112222222235333344444444443333",
	"112233222255533334444666333332",
	"122233333555553333446666633332",
	"122222223355533333336666633332",
	"222222222335322233336666633332",
	"222222222334222233336666622222",
	"222222222234222233336666622211",
	"222222222223222223322565212222",
	"222222222222223333322252112222",
	"222222222222222233322242112222",
	"222222222222222222222222212222",
	"222222222222222222222222222222",
	"222333332222222222222222222222",
	"223333332222222222222222222222",
]
const OBJECTS := [
	"FFFF~~....gggFFFFFggggggggg...",
	"FFFF~~....gggFFFFggggggggg...B",
	"FFFF~~....B..ggF.ggggggggggg.g",
	"FFFg~~.....B.g....B...Tgg....g",
	"FFgg~~..B......FB.F...F.g....F",
	"PFgg~~..B..B..........F.g....F",
	"....~~.......................F",
	"....~~g..FF.T........F.....g.B",
	"....~~ggFFF.FFF.....FFFT...g..",
	"P....Y..FFF.FFFFFFFFFF.F.FF...",
	"...g~~ggFFF.FFFFFFFFFF.FFFF...",
	"...g~~ggFFFF.FFFFFFFFF.FFFF...",
	"....~~g....FFFFFFFFFFF...FFF..",
	"FFF.~~.....FFF....FFFF...gFFFF",
	"FFFF~~FF...Fg......FFF.....FFF",
	"FFFF~~FP...Pg.......FP...P.FFF",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 8, 10, "gr_3", "", false],
	[ExitDef.Edge.SOUTH, 22, 24, "gr_4", "", false],
	[ExitDef.Edge.WEST, 6, 8, "gr_x", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(8, 2), Vector2.LEFT, EnemyKind.Kind.WEAK, 2],
	[Vector2i(27, 5), Vector2.RIGHT, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(24, 9), Vector2.DOWN, EnemyKind.Kind.SHADOW, 2],
	[Vector2i(14, 6), Vector2.RIGHT, EnemyKind.Kind.LOBBER, 2],
	[Vector2i(18, 7), Vector2.DOWN, EnemyKind.Kind.BEETLE, 2],
	[Vector2i(12, 11), Vector2.UP, EnemyKind.Kind.WASP, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(16, 2), "seal_gr", 1],
	[Vector2i(19, 3), "arrow", 10],
	[Vector2i(26, 1), "herb", 3],
	[Vector2i(17, 15), "scale", 2],
	[Vector2i(13, 5), "money", 30],
	[Vector2i(20, 3), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_8:0", "THORNS", [Vector2i(5, 9)], [Vector2i(5, 9)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
