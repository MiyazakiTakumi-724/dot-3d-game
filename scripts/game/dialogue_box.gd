class_name DialogueBox
extends CanvasLayer
## 話す・読む画面（2026-11-26 の4回目の直し、ストーリー）。画面の下に名前と言葉の枠を出す。
## F・Space・Enter・左クリックで次のページ、Esc で閉じる（はじまりと終わりは全部とばす）。
## full（はじまり・終わり）は、黒い画面の真ん中に言葉を出す。開いている間は field.gd が世界を止める。

signal finished

const PANEL_POS := Vector2(8, 116)
const PANEL_SIZE := Vector2(304, 58)

var pages: Array = []
var index := 0
var full := false
var speaker := ""
var _bg: ColorRect
var _frame: ColorRect
var _panel: ColorRect
var _name: Label
var _text: Label
var _hint: Label
var _center: Label
var _open := false
## 開いた直後の同じ押下で、すぐ次へ進まないように
var _guard := 0.0

func setup() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 1.0)
	_bg.size = Vector2(320, 180)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_center = UiText.label(true)
	_center.position = Vector2(10, 60)
	_center.size = Vector2(300, 60)
	_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_center)
	_frame = ColorRect.new()
	_frame.color = Color("8a7650")
	_frame.position = PANEL_POS - Vector2.ONE
	_frame.size = PANEL_SIZE + Vector2(2, 2)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_panel = ColorRect.new()
	_panel.color = Color(0.07, 0.06, 0.05, 0.95)
	_panel.position = PANEL_POS
	_panel.size = PANEL_SIZE
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_name = UiText.label()
	_name.position = PANEL_POS + Vector2(6, 2)
	_name.add_theme_color_override("font_color", Color("f0d080"))
	add_child(_name)
	_text = UiText.label()
	_text.position = PANEL_POS + Vector2(6, 15)
	_text.size = Vector2(PANEL_SIZE.x - 12, 40)
	add_child(_text)
	_hint = UiText.label()
	_hint.size = Vector2(120, 12)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	add_child(_hint)
	_set_visible(false)

func is_open() -> bool:
	return _open

## 言葉を出す。full なら黒い画面の真ん中に。
func open(name_: String, pages_: Array, full_screen := false) -> void:
	if pages_.is_empty():
		return
	speaker = name_
	pages = pages_.duplicate()
	index = 0
	full = full_screen
	_open = true
	_guard = 0.15
	_set_visible(true)
	_show_page()
	Sfx.play("ui_open", null, -6.0)

func advance() -> void:
	if not _open:
		return
	index += 1
	if index >= pages.size():
		close()
	else:
		Sfx.play("ui_close", null, -12.0)
		_show_page()

func close() -> void:
	if not _open:
		return
	_open = false
	_set_visible(false)
	finished.emit()

func page_text() -> String:
	return pages[index] if _open and index < pages.size() else ""

func _show_page() -> void:
	var t: String = pages[index]
	var last := index == pages.size() - 1
	if full:
		_center.text = t
		_hint.position = Vector2(196, 166)
		_hint.text = ("F：つぎへ" if not last else "F：とじる") + "　Esc：とばす"
	else:
		_name.text = speaker
		_text.text = t
		_hint.position = PANEL_POS + Vector2(PANEL_SIZE.x - 126, PANEL_SIZE.y - 13)
		_hint.text = "F：つぎへ" if not last else "F：とじる"

func _set_visible(v: bool) -> void:
	_bg.visible = v and full
	_center.visible = v and full
	for c in [_frame, _panel, _name, _text]:
		c.visible = v and not full
	_hint.visible = v

func _process(delta: float) -> void:
	_guard = maxf(0.0, _guard - delta)

func _input(event: InputEvent) -> void:
	if not _open:
		return
	var next := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close()
			return
		next = event.physical_keycode in [KEY_F, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		next = true
	if next:
		get_viewport().set_input_as_handled()
		if _guard <= 0.0:
			advance()
