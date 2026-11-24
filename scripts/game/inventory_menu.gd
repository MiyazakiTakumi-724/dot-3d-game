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
	_title = _label("持ち物　（Tab / Esc：閉じる）", Vector2(8, 6))
	_normal = _button(Vector2(8, 24), false)
	_strong = _button(Vector2(8, 46), true)
	_items = _label("", Vector2(8, 74))
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
	# ● が今使う鉄球
	_normal.text = ("●" if not inv.equipped_strong else "○") + " 鉄球（ふつう）"
	if inv.has_strong_ball:
		_strong.text = ("●" if inv.equipped_strong else "○") + " 鉄球（強い）"
	elif inv.equipped_strong:
		_strong.text = "● 鉄球（強い）：墓石の中にある"
	else:
		_strong.text = "○ 鉄球（強い）：まだ持っていない"
	_strong.disabled = not inv.has_strong_ball
	_items.text = "回復 ×%d　　素材 ×%d\nお金 %d　　Lv%d　ポイント %d\n\n選んだ鉄球は、手に持っているときに使う。" % [inv.heals, inv.materials, inv.money, run.stats.level, run.stats.points]

func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_TAB or event.physical_keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		close_requested.emit()

func _label(text: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	UiText.style(l)
	_panel.add_child(l)
	return l

func _button(pos: Vector2, strong: bool) -> Button:
	var b := Button.new()
	b.position = pos
	b.focus_mode = Control.FOCUS_NONE
	UiText.style(b)
	b.pressed.connect(func(): choose_ball(strong))
	_panel.add_child(b)
	return b
