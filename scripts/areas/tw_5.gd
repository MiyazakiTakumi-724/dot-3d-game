extends RefCounted
## 塔の回廊 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "tw_5"
const TITLE := "塔の回廊"
const REGION := "神秘の塔"
const THEME := "tower"
const ORIGIN := Vector2i(-14, 38)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"222222222222222222",
	"222222222222222222",
	"222222222222444222",
	"222222222224444422",
	"222222222224444432",
	"222222222224444422",
	"222222222222444222",
	"222244422222222222",
	"222444442222222222",
	"222444443222222222",
	"222444442111111222",
	"222144422111111222",
	"221112222111122222",
	"211111111222222222",
]
const OBJECTS := [
	".....I...I..I.....",
	".............I....",
	"..................",
	"..................",
	"..................",
	"..................",
	"..................",
	"..................",
	"..................",
	"..................",
	"..................",
	"..................",
	"..................",
	"..................",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 6, 8, "tw_1", "", false],
]
## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]
const ENEMIES := [
	[Vector2i(7, 4), Vector2.UP, EnemyKind.Kind.SHADOW, 5],
	[Vector2i(15, 11), Vector2.LEFT, EnemyKind.Kind.GHOST, 5],
	[Vector2i(6, 9), Vector2.UP, EnemyKind.Kind.MAGE, 5],
	[Vector2i(15, 2), Vector2.DOWN, EnemyKind.Kind.SPEAR, 5],
]
## [マス, 品物の id（ItemCatalog、お金は money）, 数]
const PICKUPS := [
	[Vector2i(5, 8), "potion_m", 1],
	[Vector2i(2, 3), "ether", 1],
	[Vector2i(15, 12), "star_shard", 1],
	[Vector2i(14, 1), "star_shard", 1],
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
