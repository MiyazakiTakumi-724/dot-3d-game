class_name HeroAnim
extends RefCounted
## 主人公の動き。今どの姿（HeroModel の pose）で、どれだけ下げ・ひねり・縮め・前後にずらして描くかを決める。描画に依存しないので単体テストできる。
## 歩く：歩いた距離で 左足→そろえる→右足→そろえる をくり返す（足が滑って見えないよう、時間でなく距離で進める）。
## 少しの間だけの動き（鉄球を放す・拾う・剣を振る・突く・回転斬り・弓を放す・杖をふるう・薬を飲む・門を押す・ダメージ・着地）は、
## play_* で始めて update の時間で終わる。弓を溜める（set_charge）・よじ登る（set_climb）は、毎フレーム今の値を渡す。
## 倒れる（play_die：ひざをついてから横たわる）・奈落に落ちる（play_fall：両手を上げる）は、revive まで続く。
## 姿の優先：倒れる・落ちる ＞ 少しの間の動き ＞ よじ登る ＞ 弓を溜める ＞ 歩く・立つ。

const STEP_PX := 5.0  ## 足を1回出すあいだに進む距離（ゲームの座標のpx）
const BOB_PX := 0.5  ## 足を出しているときに体を下げる量（本当の画面の1px）
const RELEASE_TIME := 0.25  ## 鉄球を放したあと、両手を前に出している時間
const PICKUP_TIME := 0.2  ## 拾うときにかがむ時間
const PICKUP_DIP := 6  ## 拾うときに一番かがんだときの、描かない下の輪切りの数
const SWING_TWIST := 0.8  ## 剣を振るときのひねり（ラジアン。剣を持つ側の−から＋へ）
const THRUST_PX := 3.0  ## 突きで前へ踏み込む量（ゲームの座標のpx）
const LOOSE_TIME := 0.15  ## 弓を放したあとの反動の時間
const LOOSE_PX := 1.0  ## 弓を放した反動で後ろへ下がる量
const CAST_TIME := 0.3  ## 杖をふるう姿の時間（杖の先が光る）
const DRINK_TIME := 0.5  ## 薬を飲む姿の時間
const PUSH_TIME := 0.4  ## 門を押す姿の時間
const HURT_TIME := 0.25  ## ダメージで赤く光り、のけぞる時間
const HURT_PX := 1.5  ## ダメージでのけぞる量
const CLIMB_LIFT_PX := 6.0  ## よじ登りきる直前に、体が上がる量
const KNEEL_TIME := 0.35  ## 倒れるとき、ひざをつくまでの時間（そのあと横たわる）
const KNEEL_DIP := 8  ## ひざをついたときに描かない下の輪切りの数
const LAND_TIME := 0.12  ## 着地で縮んでいる時間
const LAND_SQUASH := 0.8  ## 着地の瞬間の、輪切りの間の詰め方（1でそのまま）

const WALK_POSES := ["step_l", "", "step_r", ""]

enum Down { NONE, DYING, FALLING }

var _walk_dist := 0.0
var _moving := false
## 少しの間の姿（release・slash・thrust・cast・drink・push）と残り時間
var _action := ""
var _action_t := 0.0
var _action_len := 0.0
var _pickup_t := 0.0
var _twist_t := 0.0
var _twist_len := 0.0
var _spin := false
var _land_t := 0.0
var _loose_t := 0.0
var _hurt_t := 0.0
var _charge := -1.0
var _climb := 0.0
var _down := Down.NONE
var _down_t := 0.0

## このフレームに足を地面に着いたか（足音を鳴らすのに使う。2026-11-26）
var stepped := false

## 毎フレーム。moved_px はこのフレームに歩いた距離（止まっていれば0）。
func update(delta: float, moved_px: float) -> void:
	_action_t = maxf(0.0, _action_t - delta)
	if _action_t <= 0.0:
		_action = ""
	_pickup_t = maxf(0.0, _pickup_t - delta)
	_twist_t = maxf(0.0, _twist_t - delta)
	_land_t = maxf(0.0, _land_t - delta)
	_loose_t = maxf(0.0, _loose_t - delta)
	_hurt_t = maxf(0.0, _hurt_t - delta)
	if _down != Down.NONE:
		_down_t += delta
	stepped = false
	if moved_px > 0.01:
		if _moving:
			var before := int(_walk_dist / STEP_PX)
			_walk_dist += moved_px
			stepped = int(_walk_dist / STEP_PX) != before and pose().begins_with("step")  # 足が地面に着いた
		_moving = true
	else:
		_moving = false
		_walk_dist = 0.0

func _play(action: String, seconds: float) -> void:
	_action = action
	_action_t = seconds
	_action_len = seconds

func play_release() -> void:
	_play("release", RELEASE_TIME)

func play_pickup() -> void:
	_pickup_t = PICKUP_TIME

## 剣を振る（seconds の間に、ひねりを − から ＋ へ）。thrust なら技能「突き」：ひねらず、前へ踏み込む。
func play_swing(seconds: float, thrust := false) -> void:
	_play("thrust" if thrust else "slash", seconds)
	_twist_t = 0.0 if thrust else seconds
	_twist_len = seconds
	_spin = false

## 回転斬り（seconds の間に1回転）。
func play_spin(seconds: float) -> void:
	_play("slash", seconds)
	_twist_t = seconds
	_twist_len = seconds
	_spin = true

## 弓を放した（少し後ろへ反動）。
func play_loose() -> void:
	_loose_t = LOOSE_TIME

func play_cast() -> void:
	_play("cast", CAST_TIME)

func play_drink() -> void:
	_play("drink", DRINK_TIME)

func play_push() -> void:
	_play("push", PUSH_TIME)

func play_hurt() -> void:
	_hurt_t = HURT_TIME

func play_land() -> void:
	_land_t = LAND_TIME

## 弓のチャージ率（Bow.rate。溜めていなければ負）。毎フレーム渡す。
func set_charge(rate: float) -> void:
	_charge = rate

## よじ登りの進み具合（0〜1。PlayerMover.climb_progress）。毎フレーム渡す。
func set_climb(progress: float) -> void:
	_climb = clampf(progress, 0.0, 1.0)

## 倒れる（ひざをついてから横たわる）。
func play_die() -> void:
	_down = Down.DYING
	_down_t = 0.0

## 奈落に落ちる（両手を上げる）。
func play_fall() -> void:
	_down = Down.FALLING
	_down_t = 0.0

## 再開。すべての動きを止めて立ち姿に戻る。
func revive() -> void:
	_down = Down.NONE
	_action = ""
	_action_t = 0.0
	_pickup_t = 0.0
	_twist_t = 0.0
	_land_t = 0.0
	_loose_t = 0.0
	_hurt_t = 0.0
	_charge = -1.0
	_climb = 0.0
	_moving = false
	_walk_dist = 0.0

## 今の姿（HeroModel.build の pose）。"" は立ち姿。
func pose() -> String:
	match _down:
		Down.DYING:
			return "down" if _down_t >= KNEEL_TIME else ""
		Down.FALLING:
			return "climb"
	if _action != "":
		return _action
	if _climb > 0.0:
		return "climb"
	if _charge >= 0.0:
		return "draw_full" if _charge >= 1.0 else "draw"
	if not _moving:
		return ""
	return WALK_POSES[int(_walk_dist / STEP_PX) % WALK_POSES.size()]

## 体を下げる量（ゲームの座標のpx）。
func bob() -> float:
	return BOB_PX if pose().begins_with("step") else 0.0

## 描かない下の輪切りの数（拾うときにかがんで戻る。倒れるときはひざをつく）。
func dip_layers() -> int:
	if _down == Down.DYING and _down_t < KNEEL_TIME:
		var k := _down_t / KNEEL_TIME
		return maxi(1, roundi(KNEEL_DIP * sin(k * PI * 0.5)))
	if _pickup_t <= 0.0:
		return 0
	return roundi(PICKUP_DIP * sin(PI * (1.0 - _pickup_t / PICKUP_TIME)))

## 向きに足す回転（ラジアン）。
func twist() -> float:
	if _down != Down.NONE or _twist_t <= 0.0 or _twist_len <= 0.0:
		return 0.0
	var k := 1.0 - _twist_t / _twist_len  # 0 → 1
	if _spin:
		return TAU * k
	return lerpf(-SWING_TWIST, SWING_TWIST, k)

## 向いている方へずらす量（ゲームの座標のpx。後ろは負）。突きの踏み込み、弓の反動、ダメージののけぞり。
func forward_px() -> float:
	var f := 0.0
	if _action == "thrust" and _action_len > 0.0:
		f += THRUST_PX * sin(PI * (1.0 - _action_t / _action_len))
	f -= LOOSE_PX * _loose_t / LOOSE_TIME
	f -= HURT_PX * _hurt_t / HURT_TIME
	return f

## よじ登りで体が上がる量（ゲームの座標のpx）。
func climb_lift() -> float:
	if _down != Down.NONE:
		return 0.0
	return CLIMB_LIFT_PX * _climb

## 杖の先の光の強さ（0〜1）。
func cast_flash() -> float:
	if _action != "cast" or _action_len <= 0.0:
		return 0.0
	return _action_t / _action_len

## ダメージの赤い光の強さ（0〜1）。
func hurt_flash() -> float:
	return _hurt_t / HURT_TIME

## 薬を飲んでいる進み具合（0〜1。飲んでいなければ負）。回復のきらめきに使う。
func drink_progress() -> float:
	if _action != "drink" or _action_len <= 0.0:
		return -1.0
	return 1.0 - _action_t / _action_len

## 輪切りの間の詰め方（着地で縮む）。
func stretch() -> float:
	if _land_t <= 0.0:
		return 1.0
	return lerpf(1.0, LAND_SQUASH, _land_t / LAND_TIME)
