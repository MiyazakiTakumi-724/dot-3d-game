extends RefCounted
## 鷹の巣 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "mt_7"
const TITLE := "鷹の巣"
const REGION := "山岳"
const THEME := "mountain"
const ORIGIN := Vector2i(-24, -26)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"4444556667777667",
	"4444556666776667",
	"4444455666666666",
	"4444888888666666",
	"4488888888855666",
	"4688888888877566",
	"4588888888877766",
	"5555888888877755",
	"5555558888877755",
	"5555554888777555",
	"5555554474634555",
	"5555554463634455",
	"5555544454544455",
	"5554444444444445",
]
const OBJECTS := [
	"...........R....",
	"................",
	"................",
	"....R....R..R...",
	"R...R.....R.....",
	"......R.........",
	"...R.R..R.......",
	"...R............",
	".R.P............",
	"R.R.............",
	"....R.........R.",
	".............P..",
	"....R........R..",
	"R...............",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 10, 12, "mt_4", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(7, 11), Vector2.LEFT, EnemyKind.Kind.SPEAR, 2],
	[Vector2i(9, 4), Vector2.DOWN, EnemyKind.Kind.WASP, 2],
	[Vector2i(5, 7), Vector2.RIGHT, EnemyKind.Kind.MELEE, 2],
	[Vector2i(2, 2), Vector2.RIGHT, EnemyKind.Kind.CHARGER, 2],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(13, 2), "seal_mt", 1],
	[Vector2i(15, 13), "potion", 1],
	[Vector2i(5, 2), "bone", 2],
	[Vector2i(6, 9), "arrow", 10],
	[Vector2i(1, 4), "iron_ore", 3],
]
## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く
const MERCHANTS := [
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
]
## ボスの居場所 [マス, 名前, 色]
const BOSSES := [
]
