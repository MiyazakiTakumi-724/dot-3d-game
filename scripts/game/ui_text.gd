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
