class_name ItemCatalog
extends RefCounted
## 装備の品物の一覧（2026-11-24 決定）。装備は種類（Equipment.Slot）とランクだけでなく、品物ごとに id を持つ。
## 同じ種類・同じランクでも、効果の違う特別な品物を足せるようにするため（例：ランク2の剣が何本もある）。
## ランクは1〜10。杖は品物ごとに使える魔法（spells、覚える順）を持ち、その数はランクで決まる範囲に入れる（spell_range）。
## 今ある品物は試すためのもの。ボスの落とし物やお店ができたら増やす。

const ITEMS := {
	"ball_1": {"slot": Equipment.Slot.BALL, "rank": 1, "name": "鉄球"},
	"ball_2": {"slot": Equipment.Slot.BALL, "rank": 2, "name": "鉄球", "trait": "当たる範囲が広い"},
	"sword_1": {"slot": Equipment.Slot.SWORD, "rank": 1, "name": "剣"},
	"bow_1": {"slot": Equipment.Slot.BOW, "rank": 1, "name": "弓"},
	"staff_none_1": {"slot": Equipment.Slot.STAFF, "rank": 1, "name": "無の杖", "spells": [Magic.Spell.NULL_BOLT]},
	"staff_fire_1": {"slot": Equipment.Slot.STAFF, "rank": 1, "name": "炎の小杖", "spells": [Magic.Spell.FIREBALL]},
	"staff_fire_3": {"slot": Equipment.Slot.STAFF, "rank": 3, "name": "炎の杖", "spells": [Magic.Spell.FIREBALL, Magic.Spell.FIRE_PILLAR]},
	"staff_fire_9": {"slot": Equipment.Slot.STAFF, "rank": 9, "name": "炎の大杖", "spells": [Magic.Spell.FIREBALL, Magic.Spell.FIRE_PILLAR, Magic.Spell.FIRE_RAIN]},
	"armor_1": {"slot": Equipment.Slot.ARMOR, "rank": 1, "name": "防具"},
}

## 一覧（ITEMS）の中の順番。同じランクの品物を並べるときに使う。
static func order(id: String) -> int:
	return ITEMS.keys().find(id)

static func exists(id: String) -> bool:
	return ITEMS.has(id)

static func slot(id: String) -> Equipment.Slot:
	return ITEMS[id]["slot"]

static func rank(id: String) -> int:
	return ITEMS[id]["rank"] if ITEMS.has(id) else 0

static func name_of(id: String) -> String:
	return ITEMS[id]["name"] if ITEMS.has(id) else ""

## 特別な効果の説明（なければ空）。
static func trait_of(id: String) -> String:
	return ITEMS[id].get("trait", "") if ITEMS.has(id) else ""

## 杖の魔法（覚える順）。杖でなければ空。
static func spells(id: String) -> Array:
	return ITEMS[id].get("spells", []) if ITEMS.has(id) else []

## ステータスの魔法の数（spell_slots）までの、杖の魔法。
static func usable_spells(id: String, spell_slots: int) -> Array:
	return spells(id).slice(0, spell_slots)

## 杖のランクごとの魔法の数（最小, 最大）。1は1つ、2〜3は1〜2、4〜6は2、7〜8は2〜3、9〜10は3。
static func spell_range(r: int) -> Vector2i:
	if r <= 1:
		return Vector2i(1, 1)
	if r <= 3:
		return Vector2i(1, 2)
	if r <= 6:
		return Vector2i(2, 2)
	if r <= 8:
		return Vector2i(2, 3)
	return Vector2i(3, 3)

## 画面に出す名前。ランク2以上は★とランクを付ける。
static func label(id: String) -> String:
	if not ITEMS.has(id):
		return ""
	var r := rank(id)
	return name_of(id) if r <= 1 else "%s★%d" % [name_of(id), r]
