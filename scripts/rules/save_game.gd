class_name SaveGame
extends RefCounted
## セーブとロード（2026-11-26 独自の開発1）。冒険の状態（RunState）を JSON にして、3つの枠（スロット）の1つに書く。
## セーブするのは、たき火で休んだとき・たき火から移ったとき・エリアを移ったとき・ボスを倒したとき・止める画面でやめるとき。
## ロードすると、最後に休んだたき火から始まる（その場所でなく）【提案】。

const SLOTS := 3
const DEFAULT_DIR := "user://"
## テストでは別の所に書く
static var dir := DEFAULT_DIR

static func path(slot: int) -> String:
	return dir + "save_%d.json" % slot

static func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))

## 冒険の状態を枠 slot に書く。place は一覧に出す場所の名前。
static func write(slot: int, run: RunState, place: String) -> bool:
	DirAccess.make_dir_recursive_absolute(dir)
	var d := run.to_dict()
	d["place"] = place
	d["saved_at"] = Time.get_datetime_string_from_system(false, true)
	var tmp := path(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d))
	f.close()
	# 書いている途中で落ちても前のセーブが残るように、書き終えてから入れ替える
	if DirAccess.rename_absolute(tmp, path(slot)) != OK:
		return false
	return true

static func _load(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(path(slot))) != OK:
		return {}  # 壊れたファイルは無いものとして扱う
	var d = j.data
	return d if d is Dictionary and d.has("version") else {}

## 枠 slot を run に読み込む。ないか壊れていれば false（run はそのまま）。
static func read(slot: int, run: RunState) -> bool:
	var d := _load(slot)
	if d.is_empty():
		return false
	run.load_dict(d)
	return true

## 一覧に出す中身。ないか壊れていれば空。
static func summary(slot: int) -> Dictionary:
	var d := _load(slot)
	if d.is_empty():
		return {}
	var st: Dictionary = d.get("stats", {})
	return {
		"level": int(st.get("level", 1)),
		"place": str(d.get("place", "")),
		"bosses": (d.get("bosses", []) as Array).size(),
		"play_time": float(d.get("play_time", 0.0)),
		"cleared": bool(d.get("cleared", false)),
		"saved_at": str(d.get("saved_at", "")),
	}

static func erase(slot: int) -> void:
	if exists(slot):
		DirAccess.remove_absolute(path(slot))

## 遊んだ時間を「時:分」で。
static func time_text(seconds: float) -> String:
	var m := int(seconds) / 60
	return "%d:%02d" % [m / 60, m % 60]
