class_name Arrow
extends RefCounted
## 飛んでいる矢と、矢の種類。山なりに飛ぶので途中の壁には当たらず、落ちた所でだけ当たる。
## 種類：普通の矢（倍率1.0）、毒矢（倍率0.5、当たると5秒間、毎秒1ダメージ）、火矢（倍率0.8、やけど）、鉄の矢（倍率1.5）。
## 普通の矢のほかは、弓の技能「矢の種類」で使える。持ち物では ItemCatalog.ARROWS の id（ID）で数える。

enum Kind { NORMAL, POISON, FIRE, IRON }

const NAMES := {Kind.NORMAL: "矢", Kind.POISON: "毒矢", Kind.FIRE: "火矢", Kind.IRON: "鉄の矢"}
const MULT := {Kind.NORMAL: 1.0, Kind.POISON: 0.5, Kind.FIRE: 0.8, Kind.IRON: 1.5}
const ID := {Kind.NORMAL: "arrow", Kind.POISON: "arrow_poison", Kind.FIRE: "arrow_fire", Kind.IRON: "arrow_iron"}
const KINDS := [Kind.NORMAL, Kind.POISON, Kind.FIRE, Kind.IRON]
const POISON_SECONDS := 5.0
const HIT_RADIUS := 8.0  ## 落ちた点からこの半径の中にいる、同じ高さのものに当たる
const SPEED := 220.0  ## 横に進む速さ（px/秒）
const MIN_TIME := 0.2

var kind: Kind = Kind.NORMAL
## 撃ったときのチャージ率と、撃った高さ（段）。ダメージの計算に使う
var rate := 1.0
var from_h := 0
var from: Vector2
var to: Vector2
var from_px := 0.0
var to_px := 0.0
var duration := 0.0
var t := 0.0

## 普通の矢のほかは、弓の技能を1つ（「矢の種類」）覚えていないと使えない。
static func usable(k: Kind, bow_skills: int) -> bool:
	return k == Kind.NORMAL or bow_skills >= 1

## p0（高さ h0_px）から p1（高さ h1_px）へ飛ばし始める。
func launch(p0: Vector2, h0_px: float, p1: Vector2, h1_px: float) -> void:
	from = p0
	to = p1
	from_px = h0_px
	to_px = h1_px
	duration = maxf(MIN_TIME, p0.distance_to(p1) / SPEED)
	t = 0.0

## 進める。落ちたら true。
func update(delta: float) -> bool:
	t = minf(duration, t + delta)
	return t >= duration

func progress() -> float:
	return t / duration if duration > 0.0 else 1.0

func pos() -> Vector2:
	return from.lerp(to, progress())

## 今の高さ（px）。両端を結んだ線に、山の分（遠いほど高い）を足す。
func height_px() -> float:
	var k := progress()
	var apex := 8.0 + from.distance_to(to) * 0.25
	return lerpf(from_px, to_px, k) + apex * 4.0 * k * (1.0 - k)

## 今の傾き：横に1px進むあいだに上がる高さ（px）。上向きなら正。矢の絵を傾けるのに使う。
func slope() -> float:
	var d := from.distance_to(to)
	if d <= 0.0:
		return 0.0
	var k := progress()
	var apex := 8.0 + d * 0.25
	return (to_px - from_px) / d + apex * 4.0 * (1.0 - 2.0 * k) / d

## 横に進む向き（長さ1）。
func direction() -> Vector2:
	return (to - from).normalized()

## 落ちた点（地面の高さ land_h）が、other_pos に立つ高さ other_h のものに当たるか。
static func hits(land_pos: Vector2, land_h: int, other_pos: Vector2, other_h: int) -> bool:
	return land_h == other_h and land_pos.distance_to(other_pos) < HIT_RADIUS
