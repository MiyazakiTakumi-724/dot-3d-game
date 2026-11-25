class_name Continent
extends RefCounted
## 大陸のすべてのエリア（45）をまとめる（はじまりの地（町）・山岳・草原・廃城・溶岩・神秘の塔）。
## 地図は tools/area_maps/gen.py が作る。並べ方は docs/superpowers/specs/2026-11-25-full-game-design.md。

const TOWN := preload("res://scripts/areas/town.gd")
const AREA_SCRIPTS := [
	TOWN,
	preload("res://scripts/areas/rocks.gd"),
	preload("res://scripts/areas/hills.gd"),
	preload("res://scripts/areas/forest.gd"),
	preload("res://scripts/areas/mt_1.gd"),
	preload("res://scripts/areas/mt_2.gd"),
	preload("res://scripts/areas/mt_3.gd"),
	preload("res://scripts/areas/mt_4.gd"),
	preload("res://scripts/areas/mt_5.gd"),
	preload("res://scripts/areas/mt_x.gd"),
	preload("res://scripts/areas/gr_1.gd"),
	preload("res://scripts/areas/gr_2.gd"),
	preload("res://scripts/areas/gr_3.gd"),
	preload("res://scripts/areas/gr_4.gd"),
	preload("res://scripts/areas/gr_5.gd"),
	preload("res://scripts/areas/cs_1.gd"),
	preload("res://scripts/areas/cs_2.gd"),
	preload("res://scripts/areas/cs_3.gd"),
	preload("res://scripts/areas/cs_4.gd"),
	preload("res://scripts/areas/cs_5.gd"),
	preload("res://scripts/areas/lv_1.gd"),
	preload("res://scripts/areas/lv_2.gd"),
	preload("res://scripts/areas/lv_3.gd"),
	preload("res://scripts/areas/lv_4.gd"),
	preload("res://scripts/areas/lv_5.gd"),
	preload("res://scripts/areas/lv_x.gd"),
	preload("res://scripts/areas/tw_1.gd"),
	preload("res://scripts/areas/tw_2.gd"),
	preload("res://scripts/areas/tw_3.gd"),
	preload("res://scripts/areas/tw_4.gd"),
	preload("res://scripts/areas/mt_6.gd"),
	preload("res://scripts/areas/mt_7.gd"),
	preload("res://scripts/areas/mt_8.gd"),
	preload("res://scripts/areas/gr_6.gd"),
	preload("res://scripts/areas/gr_7.gd"),
	preload("res://scripts/areas/gr_8.gd"),
	preload("res://scripts/areas/gr_x.gd"),
	preload("res://scripts/areas/cs_6.gd"),
	preload("res://scripts/areas/cs_7.gd"),
	preload("res://scripts/areas/cs_8.gd"),
	preload("res://scripts/areas/cs_x.gd"),
	preload("res://scripts/areas/lv_6.gd"),
	preload("res://scripts/areas/lv_7.gd"),
	preload("res://scripts/areas/lv_8.gd"),
	preload("res://scripts/areas/tw_5.gd"),
]
const START_AREA := "town"
const START_CELL: Vector2i = TOWN.START

static func build() -> WorldMap:
	var w := WorldMap.new()
	for s in AREA_SCRIPTS:
		w.add(area_from(s))
	return w

static func area_from(s) -> AreaDef:
	var a := AreaDef.new()
	a.id = s.ID
	a.title = s.TITLE
	a.region = s.REGION
	a.theme = s.THEME
	a.open_flat = s.OPEN_FLAT
	a.origin = s.ORIGIN
	a.heights = s.HEIGHTS
	a.objects = s.OBJECTS
	var exits: Array[ExitDef] = []
	for e in s.EXITS:
		var ex := ExitDef.new()
		ex.edge = e[0]
		ex.from = e[1]
		ex.to = e[2]
		ex.target = e[3]
		ex.door_id = e[4]
		ex.opens_here = e[5]
		exits.append(ex)
	a.exits = exits
	a.enemies = s.ENEMIES
	a.pickups = s.PICKUPS
	var gs: Array[Gimmick] = []
	for d in s.GIMMICKS:
		gs.append(Gimmick.from_data(d))
	a.gimmicks = gs
	a.bosses = s.BOSSES
	a.merchants = s.MERCHANTS
	return a

## エリアの地図を高さマップにする。info は Terrain.parse_layers の結果（deco["theme"] に地方が入る）。
## 仕掛けは閉じた形で書き込む（開けた仕掛けは、ステージ側が開ける）。
static func load_map(a: AreaDef) -> Array:
	var map := HeightMap.new(a.size())
	var info := Terrain.parse_layers(a.heights, a.objects, map)
	info["deco"]["theme"] = a.theme
	for g in a.gimmicks:
		g.close(map)
	return [map, info]
