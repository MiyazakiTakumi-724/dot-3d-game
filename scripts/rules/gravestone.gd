class_name Gravestone
extends RefCounted
## 死んだ場所に残る墓石。叩いて壊すと中身が手元に戻る。世界に1つだけ。

## 墓石があるエリア
var area_id: String = ""
var cell: Vector2i
var money: int = 0
## 墓石に入った素材・道具・矢（id → 数）
var counts := {}
## 墓石に入った武器と防具（Equipment.take_for_grave の結果。品物の id の配列）
var equipment: Array = []

## セーブ（2026-11-26 独自の開発1）。
func to_dict() -> Dictionary:
	return {"area": area_id, "cell": [cell.x, cell.y], "money": money, "counts": counts.duplicate(), "equipment": equipment.duplicate()}

static func from_dict(d: Dictionary) -> Gravestone:
	var g := Gravestone.new()
	g.area_id = str(d.get("area", ""))
	var c: Array = d.get("cell", [0, 0])
	g.cell = Vector2i(int(c[0]), int(c[1]))
	g.money = int(d.get("money", 0))
	var counts_in: Dictionary = d.get("counts", {})
	for id in counts_in:
		g.counts[str(id)] = int(counts_in[id])
	for id in d.get("equipment", []):
		g.equipment.append(str(id))
	return g
