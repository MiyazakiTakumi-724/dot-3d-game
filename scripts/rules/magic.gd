class_name Magic
extends RefCounted
## 魔法（2026-11-24 決定。エアガンの代わり）。手に持つ杖の品物（ItemCatalog の spells）で使える魔法が決まる。
## ステータスの「魔法」で同時に使える数（spell_slots、1〜3）が決まり、杖の魔法のうち前から順にその数だけ使える。
## 数値（マナ・威力・広さ）は【提案】の仮の値。

## 2026-11-25：氷のつぶて（当てた敵を遅くする）・雷（狙った点に落ちる）・癒し（自分の いのちが戻る）を足した
enum Spell { NULL_BOLT, FIREBALL, FIRE_PILLAR, FIRE_RAIN, ICE_SHARD, THUNDER, HEAL }

const NAMES := {
	Spell.NULL_BOLT: "無の弾",
	Spell.FIREBALL: "火の玉",
	Spell.FIRE_PILLAR: "火柱",
	Spell.FIRE_RAIN: "炎の雨",
	Spell.ICE_SHARD: "氷のつぶて",
	Spell.THUNDER: "雷",
	Spell.HEAL: "癒し",
}
## 使うのに要るマナ（燃費は悪くして、何発も撃てないようにする。2026-11-24 23:07 の指示）
const COST := {
	Spell.NULL_BOLT: 10,
	Spell.FIREBALL: 15,
	Spell.FIRE_PILLAR: 25,
	Spell.FIRE_RAIN: 35,
	Spell.ICE_SHARD: 12,
	Spell.THUNDER: 30,
	Spell.HEAL: 25,
}
## 魔法ごとの待ち時間（秒）。使ってからこの間は、同じ魔法を使えない（連発させない）
const COOLDOWN := {
	Spell.NULL_BOLT: 1.5,
	Spell.FIREBALL: 3.0,
	Spell.FIRE_PILLAR: 5.0,
	Spell.FIRE_RAIN: 10.0,
	Spell.ICE_SHARD: 2.0,
	Spell.THUNDER: 6.0,
	Spell.HEAL: 8.0,
}
## 威力の倍率（Damage.magic）
const POWER := {
	Spell.NULL_BOLT: 0.6,
	Spell.FIREBALL: 0.8,
	Spell.FIRE_PILLAR: 1.2,
	Spell.FIRE_RAIN: 0.7,
	Spell.ICE_SHARD: 0.7,
	Spell.THUNDER: 1.6,
	Spell.HEAL: 0.0,
}
## 弾として飛ぶ魔法（狙った高さへまっすぐ）
const BOLTS := [Spell.NULL_BOLT, Spell.FIREBALL, Spell.ICE_SHARD]
## 氷のつぶてで遅くなる時間（秒）。遅くなった敵は半分の速さで歩く
const SLOW_SECONDS := 3.0
## 雷：狙った点（REACH まで）に落ちる。自分より高い所の敵には当たらない
const THUNDER_REACH := 80.0
const THUNDER_RADIUS := 10.0
## 癒しで戻る いのち
const HEAL_AMOUNT := 10
const INTERVAL := 0.35  ## どの魔法でも、次を使えるまで（秒）
## 火の玉：当たった所で弾け、まわりも焼く。落ちた所が少しの間燃える
const FIREBALL_RADIUS := 14.0
const BURN_SECONDS := 3.0
const FIRE_PATCH_SECONDS := 2.5
## 火柱：狙った点（REACH まで）に立つ。自分より高い所の敵には当たらない
const PILLAR_REACH := 64.0
const PILLAR_RADIUS := 10.0
## 炎の雨：狙った点（REACH まで）のまわりに降る。自分より高い所には降らない。高い所から使うほど広い
const RAIN_REACH := 96.0
const RAIN_BASE_RADIUS := 16.0
const RAIN_RADIUS_PER_LEVEL := 8.0

var cooldown := 0.0
var _index := 0
var _spell_cd := {}  # Spell → 残りの待ち時間

## 炎の雨の広さ。caster_h は使う人の段、ground_h は降らせる所の段。
static func rain_radius(caster_h: int, ground_h: int) -> float:
	return RAIN_BASE_RADIUS + maxi(0, caster_h - ground_h) * RAIN_RADIUS_PER_LEVEL

func update(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	for k in _spell_cd.keys():
		_spell_cd[k] = maxf(0.0, _spell_cd[k] - delta)

## その魔法をまた使えるまでの秒数。
func remaining(spell: Spell) -> float:
	return _spell_cd.get(spell, 0.0)

## 使えればマナを払って true。
## cost_mult は装備の特色（マナ×0.7 など）。
func try_cast(spell: Spell, mana: Mana, cost_mult := 1.0) -> bool:
	if cooldown > 0.0 or remaining(spell) > 0.0 or not mana.try_spend(cost_of(spell, cost_mult)):
		return false
	cooldown = INTERVAL
	_spell_cd[spell] = COOLDOWN[spell]
	return true

## 特色で変わったあとの、使うのに要るマナ（切り上げ）。
static func cost_of(spell: Spell, cost_mult := 1.0) -> int:
	return ceili(COST[spell] * cost_mult - 0.0001)

## 選んでいる魔法（list は ItemCatalog.usable_spells の結果）。list が空なら -1。
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
