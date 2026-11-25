class_name Gimmick
extends RefCounted
## 武器で開く仕掛け（docs/superpowers/specs/2026-11-25-world-map-design.md 5章）。
## - CRACK（ひびの入った岩）：上から鉄球を落とすと砕ける（1段以上の高さから）。
## - TARGET（的と上がった橋）：弓で的（trigger）を撃つと、橋（cells の水のマス）が下りる。
## - THORNS（茨）：炎の魔法で燃える。
## - VINES（つた）：剣で斬れる。
## 一度開けた仕掛けは RunState が覚えていて、死んでも開いたまま。
## 2026-11-26（3回目の直し）に足したもの：
## - PLATE（押し板と鉄格子）：鉄球を板（trigger）の上に置く（落とす高さは問わない）と、鉄格子（cells）が上がる。
## - LEVER（レバーと鉄格子）：レバー（trigger）のとなりに立って F で引くと、鉄格子が上がる。
## - CRYSTAL（魔法の水晶とせり上がる足場）：水晶（trigger）に魔法を当てると、足場（cells）が heights の高さまでせり上がる。
##   閉じている間は地図のままの低さ（高い所へ登れない）。高低差を使う仕掛け。
## - BRITTLE（もろい壁）：爆弾でだけ崩れる。

enum Kind { CRACK, TARGET, THORNS, VINES, PLATE, LEVER, CRYSTAL, BRITTLE }

const FIRE_REACH := 8.0  ## 炎の当たる所から、マスのふちまでこの距離なら燃える（炎の広さに足す）
const PLATE_REACH := 3.0  ## 鉄球の中心が、押し板のマスのふちからこの距離までなら沈む

var id := ""
var kind: Kind = Kind.CRACK
## ふさぐマス（TARGET では橋になる水のマス）
var cells: Array[Vector2i] = []
## 武器を当てるマス（TARGET では的、PLATE は板、LEVER はレバー、CRYSTAL は水晶。ほかは cells と同じ）
var trigger: Array[Vector2i] = []
## CRYSTAL：開けたときの cells の高さ（cells と同じ順）
var heights: Array[int] = []

static func make(gid: String, k: Kind, c: Array, t: Array, h: Array = []) -> Gimmick:
	var g := Gimmick.new()
	g.id = gid
	g.kind = k
	g.cells.assign(c)
	g.trigger.assign(t)
	g.heights.assign(h)
	return g

## エリアのデータ [id, 種類の名前, ふさぐマス, 当てるマス, (開けたときの高さ)] から作る。
static func from_data(d: Array) -> Gimmick:
	return make(d[0], Kind[d[1]], d[2], d[3], d[4] if d.size() > 4 else [])

static func blocker(k: Kind) -> HeightMap.Blocker:
	match k:
		Kind.CRACK:
			return HeightMap.Blocker.CRACK
		Kind.THORNS:
			return HeightMap.Blocker.THORNS
		Kind.VINES:
			return HeightMap.Blocker.VINES
		Kind.PLATE, Kind.LEVER:
			return HeightMap.Blocker.BARS
		Kind.BRITTLE:
			return HeightMap.Blocker.BRITTLE
	return HeightMap.Blocker.NONE

## まだ開いていない形にする（CRYSTAL は地図のままの低さ）。
func close(map: HeightMap) -> void:
	for c in cells:
		if kind == Kind.TARGET:
			map.set_water(c, true)
		elif kind != Kind.CRYSTAL:
			map.set_blocker(c, blocker(kind))

## 開いた形にする（岩・茨・つた・鉄格子・もろい壁はなくなり、橋は渡れ、足場はせり上がる）。
func open(map: HeightMap) -> void:
	for i in cells.size():
		var c := cells[i]
		if kind == Kind.TARGET:
			map.set_water(c, false)
		elif kind == Kind.CRYSTAL:
			if i < heights.size():
				map.set_height(c, heights[i])
		else:
			map.set_blocker(c, HeightMap.Blocker.NONE)

func _touches(p: Vector2, extra: float) -> bool:
	for c in trigger:
		var lo := Vector2(c) * HeightMap.CELL_PX
		var nearest := p.clamp(lo, lo + Vector2.ONE * HeightMap.CELL_PX)
		if p.distance_to(nearest) <= extra:
			return true
	return false

## 鉄球が land_pos に、fall_levels 段落ちて着いた。ひびの岩は上から落とすと砕け、押し板は乗せるだけで沈む。
func by_ball(land_pos: Vector2, fall_levels: int) -> bool:
	if kind == Kind.PLATE:
		return _touches(land_pos, PLATE_REACH)
	return kind == Kind.CRACK and fall_levels >= 1 and _touches(land_pos, IronBall.HIT_RADIUS)

## レバーのとなり（斜めも）の cell に立っている。高さの差は1段まで。
func by_hand(cell: Vector2i, map: HeightMap) -> bool:
	if kind != Kind.LEVER:
		return false
	for t in trigger:
		var d := (cell - t).abs()
		if maxi(d.x, d.y) == 1 and absi(map.get_height(cell) - map.get_height(t)) <= 1:
			return true
	return false

## 魔法（弾・炎・雷）が point のまわり radius に当たった。
func by_magic(point: Vector2, radius: float) -> bool:
	return kind == Kind.CRYSTAL and _touches(point, radius + FIRE_REACH)

## 爆弾が point のまわり radius で弾けた。
func by_bomb(point: Vector2, radius: float) -> bool:
	return kind == Kind.BRITTLE and _touches(point, radius)

## 矢が land_pos に落ちた。
func by_arrow(land_pos: Vector2) -> bool:
	return kind == Kind.TARGET and _touches(land_pos, IronBall.HIT_RADIUS)

## 炎の魔法が point のまわり radius に当たった。
func by_fire(point: Vector2, radius: float) -> bool:
	return kind == Kind.THORNS and _touches(point, radius + FIRE_REACH)

## pos（高さ h）から facing へ剣を振った。下から上へは届かない。
func by_sword(pos: Vector2, h: int, facing: Vector2, map: HeightMap, thrust := false) -> bool:
	if kind != Kind.VINES:
		return false
	for c in trigger:
		if Sword.hits(pos, h, facing, HeightMap.cell_center(c), map.get_height(c), thrust):
			return true
	return false
