class_name Gimmick
extends RefCounted
## 武器で開く仕掛け（docs/superpowers/specs/2026-11-25-world-map-design.md 5章）。
## - CRACK（ひびの入った岩）：上から鉄球を落とすと砕ける（1段以上の高さから）。
## - TARGET（的と上がった橋）：弓で的（trigger）を撃つと、橋（cells の水のマス）が下りる。
## - THORNS（茨）：炎の魔法で燃える。
## - VINES（つた）：剣で斬れる。
## 一度開けた仕掛けは RunState が覚えていて、死んでも開いたまま。

enum Kind { CRACK, TARGET, THORNS, VINES }

const FIRE_REACH := 8.0  ## 炎の当たる所から、マスのふちまでこの距離なら燃える（炎の広さに足す）

var id := ""
var kind: Kind = Kind.CRACK
## ふさぐマス（TARGET では橋になる水のマス）
var cells: Array[Vector2i] = []
## 武器を当てるマス（TARGET では的。ほかは cells と同じ）
var trigger: Array[Vector2i] = []

static func make(gid: String, k: Kind, c: Array, t: Array) -> Gimmick:
	var g := Gimmick.new()
	g.id = gid
	g.kind = k
	g.cells.assign(c)
	g.trigger.assign(t)
	return g

## エリアのデータ [id, 種類の名前, ふさぐマス, 当てるマス] から作る。
static func from_data(d: Array) -> Gimmick:
	return make(d[0], Kind[d[1]], d[2], d[3])

static func blocker(k: Kind) -> HeightMap.Blocker:
	match k:
		Kind.CRACK:
			return HeightMap.Blocker.CRACK
		Kind.THORNS:
			return HeightMap.Blocker.THORNS
		Kind.VINES:
			return HeightMap.Blocker.VINES
	return HeightMap.Blocker.NONE

## まだ開いていない形にする。
func close(map: HeightMap) -> void:
	for c in cells:
		if kind == Kind.TARGET:
			map.set_water(c, true)
		else:
			map.set_blocker(c, blocker(kind))

## 開いた形にする（岩・茨・つたはなくなり、橋は渡れる）。
func open(map: HeightMap) -> void:
	for c in cells:
		if kind == Kind.TARGET:
			map.set_water(c, false)
		else:
			map.set_blocker(c, HeightMap.Blocker.NONE)

func _touches(p: Vector2, extra: float) -> bool:
	for c in trigger:
		var lo := Vector2(c) * HeightMap.CELL_PX
		var nearest := p.clamp(lo, lo + Vector2.ONE * HeightMap.CELL_PX)
		if p.distance_to(nearest) <= extra:
			return true
	return false

## 鉄球が land_pos に、fall_levels 段落ちて着いた。
func by_ball(land_pos: Vector2, fall_levels: int) -> bool:
	return kind == Kind.CRACK and fall_levels >= 1 and _touches(land_pos, IronBall.HIT_RADIUS)

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
