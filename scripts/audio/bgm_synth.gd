class_name BgmSynth
extends RefCounted
## 曲（BGM）をコードで作る（2026-11-27。パズル「箱庭外伝」の作り方を写し、曲を灯りの瞳の地方に合わせた。曲の中身は【提案】）。
## 曲ごとに、速さ・調・和音の進み・楽器の組み合わせを決め、旋律は決まった種（seed）の乱数で作る（同じ名前なら毎回同じ曲）。
## 16小節（A A' B A''）で、終わりの音の余韻ははじめへ回り込むので、つなぎ目なく繰り返せる。
## 1曲 16小節を作るのに数秒かかるので、Bgm が別のスレッドで作り、user:// に取っておく（VERSION を変えると作り直す）。

const RATE := 22050
const VERSION := 1
const BARS := 16
const SCALES := {"major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10]}
const PULSE := 0
const TRI := 1
const SINE := 2

## 曲。root は主音（MIDI の番号）。prog_a・prog_b は小節ごとの和音（音階の何番目か、0 から）。
## lead：旋律（wave・duty・vol・oct は主音からのオクターブ・rest は休む割合）、bass：低音の型、pad：和音をのばす大きさ、
## arp：和音を分けて鳴らす（0 でなし、8 か 16 で細かさ）、drums：打楽器の型。
const TRACKS := {
	"title": {"name": "灯りのまどろみ", "bpm": 76, "root": 62, "scale": "major", "seed": 11,
		"prog_a": [0, 5, 3, 4], "prog_b": [3, 4, 2, 5],
		"lead": {"wave": TRI, "duty": 0.5, "vol": 0.20, "oct": 1, "rest": 0.35},
		"bass": "whole", "pad": 0.035, "arp": 8, "arp_vol": 0.045, "drums": "none"},
	"town": {"name": "はじまりの町", "bpm": 92, "root": 65, "scale": "major", "seed": 17,
		"prog_a": [0, 3, 4, 0], "prog_b": [5, 3, 1, 4],
		"lead": {"wave": TRI, "duty": 0.5, "vol": 0.18, "oct": 1, "rest": 0.3},
		"bass": "root5", "pad": 0.03, "arp": 8, "arp_vol": 0.035, "drums": "light"},
	"field": {"name": "草原をゆく", "bpm": 104, "root": 67, "scale": "major", "seed": 23,
		"prog_a": [0, 3, 0, 4], "prog_b": [5, 3, 0, 4],
		"lead": {"wave": PULSE, "duty": 0.25, "vol": 0.11, "oct": 0, "rest": 0.2},
		"bass": "root5", "pad": 0.025, "arp": 0, "arp_vol": 0.0, "drums": "light"},
	"mountain": {"name": "風の峠", "bpm": 96, "root": 69, "scale": "minor", "seed": 37,
		"prog_a": [0, 6, 5, 6], "prog_b": [3, 0, 5, 4],
		"lead": {"wave": PULSE, "duty": 0.5, "vol": 0.09, "oct": 0, "rest": 0.25},
		"bass": "walk", "pad": 0.03, "arp": 16, "arp_vol": 0.03, "drums": "beat"},
	"castle": {"name": "崩れた城", "bpm": 84, "root": 64, "scale": "minor", "seed": 41,
		"prog_a": [0, 5, 3, 4], "prog_b": [5, 6, 0, 4],
		"lead": {"wave": TRI, "duty": 0.5, "vol": 0.17, "oct": 1, "rest": 0.3},
		"bass": "whole", "pad": 0.04, "arp": 16, "arp_vol": 0.03, "drums": "none"},
	"lava": {"name": "灰と炎", "bpm": 120, "root": 60, "scale": "minor", "seed": 47,
		"prog_a": [0, 0, 5, 6], "prog_b": [3, 4, 5, 6],
		"lead": {"wave": PULSE, "duty": 0.25, "vol": 0.09, "oct": 0, "rest": 0.18},
		"bass": "drive", "pad": 0.02, "arp": 0, "arp_vol": 0.0, "drums": "beat"},
	"tower": {"name": "見通す塔", "bpm": 70, "root": 66, "scale": "minor", "seed": 59,
		"prog_a": [0, 5, 2, 6], "prog_b": [3, 0, 4, 4],
		"lead": {"wave": SINE, "duty": 0.5, "vol": 0.22, "oct": 1, "rest": 0.4},
		"bass": "whole", "pad": 0.045, "arp": 16, "arp_vol": 0.035, "drums": "none"},
	"mist": {"name": "霧の谷", "bpm": 66, "root": 62, "scale": "minor", "seed": 61,
		"prog_a": [0, 3, 5, 4], "prog_b": [5, 3, 6, 4],
		"lead": {"wave": TRI, "duty": 0.5, "vol": 0.2, "oct": 1, "rest": 0.45},
		"bass": "whole", "pad": 0.04, "arp": 8, "arp_vol": 0.03, "drums": "none"},
	"boss": {"name": "ぬし", "bpm": 138, "root": 64, "scale": "minor", "seed": 53,
		"prog_a": [0, 5, 6, 0], "prog_b": [3, 6, 5, 4],
		"lead": {"wave": PULSE, "duty": 0.125, "vol": 0.09, "oct": 0, "rest": 0.12},
		"bass": "drive", "pad": 0.02, "arp": 0, "arp_vol": 0.0, "drums": "drive"},
	"last": {"name": "闇と光", "bpm": 150, "root": 59, "scale": "minor", "seed": 71,
		"prog_a": [0, 6, 5, 4], "prog_b": [3, 4, 5, 6],
		"lead": {"wave": PULSE, "duty": 0.125, "vol": 0.085, "oct": 1, "rest": 0.1},
		"bass": "drive", "pad": 0.025, "arp": 16, "arp_vol": 0.025, "drums": "drive"},
}

static var _noise := PackedFloat32Array()

## 曲の波形（-1〜1、RATE Hz、bars 小節ちょうど）。テストでは bars を小さくして速く作る。
static func render(name: String, bars := BARS) -> PackedFloat32Array:
	var t: Dictionary = TRACKS[name]
	_make_noise()
	var beat := 60.0 / float(t["bpm"])
	var n := int(round(bars * 4 * beat * RATE))
	var out := PackedFloat32Array()
	out.resize(n)
	var slot := beat / 2.0  # 8分音符
	var scale: Array = SCALES[t["scale"]]
	var root: int = int(t["root"])
	for b in bars:
		var chord: int = _chord_of(t, b)
		var bar_t := b * 4 * beat
		# 和音をのばす
		if float(t["pad"]) > 0.0:
			var freqs: Array = []
			for k: int in [0, 2, 4]:
				freqs.append(_freq(root - 12 + _deg(scale, chord + k)))
			_pad(out, bar_t, 4 * beat, freqs, float(t["pad"]))
		# 低音
		for p in _bass_pattern(t["bass"]):
			var m: int = root - 24 + _deg(scale, chord) + int(p[2])
			if _deg(scale, chord) > 7:
				m -= 12
			_tone(out, bar_t + int(p[0]) * slot, int(p[1]) * slot * 0.92, _freq(m), TRI, 0.22, 0.006, 0.05)
		# 和音を分けて鳴らす
		var arp: int = int(t["arp"])
		if arp > 0:
			var step := 4 * beat / arp
			var tones := [0, 2, 4, 7]
			for k in arp:
				var m: int = root + _deg(scale, chord + int(tones[k % 4]))
				_tone(out, bar_t + k * step, step * 0.8, _freq(m), TRI, float(t["arp_vol"]), 0.004, 0.04)
		_drums(out, bar_t, beat, t["drums"])
	# 旋律
	var lead: Dictionary = t["lead"]
	for note in _melody(t, bars):
		var m: int = root + 12 * int(lead["oct"]) + _deg(scale, int(note[2]))
		_tone(out, int(note[0]) * slot, int(note[1]) * slot * 0.94, _freq(m), int(lead["wave"]), float(lead["vol"]), 0.008, 0.09,
			float(lead["duty"]), 0.012)
	# 大きさをそろえる（一番大きい所を 0.8 に）
	var peak := 0.0
	for v in out:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		var g := 0.8 / peak
		for i in n:
			out[i] *= g
	return out

## Godot の音（16bit・1チャンネル）のバイト列に。
static func to_bytes(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	return bytes

## 繰り返して鳴らす音にする。
static func to_stream(bytes: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = bytes.size() / 2
	return s

static func _chord_of(t: Dictionary, bar: int) -> int:
	var phrase := (bar / 4) % 4
	var prog: Array = t["prog_b"] if phrase == 2 else t["prog_a"]
	return prog[bar % 4]

## 音階の d 番目（7 で1オクターブ上）の、主音からの半音の数。
static func _deg(scale: Array, d: int) -> int:
	return 12 * floori(d / 7.0) + scale[posmod(d, 7)]

static func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)

## 旋律：[はじめ（8分音符の何個目）, 長さ（8分音符の数）, 音階の何番目]。
## 4小節ずつ A・A'・B・A''。A' と A'' は A の最後の小節だけ変え、A'' は主音で終わる。
static func _melody(t: Dictionary, bars: int) -> Array:
	var notes: Array = []
	var lead: Dictionary = t["lead"]
	var rest: float = float(lead["rest"])
	for phrase in ceili(bars / 4.0):
		var kind := phrase % 4
		var rng := RandomNumberGenerator.new()
		rng.seed = int(t["seed"]) + (100 if kind == 2 else 0)
		var cur := 7  # 1オクターブ上の主音から
		for b in 4:
			var bar := phrase * 4 + b
			if bar >= bars:
				break
			if b == 3 and kind != 2:
				rng.seed = int(t["seed"]) + 10 + kind
			var chord: int = _chord_of(t, bar)
			var base := bar * 8
			var s := 0
			while s < 8:
				if b == 3 and s >= 4:
					# 句の終わり：長くのばす（最後の句は主音）
					var target: int = 7 if kind == 3 else _nearest_chord_tone(cur, chord)
					notes.append([base + s, 8 - s, target])
					cur = target
					break
				var r := rng.randf()
				var length := 1
				if s == 0 or s == 4:
					if r < 0.85:
						cur = _nearest_chord_tone(cur, chord)
					length = 2 if rng.randf() < 0.6 else 1
				else:
					if r < rest:
						s += 1
						continue
					var mv := rng.randf()
					var step := 0
					if mv < 0.32:
						step = 1
					elif mv < 0.64:
						step = -1
					elif mv < 0.76:
						step = 2
					elif mv < 0.88:
						step = -2
					cur = clampi(cur + step, 3, 13)
					length = 1 if rng.randf() < 0.7 else 2
				length = mini(length, 8 - s)
				notes.append([base + s, length, cur])
				s += length
	return notes

static func _nearest_chord_tone(cur: int, chord: int) -> int:
	var best := cur
	var best_d := 99
	for o: int in [-7, 0, 7, 14]:
		for k: int in [0, 2, 4]:
			var d: int = chord + k + o
			if d < 3 or d > 13:
				continue
			if absi(d - cur) < best_d:
				best_d = absi(d - cur)
				best = d
	return best

## 低音の型：[はじめ, 長さ, 半音]（8分音符で）。
static func _bass_pattern(kind: String) -> Array:
	match kind:
		"whole":
			return [[0, 8, 0]]
		"root5":
			return [[0, 3, 0], [3, 1, 0], [4, 3, 7], [7, 1, 0]]
		"walk":
			return [[0, 2, 0], [2, 2, 7], [4, 2, 12], [6, 2, 7]]
		"drive":
			return [[0, 1, 0], [1, 1, 0], [2, 1, 12], [3, 1, 0], [4, 1, 0], [5, 1, 0], [6, 1, 12], [7, 1, 7]]
	return []

## 1つの音を足す。余韻が曲の終わりを越えたら、はじめへ回り込む（つなぎ目なく繰り返すため）。
static func _tone(out: PackedFloat32Array, start: float, dur: float, freq: float, wave: int, vol: float,
		attack: float, release: float, duty := 0.5, vib := 0.0) -> void:
	var n := out.size()
	var s0 := int(start * RATE)
	var hold := int(dur * RATE)
	var rel := maxi(1, int(release * RATE))
	var atk := maxf(1.0, attack * RATE)
	var decay := 0.3 * RATE
	var inc := freq / RATE
	var ph := 0.0
	var y := 0.0
	var vib_from := int(0.18 * RATE)
	var vib_w := TAU * 5.5 / RATE
	for i in hold + rel:
		var env: float
		if i < atk:
			env = i / atk
		elif i < hold:
			env = 1.0 - 0.35 * minf(1.0, (i - atk) / decay)
		else:
			env = (1.0 - 0.35 * minf(1.0, (hold - atk) / decay)) * (1.0 - float(i - hold) / rel)
		if vib > 0.0 and i > vib_from:
			ph += inc * (1.0 + vib * sin(vib_w * i))
		else:
			ph += inc
		ph -= floorf(ph)
		var x: float
		if wave == PULSE:
			x = 1.0 if ph < duty else -1.0
		elif wave == TRI:
			x = 4.0 * absf(ph - 0.5) - 1.0
		else:
			x = sin(TAU * ph)
		y += 0.3 * (x - y)  # 角を少し丸める
		out[(s0 + i) % n] += y * env * vol

## 和音をのばす（ゆっくり立ち上がって消える三角波）。
static func _pad(out: PackedFloat32Array, start: float, dur: float, freqs: Array, vol: float) -> void:
	var n := out.size()
	var s0 := int(start * RATE)
	var len := int(dur * RATE)
	var atk := 0.15 * RATE
	var rel := 0.25 * RATE
	var incs := PackedFloat32Array()
	var phs := PackedFloat32Array()
	for f in freqs:
		incs.append(f / RATE)
		phs.append(0.0)
	var total := len + int(rel)
	for i in total:
		var env := minf(1.0, i / atk)
		if i > len:
			env *= 1.0 - (i - len) / rel
		var x := 0.0
		for k in incs.size():
			phs[k] = fposmod(phs[k] + incs[k], 1.0)
			x += 4.0 * absf(phs[k] - 0.5) - 1.0
		out[(s0 + i) % n] += x * env * vol

## 打楽器（16分音符の位置で）。
static func _drums(out: PackedFloat32Array, bar_t: float, beat: float, kind: String) -> void:
	var kicks: Array = []
	var snares: Array = []
	var hats: Array = []
	match kind:
		"light":
			kicks = [0]
			hats = [0, 2, 4, 6, 8, 10, 12, 14]
		"beat":
			kicks = [0, 8, 10]
			snares = [4, 12]
			hats = [0, 2, 4, 6, 8, 10, 12, 14]
		"drive":
			kicks = [0, 4, 8, 12, 14]
			snares = [4, 12]
			hats = range(16)
		_:
			return
	var q := beat / 4.0
	for k: int in kicks:
		_kick(out, bar_t + k * q)
	for k: int in snares:
		_hit(out, bar_t + k * q, 0.09, 0.12, 0.25)
	for k: int in hats:
		_hit(out, bar_t + k * q, 0.025, 0.035 if k % 4 == 0 else 0.022, 0.9)

static func _kick(out: PackedFloat32Array, start: float) -> void:
	var n := out.size()
	var s0 := int(start * RATE)
	var len := int(0.14 * RATE)
	var ph := 0.0
	for i in len:
		var t := float(i) / len
		ph += (110.0 - 70.0 * t) / RATE
		out[(s0 + i) % n] += sin(TAU * ph) * (1.0 - t) * (1.0 - t) * 0.3

## 雑音の打楽器。bright が大きいほど高い音（シャカシャカ）、小さいとこもった音（スネア）。
static func _hit(out: PackedFloat32Array, start: float, dur: float, vol: float, bright: float) -> void:
	var n := out.size()
	var s0 := int(start * RATE)
	var len := int(dur * RATE)
	var lp := 0.0
	var off := (s0 * 7) % _noise.size()
	for i in len:
		var x := _noise[(off + i) % _noise.size()]
		lp += (1.0 - bright) * (x - lp)
		var v := x - lp if bright > 0.5 else lp
		var e := 1.0 - float(i) / len
		out[(s0 + i) % n] += v * e * e * vol

static func _make_noise() -> void:
	if not _noise.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_noise.resize(8192)
	for i in _noise.size():
		_noise[i] = rng.randf_range(-1.0, 1.0)
