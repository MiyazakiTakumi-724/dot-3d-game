extends RefCounted
## 花の丘 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_3"
const TITLE := "花の丘"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(70, -16)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"2233332222233333",
	"2233333222233333",
	"3322233322222333",
	"3322233322222233",
	"3322233332222223",
	"3332223333222233",
	"3322255533333333",
	"3322255533333333",
	"3444555553333333",
	"3332255522223333",
	"2333355522222333",
	"3333322222222333",
	"3333333332222333",
	"3333333333222333",
	"3333333333333333",
	"3333333333333333",
]
const OBJECTS := [
	"FFF....P...Pg...",
	"FTTTTT.....gg...",
	"FT...T.....g..FF",
	".T...TF....FFFFF",
	"gT...T..FFFFFFFF",
	"gTTYTTT.FFFFFFFP",
	"ggg.g..FFFF.....",
	"gg...FFFFFFF....",
	".....F.FFFFF....",
	"...FFFFFFFgFFFFP",
	"...FFFF.FggFFFFF",
	"....FFFFFgggF.FF",
	"....FF.......FFF",
	"............B...",
	".....g........T.",
	"FF...P...P......",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 6, 8, "gr_2", "", false],
	[ExitDef.Edge.EAST, 6, 8, "gr_4", "", false],
	[ExitDef.Edge.NORTH, 8, 10, "gr_8", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(6, 8), Vector2.LEFT, EnemyKind.Kind.WEAK, 2],
	[Vector2i(2, 13), Vector2.UP, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(11, 6), Vector2.DOWN, EnemyKind.Kind.SHADOW, 2],
	[Vector2i(2, 7), Vector2.DOWN, EnemyKind.Kind.LOBBER, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(2, 2), "potion_m", 2],
	[Vector2i(3, 0), "arrow", 10],
	[Vector2i(7, 10), "herb", 3],
	[Vector2i(13, 11), "scale", 2],
	[Vector2i(7, 5), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_3:0", "THORNS", [Vector2i(3, 5)], [Vector2i(3, 5)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
