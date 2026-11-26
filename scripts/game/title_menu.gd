class_name TitleMenu
extends CanvasLayer
## タイトル画面（2026-11-26 独自の開発1）。うしろには、はじまりの町をカメラがゆっくり回って映す（field.gd の title モード）。
## つづきから（セーブの枠を選ぶ）・はじめから（空いた枠を選ぶ。使っている枠なら上書きを確かめる）・設定・おわる。
## ゲームの名前は【提案】「灯りの瞳」（主人公は灯りの村の生き残りで、塔の上の目＝ブライトと戦う。カメラを回して物の
## 本当の姿を見る力を「灯りの瞳」と呼ぶ。docs/superpowers/specs/2026-11-26-steam-push-1.md）。

signal start_new(slot: int)
signal load_slot(slot: int)
signal quit_game
signal settings_changed

const GAME_TITLE := "灯りの瞳"
const GAME_SUBTITLE := "― Lantern Eye ―"
const VERSION := "v0.1　開発中"

enum Mode { MAIN, LOAD, NEW, CONFIRM, SETTINGS }

var settings: GameSettings
var mode: Mode = Mode.MAIN
var _root: Control
var _main: Control
var _slots: Control
var _slot_head: Label
var _slot_buttons: Array[Button] = []
var _confirm: Control
var _confirm_text: Label
var _confirm_slot := 0
var _big: ColorRect
var _settings_panel: SettingsPanel
var _continue: Button

func setup(s: GameSettings) -> void:
	settings = s
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.size = Vector2(320, 180)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var shade := ColorRect.new()  # 文字を読みやすくする上下の暗がり
	shade.color = Color(0.02, 0.03, 0.06, 0.55)
	shade.size = Vector2(320, 78)
	shade.position = Vector2(0, 16)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)
	var title := UiText.label(true)
	title.text = GAME_TITLE
	title.add_theme_font_size_override("font_size", 24)  # 12px のドット絵フォントの2倍（にじまない）
	title.add_theme_constant_override("outline_size", 4)
	title.position = Vector2(0, 26)
	title.size = Vector2(320, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1.0, 0.86, 0.55)
	_root.add_child(title)
	var sub := UiText.label()
	sub.text = GAME_SUBTITLE
	sub.position = Vector2(0, 62)
	sub.size = Vector2(320, 12)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.85, 0.88, 0.95, 0.85)
	_root.add_child(sub)
	var ver := UiText.label()
	ver.text = VERSION
	ver.position = Vector2(4, 3)
	ver.modulate.a = 0.6
	_root.add_child(ver)

	_main = Control.new()
	_main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_main)
	_continue = _button(_main, "つづきから", Vector2(115, 88), Vector2(90, 17), func(): show_slots(Mode.LOAD))
	_button(_main, "はじめから", Vector2(115, 107), Vector2(90, 17), func(): show_slots(Mode.NEW))
	_button(_main, "設定・操作", Vector2(115, 126), Vector2(90, 17), func(): show_mode(Mode.SETTINGS))
	_button(_main, "おわる", Vector2(115, 145), Vector2(90, 17), func(): quit_game.emit())

	_slots = Control.new()
	_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_slots)
	var sbg := ColorRect.new()
	sbg.color = Color(0.05, 0.07, 0.1, 0.94)
	sbg.position = Vector2(50, 80)
	sbg.size = Vector2(220, 98)
	sbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slots.add_child(sbg)
	_slot_head = UiText.label()
	_slot_head.position = Vector2(56, 82)
	_slots.add_child(_slot_head)
	for i in SaveGame.SLOTS:
		var slot := i + 1
		var b := _button(_slots, "", Vector2(56, 96 + i * 25), Vector2(208, 23), func(): choose_slot(slot))
		_slot_buttons.append(b)
	_button(_slots, "もどる", Vector2(222, 81), Vector2(42, 13), func(): show_mode(Mode.MAIN))

	_confirm = Control.new()
	_confirm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_confirm)
	var cbg := ColorRect.new()
	cbg.color = Color(0.08, 0.05, 0.05, 0.97)
	cbg.position = Vector2(50, 96)
	cbg.size = Vector2(220, 56)
	cbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm.add_child(cbg)
	_confirm_text = UiText.label()
	_confirm_text.position = Vector2(56, 100)
	_confirm_text.size = Vector2(208, 26)
	_confirm_text.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_confirm.add_child(_confirm_text)
	_button(_confirm, "上書きして はじめる", Vector2(56, 132), Vector2(110, 15), func(): confirm(true))
	_button(_confirm, "やめる", Vector2(174, 132), Vector2(90, 15), func(): confirm(false))

	_big = ColorRect.new()
	_big.color = Color(0.05, 0.07, 0.1, 0.97)
	_big.position = Vector2(8, 6)
	_big.size = SettingsPanel.SIZE
	_root.add_child(_big)
	var head := UiText.label()
	head.text = "設定"
	head.position = Vector2(6, 5)
	_big.add_child(head)
	_button(_big, "もどる（Esc）", Vector2(SettingsPanel.SIZE.x - 72, 3), Vector2.ZERO, func(): show_mode(Mode.MAIN))
	_settings_panel = SettingsPanel.new()
	_settings_panel.setup(settings)
	_settings_panel.changed.connect(func(): settings_changed.emit())
	_big.add_child(_settings_panel)
	visible = false

func is_open() -> bool:
	return visible

func open() -> void:
	visible = true
	show_mode(Mode.MAIN)

func close() -> void:
	visible = false

## セーブのある枠があるか。
func has_any_save() -> bool:
	for i in SaveGame.SLOTS:
		if SaveGame.exists(i + 1):
			return true
	return false

func show_mode(m: Mode) -> void:
	mode = m
	_main.visible = m == Mode.MAIN
	_slots.visible = m == Mode.LOAD or m == Mode.NEW
	_confirm.visible = m == Mode.CONFIRM
	_big.visible = m == Mode.SETTINGS
	_continue.disabled = not has_any_save()
	if m == Mode.SETTINGS:
		_settings_panel.show_controls(false)
		_settings_panel.refresh()

func show_slots(m: Mode) -> void:
	if m == Mode.LOAD and not has_any_save():
		return
	show_mode(m)
	_slot_head.text = "つづきから：セーブを選ぶ" if m == Mode.LOAD else "はじめから：書く枠を選ぶ"
	for i in _slot_buttons.size():
		var b := _slot_buttons[i]
		b.text = slot_text(i + 1)
		b.disabled = m == Mode.LOAD and not SaveGame.exists(i + 1)

## 枠の一覧の文字（2行）。
static func slot_text(slot: int) -> String:
	var s := SaveGame.summary(slot)
	if s.is_empty():
		return "%d　（空き）" % slot
	var line1 := "%d　Lv%d　遊んだ時間 %s%s" % [slot, s["level"], SaveGame.time_text(s["play_time"]), "　★クリア" if s["cleared"] else ""]
	var line2 := "　%s　倒したぬし %d" % [s["place"], s["bosses"]]
	return line1 + "\n" + line2

func choose_slot(slot: int) -> void:
	if mode == Mode.LOAD:
		if SaveGame.exists(slot):
			Sfx.play("ui_click")
			load_slot.emit(slot)
	elif mode == Mode.NEW:
		if SaveGame.exists(slot):
			_confirm_slot = slot
			_confirm_text.text = "枠%d のセーブを消して、\nはじめから 始めますか？" % slot
			show_mode(Mode.CONFIRM)
		else:
			Sfx.play("ui_click")
			start_new.emit(slot)

func confirm(yes: bool) -> void:
	if yes:
		start_new.emit(_confirm_slot)
	else:
		show_slots(Mode.NEW)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if mode == Mode.SETTINGS and _settings_panel.controls_shown():
				_settings_panel.show_controls(false)
			elif mode == Mode.CONFIRM:
				show_slots(Mode.NEW)
			elif mode != Mode.MAIN:
				show_mode(Mode.MAIN)
		elif event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_3 and (mode == Mode.LOAD or mode == Mode.NEW):
			get_viewport().set_input_as_handled()
			choose_slot(event.physical_keycode - KEY_0)

func _button(parent: Node, text: String, pos: Vector2, sz: Vector2, on_press: Callable) -> Button:
	var b := Button.new()
	UiText.style_button(b)  # 大きさを決める前にフォントを決める（先に決めると大きいフォントの大きさのままになる）
	b.text = text
	b.position = pos
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT if sz.y > 20 else HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(on_press)
	# size を直接決めると、木に入る前の既定のフォント（16px）で測った大きさのままになるので、最小の大きさで決める
	b.custom_minimum_size = sz
	parent.add_child(b)
	return b
