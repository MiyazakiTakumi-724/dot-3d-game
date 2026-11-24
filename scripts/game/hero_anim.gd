class_name HeroAnim
extends RefCounted
## 主人公の動き。今どの姿（HeroModel の pose）で、どれだけ下げ・ひねり・縮めて描くかを決める。描画に依存しないので単体テストできる。
## 歩く：歩いた距離で 左足→そろえる→右足→そろえる をくり返す（足が滑って見えないよう、時間でなく距離で進める）。
## 鉄球を放す・拾う・剣を振る・回転斬り・飛び降りの着地は、play_* で始めて update の時間で終わる。

const STEP_PX := 5.0  ## 足を1回出すあいだに進む距離（ゲームの座標のpx）
const BOB_PX := 0.5  ## 足を出しているときに体を下げる量（本当の画面の1px）
const RELEASE_TIME := 0.25  ## 鉄球を放したあと、両手を前に出している時間
const PICKUP_TIME := 0.2  ## 拾うときにかがむ時間
const PICKUP_DIP := 6  ## 拾うときに一番かがんだときの、描かない下の輪切りの数
const SWING_TWIST := 0.8  ## 剣を振るときのひねり（ラジアン。剣を持つ側の−から＋へ）
const LAND_TIME := 0.12  ## 着地で縮んでいる時間
const LAND_SQUASH := 0.8  ## 着地の瞬間の、輪切りの間の詰め方（1でそのまま）

const WALK_POSES := ["step_l", "", "step_r", ""]

var _walk_dist := 0.0
var _moving := false
var _release_t := 0.0
var _pickup_t := 0.0
var _twist_t := 0.0
var _twist_len := 0.0
var _spin := false
var _land_t := 0.0

## 毎フレーム。moved_px はこのフレームに歩いた距離（止まっていれば0）。
func update(delta: float, moved_px: float) -> void:
	_release_t = maxf(0.0, _release_t - delta)
	_pickup_t = maxf(0.0, _pickup_t - delta)
	_twist_t = maxf(0.0, _twist_t - delta)
	_land_t = maxf(0.0, _land_t - delta)
	if moved_px > 0.01:
		if _moving:
			_walk_dist += moved_px
		_moving = true
	else:
		_moving = false
		_walk_dist = 0.0

func play_release() -> void:
	_release_t = RELEASE_TIME

func play_pickup() -> void:
	_pickup_t = PICKUP_TIME

## 剣を振る（seconds の間に、ひねりを − から ＋ へ）。
func play_swing(seconds: float) -> void:
	_twist_t = seconds
	_twist_len = seconds
	_spin = false

## 回転斬り（seconds の間に1回転）。
func play_spin(seconds: float) -> void:
	_twist_t = seconds
	_twist_len = seconds
	_spin = true

func play_land() -> void:
	_land_t = LAND_TIME

## 今の姿（HeroModel.build の pose）。"" は立ち姿。
func pose() -> String:
	if _release_t > 0.0:
		return "release"
	if not _moving:
		return ""
	return WALK_POSES[int(_walk_dist / STEP_PX) % WALK_POSES.size()]

## 体を下げる量（ゲームの座標のpx）。
func bob() -> float:
	return BOB_PX if pose().begins_with("step") else 0.0

## 拾うときに描かない下の輪切りの数（かがんで、戻る）。
func dip_layers() -> int:
	if _pickup_t <= 0.0:
		return 0
	return roundi(PICKUP_DIP * sin(PI * (1.0 - _pickup_t / PICKUP_TIME)))

## 向きに足す回転（ラジアン）。
func twist() -> float:
	if _twist_t <= 0.0 or _twist_len <= 0.0:
		return 0.0
	var k := 1.0 - _twist_t / _twist_len  # 0 → 1
	if _spin:
		return TAU * k
	return lerpf(-SWING_TWIST, SWING_TWIST, k)

## 輪切りの間の詰め方（着地で縮む）。
func stretch() -> float:
	if _land_t <= 0.0:
		return 1.0
	return lerpf(1.0, LAND_SQUASH, _land_t / LAND_TIME)
