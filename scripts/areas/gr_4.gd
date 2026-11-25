extends RefCounted
## 背高草の野 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "gr_4"
const TITLE := "背高草の野"
const REGION := "草原"
const THEME := "grass"
const ORIGIN := Vector2i(148, 8)
## 広場（たき火・町・ボスの間）。広い平地があってよい
const OPEN_FLAT := false
const HEIGHTS := [
	"22333322333221112222222333332333333222223333",
	"22333322333221122222223333333333333222223333",
	"22333322333222222222333333333333332222223333",
	"22333322333222222233333333333322222222233333",
	"22333322222222222333333333333322222222233333",
	"23333322222222322223333333333222222222333333",
	"33333322222223332222222233222222222222333333",
	"33333322222223332222222232222221112222333333",
	"33333322222233333222222233222222222222333333",
	"33333333333333333222222333322222222222333333",
	"33333333333332223332222333332222222223333344",
	"33333333333333223332222333332222222223333344",
	"33333333333333333333222333332222222222333344",
	"33333333333333333333222333332222222222333334",
	"33333333333333333333222233322222222222333333",
	"33333333333333333332222233222222222222333333",
	"33333333333333333222222233222222222222333333",
	"22233333333333332222222222222223333333222223",
	"22222233333333332522212222222223333333222222",
	"22222223333333355555212222222233333333222222",
	"22222223333333355555221112223333333333222222",
	"22222222333444555555521111223333333333322222",
	"22222223333333355555221111223333333333322222",
	"22222233333333355555222111222222332222222222",
	"22222233333333322515552222222222222222322222",
	"22222233333333322555555522222222222222322222",
	"22222233333233322555555522222222233333322222",
	"22222233322223445555555553322222233333322222",
	"32222233322222222555555533333322222333333332",
	"33222223222222222555555533333322222333332222",
	"33222222222222222335553333333322222333322222",
	"33222222222222223333333333333322222333322222",
	"33322222222222223333333333333333333333322222",
	"33322222222222222333333333333333333333322222",
	"33322222221111222222333333333333333333322222",
	"33322222211111122222233333333333333333222222",
	"33322222221112222222233333333333333332222222",
	"33322222222222222222233333333333332222222222",
	"33322223222222222222233222233333322222222222",
	"33322233222222222222222222222222222222222222",
]
const OBJECTS := [
	"B...gggP...PggggggggggggggF.......gggggggggg",
	"B...ggg....ggggggggggg.ggggF......gggggggggg",
	".......g...ggggggggggg.gggggg.....ggTggggggg",
	"...ggggg...gggggggg....gggggg...g.g..ggggggg",
	"ggggggggggggggggggg....ggggggg.......ggggggg",
	"ggggggggggggggggggg..T.ggggggggg.....ggggggg",
	"ggggggggggggggggggg..F.gggg.Fgg.F....ggggggg",
	"gg.gggFggggggggggg...g..gggg..........gggggg",
	"gg.ggggg....gggggg.......g..B......F..ggggT.",
	"...ggBgT.g...ggggg...T..................gg.g",
	"...Fggg....T.gggggT.......g...............gg",
	"P.T.ggg.F..g.ggggg.....TBBg.....g....B......",
	"....gFgB.....ggggg.B.....B............BgTgTg",
	"....Fg....g..gggggB.....gggg......FggggggBg.",
	".........gggggggggg....ggggg..g..ggggggggggF",
	"Pggg...B.ggggBggFgg....gggggF.ggggggggTgggBT",
	"gggg..g..ggggggggggF..Fggggg..ggggggggggggg.",
	"gFgT.F....gg.gggggggFgggggggB....ggggggggggg",
	"gggg......g..ggggggggggggggg.....ggggggggggg",
	"ggggg...g...g.ggTggggggggggg.....ggggggggggP",
	"ggggg.....gg..gggFggggggggggg....ggggggg....",
	"FgggB..........gggggggggggggB.....gggggg....",
	"gFgg...F.......Fggggggggggg.........gggg....",
	"gg............B..ggTgggg....B.....T..ggg....",
	"............F....gggggg..FB.....g.F...ggggFP",
	".g....B.......gg.gggggg........g......gggggF",
	"..g..g.........g.gggggB.........~..g.gggggg.",
	"....gggg..........gggggg.....TTT~TTTgggggg..",
	"F...ggggggggg.....gFgggB..B.FT.....Tgggggg..",
	".T.Fggggggggg.F...gggggggggggT..Q..Tgggg..F.",
	"....ggggggggg....ggggggggggggT.....Tgggg....",
	"...Fggggggggg.....gggggggggggT.....Tgggg....",
	".F.ggggggggggg....gggggggggggTTTTTTTgggF....",
	"gg.gggggggggggggggggggT.ggg...gggBgggggggggg",
	"ggggggggggggggggggBFgg..ggg.......F..ggggggg",
	"ggggggggggggggggggggg...ggg..........ggFgggg",
	"ggggggggggggggggggggg.Fg......g....g.ggggggF",
	"g.ggggggggggggggggggg.......T..g.....gBgTggg",
	".......gggggggggggggg..F.......T...g..gggggT",
	"g...F.BFggggggggBFggg.T.......g.TT........gg",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.NORTH, 8, 10, "gr_3", "", false],
	[ExitDef.Edge.WEST, 12, 14, "gr_2", "gr_gate", true],
	[ExitDef.Edge.EAST, 20, 23, "gr_5", "", false],
]
const ENEMIES := [
]
const PICKUPS := [
	[Vector2i(30, 31), RunState.PickupKind.ARROWS, 40],
	[Vector2i(27, 6), RunState.PickupKind.MONEY, 20],
	[Vector2i(40, 11), RunState.PickupKind.MATERIAL, 2],
	[Vector2i(4, 18), RunState.PickupKind.HEAL, 1],
	[Vector2i(2, 7), RunState.PickupKind.MONEY, 30],
	[Vector2i(24, 26), RunState.PickupKind.HEAL, 2],
]
## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]
const GIMMICKS := [
	["gr_4:0", "TARGET", [Vector2i(32, 27), Vector2i(32, 26)], [Vector2i(32, 29)]],
]
## ボスの居場所 [像のマス, 名前, 像の色]（ボスはまだいないので像を置く）
const BOSSES := [
]
