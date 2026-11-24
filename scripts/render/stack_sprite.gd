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
## sort_by_cell のとき、これがあれば足元の円（半径 sort_radius）がかかるマスのうち、
## 自分以下の高さのマスの一番手前で奥行きを決める（sort_depth）。マスの手前のふちに立っても、
## 手前のマスの地面が上にかぶらないようにするため。
var sort_map: HeightMap
var sort_radius := 5.0
var _layers: Array[ImageTexture] = []
## true の間は描かない。visible は画面外かどうかで毎フレーム書き換えるので、隠したいときはこちらを使う。
var force_hidden := false
## true なら毎フレーム描き直す（向きが変わるプレイヤーや敵など）。
## false のものは、カメラの角度が変わったときだけ描き直す（地形など。動かすだけなら描き直さなくてよい）。
var always_redraw := false
var _drawn_angle := NAN
## 0より大きければ、足元（lift_px の分だけ下の地面）に、この半径の影を描く
var shadow_radius := 0.0
## 地面の柱の上の面のふちに引く明るい線（隣が低い辺。1＝北、2＝東、4＝南、8＝西）と、上の面の輪切りの番号・色
var rim_sides := 0
var rim_layer := 0
var rim_color := Color.WHITE

## 画面（320×180）から、これだけ外にはみ出したものは描かない。広いエリアで描画を軽くするため。
## 輪切りを回すと、マスより少し大きく見えるので、その分の余裕。
const VISIBLE_MARGIN := 24.0

## 奥行き1pxあたりの z_index。この中で draw_bias（0〜7）で順番を決める。
## 地面 0、目印 1、敵・墓石 2、プレイヤー 2、鉄球・弾 3、木や岩 5（Terrain.DECO_BIAS）。
const Z_PER_PX := 8

## 足元の円がかかるマスのうち、高さ h 以下で壁でないマス（と自分のマス）の、一番手前の中心の奥行き。
## それより高いマスや壁は、手前にあればキャラを隠すのが正しいので数えない。
static func sort_depth(cam: StackCamera, map: HeightMap, pos: Vector2, h: int, radius: float) -> float:
	var own := HeightMap.world_to_cell(pos)
	var best := cam.depth_key(HeightMap.cell_center(own))
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var c := HeightMap.world_to_cell(pos + corner * radius)
		if c == own or not map.in_bounds(c) or map.is_wall(c) or map.get_height(c) > h:
			continue
		best = maxf(best, cam.depth_key(HeightMap.cell_center(c)))
	return best

## 奥行きを決めるのに使う地図。動くもの（プレイヤー・敵・鉄球）は自分の地図を返すよう上書きする。
func _sort_map() -> HeightMap:
	return sort_map

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
	var depth := camera.depth_key(world_pos)
	if sort_by_cell:
		var m := _sort_map()
		if m != null:
			depth = sort_depth(camera, m, world_pos, base_height, sort_radius)
		else:
			depth = camera.depth_key(HeightMap.cell_center(HeightMap.world_to_cell(world_pos)))
	z_index = clampi(int(depth) * Z_PER_PX + draw_bias, -4000, 4000)
	if needs_redraw() or not was_visible:
		queue_redraw()

## 一番下の輪切り（position）から一番上（輪切りの枚数だけ上）までのどこかが、画面に入っているか。
func _on_screen() -> bool:
	var m := VISIBLE_MARGIN
	return position.x > -m and position.x < 320.0 + m \
		and position.y + m > 0.0 and position.y - _layers.size() - m < 180.0

## 足元の影。横長の楕円（ドット絵らしく、少ない色の半透明の黒）。
func _draw_shadow() -> void:
	if shadow_radius <= 0.0:
		return
	draw_set_transform(Vector2(0, lift_px), 0.0, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, shadow_radius, Color(0, 0, 0, 0.32), true, -1.0, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func needs_redraw() -> bool:
	return always_redraw or camera == null or camera.angle != _drawn_angle

func _draw() -> void:
	if camera == null:
		return
	_drawn_angle = camera.angle
	_draw_shadow()
	for i in _layers.size():
		var t := _layers[i]
		draw_set_transform(Vector2(0, -i), -camera.angle, Vector2.ONE)
		draw_texture(t, -t.get_size() * 0.5)
	_draw_rim()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## 上の面のふちの明るい線（地面の柱だけ）。
func _draw_rim() -> void:
	if rim_sides == 0:
		return
	draw_set_transform(Vector2(0, -rim_layer), -camera.angle, Vector2.ONE)
	if rim_sides & 1:
		draw_rect(Rect2(-8, -8, 16, 1), rim_color)
	if rim_sides & 2:
		draw_rect(Rect2(7, -8, 1, 16), rim_color)
	if rim_sides & 4:
		draw_rect(Rect2(-8, 7, 16, 1), rim_color)
	if rim_sides & 8:
		draw_rect(Rect2(-8, -8, 1, 16), rim_color)
