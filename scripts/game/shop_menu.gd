class_name ShopMenu
extends CanvasLayer
## お店と鍛冶屋の画面（2026-11-25 の設計 3章）。商人のそばで F を押すと開く。開いている間も世界は動く。
## 品物の名前・ランク・特色・値段（鍛冶屋は素材とお金）が並び、クリックで買う・作る。F・Esc・Tab で閉じる。

signal bought(id: String)

const PANEL_POS := Vector2(40, 10)
const PANEL_SIZE := Vector2(240, 160)

var run: RunState
var shop_id := ""
var _panel: ColorRect
var _title: Label
var _money: Label
var _box: VBoxContainer
var _info: Label
var _info_time := 0.0
## カーソルを合わせた品物の説明
var tip: ItemTip

func setup(r: RunState) -> void:
	run = r
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	_panel.color = Color(0.07, 0.06, 0.05, 0.96)
	_panel.position = PANEL_POS
	_panel.size = PANEL_SIZE
	add_child(_panel)
	_title = _label(_panel, "", Vector2(6, 4))
	_money = _label(_panel, "", Vector2(150, 4))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(4, 20)
	scroll.size = Vector2(PANEL_SIZE.x - 8, PANEL_SIZE.y - 38)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 1)
	scroll.add_child(_box)
	_info = _label(_panel, "", Vector2(6, PANEL_SIZE.y - 15))
	tip = ItemTip.new()
	tip.stats = run.stats
	add_child(tip)
	_panel.hide()

func is_open() -> bool:
	return _panel.visible

func open(id: String) -> void:
	shop_id = id
	refresh()
	_panel.show()

func close() -> void:
	tip.hide_tip()
	_panel.hide()

## 並んでいる行（テスト用）：[品物の id, 説明, 買える・作れるか]
func rows() -> Array:
	var out := []
	if shop_id == "smith":
		for i in Recipes.LIST.size():
			var r: Array = Recipes.LIST[i]
			out.append([r[0], "%s　%s" % [_item_text(r[0], r[1]), Recipes.cost_text(i)], Recipes.can_make(run.inventory, i)])
	else:
		for i in Shop.STOCK[shop_id].size():
			var row: Array = Shop.STOCK[shop_id][i]
			out.append([row[0], "%s　%dG" % [_item_text(row[0], row[2]), row[1]], Shop.can_buy(run.inventory, shop_id, i)])
	return out

## i 番目の行を買う（鍛冶屋なら作る）。
func choose(i: int) -> bool:
	var ok := false
	var id := ""
	if shop_id == "smith":
		id = Recipes.LIST[i][0]
		ok = Recipes.make(run.inventory, i)
	else:
		id = Shop.STOCK[shop_id][i][0]
		ok = Shop.buy(run.inventory, shop_id, i)
	if ok:
		_say("%sを%s" % [ItemCatalog.name_of(id), "作った" if shop_id == "smith" else "買った"])
		bought.emit(id)
	else:
		_say("持っているか、足りない")
	refresh()
	return ok

func _item_text(id: String, n: int) -> String:
	var text := ItemCatalog.label(id)
	if n > 1:
		text += " ×%d" % n
	if ItemCatalog.exists(id):
		if run.inventory.equipment.has(id):
			text += "（持っている）"
		if ItemCatalog.required_level(id) > run.stats.level:
			text += "（Lv%dから）" % ItemCatalog.required_level(id)
		var t := ItemCatalog.trait_of(id)
		if ItemCatalog.slot(id) == Equipment.Slot.STAFF:
			var names: Array[String] = []
			for sp in ItemCatalog.spells(id):
				names.append(Magic.NAMES[sp])
			t = "・".join(names)
		if t != "":
			text += "\n　" + t
	elif ItemCatalog.is_tool_item(id):
		text += "\n　" + ItemCatalog.trait_of(id)
	return text

func refresh() -> void:
	_title.text = Shop.NAMES.get(shop_id, "お店") + ("：素材とお金で作る" if shop_id == "smith" else "")
	_money.text = "お金 %d" % run.inventory.money
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var rs := rows()
	for i in rs.size():
		var idx := i
		var id: String = rs[i][0]
		var b := _button(_box, rs[i][1], func(): choose(idx))
		b.icon = ItemIcons.texture(id)
		b.modulate = Color.WHITE if rs[i][2] else Color(1, 1, 1, 0.45)
		b.mouse_entered.connect(func(): tip.show_item(id, 1, Vector2(PANEL_POS.x + PANEL_SIZE.x, b.global_position.y)))
		b.mouse_exited.connect(tip.hide_tip)

func _say(text: String) -> void:
	_info.text = text
	_info_time = 2.0

func _process(delta: float) -> void:
	_info_time = maxf(0.0, _info_time - delta)
	if _info_time <= 0.0 and _info != null:
		_info.text = "クリック：%s　F・Esc：閉じる" % ("作る" if shop_id == "smith" else "買う")

func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_F, KEY_ESCAPE, KEY_TAB]:
		get_viewport().set_input_as_handled()
		close()

func _label(parent: Node, text: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiText.style(l)
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiText.style_button(b)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b
