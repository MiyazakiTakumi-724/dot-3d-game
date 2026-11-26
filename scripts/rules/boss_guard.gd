class_name BossGuard
extends RefCounted
## ボスの構え（崩し、2026-11-26 の4回目の直し）。弓で逃げながら撃ち続けるだけで勝てないようにする【提案】。
## 構えている間は、矢と魔法があまり効かない（GUARD_MULT）。剣・鉄球・爆弾は構えを大きく削り（BREAK_RATE）、
## 削りきると崩れる（STAGGER 秒。ボスは目を回して動かず、どの攻撃も×2 入る。Boss.stunned を使う）。
## 崩れが終わると構えは元に戻る。しばらく（REGEN_DELAY 秒）攻撃されないと、構えは少しずつ戻る。
## ボスにはそれぞれ弱点の武器が1つある（WEAK）。弱点の武器は構えで弱まらず、構えを2倍削る。

## 最大体力に対する構えの量
const RATIO := 0.15
## 崩れている秒
const STAGGER := 3.5
## 攻撃されないと戻りはじめる秒と、1秒に戻る割合
const REGEN_DELAY := 4.0
const REGEN_RATE := 0.2
## 構えている間のダメージの倍率（ない武器は1）
const GUARD_MULT := {"arrow": 0.35, "magic": 0.6}
## 構えを削る割合（ダメージに掛ける）
const BREAK_RATE := {"sword": 1.5, "ball": 1.5, "bomb": 2.0, "magic": 0.5, "arrow": 0.15}
## 弱点の武器が構えを削る倍率
const WEAK_BREAK := 2.0
## ボスの弱点の武器【提案】
const WEAK := {
	"岩転がしの巨人": "ball",
	"草むらの大蛇": "sword",
	"満ち引きする溶岩": "arrow",
	"廃城の主": "magic",
	"岩窟のぬし": "bomb",
	"溶岩洞のぬし": "sword",
	"女王蜂": "arrow",
	"宝箱の王": "bomb",
	"双子": "sword",
	"らせん塔の番人": "ball",
	"ブライト": "magic",
	"闇の王": "magic",
}
## 弱点の名前（画面に出す）
const SOURCE_NAMES := {"sword": "剣", "arrow": "弓", "magic": "魔法", "ball": "鉄球", "bomb": "爆弾"}

var max_value := 1.0
var value := 1.0
var stagger := 0.0
var weak_source := ""
var _since_hit := 0.0

func _init(max_hp := 100, weak := "") -> void:
	max_value = maxf(1.0, max_hp * RATIO)
	value = max_value
	weak_source = weak

func broken() -> bool:
	return stagger > 0.0

## 構えの残り（0〜1）
func ratio() -> float:
	return value / max_value

## ダメージの倍率。崩れている間と弱点の武器は1。
func mult(source: String) -> float:
	if broken() or source == weak_source:
		return 1.0
	return GUARD_MULT.get(source, 1.0)

## 攻撃が当たった（dmg は倍率を掛ける前のダメージ）。いま崩れたら true。
func hit(source: String, dmg: float) -> bool:
	if broken():
		return false
	_since_hit = 0.0
	var rate: float = BREAK_RATE.get(source, 1.0) * (WEAK_BREAK if source == weak_source else 1.0)
	value -= dmg * rate
	if value <= 0.0:
		value = 0.0
		stagger = STAGGER
		return true
	return false

func update(delta: float) -> void:
	if broken():
		stagger -= delta
		if stagger <= 0.0:
			stagger = 0.0
			value = max_value
			_since_hit = 0.0
		return
	_since_hit += delta
	if _since_hit >= REGEN_DELAY:
		value = minf(max_value, value + max_value * REGEN_RATE * delta)
