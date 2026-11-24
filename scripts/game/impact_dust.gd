class_name ImpactDust
extends Node2D
## 鉄球が地面に着いたときの土ぼこり。着いた点のまわりに、小さな粒が輪になって広がりながら消える。
## 高い所から落ちたほど大きく広がる。終わったら自分で消える。

const LIFE := 0.35  ## 出ている時間（秒）
const PUFFS := 12  ## 粒の数
const COLOR := Color("efe3c4")

var camera: StackCamera
var world_pos := Vector2.ZERO
var height := 0  ## 着いた所の段
var radius := 8.0  ## 一番広がったときの半径（ゲームの座標のpx）
var _t := 0.0

## pos・h に着いた、levels 段落ちた鉄球の土ぼこり。
func setup(cam: StackCamera, pos: Vector2, h: int, levels: int) -> void:
	camera = cam
	world_pos = pos
	height = h
	radius = 6.0 + 2.0 * clampi(levels, 0, 4)
	_place()

## 0〜1（出てから消えるまで）
func progress() -> float:
	return clampf(_t / LIFE, 0.0, 1.0)

func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	_place()
	queue_redraw()

func _place() -> void:
	if camera == null:
		return
	position = camera.world_to_screen(world_pos, height * StackSprite.LEVEL_PX)
	z_index = clampi(int(camera.depth_key(world_pos)) * StackSprite.Z_PER_PX + 4, -4000, 4000)

func _draw() -> void:
	var k := progress()
	var ease_out := 1.0 - (1.0 - k) * (1.0 - k)
	var r := lerpf(3.0, radius, ease_out)
	var c := COLOR
	c.a = 0.85 * (1.0 - k)
	var size := 2.0 if k < 0.4 else 1.0  # 粒ははじめ大きく、広がると小さく
	for i in PUFFS:
		var a := TAU * i / PUFFS + 0.3
		# 見下ろしなので横長の楕円に広げ、少し浮き上がらせる
		var p := Vector2(cos(a) * r, sin(a) * r * 0.55 - 3.0 * ease_out)
		p = (p * StackCamera.PIXEL_SCALE).round() / StackCamera.PIXEL_SCALE
		draw_rect(Rect2(p - Vector2.ONE * size * 0.5, Vector2.ONE * size), c)
