class_name Continent
extends RefCounted
## 大陸の4エリア（野営地・岩場・丘陵・奥の森）をまとめる。地図は tools/area_maps/gen.py が作る。

const CAMP := preload("res://scripts/areas/camp.gd")
const AREA_SCRIPTS := [
	CAMP,
	preload("res://scripts/areas/rocks.gd"),
	preload("res://scripts/areas/hills.gd"),
	preload("res://scripts/areas/forest.gd"),
]
const START_AREA := "camp"
const START_CELL: Vector2i = CAMP.START

static func build() -> WorldMap:
	var w := WorldMap.new()
	for s in AREA_SCRIPTS:
		w.add(area_from(s))
	return w

static func area_from(s) -> AreaDef:
	var a := AreaDef.new()
	a.id = s.ID
	a.title = s.TITLE
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
	return a

## エリアの地図を高さマップにする。info は Terrain.parse_layers の結果。
static func load_map(a: AreaDef) -> Array:
	var map := HeightMap.new(a.size())
	var info := Terrain.parse_layers(a.heights, a.objects, map)
	return [map, info]
