class_name DamagePopup
extends Label
## 当たったときに出るダメージの数字。ワールドの点の上に出て、少し上がりながら消える。
## 画面の文字の層（CanvasLayer）に置き、毎フレームカメラで画面の位置を求め直す。

const SECONDS := 0.8
const RISE_PX := 10.0
const WIDTH := 40.0

var camera: StackCamera
var world_pos: Vector2
var height_px: float
var _t := 0.0

static func make(cam: StackCamera, pos: Vector2, h_px: float, amount: int, color: Color) -> DamagePopup:
	return make_text(cam, pos, h_px, str(amount), color)

## 数字でない言葉（「ふせいだ」・回復の「+6」など）。
static func make_text(cam: StackCamera, pos: Vector2, h_px: float, text: String, color: Color) -> DamagePopup:
	var p := DamagePopup.new()
	UiText.style(p)
	p.add_theme_color_override("font_outline_color", UiText.OUTLINE_COLOR)
	p.add_theme_constant_override("outline_size", 2)
	p.add_theme_color_override("font_color", color)
	p.text = text
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.size = Vector2(maxf(WIDTH, text.length() * 12.0), 12)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.camera = cam
	p.world_pos = pos
	p.height_px = h_px
	p._place()
	return p

func _process(delta: float) -> void:
	_t += delta
	if _t >= SECONDS:
		queue_free()
		return
	_place()
	modulate.a = 1.0 - clampf((_t - SECONDS * 0.5) / (SECONDS * 0.5), 0.0, 1.0)

func _place() -> void:
	var p := camera.world_to_screen(world_pos, height_px)
	position = (p + Vector2(-WIDTH * 0.5, -22.0 - RISE_PX * _t / SECONDS)).round()
