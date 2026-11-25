class_name Sfx
extends RefCounted
## 効果音を鳴らす（2026-11-26 の3回目の直し）。音は SfxSynth がコードで作り、最初に使うときか warm_step で用意する。
## field.gd が attach(自分) で鳴らす所（AudioStreamPlayer をいくつか）を作る。attach していなければ鳴らさない（記録だけ）。
## play(名前, 場所) の場所が主人公（listener）から遠いほど小さく、FAR より遠ければ鳴らさない。

const VOICES := 16  ## 同時に鳴らせる数
const FAR := 280.0  ## これより遠い音は鳴らさない（ゲームの座標のpx）
const FAR_DB := 14.0  ## FAR のときに下げる大きさ（dB）
const MIN_GAP := 0.035  ## 同じ音を続けて鳴らすときの最短の間（秒）
## 設定の大きさ（0 なし・1 小・2 中・3 大）ごとに足す dB
const LEVEL_DB := [-80.0, -14.0, -7.0, 0.0]

static var level := 2
static var listener := Vector2.ZERO
static var _players: Array = []
static var _next := 0
static var _streams := {}
static var _last := {}
static var _warm_names: Array = []
## 鳴らした音の名前（新しい順に HISTORY_MAX まで。テストと確かめに使う）
static var history: Array = []
const HISTORY_MAX := 64

## node の下に鳴らす所を作る（前のものは捨てる）。
static func attach(node: Node) -> void:
	_players.clear()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		node.add_child(p)
		_players.append(p)
	_next = 0

## 名前の音（なければ作る）。
static func stream(name: String) -> AudioStreamWAV:
	if not _streams.has(name):
		_streams[name] = SfxSynth.to_stream(SfxSynth.render(name))
	return _streams[name]

## 音を少しずつ用意する（1フレームに budget_ms まで）。すべて用意できたら true。
static func warm_step(budget_ms := 3.0) -> bool:
	if _warm_names.is_empty() and _streams.size() < SfxSynth.RECIPES.size():
		for n in SfxSynth.RECIPES:
			if not _streams.has(n):
				_warm_names.append(n)
	var start := Time.get_ticks_usec()
	while not _warm_names.is_empty() and (Time.get_ticks_usec() - start) < budget_ms * 1000.0:
		stream(_warm_names.pop_back())
	return _warm_names.is_empty()

## 鳴らす。at（ワールドの位置）があれば、主人公から遠いほど小さい。pitch_var は高さのばらつき。
static func play(name: String, at = null, db := 0.0, pitch_var := 0.06) -> void:
	if not SfxSynth.RECIPES.has(name):
		push_warning("効果音がない：%s" % name)
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(name, -1.0)) < MIN_GAP:
		return
	var vol := db + float(LEVEL_DB[clampi(level, 0, 3)])
	if at != null:
		var d: float = (at as Vector2).distance_to(listener)
		if d > FAR:
			return
		vol -= d / FAR * FAR_DB
	_last[name] = now
	history.push_front(name)
	if history.size() > HISTORY_MAX:
		history.pop_back()
	if level <= 0 or _players.is_empty():
		return
	var p = _players[_next]
	_next = (_next + 1) % _players.size()
	if not is_instance_valid(p) or not p.is_inside_tree():
		return
	p.stream = stream(name)
	p.volume_db = vol
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()

## 鳴らした回数（history の中で）。
static func count(name: String) -> int:
	return history.count(name)

static func clear_history() -> void:
	history.clear()
	_last.clear()
