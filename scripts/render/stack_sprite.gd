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

## 画面（320×180）からこれ以上はみ出したものは描かない。広いエリアで描画を軽くするため。
## 背の高いもの（台地・壁）が下から画面に入るので、縦は多めに取る。
const VISIBLE_RECT := Rect2(-48, -48, 320 + 96, 180 + 120)

func set_model(m: VoxelModel) -> void:
	_layers.clear()
	for img in m.slices():
		_layers.append(ImageTexture.create_from_image(img))
	queue_redraw()

func _process(_delta: float) -> void:
	refresh()

## 画面上の位置と描く順番を今の状態に合わせる。
func refresh() -> void:
	if camera == null:
		return
	position = camera.world_to_screen(world_pos, base_height * LEVEL_PX + lift_px)
	visible = VISIBLE_RECT.has_point(position)
	if not visible:
		return
	var sort_pos := HeightMap.cell_center(HeightMap.world_to_cell(world_pos)) if sort_by_cell else world_pos
	z_index = clampi(int(camera.depth_key(sort_pos)) * 4 + draw_bias, -4000, 4000)
	queue_redraw()

func _draw() -> void:
	if camera == null:
		return
	for i in _layers.size():
		var t := _layers[i]
		draw_set_transform(Vector2(0, -i), -camera.angle, Vector2.ONE)
		draw_texture(t, -t.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
