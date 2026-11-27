class_name Bgm
extends Node
## 曲を鳴らす（2026-11-27。パズルから写した）。曲は BgmSynth が作る。はじめて使う曲は別のスレッドで作り（数秒）、user://bgm/ に取っておく。
## play(名前) で曲を替える（前の曲は FADE 秒で小さくなり、次の曲が大きくなる）。level は設定の大きさ（0 なし〜3 大）。

const FADE := 0.8
const LEVEL_DB := [-80.0, -18.0, -11.0, -5.0]
const DIR := "user://bgm"

static var level := 2

var want := ""
var _players: Array = []
## 鳴らしている曲の名前（_players と同じ順）と、いまの大きさ（0〜1）
var _names := ["", ""]
var _amp := [0.0, 0.0]
var _streams := {}
var _task := -1
var _task_name := ""
var _task_bytes := PackedByteArray()
## 手があいたときに先に作っておく曲（まだ取っていないものだけ）
var _warm: Array = []

func _ready() -> void:
	BgmSynth._make_noise()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)

## 曲を替える（"" で止める）。同じ曲なら何もしない。
func play(name: String) -> void:
	if name == want:
		return
	want = name
	if name != "" and not _streams.has(name):
		_load(name)

## 手があいたときに作っておく（次に鳴らすときに待たない）。
func warm(names: Array) -> void:
	_warm = names.duplicate()

## 地方の見た目（AreaDef.theme）→ 曲。ボスと戦っている間は boss（闇の王とブライトは last）、タイトルは title。
const THEME_TRACKS := {"town": "town", "grass": "field", "mountain": "mountain", "castle": "castle", "lava": "lava",
	"tower": "tower", "mist": "mist"}

static func track_for(theme: String, boss_group := "", title := false) -> String:
	if title:
		return "title"
	if boss_group != "":
		return "last" if boss_group in ["闇の王", "ブライト"] else "boss"
	return THEME_TRACKS.get(theme, "field")

func _path(name: String) -> String:
	return "%s/%s_v%d.pcm" % [DIR, name, BgmSynth.VERSION]

func _load(name: String) -> void:
	if FileAccess.file_exists(_path(name)):
		var bytes := FileAccess.get_file_as_bytes(_path(name))
		if bytes.size() > 0:
			_streams[name] = BgmSynth.to_stream(bytes)
			return
	_start_render()

func _start_render() -> void:
	if _task >= 0:
		return
	var name := want
	if name == "" or _streams.has(name):
		name = ""
		while not _warm.is_empty() and name == "":
			var n: String = _warm.pop_front()
			if not _streams.has(n) and not FileAccess.file_exists(_path(n)):
				name = n
	if name == "":
		return
	_task_name = name
	_task = WorkerThreadPool.add_task(func(): _task_bytes = BgmSynth.to_bytes(BgmSynth.render(_task_name)))

func _process(delta: float) -> void:
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_streams[_task_name] = BgmSynth.to_stream(_task_bytes)
		DirAccess.make_dir_recursive_absolute(DIR)
		var f := FileAccess.open(_path(_task_name), FileAccess.WRITE)
		if f:
			f.store_buffer(_task_bytes)
		_task_bytes = PackedByteArray()
		_start_render()
	elif _task < 0 and not _warm.is_empty():
		_start_render()
	# 鳴らす曲を、どちらかの鳴らす所に入れる
	if want != "" and _streams.has(want) and not _names.has(want):
		var k := 0 if _amp[0] <= _amp[1] else 1
		var p: AudioStreamPlayer = _players[k]
		p.stream = _streams[want]
		p.play()
		_names[k] = want
		_amp[k] = 0.0
	for k in 2:
		var target := 1.0 if _names[k] == want and want != "" else 0.0
		_amp[k] = move_toward(_amp[k], target, delta / FADE)
		var p: AudioStreamPlayer = _players[k]
		if _amp[k] <= 0.0 and _names[k] != want:
			if p.playing:
				p.stop()
			_names[k] = ""
		p.volume_db = LEVEL_DB[level] + linear_to_db(maxf(0.0001, _amp[k]))

func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
