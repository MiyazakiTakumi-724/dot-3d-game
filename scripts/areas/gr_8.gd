extends RefCounted
## 果ての草原 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_8"
const TITLE := "果ての草原"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(108, -19)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"22233333335.........................",
	"22233333335...................555...",
	"22233333335.............555...5554..",
	"222333333347455......5555555555444..",
	"2223333333777444455555588888555444..",
	"22333333477777744445558888888444433.",
	"22333333347774434444448888888443333.",
	"33333333344733333334448888888333332.",
	"3333333333463333333333777777733222..",
	"333333333346333333333377777773322...",
	"333333333335333333333366666662222...",
	"333333333335333333333366666662222...",
	"222222222335333333333345585522222...",
	"2222222223353333333333455855222222..",
	"222222222234333333333333372222222...",
	"222222222233333333333333362222222...",
	"3333332233333333333.3333322222222...",
	"333333333332....2.......322222......",
	"333333333333............322222......",
	"333344333333............322223......",
]
const OBJECTS := [
	"FFFF~~....g.........................",
	"FFFF~~....g...................ggg...",
	"FFFF~~....g.............ggg...g.....",
	"FFFF~~....B..gg......gggg.gggggggg..",
	"FFFg~~.....B.gg.....B....Tgggggggg..",
	"FFgg~~..B.......FBB.F.....FFggggggg.",
	"PFgg~~...B..B.............FFggggg.g.",
	"....~~...............g.......gggggg.",
	"....~~g..FF..TT..........F..........",
	"....~~g..FF..TT..........F..........",
	"....~~ggFFF.FFFFBFFFFFFFFF..T.......",
	"....~~ggFFF.FFFFBFFFFFFFFF..T.......",
	"P....Y..FFF.FFFFFFFFFFFFF.FF.FFFF...",
	"P....Y..FFF.FFFFFFFFFFFFF.FF.FFFF...",
	"...g~~ggFFF.FFFF.FFFFFFFF.FFFFFFF...",
	"...g~~ggFFF..FFFFFFFFFFFF.FFFFFFF...",
	"....~~g....FFFFFFFF.FFFFF....FFFF...",
	"FFF.~~.....F............F...........",
	"FFFF~~FF...F............F...........",
	"FFFF~~FP...P............P....P......",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 8, 10, "gr_3", "", false],
	[ExitDef.Edge.SOUTH, 25, 28, "gr_4", "", false],
	[ExitDef.Edge.WEST, 7, 11, "gr_x", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(28, 12), Vector2.DOWN, EnemyKind.Kind.WEAK, 2],
	[Vector2i(8, 3), Vector2.LEFT, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(33, 6), Vector2.RIGHT, EnemyKind.Kind.SHADOW, 2],
	[Vector2i(15, 7), Vector2.RIGHT, EnemyKind.Kind.LOBBER, 2],
	[Vector2i(12, 15), Vector2.UP, EnemyKind.Kind.BEETLE, 2],
	[Vector2i(25, 3), Vector2.RIGHT, EnemyKind.Kind.WASP, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(22, 5), "seal_gr", 1],
	[Vector2i(31, 2), "arrow", 10],
	[Vector2i(6, 7), "herb", 3],
	[Vector2i(16, 14), "scale", 2],
	[Vector2i(22, 7), "money", 30],
	[Vector2i(22, 4), "potion", 2],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_8:0", "THORNS", [Vector2i(5, 12), Vector2i(5, 13)], [Vector2i(5, 12)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
