class_name SettingsPanel
extends Control
## 設定の欄（2026-11-26 独自の開発1）。インベントリ画面の「設定」・止める画面・タイトル画面で同じものを使う。
## 変えるとすぐに効き、changed を出す（field.gd が settings.json に保存する）。
## 行：難易度・画面の光・画面のゆれ・カメラを回す間・効果音・曲・画面。下の行に、カーソルを合わせた行の説明を出す。

signal changed

const SIZE := Vector2(304, 168)
const ROW_Y := 23.0
const ROW_H := 17.0
const BUTTON_X := 92.0

var settings: GameSettings
var _rows := {}  # 名前 → {値 → Button}
var _main: Control
var _controls: Control
var _note: Label

## 行：[名前, 画面の見出し, [[値, 文字], ...], 説明]
const ROWS := [
	["easy_mode", "難易度", [[false, "普通"], [true, "簡単"]], "簡単：敵から受けるダメージだけが半分になる"],
	["soft_flash", "画面の光", [[false, "ふつう"], [true, "弱い"]], "弱い：画面が白く光る演出を弱くする"],
	["shake", "画面のゆれ", [[true, "あり"], [false, "なし"]], "なし：鉄球や爆発で画面をゆらさない"],
	["slow_turn", "カメラを回す間", [[false, "ふつう"], [true, "ゆっくり"]], "ゆっくり：カメラを回している間だけ、時間がゆっくり進む"],
	["sfx_level", "効果音", [[0, "なし"], [1, "小"], [2, "中"], [3, "大"]], "効果音の大きさ"],
	["bgm_level", "曲", [[0, "なし"], [1, "小"], [2, "中"], [3, "大"]], "曲（BGM）の大きさ"],
	["fullscreen", "画面", [[false, "ウィンドウ"], [true, "全画面"]], "F11 でも切りかえられる"],
]

func setup(s: GameSettings) -> void:
	settings = s
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_main = Control.new()
	_main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_main)
	for i in ROWS.size():
		var row: Array = ROWS[i]
		var key: String = row[0]
		var y := ROW_Y + i * ROW_H
		_label(_main, row[1], Vector2(6, y + 3))
		var buttons := {}
		var x := BUTTON_X
		for choice in row[2]:
			var v = choice[0]
			var b := _button(_main, "", Vector2(x, y), func(): set_value(key, v))
			b.mouse_entered.connect(func(): _note.text = row[3])
			buttons[v] = b
			x += 14.0 + UiText.SMALL_FONT.get_string_size("● " + choice[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		_rows[key] = buttons
	_button(_main, "操作の一覧を見る", Vector2(6, ROW_Y + ROWS.size() * ROW_H + 2), func(): show_controls(true))
	_note = _label(_main, "", Vector2(6, SIZE.y - 13))
	_note.modulate.a = 0.75
	# 操作の一覧（遊ぶ画面には出さず、ここで見る）
	_controls = Control.new()
	_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls.visible = false
	add_child(_controls)
	_label(_controls, "操作の一覧", Vector2(6, 25))
	_button(_controls, "もどる", Vector2(SIZE.x - 54, 22), func(): show_controls(false))
	var y := 42.0
	for row in GameSettings.CONTROLS:
		var k := _label(_controls, row[0], Vector2(8, y))
		k.modulate = Color(1.0, 0.9, 0.55)
		_label(_controls, row[1], Vector2(100, y))
		y += 11.0
	refresh()

## 1つの設定を変える。
func set_value(key: String, v) -> void:
	settings.set(key, v)
	match key:
		"sfx_level":
			Sfx.level = v
			Sfx.play("ui_click")
		"bgm_level":
			Bgm.level = v
		"fullscreen":
			InventoryMenu.apply_window(v)
	refresh()
	changed.emit()

func show_controls(on: bool) -> void:
	_controls.visible = on
	_main.visible = not on

func controls_shown() -> bool:
	return _controls.visible

func refresh() -> void:
	for key in _rows:
		var buttons: Dictionary = _rows[key]
		var row: Array = []
		for r in ROWS:
			if r[0] == key:
				row = r
		for choice in row[2]:
			var on: bool = settings.get(key) == choice[0]
			buttons[choice[0]].text = ("● " if on else "○ ") + choice[1]
			buttons[choice[0]].modulate = Color(1.0, 0.92, 0.6) if on else Color.WHITE

func _label(parent: Node, text: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiText.style(l)
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, pos: Vector2, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiText.style_button(b)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b
