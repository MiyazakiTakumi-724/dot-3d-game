class_name GameSettings
extends RefCounted
## 設定（インベントリ画面の「設定」のページで変える）。難易度と、画面が白く光る演出の強さ。
## 簡単モードでは、敵から受けるダメージだけが半分になる（design.md 13章）。
## 光を弱める（2026-11-25 の設計 5章）：ブライトの光で画面が白くなるのを、弱く（0.4）できる。

var easy_mode := false
var soft_flash := false
## 効果音の大きさ（0 なし・1 小・2 中・3 大。2026-11-26）
var sfx_level := 2
## 全画面か（false ならウィンドウ。F11 でも切りかえる。2026-11-26）
var fullscreen := true
## 画面のゆれ（鉄球が落ちた・爆発など）。弱い人のために切れる（2026-11-26 独自の開発1）
var shake := true
## カメラを回している間だけ、時間がゆっくり進む（design.md 5章でユーザーが「後で付ける」と決めたもの。2026-11-26）
var slow_turn := false
## 回している間の時間の速さ
const SLOW_TURN_SCALE := 0.35

## 設定は冒険とは別に、ここに保存する（どのセーブを選んでも同じ）
const FILE := "user://settings.json"

const SFX_NAMES := ["なし", "小", "中", "大"]

## 設定のページで見せる、操作の一覧（2026-11-26：遊ぶ画面には出さず、ここで見る）
const CONTROLS := [
	["WASD・矢印", "移動"],
	["左クリック", "手に持つ物を使う"],
	["", "弓は押して溜め、離して撃つ"],
	["1〜5", "持ちかえ（鉄球・剣・弓・杖・道具）"],
	["ホイール", "杖の魔法・道具を替える"],
	["右ドラッグ・Q/E", "カメラを回す"],
	["F", "宝箱・レバー・門・商人と話す"],
	["Tab・M", "持ち物・全体マップ"],
	["Space・C", "回転斬り・しゃがむ（技能）"],
	["F11", "全画面とウィンドウ"],
]

## 画面を白くする光の強さ（0〜1）。
func flash_strength() -> float:
	return 0.4 if soft_flash else 1.0


# ---------------------------------------------------------------- 保存（2026-11-26 独自の開発1）

func to_dict() -> Dictionary:
	return {"easy_mode": easy_mode, "soft_flash": soft_flash, "sfx_level": sfx_level,
		"fullscreen": fullscreen, "shake": shake, "slow_turn": slow_turn}

func load_dict(d: Dictionary) -> void:
	easy_mode = bool(d.get("easy_mode", easy_mode))
	soft_flash = bool(d.get("soft_flash", soft_flash))
	sfx_level = clampi(int(d.get("sfx_level", sfx_level)), 0, SFX_NAMES.size() - 1)
	fullscreen = bool(d.get("fullscreen", fullscreen))
	shake = bool(d.get("shake", shake))
	slow_turn = bool(d.get("slow_turn", slow_turn))

func save_file(path := FILE) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()
	return true

## 保存した設定を読む。ないか壊れていれば false（今の値のまま）。
func load_file(path := FILE) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(path)) != OK or not j.data is Dictionary:
		return false
	var d: Dictionary = j.data
	load_dict(d)
	return true
