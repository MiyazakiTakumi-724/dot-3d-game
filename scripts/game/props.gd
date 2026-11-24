class_name Props
extends RefCounted
## 主人公以外の物の模型（矢・小物など）。主人公と同じ2倍の細かさで作り、ボクセル1つを本当の画面の1pxで描く
## （StackSprite.voxel_scale = VOXEL_SCALE）。影は VoxelShade で主人公と同じように付ける。作った模型は使い回す。

const VOXEL_SCALE := 0.5

const SHAFT := Color("b07a46")
const ARROW_HEAD := Color("dfe7f0")
const POISON_HEAD := Color("8fdc5a")
const FEATHER := Color("f4f1ea")
const FEATHER_BAND := Color("d9463b")
const POISON_FEATHER := Color("5c9e3c")

## 矢の長さ（ボクセル）と、模型の大きさ。矢の真ん中が模型の真ん中に来る
const ARROW_LEN := 20
const ARROW_BOX := Vector3i(6, 22, 22)
## 傾きの段（この角度ごとに模型を作る）と、一番の傾き
const PITCH_STEP := PI / 12.0
const PITCH_MAX := PI * 5.0 / 12.0

static var _cache := {}

## 飛んでいる矢の模型。pitch は上向きを正とする傾き（ラジアン）。PITCH_STEP ごとにまとめて使い回す。
static func arrow_model(kind: Arrow.Kind, pitch: float) -> VoxelModel:
	var q := roundi(clampf(pitch, -PITCH_MAX, PITCH_MAX) / PITCH_STEP)
	var key := "arrow|%d|%d" % [kind, q]
	if not _cache.has(key):
		_cache[key] = VoxelShade.apply(arrow_raw(kind, q * PITCH_STEP))
	return _cache[key]

## 影をつける前の矢。前（+y）が矢じり。軸は1本、矢じりは横に広い三角、後ろに上下左右の羽根。
static func arrow_raw(kind: Arrow.Kind, pitch: float) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = ARROW_BOX
	var center := Vector3(ARROW_BOX) / 2.0 - Vector3(0.5, 0.5, 0.5)
	var fwd := Vector3(0, cos(pitch), sin(pitch))
	var up := Vector3(0, -sin(pitch), cos(pitch))  # 矢から見た上
	var head_c := POISON_HEAD if kind == Arrow.Kind.POISON else ARROW_HEAD
	var feather_c := POISON_FEATHER if kind == Arrow.Kind.POISON else FEATHER
	var half := ARROW_LEN / 2.0
	# 軸（後ろから前へ、半ボクセルずつ置いて切れ目がないように）
	for i in range(0, ARROW_LEN * 2):
		var t := -half + i * 0.5
		_put(m, center + fwd * t, SHAFT)
	# 矢じり：先へいくほど細い
	for i in 4:
		var t := half - i
		var w := mini(i, 2)
		for dx in range(-w, w + 1):
			_put(m, center + fwd * t + Vector3(dx * 0.5, 0, 0), head_c)
			_put(m, center + fwd * t + up * (dx * 0.5), head_c)
	# 羽根：後ろの5つぶん、横と上下に2つ出す。真ん中に赤い帯
	for i in 5:
		var t := -half + 1 + i
		var c := FEATHER_BAND if i == 2 and kind == Arrow.Kind.NORMAL else feather_c
		for side in [-2, -1, 1, 2]:
			_put(m, center + fwd * t + Vector3(side, 0, 0), c)
			_put(m, center + fwd * t + up * side, c)
	return m

static func _put(m: VoxelModel, p: Vector3, c: Color) -> void:
	m.set_voxel(Vector3i(p.round()), c)
