extends RefCounted
## 雪の峠 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mt_4"
const TITLE := "雪の峠"
const REGION := "山岳"
const THEME := "mountain"
const ORIGIN := Vector2i(-56, -26)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"55544455556655555555555555555544",
	"55544555555655555555555555555444",
	"55555777555755555555555555555543",
	"55557777756866555555555555555533",
	"66667777756868665555555555555533",
	"66667777788877775555555555555533",
	"66665777588888888555556555555543",
	"66665565588888888556666555544443",
	"66666565566888888555666555544443",
	"55666565566668885555566555544443",
	"55566555556668885555555555444443",
	"55566555556666765555555555444433",
	"55555555555666655555555555444433",
	"55555555555555555555555555444433",
]
const OBJECTS := [
	".PR....R.R...R....R..........R..",
	".............P......P...........",
	".....................R..RRRRRR..",
	"RP.......................R...R.R",
	"................R........V...R..",
	"......RRR.......P........R...R.R",
	"........B................RRRRR.P",
	"....P...R.R...................R.",
	"..................P....R...B....",
	".R.............B......R.R......R",
	"................................",
	"............R...................",
	"...R.........R.......R..........",
	"....RR...R......P........R...R..",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.SOUTH, 6, 8, "mt_3", "", false],
	[ExitDef.Edge.SOUTH, 26, 28, "mt_2", "mt_gate", true],
	[ExitDef.Edge.NORTH, 14, 17, "mt_5", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(2, 6), Vector2.RIGHT, EnemyKind.Kind.SHOOTER, 2],
	[Vector2i(13, 4), Vector2.DOWN, EnemyKind.Kind.FLYER, 2],
	[Vector2i(27, 9), Vector2.RIGHT, EnemyKind.Kind.MELEE, 2],
	[Vector2i(18, 11), Vector2.DOWN, EnemyKind.Kind.CHARGER, 2],
	[Vector2i(20, 5), Vector2.DOWN, EnemyKind.Kind.SHOOTER, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(28, 3), "arrow_iron", 10],
	[Vector2i(20, 12), "arrow", 10],
	[Vector2i(9, 7), "iron_ore", 2],
	[Vector2i(26, 9), "snow", 2],
	[Vector2i(1, 1), "money", 30],
	[Vector2i(8, 2), "iron_ore", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["mt_4:0", "VINES", [Vector2i(25, 4)], [Vector2i(25, 4)]],
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
