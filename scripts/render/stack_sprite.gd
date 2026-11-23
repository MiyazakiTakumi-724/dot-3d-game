class_name StackSprite
extends Node2D
## 輪切り画像を1枚ずつ上にずらして重ね、カメラの向きに合わせて回して描く。

const LEVEL_PX := 8  # 1段 = 輪切り8枚 = 画面で8px

var camera: StackCamera
var world_pos: Vector2 = Vector2.ZERO
var base_height: int = 0
var lift_px: float = 0.0  ## 段とは別に浮かせる量（落下中の鉄球など）
var draw_bias: int = 0  ## 同じ奥行きのとき、大きい方を後に描く
## true なら立っているマスの中心で奥行きを決める（動くもの用）。
## マスの奥側に立っても、足元の床より後に描かれるようにするため。
var sort_by_cell := false
var _layers: Array[ImageTexture] = []
## true の間は描かない。visible は画面外かどうかで毎フレーム書き換えるので、隠したいときはこちらを使う。
var force_hidden := false
## true なら毎フレーム描き直す（向きが変わるプレイヤーや敵など）。
## false のものは、カメラの角度が変わったときだけ描き直す（地形など。動かすだけなら描き直さなくてよい）。
var always_redraw := false
var _drawn_angle := NAN

## 画面（320×180）から、これだけ外にはみ出したものは描かない。広いエリアで描画を軽くするため。
## 輪切りを回すと、マスより少し大きく見えるので、その分の余裕。
const VISIBLE_MARGIN := 24.0

func set_model(m: VoxelModel) -> void:
	_layers = m.textures()
	queue_redraw()

func _process(_delta: float) -> void:
	refresh()

## 画面上の位置と描く順番を今の状態に合わせる。
func refresh() -> void:
	if camera == null:
		return
	position = camera.world_to_screen(world_pos, base_height * LEVEL_PX + lift_px)
	var was_visible := visible
	visible = not force_hidden and _on_screen()
	if not visible:
		return
	var sort_pos := HeightMap.cell_center(HeightMap.world_to_cell(world_pos)) if sort_by_cell else world_pos
	z_index = clampi(int(camera.depth_key(sort_pos)) * 4 + draw_bias, -4000, 4000)
	if needs_redraw() or not was_visible:
		queue_redraw()

## 一番下の輪切り（position）から一番上（輪切りの枚数だけ上）までのどこかが、画面に入っているか。
func _on_screen() -> bool:
	var m := VISIBLE_MARGIN
	return position.x > -m and position.x < 320.0 + m \
		and position.y + m > 0.0 and position.y - _layers.size() - m < 180.0

func needs_redraw() -> bool:
	return always_redraw or camera == null or camera.angle != _drawn_angle

func _draw() -> void:
	if camera == null:
		return
	_drawn_angle = camera.angle
	for i in _layers.size():
		var t := _layers[i]
		draw_set_transform(Vector2(0, -i), -camera.angle, Vector2.ONE)
		draw_texture(t, -t.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
