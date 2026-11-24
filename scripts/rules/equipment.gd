class_name Equipment
extends RefCounted
## 武器と防具の持ち物と装備。種類（Slot）ごとに、持っているランクと、装備するランクを覚える。
## ランク1が最低ランク。死ぬとランク1以外は墓石に入る（design.md 10章）。
## 装備するランクは死んでも好みとして残るので、墓石から取り返すと設定し直さなくても元に戻る。
## 鉄球のランク1は最初から持っている。

enum Slot { BALL, SWORD, BOW, GUN, HEAD, BODY, LEGS }

const NAMES := {
	Slot.BALL: "鉄球",
	Slot.SWORD: "剣",
	Slot.BOW: "弓",
	Slot.GUN: "エアガン",
	Slot.HEAD: "頭",
	Slot.BODY: "体",
	Slot.LEGS: "足",
}
const WEAPONS := [Slot.BALL, Slot.SWORD, Slot.BOW, Slot.GUN]
const ARMOR := [Slot.HEAD, Slot.BODY, Slot.LEGS]
const MIN_RANK := 1
## ランクが1上がるごとに足される攻撃力【提案】（ランク2の鉄球＝前の「強い鉄球」で＋2）
const ATTACK_PER_RANK := 2

## 防具のランク1つにつき足される最大体力【提案】（部位と守りの値は未定。design.md 16章）
const HP_PER_ARMOR_RANK := 2

var _owned := {}  # Slot → Array[int]（小さい順）
var _equipped := {}  # Slot → int

func _init() -> void:
	gain(Slot.BALL, MIN_RANK)

## 武器のランクで足される攻撃力。持っていない（0）とランク1は0。
static func rank_attack(rank: int) -> int:
	return maxi(0, rank - 1) * ATTACK_PER_RANK

func gain(slot: Slot, rank: int) -> void:
	var r: Array = _owned.get(slot, [])
	if r.has(rank):
		return
	r.append(rank)
	r.sort()
	_owned[slot] = r
	if not _equipped.has(slot):
		_equipped[slot] = rank  # その種類で初めて手に入れたものは、すぐ装備する

func has(slot: Slot, rank: int) -> bool:
	return _owned.get(slot, []).has(rank)

func ranks(slot: Slot) -> Array:
	return _owned.get(slot, []).duplicate()

func equip(slot: Slot, rank: int) -> bool:
	if not has(slot, rank):
		return false
	_equipped[slot] = rank
	return true

## 選んでいるランク（好み）。持っているかは問わない。
func chosen(slot: Slot) -> int:
	return _equipped.get(slot, 0)

## 実際に使うランク。選んだものが手元になければ（墓石の中など）、持っている一番低いランク。何もなければ0。
func effective(slot: Slot) -> int:
	var r: Array = _owned.get(slot, [])
	if r.is_empty():
		return 0
	var c := chosen(slot)
	return c if r.has(c) else r[0]

## 装備している防具で足される最大体力。
func armor_hp() -> int:
	var total := 0
	for slot in ARMOR:
		total += effective(slot) * HP_PER_ARMOR_RANK
	return total

## 死んだとき：ランク1以外を取り出して返す（墓石に入れる分）。Slot → Array[int]。
func take_for_grave() -> Dictionary:
	var taken := {}
	for slot in _owned.keys():
		var keep: Array = []
		var out: Array = []
		for rank in _owned[slot]:
			if rank == MIN_RANK:
				keep.append(rank)
			else:
				out.append(rank)
		if not out.is_empty():
			taken[slot] = out
		if keep.is_empty():
			_owned.erase(slot)
		else:
			_owned[slot] = keep
	return taken

## 墓石から取り返したものを戻す。
func restore(taken: Dictionary) -> void:
	for slot in taken.keys():
		for rank in taken[slot]:
			var c := chosen(slot)
			gain(slot, rank)
			if c != 0:
				_equipped[slot] = c  # gain で好みが変わらないように
