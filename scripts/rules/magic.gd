class_name Magic
extends RefCounted
## 魔法（2026-11-24 決定。エアガンの代わり）。手に持つ杖（Equipment の STAFF_*）の種類とランクで使える魔法が決まる。
## 杖のランク1は魔法1つ、2は2つ、3以上は3つ。無の杖はランク1だけで、無の弾の1つ。
## ステータスの「魔法」で同時に使える数（spell_slots、1〜3）が決まり、杖の魔法のうち前から順にその数だけ使える。
## 数値（マナ・威力・広さ）は【提案】の仮の値。

enum Spell { NULL_BOLT, FIREBALL, FIRE_PILLAR, FIRE_RAIN }

const NAMES := {
	Spell.NULL_BOLT: "無の弾",
	Spell.FIREBALL: "火の玉",
	Spell.FIRE_PILLAR: "火柱",
	Spell.FIRE_RAIN: "炎の雨",
}
## 使うのに要るマナ
const COST := {
	Spell.NULL_BOLT: 5,
	Spell.FIREBALL: 8,
	Spell.FIRE_PILLAR: 12,
	Spell.FIRE_RAIN: 20,
}
## 威力の倍率（Damage.magic）
const POWER := {
	Spell.NULL_BOLT: 0.6,
	Spell.FIREBALL: 0.8,
	Spell.FIRE_PILLAR: 1.2,
	Spell.FIRE_RAIN: 0.7,
}
## 杖の種類ごとの魔法（覚える順）
const STAFF_SPELLS := {
	Equipment.Slot.STAFF_NONE: [Spell.NULL_BOLT],
	Equipment.Slot.STAFF_FIRE: [Spell.FIREBALL, Spell.FIRE_PILLAR, Spell.FIRE_RAIN],
}

const INTERVAL := 0.35  ## 次の魔法を使えるまで（秒）
## 火の玉：当たった所で弾け、まわりも焼く。落ちた所が少しの間燃える
const FIREBALL_RADIUS := 14.0
const BURN_SECONDS := 3.0
const FIRE_PATCH_SECONDS := 2.5
## 火柱：狙った点（REACH まで）の、全部の高さに当たる
const PILLAR_REACH := 64.0
const PILLAR_RADIUS := 10.0
## 炎の雨：狙った点（REACH まで）のまわりに降る。自分より高い所には降らない。高い所から使うほど広い
const RAIN_REACH := 96.0
const RAIN_BASE_RADIUS := 16.0
const RAIN_RADIUS_PER_LEVEL := 8.0

var cooldown := 0.0
var _index := 0

## 杖（slot）のランク rank で使える魔法。
static func staff_spells(slot: Equipment.Slot, rank: int) -> Array:
	var all: Array = STAFF_SPELLS.get(slot, [])
	return all.slice(0, clampi(rank, 0, mini(3, all.size())))

## ステータスの魔法の数（spell_slots）も考えて、今使える魔法。
static func usable(slot: Equipment.Slot, rank: int, spell_slots: int) -> Array:
	return staff_spells(slot, rank).slice(0, spell_slots)

## 炎の雨の広さ。caster_h は使う人の段、ground_h は降らせる所の段。
static func rain_radius(caster_h: int, ground_h: int) -> float:
	return RAIN_BASE_RADIUS + maxi(0, caster_h - ground_h) * RAIN_RADIUS_PER_LEVEL

func update(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)

## 使えればマナを払って true。
func try_cast(spell: Spell, mana: Mana) -> bool:
	if cooldown > 0.0 or not mana.try_spend(COST[spell]):
		return false
	cooldown = INTERVAL
	return true

## 選んでいる魔法（list は usable の結果）。list が空なら -1。
func current(list: Array) -> int:
	if list.is_empty():
		return -1
	_index = clampi(_index, 0, list.size() - 1)
	return list[_index]

## ホイールで選ぶ魔法を替える（端は回り込む）。
func cycle(d: int, list: Array) -> void:
	if list.is_empty():
		return
	_index = posmod(clampi(_index, 0, list.size() - 1) + d, list.size())
