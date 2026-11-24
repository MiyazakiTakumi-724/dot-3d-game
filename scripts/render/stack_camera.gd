class_name StackCamera
extends Node2D
## sprite stacking 用のカメラ。ワールド座標（真上から見た平面）を画面座標に変える。
## Q / E、またはマウスの右ボタンを押したまま左右に動かして回す（左クリックはアイテムを使うボタン）。

const SCREEN_CENTER := Vector2(160, 90)
## 本当の画面（640×360）は、ゲームの画面の座標（320×180）の2倍の細かさ。シーンの根と CanvasLayer をこの倍率で大きくする。
## 細かい物（主人公など）は、ボクセル1つを本当の画面の1pxで描く（StackSprite.voxel_scale = 1 / PIXEL_SCALE）。
const PIXEL_SCALE := 2

## シーンの根 root と、その子の CanvasLayer を PIXEL_SCALE 倍にする（ゲームの座標は 320×180 のまま）。
static func apply_pixel_scale(root: Node2D) -> void:
	root.scale = Vector2.ONE * PIXEL_SCALE
	for c in root.get_children():
		if c is CanvasLayer:
			c.scale = Vector2.ONE * PIXEL_SCALE
const TURN_SPEED := PI / 2  # 1秒で90°
const MOUSE_SENSITIVITY := 0.012  # 画面1pxあたりの回転量（ラジアン）

var angle: float = 0.0
var focus: Vector2 = Vector2.ZERO
## 画面の真ん中に来る高さ（px）。高台に立ったプレイヤーが画面の上に寄らないように、立っている高さに合わせる。
var focus_height: float = 0.0
## 高さの追いかけの速さ（1秒あたり、残りのこの割合だけ近づく）
const FOLLOW_HEIGHT_RATE := 6.0
## 画面のゆれ（鉄球が着いたときなど）。shake_offset だけ画面全体をずらす（本当の画面のpxにそろえる）
const SHAKE_TIME := 0.18
var shake_offset := Vector2.ZERO
var _shake_t := 0.0
var _shake_amp := 0.0

func _process(delta: float) -> void:
	var turn := 0.0
	if Input.is_physical_key_pressed(KEY_Q):
		turn -= 1.0
	if Input.is_physical_key_pressed(KEY_E):
		turn += 1.0
	angle = wrapf(angle + turn * TURN_SPEED * delta, -PI, PI)
	_update_shake(delta)

## 画面を amp（ゲームの座標のpx）だけ、SHAKE_TIME の間ゆらす。だんだん弱くなる。
func shake(amp: float) -> void:
	_shake_amp = maxf(amp, _shake_amp if _shake_t > 0.0 else 0.0)
	_shake_t = SHAKE_TIME

func _update_shake(delta: float) -> void:
	_shake_t = maxf(0.0, _shake_t - delta)
	if _shake_t <= 0.0:
		shake_offset = Vector2.ZERO
		return
	var a := _shake_amp * _shake_t / SHAKE_TIME
	shake_offset = (Vector2(randf_range(-a, a), randf_range(-a, a)) * PIXEL_SCALE).round() / PIXEL_SCALE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			angle = wrapf(angle + event.relative.x / PIXEL_SCALE * MOUSE_SENSITIVITY, -PI, PI)

## world を真ん中に、高さ height_px をなめらかに追いかける（段を登ったときに画面が跳ねないように）。
func follow(world: Vector2, height_px: float, delta: float) -> void:
	focus = world
	focus_height = lerpf(focus_height, height_px, minf(1.0, FOLLOW_HEIGHT_RATE * delta))

func world_to_screen(world: Vector2, height_px: float) -> Vector2:
	var p := (world - focus).rotated(-angle)
	return SCREEN_CENTER + p - Vector2(0, height_px - focus_height) + shake_offset

## world_to_screen の逆。height_px の高さの面の上で、画面の点に当たるワールドの位置。
func screen_to_world(screen: Vector2, height_px: float) -> Vector2:
	return focus + (screen - shake_offset - SCREEN_CENTER + Vector2(0, height_px - focus_height)).rotated(angle)

## 画面の点に見えている地面の点。高い段から順に、その高さの面の上の点を求め、
## そこのマスがちょうどその高さなら、それが見えている地面。なければ高さ0の面の点。
func pick_ground(screen: Vector2, map: HeightMap, max_h: int) -> Vector2:
	for h in range(max_h, -1, -1):
		var w := screen_to_world(screen, h * StackSprite.LEVEL_PX)
		var c := HeightMap.world_to_cell(w)
		if map.in_bounds(c) and not map.is_void(c) and map.get_height(c) == h:
			return w
	return screen_to_world(screen, 0)

## 画面上の向き（例：上キー = Vector2.UP）をワールドの向きに変える。
func screen_dir_to_world(dir: Vector2) -> Vector2:
	return dir.rotated(angle)

## 大きいほど手前（後から描く）。
func depth_key(world: Vector2) -> float:
	return (world - focus).rotated(-angle).y
