class_name PauseMenu
extends CanvasLayer
## 止める画面（2026-11-26 独自の開発1）。遊んでいる間に Esc で開き、世界を止める。
## つづける・設定・タイトルへもどる・ゲームをおわる。もどる・おわるときは、その前にセーブする（field.gd）。

signal resumed
signal to_title
signal quit_game
signal settings_changed

const PANEL_SIZE := Vector2(150, 112)
const BIG_POS := Vector2(8, 6)

var settings: GameSettings
var _panel: ColorRect
var _big: ColorRect
var _settings_panel: SettingsPanel
var _info: Label

func setup(s: GameSettings) -> void:
	settings = s
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.size = Vector2(320, 180)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_panel = ColorRect.new()
	_panel.color = Color(0.05, 0.07, 0.1, 1.0)
	_panel.size = PANEL_SIZE
	_panel.position = (Vector2(320, 180) - PANEL_SIZE) / 2.0
	dim.add_child(_panel)
	var title := UiText.label(true)
	title.text = "ひと休み"
	title.position = Vector2(0, 5)
	title.size = Vector2(PANEL_SIZE.x, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	var items := [
		["つづける", func(): close()],
		["設定・操作", func(): show_settings(true)],
		["セーブしてタイトルへ", func(): to_title.emit()],
		["セーブしてゲームをおわる", func(): quit_game.emit()],
	]
	for i in items.size():
		var b := Button.new()
		UiText.style_button(b)  # 大きさより先にフォント
		b.text = items[i][0]
		b.position = Vector2(12, 24 + i * 19)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(items[i][1])
		b.custom_minimum_size = Vector2(PANEL_SIZE.x - 24, 16)  # size を直接決めると16pxのフォントの大きさのままになる
		_panel.add_child(b)
	_info = UiText.label()
	_info.position = Vector2(0, PANEL_SIZE.y - 14)
	_info.size = Vector2(PANEL_SIZE.x, 12)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.modulate.a = 0.7
	_panel.add_child(_info)
	_big = ColorRect.new()
	_big.color = Color(0.05, 0.07, 0.1, 1.0)
	_big.position = BIG_POS
	_big.size = SettingsPanel.SIZE
	_big.visible = false
	dim.add_child(_big)
	var head := UiText.label()
	head.text = "設定"
	head.position = Vector2(6, 5)
	_big.add_child(head)
	var back := Button.new()
	UiText.style_button(back)
	back.text = "もどる（Esc）"
	back.position = Vector2(SettingsPanel.SIZE.x - 72, 3)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func(): show_settings(false))
	_big.add_child(back)
	_settings_panel = SettingsPanel.new()
	_settings_panel.setup(settings)
	_settings_panel.changed.connect(func(): settings_changed.emit())
	_big.add_child(_settings_panel)
	visible = false

func is_open() -> bool:
	return visible

## 開いて世界を止める。play_time は一覧に出す遊んだ時間。
func open(play_time := -1.0) -> void:
	_info.text = "遊んだ時間 %s" % SaveGame.time_text(play_time) if play_time >= 0.0 else "Esc：つづける"
	show_settings(false)
	visible = true
	if is_inside_tree():
		get_tree().paused = true
	Sfx.play("ui_open")

func close() -> void:
	if not visible:
		return
	visible = false
	if is_inside_tree():
		get_tree().paused = false
	Sfx.play("ui_close")
	resumed.emit()

func show_settings(on: bool) -> void:
	_big.visible = on
	_panel.visible = not on
	_settings_panel.show_controls(false)
	_settings_panel.refresh()

func settings_shown() -> bool:
	return _big.visible

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if _settings_panel.controls_shown():
			_settings_panel.show_controls(false)
		elif _big.visible:
			show_settings(false)
		else:
			close()
