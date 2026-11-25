class_name Inventory
extends RefCounted
## プレイヤーの持ち物。所持数に制限はない。武器と防具は equipment（最初は鉄球だけ）。
## 素材・道具・矢は、品物の id（ItemCatalog）ごとの数で持つ（2026-11-25）。

var money: int = 0
## 素材・道具・矢の数（id → 数）
var counts := {}
## 武器と防具
var equipment := Equipment.new()
## 撃つ矢の種類（インベントリで選ぶ）
var arrow_kind: Arrow.Kind = Arrow.Kind.NORMAL
## 5番で手に持つ道具（ItemCatalog.TOOLS の id）
var tool_id := "potion"

func count(id: String) -> int:
	return counts.get(id, 0)

## 品物を足す。装備は1つ持つ（もう持っていれば false）、お金はお金に、ほかは数を足す。知らない id は false。
func add(id: String, n := 1) -> bool:
	if id == ItemCatalog.MONEY:
		money += n
		return true
	if ItemCatalog.exists(id):
		return equipment.gain(id)
	if not ItemCatalog.is_counted(id) or n <= 0:
		return false
	counts[id] = count(id) + n
	return true

## n 個を使う（足りなければ使わずに false）。
func take(id: String, n := 1) -> bool:
	if count(id) < n:
		return false
	counts[id] = count(id) - n
	if counts[id] == 0:
		counts.erase(id)
	return true

## 持っている素材・道具・矢の id（一覧の順）。
func ids(filter: Callable) -> Array:
	var out: Array = []
	for id in counts:
		if filter.call(id) and count(id) > 0:
			out.append(id)
	out.sort_custom(func(a, b): return ItemCatalog.order(a) < ItemCatalog.order(b))
	return out

func materials() -> Array:
	return ids(ItemCatalog.is_material)

func tools() -> Array:
	return ids(ItemCatalog.is_tool)

## 手に持つ道具。選んだものがなくなっていれば、持っている道具の最初のもの。何もなければ空。
func current_tool() -> String:
	if count(tool_id) > 0:
		return tool_id
	var list := tools()
	return list[0] if not list.is_empty() else ""

## 手に持つ道具を替える（ホイール）。
func cycle_tool(d: int) -> void:
	var list := tools()
	if list.is_empty():
		return
	var i := list.find(current_tool())
	tool_id = list[posmod(i + d, list.size())]

func arrow_count(k: Arrow.Kind) -> int:
	return count(Arrow.ID[k])

func add_arrows(k: Arrow.Kind, n: int) -> void:
	add(Arrow.ID[k], n)

## 撃つ矢を1本取り出して種類を返す。選んだ種類が使えて残っていればそれ、なければ普通の矢。どちらもなければ -1。
func take_arrow(bow_skills: int) -> int:
	var k := arrow_kind
	if not Arrow.usable(k, bow_skills) or arrow_count(k) <= 0:
		k = Arrow.Kind.NORMAL
	if not take(Arrow.ID[k]):
		return -1
	return k
