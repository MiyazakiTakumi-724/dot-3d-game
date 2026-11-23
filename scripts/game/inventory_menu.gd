class_name InventoryMenu
extends CanvasLayer
## インベントリ画面。Tab で開閉し、開いている間はゲームが止まる（このノードだけは止まらない）。
## 使う鉄球（普通・強い）をここで前もって決める。

signal close_requested

var run: RunState
var _panel: ColorRect
var _title: Label
var _items: Label
var _normal: Button
var _strong: Button

func setup(r: RunState) -> void:
	run = r
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	_panel.color = Color(0.05, 0.07, 0.1, 0.85)
	_panel.position = Vector2(40, 24)
	_panel.size = Vector2(240, 132)
	add_child(_panel)
	_title = _label("INVENTORY   (TAB: close)", Vector2(8, 6))
	_normal = _button(Vector2(8, 24), false)
	_strong = _button(Vector2(8, 44), true)
	_items = _label("", Vector2(8, 72))
	_panel.hide()

func is_open() -> bool:
	return _panel.visible

func open() -> void:
	refresh()
	_panel.show()

func close() -> void:
	_panel.hide()

## 使う鉄球を決める。強い鉄球は持っているときだけ選べる。
func choose_ball(strong: bool) -> bool:
	if strong and not run.inventory.has_strong_ball:
		return false
	run.inventory.equipped_strong = strong
	refresh()
	return true

func refresh() -> void:
	var inv := run.inventory
	_normal.text = ("> " if not inv.equipped_strong else "  ") + "IRON BALL (NORMAL)"
	_strong.text = ("> " if inv.equipped_strong else "  ") + ("IRON BALL (STRONG)" if inv.has_strong_ball else "IRON BALL (STRONG)  -- not owned")
	_strong.disabled = not inv.has_strong_ball
	_items.text = "HEAL x%d   MATERIAL x%d\nMONEY %d   EXP %d\n\nThe chosen ball is used when it is in your hand." % [inv.heals, inv.materials, inv.money, inv.exp]

func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		close_requested.emit()

func _label(text: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", 8)
	_panel.add_child(l)
	return l

func _button(pos: Vector2, strong: bool) -> Button:
	var b := Button.new()
	b.position = pos
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 8)
	b.pressed.connect(func(): choose_ball(strong))
	_panel.add_child(b)
	return b
