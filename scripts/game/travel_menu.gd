class_name TravelMenu
extends CanvasLayer
## たき火から移動する画面（2026-11-26 の4回目の直し）。たき火のそばで F を押すと開く。
## 一度休んだことのあるたき火が並び、クリックか数字のキーでそこへ移る。F・Esc・Tab で閉じる。

signal chosen(area_id: String)

const PANEL_POS := Vector2(70, 22)
const PANEL_SIZE := Vector2(180, 136)
const ROW_W := PANEL_SIZE.x - 20.0

var run: RunState
var world: WorldMap
var here := ""
var _panel: ColorRect
var _box: VBoxContainer
var _info: Label

func setup(r: RunState, w: WorldMap) -> void:
	run = r
	world = w
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	_panel.color = Color(0.07, 0.06, 0.05, 1.0)
	_panel.position = PANEL_POS
	_panel.size = PANEL_SIZE
	add_child(_panel)
	_label(_panel, "たき火から移動する", Vector2(6, 4))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(4, 20)
	scroll.size = Vector2(PANEL_SIZE.x - 8, PANEL_SIZE.y - 38)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 1)
	scroll.add_child(_box)
	_info = _label(_panel, "クリック・数字：移る　F・Esc：閉じる", Vector2(6, PANEL_SIZE.y - 15))
	_panel.hide()

func is_open() -> bool:
	return _panel.visible

func open(current_area: String) -> void:
	here = current_area
	refresh()
	_panel.show()
	Sfx.play("ui_open")

func close() -> void:
	if is_open():
		Sfx.play("ui_close")
	_panel.hide()

## 並ぶたき火（テスト用）：[エリアの id, 文字]
func rows() -> Array:
	var out := []
	var areas := run.bonfire_areas()
	for i in areas.size():
		var id: String = areas[i]
		var a := world.area(id)
		var name := a.title if a.region == "はじまりの地" else "%s　%s" % [a.region, a.title]
		if id == here:
			name += "（ここ）"
		out.append([id, "%d　%s" % [i + 1, name]])
	return out

func choose(i: int) -> void:
	var rs := rows()
	if i < 0 or i >= rs.size():
		return
	var id: String = rs[i][0]
	close()
	if id != here:
		chosen.emit(id)

func refresh() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var rs := rows()
	for i in rs.size():
		var idx := i
		var b := _button(_box, rs[i][1], func(): choose(idx))
		if rs[i][0] == here:
			b.modulate = Color(0.6, 0.6, 0.65)
	if rs.size() <= 1:
		_label(_box, "ほかのたき火で休むと、\nここから移れるようになる", Vector2.ZERO)

func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_F, KEY_ESCAPE, KEY_TAB]:
			get_viewport().set_input_as_handled()
			close()
		elif event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_9:
			get_viewport().set_input_as_handled()
			choose(event.physical_keycode - KEY_1)

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
	b.custom_minimum_size.x = ROW_W
	UiText.style_button(b)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b
