class_name Equipment
extends RefCounted
## 武器と防具の持ち物と装備。品物（ItemCatalog の id）で持ち、種類（Slot）ごとに1つ装備する。
## ランク1が最低ランク、5が最高（2026-11-25 に10から5へ）。死ぬとランク1以外は墓石に入る（design.md 10章）。
## 装備する品物は死んでも好みとして残るので、墓石から取り返すと設定し直さなくても元に戻る。
## 最初から持っているのは鉄球（ランク1）だけ（2026-11-25）。品物の特色（ItemCatalog の traits）は trait_of・armor_bonus で読む。

enum Slot { BALL, SWORD, BOW, STAFF, ARMOR }

const NAMES := {
	Slot.BALL: "鉄球",
	Slot.SWORD: "剣",
	Slot.BOW: "弓",
	Slot.STAFF: "杖",
	Slot.ARMOR: "防具",
}
const WEAPONS := [Slot.BALL, Slot.SWORD, Slot.BOW, Slot.STAFF]
## 防具は頭・体・足に分けず、1つの枠だけ（2026-11-24 まさのりさんの指示）
const ARMOR := [Slot.ARMOR]
const MIN_RANK := 1
const MAX_RANK := 5
## ランクが1上がるごとに足されるつよさ【提案】。2026-11-25 夜につよさの基本を10にしたので2から3に（ランク5で＋12）
const ATTACK_PER_RANK := 3
## 防具のランク1つにつき足される最大いのち【提案】（守りの値は未定。design.md 16章）
const HP_PER_ARMOR_RANK := 4

var _owned: Array[String] = []
var _equipped := {}  # Slot → id（好み）

func _init() -> void:
	gain("ball_1")

## 武器のランクで足されるつよさ。持っていない（0）とランク1は0。
static func rank_attack(rank: int) -> int:
	return maxi(0, rank - 1) * ATTACK_PER_RANK

## 品物を手に入れる。知らない品物と、もう持っている品物は false。その種類で初めてのものは、すぐ装備する。
func gain(id: String) -> bool:
	if not ItemCatalog.exists(id) or _owned.has(id):
		return false
	_owned.append(id)
	var s := ItemCatalog.slot(id)
	if not _equipped.has(s):
		_equipped[s] = id
	return true

func has(id: String) -> bool:
	return _owned.has(id)

## その種類の持っている品物（ランクの低い順）。
func items(slot: Slot) -> Array:
	var out: Array = []
	for id in _owned:
		if ItemCatalog.slot(id) == slot:
			out.append(id)
	out.sort_custom(func(a, b): return ItemCatalog.rank(a) < ItemCatalog.rank(b) \
			or (ItemCatalog.rank(a) == ItemCatalog.rank(b) and ItemCatalog.order(a) < ItemCatalog.order(b)))
	return out

func equip(id: String) -> bool:
	if not has(id):
		return false
	_equipped[ItemCatalog.slot(id)] = id
	return true

## 選んでいる品物（好み）。持っているかは問わない。
func chosen(slot: Slot) -> String:
	return _equipped.get(slot, "")

## 実際に使う品物。選んだものが手元になければ（墓石の中など）、持っている一番低いランクのもの。何もなければ空。
func current(slot: Slot) -> String:
	var c := chosen(slot)
	if has(c):
		return c
	var list := items(slot)
	return list[0] if not list.is_empty() else ""

## 実際に使う品物のランク。何もなければ0。
func effective(slot: Slot) -> int:
	return ItemCatalog.rank(current(slot))

## 装備している防具で足される最大いのち（ランクの分と、特色の hp）。
func armor_hp() -> int:
	var total := 0
	for slot in ARMOR:
		total += effective(slot) * HP_PER_ARMOR_RANK + int(ItemCatalog.trait_value(current(slot), "hp", 0))
	return total

## その枠で実際に使う品物の特色の値（なければ dflt）。
func trait_of(slot: Slot, key: String, dflt = 0):
	return ItemCatalog.trait_value(current(slot), key, dflt)

## 防具の特色の値（守り・足・マナ・いのちの回復）。
func armor_bonus(key: String) -> float:
	var total := 0.0
	for slot in ARMOR:
		total += float(ItemCatalog.trait_value(current(slot), key, 0))
	return total

## 死んだとき：ランク1以外を取り出して返す（墓石に入れる分。id の配列）。
func take_for_grave() -> Array:
	var taken: Array = []
	for id in _owned.duplicate():
		if ItemCatalog.rank(id) > MIN_RANK:
			taken.append(id)
			_owned.erase(id)
	return taken

## 墓石から取り返したものを戻す。
func restore(taken: Array) -> void:
	for id in taken:
		var s := ItemCatalog.slot(id)
		var c := chosen(s)
		gain(id)
		if c != "" and has(c):
			_equipped[s] = c  # gain で好みが変わらないように

## セーブ（2026-11-26 独自の開発1）。
func to_dict() -> Dictionary:
	var eq := {}
	for s in _equipped:
		eq[str(int(s))] = _equipped[s]
	return {"owned": _owned.duplicate(), "equipped": eq}

## ロード：中身だけを入れ替える。知らない品物（版が変わって消えたもの）は捨てる。
func load_dict(d: Dictionary) -> void:
	_owned.clear()
	_equipped = {}
	for id in d.get("owned", []):
		if ItemCatalog.exists(str(id)) and not _owned.has(str(id)):
			_owned.append(str(id))
	var eq: Dictionary = d.get("equipped", {})
	for k in eq:
		if ItemCatalog.exists(str(eq[k])):
			_equipped[int(k)] = str(eq[k])
	if _owned.is_empty():
		gain("ball_1")
