class_name Atmosphere
extends CanvasLayer
## 画面全体の空気（2026-11-26 の3回目の直し。添付の映像のように、影と光でリアルに見せる）。
## - 雲の影（ワールドに貼りついて流れる）と、画面のふちの暗さ（atmosphere.gdshader をかけ算で重ねる）
## - 地方ごとの暗さと明かり：溶岩・廃城・塔は暗く、たき火・炎・溶岩・主人公のまわりが明るい（field.gd が set_lights で渡す）
## - 地方ごとの舞うもの（草原の綿毛・山の雪・溶岩の火の粉・廃城のほこり・塔のきらめき・霧の谷の霧のすじ）
## - 霧（2026-11-26、霧の谷）：ワールドに貼りついてゆっくり流れる白いもや（glow.gdshader にたす）
## 世界（レイヤー0）より上、画面の文字（UI のレイヤー2）より下に描く。

const SHADER := preload("res://scripts/render/atmosphere.gdshader")
const GLOW_SHADER := preload("res://scripts/render/glow.gdshader")
const MAX_LIGHTS := 16
## 地方ごとの空気：雲の影の濃さ・明るさ（1 で暗くしない）・色・舞うもの
const THEMES := {
	"grass": {"clouds": 0.28, "ambient": 1.0, "tint": Color(1, 1, 1), "particles": "pollen"},
	"town": {"clouds": 0.2, "ambient": 1.0, "tint": Color(1, 1, 1), "particles": "pollen"},
	"mountain": {"clouds": 0.26, "ambient": 1.0, "tint": Color(0.96, 0.98, 1.0), "particles": "snow"},
	"castle": {"clouds": 0.14, "ambient": 0.8, "tint": Color(0.86, 0.9, 1.0), "particles": "dust"},
	"lava": {"clouds": 0.0, "ambient": 0.66, "tint": Color(0.95, 0.72, 0.74), "particles": "embers"},
	"tower": {"clouds": 0.0, "ambient": 0.76, "tint": Color(0.84, 0.82, 1.0), "particles": "sparkles"},
	"mist": {"clouds": 0.1, "ambient": 0.74, "tint": Color(0.8, 0.88, 0.96), "particles": "mist", "fog": 0.2},
}
## 舞うものの数
const PARTICLES := 46

var camera: StackCamera
var theme := "grass"
var _rect: ColorRect
var _mat: ShaderMaterial
## 光の輝き（glow.gdshader をたし算で重ねる。2026-11-26 の4回目の直し）
var _glow_rect: ColorRect
var _glow_mat: ShaderMaterial
var _motes: Motes
var _time := 0.0

func _init() -> void:
	layer = 1

func setup(cam: StackCamera) -> void:
	camera = cam
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.position = Vector2.ZERO
	_rect.size = Vector2(320, 180)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect.material = _mat
	add_child(_rect)
	_glow_rect = ColorRect.new()
	_glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow_rect.position = Vector2.ZERO
	_glow_rect.size = Vector2(320, 180)
	_glow_mat = ShaderMaterial.new()
	_glow_mat.shader = GLOW_SHADER
	_glow_rect.material = _glow_mat
	add_child(_glow_rect)
	_motes = Motes.new()
	_motes.camera = cam
	add_child(_motes)
	set_theme("grass")

static func config(t: String) -> Dictionary:
	return THEMES.get(t, THEMES["grass"])

## 地方を替える（エリアに入ったとき）。
func set_theme(t: String) -> void:
	theme = t
	var c := config(t)
	_mat.set_shader_parameter("clouds", c["clouds"])
	_mat.set_shader_parameter("ambient", c["ambient"])
	var tint: Color = c["tint"]
	_mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	_glow_mat.set_shader_parameter("fog", float(c.get("fog", 0.0)))
	_motes.start(c["particles"])

## 暗い地方か（明かりが意味を持つ）。
func is_dark() -> bool:
	return float(config(theme)["ambient"]) < 1.0

## 明かり：[ワールドの位置, 高さのpx, 半径のpx, 強さ, (輝き)] の並び。画面の外のものは使わない。
## 輝き（0〜1、なければ1）は、明かりのまわりをほんのり光らせる強さ（主人公のまわりの明かりは 0）。
func set_lights(list: Array) -> void:
	var packed: Array[Vector4] = []
	var glows := PackedFloat32Array()
	for l in list:
		if packed.size() >= MAX_LIGHTS:
			break
		var p: Vector2 = camera.world_to_screen(l[0], l[1])
		var r: float = l[2]
		if p.x < -r or p.y < -r or p.x > 320.0 + r or p.y > 180.0 + r:
			continue
		packed.append(Vector4(p.x, p.y, r, l[3]))
		glows.append(float(l[4]) if l.size() > 4 else 1.0)
	var n := packed.size()
	while packed.size() < MAX_LIGHTS:
		packed.append(Vector4.ZERO)
		glows.append(0.0)
	_mat.set_shader_parameter("lights", packed)
	_mat.set_shader_parameter("light_count", n)
	_glow_mat.set_shader_parameter("lights", packed)
	_glow_mat.set_shader_parameter("glows", glows)
	_glow_mat.set_shader_parameter("light_count", n)

func _process(delta: float) -> void:
	_time += delta
	if camera == null:
		return
	_mat.set_shader_parameter("focus", camera.focus)
	_mat.set_shader_parameter("angle", camera.angle)
	_mat.set_shader_parameter("time", _time)
	_glow_mat.set_shader_parameter("focus", camera.focus)
	_glow_mat.set_shader_parameter("angle", camera.angle)
	_glow_mat.set_shader_parameter("time", _time)

## 舞うもの。ワールドの点として持ち、カメラに合わせて画面に描く（カメラを回すと一緒に回る）。
class Motes extends Node2D:
	var camera: StackCamera
	var kind := ""
	var _pts: Array = []  # [ワールドの位置, 高さのpx, 速さ, ゆれの位相]
	var _rng := RandomNumberGenerator.new()
	var _t := 0.0

	func start(k: String) -> void:
		kind = k
		_rng.seed = hash(k)
		_pts.clear()
		for i in PARTICLES:
			_pts.append(_spawn(true))

	func _spawn(anywhere: bool) -> Array:
		var center := camera.focus if camera != null else Vector2.ZERO
		var off := Vector2(_rng.randf_range(-190, 190), _rng.randf_range(-120, 120))
		var h := _rng.randf_range(0.0, 90.0) if anywhere else (100.0 if kind == "snow" else 0.0)
		return [center + off, h, _rng.randf_range(0.6, 1.4), _rng.randf() * TAU]

	func _process(delta: float) -> void:
		_t += delta
		if camera == null:
			return
		for p in _pts:
			match kind:
				"snow":
					p[1] -= 14.0 * p[2] * delta
					p[0] += Vector2(6.0, 2.0) * delta * p[2]
				"embers":
					p[1] += 16.0 * p[2] * delta
					p[0] += Vector2(sin(_t * 2.0 + p[3]) * 6.0, 0.0) * delta
				"pollen", "dust":
					p[1] += sin(_t * 0.8 + p[3]) * 3.0 * delta
					p[0] += Vector2(5.0, -1.5) * delta * p[2]
				"mist":
					p[1] += sin(_t * 0.4 + p[3]) * 1.5 * delta
					p[0] += Vector2(7.0, 1.0) * delta * p[2]
				_:
					p[0] += Vector2(0.0, -2.0) * delta
			var rel: Vector2 = p[0] - camera.focus
			if p[1] < -10.0 or p[1] > 130.0 or absf(rel.x) > 200.0 or absf(rel.y) > 130.0:
				var fresh := _spawn(false)
				p[0] = fresh[0]
				p[1] = fresh[1] if kind in ["snow", "embers"] else _rng.randf_range(0.0, 90.0)
				if kind == "snow":
					p[1] = _rng.randf_range(80.0, 120.0)
		queue_redraw()

	func _draw() -> void:
		if camera == null:
			return
		var w := 1.0 / StackCamera.PIXEL_SCALE
		for p in _pts:
			var s: Vector2 = camera.world_to_screen(p[0], camera.focus_height + p[1])
			var c := Color(1, 1, 1, 0.8)
			var size := w
			match kind:
				"snow":
					c = Color(1, 1, 1, 0.9)
					size = w * 2.0 if p[2] > 1.1 else w
				"embers":
					c = Color(1.0, 0.55 + 0.3 * sin(_t * 9.0 + p[3]), 0.2, 0.9)
				"pollen":
					c = Color(1.0, 0.97, 0.8, 0.85)
					size = w * 2.0 if p[2] > 1.0 else w
				"dust":
					c = Color(0.85, 0.82, 0.78, 0.45)
				"sparkles":
					var tw := 0.5 + 0.5 * sin(_t * 4.0 + p[3] * 3.0)
					c = Color(0.75, 0.9, 1.0, tw)
				"mist":
					# 霧のすじ：横に長い、うすい白
					var a: float = 0.1 + 0.06 * sin(_t * 0.7 + p[3])
					var len: float = 6.0 + 8.0 * p[2]
					draw_rect(Rect2(s - Vector2(len * 0.5, 0.0), Vector2(len, w * 2.0)), Color(0.9, 0.94, 1.0, a))
					draw_rect(Rect2(s - Vector2(len * 0.3, w * 2.0), Vector2(len * 0.6, w * 2.0)), Color(0.9, 0.94, 1.0, a * 0.7))
					size = 0.0  # 点は描かない
			if size > 0.0:
				draw_rect(Rect2(s, Vector2(size, size)), c)
