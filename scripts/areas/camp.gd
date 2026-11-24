extends RefCounted
## 野営地 のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。

const ID := "camp"
const TITLE := "野営地"
const ORIGIN := Vector2i(0, 0)
const START := Vector2i(12, 11)
const HEIGHTS := [
	"111111111144411111111111",
	"111111111144411111111111",
	"111111112344411111111111",
	"111111111144411111111111",
	"111111111111111111111111",
	"111111111111111111222111",
	"112111111111111111111111",
	"113111111111111111112311",
	"444411111111111111114444",
	"444411111111111111114444",
	"444411111111111111114444",
	"111111111111111111111111",
	"111111111111111111111111",
	"221111111111111111111111",
	"222111111111111111111111",
	"222111111111111111111112",
	"221111111111111111111112",
	"111111111111111111111112",
	"111111111111111111112222",
	"111111111111111111222222",
]
const OBJECTS := [
	"PPTBTTBTPP...BBBPPPBTTPT",
	"TTTBBBBBPT...TTPBPTBTBBT",
	"BP......F...........F.TT",
	"TP.......B............TT",
	"PT........F.T.......BTTT",
	"TB.T..............F...BT",
	"TT....................BP",
	"TT...B............F...BB",
	"........................",
	".....F..................",
	".....B......C...........",
	"TT.................BF.TB",
	"TT....................PT",
	"TT....................TT",
	"TP....................BT",
	"TP...F................TT",
	"TT..F.................PB",
	"BB.................F..BT",
	"TBPTBTTTTBTTBPTTBTTTBTTT",
	"TTBTTPTPTTTTBTTPTPTPTPBT",
]
## [辺, from, to, 相手, 門の id, この側から門を開けられるか]
const EXITS := [
	[ExitDef.Edge.WEST, 8, 10, "rocks", "", false],
	[ExitDef.Edge.EAST, 8, 10, "hills", "", false],
	[ExitDef.Edge.NORTH, 10, 12, "forest", "forest_gate", false],
]
const ENEMIES := [
]
const PICKUPS := [
	[Vector2i(9, 8), RunState.PickupKind.SWORD, 1],
	[Vector2i(15, 8), RunState.PickupKind.BOW, 1],
	[Vector2i(15, 12), RunState.PickupKind.ARROWS, 50],
	[Vector2i(9, 12), RunState.PickupKind.POISON_ARROWS, 10],
	[Vector2i(12, 6), RunState.PickupKind.GUN, 1],
	[Vector2i(14, 6), RunState.PickupKind.AMMO, 40],
	[Vector2i(8, 10), RunState.PickupKind.ARMOR, 1],
	[Vector2i(21, 3), RunState.PickupKind.HEAL, 2],
]
