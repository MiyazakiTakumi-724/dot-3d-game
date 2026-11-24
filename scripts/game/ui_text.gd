class_name UiText
extends RefCounted
## 画面の文字。日本語のドット絵フォント（PixelMplus、M+ FONT LICENSE）を、ぼやけない大きさ（10px・12px）で使う。

const SMALL_FONT := preload("res://fonts/PixelMplus10-Regular.ttf")
const LARGE_FONT := preload("res://fonts/PixelMplus12-Regular.ttf")
const OUTLINE_COLOR := Color(0.04, 0.04, 0.07)

## 文字を出す Label を作る。large なら 12px、そうでなければ 10px。
static func label(large := false, outline := true) -> Label:
	var l := Label.new()
	style(l, large)
	if outline:
		l.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
		l.add_theme_constant_override("outline_size", 2)
	return l

## Label や Button の文字を、このゲームのフォントにする。
static func style(c: Control, large := false) -> void:
	c.add_theme_font_override("font", LARGE_FONT if large else SMALL_FONT)
	c.add_theme_font_size_override("font_size", 12 if large else 10)

## ボタンの見た目。小さな画面でも押せる所だと分かるように、枠と背景を付ける。
static func style_button(b: Button) -> void:
	style(b)
	var states := {
		"normal": Color(0.14, 0.17, 0.23),
		"hover": Color(0.22, 0.27, 0.36),
		"pressed": Color(0.3, 0.36, 0.48),
		"disabled": Color(0.1, 0.11, 0.14),
	}
	for st in states:
		var box := StyleBoxFlat.new()
		box.bg_color = states[st]
		box.border_color = Color(0.45, 0.5, 0.62) if st != "disabled" else Color(0.25, 0.27, 0.32)
		box.set_border_width_all(1)
		box.content_margin_left = 3
		box.content_margin_right = 3
		box.content_margin_top = 1
		box.content_margin_bottom = 1
		b.add_theme_stylebox_override(st, box)
