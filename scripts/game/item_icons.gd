class_name ItemIcons
extends RefCounted
## 品物のアイコン（16×16のドット絵）をコードで作る（2026-11-25 夜の設計 2章）。一度作ったものは使い回す。
## 形は品物の種類（鉄球・剣・弓・杖・服・素材・薬・矢…）で決まり、色は品物ごと。まわりに暗いふちを付ける。
## ランクの色（RANK_COLORS）は、アイコンを置く枠の色に使う。

const SIZE := 16
const OUTLINE := Color(0.06, 0.05, 0.08)
## ランク1〜5の枠の色
const RANK_COLORS := [Color("6b7280"), Color("6b7280"), Color("4caf50"), Color("4a8fe0"), Color("b05ce0"), Color("f0b429")]

## 装備の色 [主な色, 差し色]
const GEAR_COLORS := {
	"ball_1": ["5a5f6a", "a8adb8"], "ball_heavy": ["3f434c", "8a8f9a"], "ball_wide": ["6a6f7a", "c8d0e0"],
	"ball_spike": ["4a5a4a", "9fd36a"], "ball_chain": ["5a5f6a", "c0a060"], "ball_ember": ["7a3a2a", "ff9a3a"],
	"ball_rock": ["6a6c73", "f0c040"], "ball_lava": ["5a2418", "ff7a2a"], "ball_quake": ["5a4a3a", "a0d0ff"],
	"ball_star": ["3a3a6a", "ffe066"], "ball_meteor": ["4a2a4a", "ff8040"],
	"sword_1": ["b8bec8", "7a5a3a"], "sword_light": ["d8e0ea", "4a7ab0"], "sword_bronze": ["c8904a", "6a4a2a"],
	"sword_poison": ["8fd06a", "4a3a5a"], "sword_long": ["c8d0da", "5a4a3a"], "sword_drain": ["c04a5a", "3a2a3a"],
	"sword_giant": ["9a9ca4", "f0c040"], "sword_flame": ["ff8a3a", "7a2a1a"], "sword_frost": ["a8e0ff", "3a5a8a"],
	"sword_star": ["fff0a0", "4a4aa0"], "sword_king": ["f0d060", "a02a3a"],
	"bow_1": ["8a5a2a", "e8e0d0"], "bow_short": ["a06a3a", "e8e0d0"], "bow_long": ["6a4a2a", "e8e0d0"],
	"bow_hunter": ["5a7a3a", "e8e0d0"], "bow_poison": ["4a6a3a", "9fe06a"], "bow_heavy": ["4a3a3a", "c0c0c0"],
	"bow_serpent": ["4a8a4a", "f0e040"], "bow_twin": ["c8c0b0", "4a6aff"], "bow_wind": ["8ac0a0", "e8fff0"],
	"bow_star": ["4a4aa0", "ffe066"], "bow_sun": ["e0a030", "fff0a0"],
	"staff_none_1": ["8a6a4a", "d8d8e0"], "staff_fire_2": ["7a5a3a", "ff7a2a"], "staff_ice_2": ["7a5a3a", "8ad8ff"],
	"staff_fire_3": ["5a3a2a", "ff5a2a"], "staff_ice_3": ["5a4a6a", "a8e8ff"], "staff_heal_3": ["c8b88a", "7aff9a"],
	"staff_lava": ["3a2a2a", "ff6a1a"], "staff_thunder": ["4a4a6a", "fff04a"], "staff_frost": ["5a6a8a", "e0f8ff"],
	"staff_star": ["3a3a6a", "ffe066"], "staff_storm": ["4a5a7a", "9ad0ff"],
	"armor_1": ["c8b898", "8a7a5a"], "armor_leather": ["8a5a3a", "5a3a2a"], "armor_travel": ["5a7a9a", "c8b080"],
	"armor_chain": ["9aa0aa", "5a606a"], "armor_scout": ["4a6a3a", "a08a5a"], "armor_mage": ["5a3a8a", "e0c060"],
	"armor_knight": ["b0b8c8", "a02a3a"], "armor_wind": ["7ad0c0", "e8fff8"], "armor_life": ["4a9a5a", "f0f0a0"],
	"armor_star": ["3a3a7a", "ffe066"], "armor_dragon": ["2a6a5a", "e04a2a"],
}

## 数で持つ品物の [形, 主な色, 差し色]
const OTHER := {
	"money": ["coin", "f0c040", "a07a10"],
	# 素材
	"hide": ["hide", "a0703a", "6a4a2a"], "bone": ["bone", "eee8d5", "a89f8a"], "scrap": ["scrap", "8a8f9a", "5a5f6a"],
	"wood": ["stick", "8a5a2a", "c08a4a"], "herb": ["leaf", "5ab04a", "2a7a2a"], "iron_ore": ["ore", "6a6a72", "c0784a"],
	"snow": ["flake", "e0f4ff", "8ac8f0"], "scale": ["scale", "4a9a6a", "a0e0a0"], "old_steel": ["ingot", "7a8088", "b0b8c0"],
	"silver": ["shard", "d8dce8", "8a90a8"], "obsidian": ["shard", "2a2430", "6a5a8a"], "fire_stone": ["gem", "e04a2a", "ffb04a"],
	"star_shard": ["star", "ffe066", "fff8d0"],
	"power_crystal": ["shard", "e05ad0", "ffd0f8"], "ancient_crystal": ["shard", "5ae0e0", "f0ffff"],
	"giant_core": ["orb", "9a9ca4", "f0c040"], "serpent_fang": ["fang", "f0ecd8", "4a8a4a"], "lava_heart": ["heart", "e0401a", "ffb03a"],
	"crest": ["crest", "a02a3a", "f0d060"], "cave_gem": ["gem", "4ad0c0", "e0fff8"], "flame_tail": ["tail", "e0602a", "ffd04a"],
	"twin_mirror": ["mirror", "c8c0b0", "8ab0ff"], "gear": ["cog", "b0a890", "6a6050"], "bright_eye": ["eye", "fff0a0", "2a2a60"],
	"queen_sting": ["fang", "f0c040", "3a2a1a"], "king_crown": ["crown", "f0c040", "c02a4a"],
	"seal_mt": ["seal", "8d8f94", "e0e8f0"], "seal_gr": ["seal", "5a9a4a", "e0f0a0"], "seal_cs": ["seal", "7a6a9a", "f0d060"],
	"seal_lv": ["seal", "a03a1a", "ffb03a"],
	# 道具
	"potion": ["flask", "e04a5a", "ffd0d8"], "potion_m": ["flask", "c02a5a", "ffb0c8"], "potion_l": ["flask_big", "a01a4a", "ffa0c0"],
	"ether": ["flask", "3a7ae0", "c0e0ff"], "power": ["flask", "e07a1a", "ffe0a0"], "guard": ["flask", "7a8aa0", "e0e8f0"],
	"swift": ["flask", "3ac08a", "d0fff0"], "feather": ["feather", "f0f0f8", "a0b0d0"], "bomb": ["bomb", "2a2a34", "ff9a3a"],
	# 矢
	"arrow": ["arrow", "c8ccd4", "8a5a2a"], "arrow_poison": ["arrow", "8fe06a", "4a6a2a"], "arrow_fire": ["arrow", "ff7a2a", "7a2a1a"],
	"arrow_iron": ["arrow", "7a808a", "3a3f48"],
}

static var _cache := {}

## 品物 id のアイコン（16×16）。知らない id は「？」の箱。
static func texture(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var img := image(id)
	var t := ImageTexture.create_from_image(img)
	_cache[id] = t
	return t

## ランクの枠の色（装備でなければランク1の色）。
static func rank_color(id: String) -> Color:
	return RANK_COLORS[clampi(ItemCatalog.rank(id), 0, 5)]

static func image(id: String) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if ItemCatalog.exists(id):
		var c: Array = GEAR_COLORS.get(id, ["9a9aa0", "e0e0e8"])
		var a := Color(c[0])
		var b := Color(c[1])
		match ItemCatalog.slot(id):
			Equipment.Slot.BALL: _ball(img, a, b, id)
			Equipment.Slot.SWORD: _sword(img, a, b, ItemCatalog.rank(id))
			Equipment.Slot.BOW: _bow(img, a, b)
			Equipment.Slot.STAFF: _staff(img, a, b, ItemCatalog.rank(id))
			_: _armor(img, a, b)
	elif OTHER.has(id):
		var o: Array = OTHER[id]
		_shape(img, o[0], Color(o[1]), Color(o[2]))
	else:
		_rect(img, 3, 3, 12, 12, Color("5a5f6a"))
		_rect(img, 7, 5, 8, 9, Color.WHITE)
		_px(img, 7, 11, Color.WHITE)
	_outline(img)
	return img

# ---------------------------------------------------------------- 形

static func _ball(img: Image, a: Color, b: Color, id: String) -> void:
	_disc(img, 8, 9, 5.5, a)
	_disc(img, 6.5, 7.5, 2.0, a.lightened(0.3))
	_px(img, 6, 6, b.lightened(0.4))
	if id == "ball_spike":
		for p in [Vector2i(8, 2), Vector2i(14, 9), Vector2i(8, 15), Vector2i(2, 9), Vector2i(12, 4), Vector2i(4, 4), Vector2i(12, 13), Vector2i(4, 13)]:
			_px(img, p.x, p.y, b)
	elif id == "ball_chain":
		for i in 4:
			_px(img, 11 + i, 4 - i, b)
	elif id in ["ball_star", "ball_meteor", "ball_rock", "ball_lava", "ball_ember", "ball_quake"]:
		_px(img, 9, 10, b)
		_px(img, 10, 9, b)
		_px(img, 8, 11, b)
		_px(img, 10, 11, b.darkened(0.2))

static func _sword(img: Image, a: Color, b: Color, rank: int) -> void:
	var length := 9 + mini(rank, 4)
	for i in length:
		var x := 3 + i
		var y := 12 - i
		if x > 14 or y < 1:
			break
		_px(img, x, y, a)
		_px(img, x + 1, y, a.darkened(0.25))
	_px(img, 3, 12, a.lightened(0.3))
	# つばと柄
	_line(img, Vector2i(1, 10), Vector2i(5, 14), b)
	_px(img, 2, 13, b.darkened(0.3))
	_px(img, 1, 14, b.darkened(0.3))
	_px(img, 1, 15, b.lightened(0.2))

static func _bow(img: Image, a: Color, b: Color) -> void:
	for i in 13:
		var t := (i - 6) / 6.0
		var x := 4 + int(round(4.0 * (1.0 - t * t)))
		_px(img, x, 2 + i, a)
		_px(img, x + 1, 2 + i, a.darkened(0.2))
	for y in range(2, 15):
		_px(img, 4, y, b)
	_px(img, 9, 8, a.lightened(0.3))

static func _staff(img: Image, a: Color, b: Color, rank: int) -> void:
	_line(img, Vector2i(3, 14), Vector2i(10, 5), a)
	_line(img, Vector2i(4, 14), Vector2i(11, 5), a.darkened(0.25))
	var r := 2.0 + minf(rank, 5) * 0.3
	_disc(img, 11.5, 4.0, r, b)
	_px(img, 11, 3, b.lightened(0.5))

static func _armor(img: Image, a: Color, b: Color) -> void:
	for y in range(3, 15):
		var half := 4 if y < 6 else 5
		if y >= 6 and y < 9:
			half = 6
		for x in range(8 - half, 8 + half):
			var c := a if x < 8 else a.darkened(0.15)
			_px(img, x, y, c)
	for y in range(2, 5):
		_px(img, 6, y, Color(0, 0, 0, 0))
		_px(img, 9, y, Color(0, 0, 0, 0))
	_rect(img, 7, 3, 8, 4, Color(0, 0, 0, 0))
	_rect(img, 3, 9, 12, 9, b)
	_px(img, 7, 6, b)
	_px(img, 8, 7, b)

static func _shape(img: Image, kind: String, a: Color, b: Color) -> void:
	match kind:
		"coin":
			_disc(img, 8, 8, 5.5, a)
			_disc(img, 8, 8, 3.5, a.lightened(0.15))
			_rect(img, 8, 5, 8, 11, b)
		"hide":
			_disc(img, 8, 8, 5.5, a)
			for p in [Vector2i(3, 3), Vector2i(12, 3), Vector2i(3, 13), Vector2i(12, 13)]:
				_px(img, p.x, p.y, a)
			_px(img, 6, 6, b)
			_px(img, 10, 9, b)
		"bone":
			_line(img, Vector2i(4, 12), Vector2i(12, 4), a)
			_line(img, Vector2i(4, 11), Vector2i(11, 4), a)
			for p in [Vector2i(3, 11), Vector2i(4, 13), Vector2i(11, 3), Vector2i(13, 4)]:
				_disc(img, p.x, p.y, 1.2, a)
			_px(img, 8, 9, b)
		"scrap":
			_rect(img, 3, 8, 7, 12, a)
			_rect(img, 8, 5, 12, 9, b)
			_rect(img, 9, 11, 12, 13, a.darkened(0.2))
		"stick":
			_line(img, Vector2i(3, 13), Vector2i(13, 3), a)
			_line(img, Vector2i(4, 13), Vector2i(13, 4), b)
			_line(img, Vector2i(8, 8), Vector2i(11, 10), a)
		"leaf":
			for i in 9:
				var w := int(round(sin(i / 8.0 * PI) * 3.0))
				for d in range(-w, w + 1):
					_px(img, 4 + i + d, 12 - i + d, a)
					_px(img, 5 + i + d, 12 - i + d, a)
			_line(img, Vector2i(3, 13), Vector2i(12, 4), b)
		"ore":
			_disc(img, 8, 9, 5.0, a)
			_px(img, 6, 7, b)
			_px(img, 10, 10, b)
			_px(img, 9, 7, b.lightened(0.3))
		"flake":
			_line(img, Vector2i(8, 2), Vector2i(8, 14), a)
			_line(img, Vector2i(3, 5), Vector2i(13, 11), a)
			_line(img, Vector2i(3, 11), Vector2i(13, 5), a)
			_px(img, 8, 8, b)
		"scale":
			for y in [4, 8, 12]:
				for x in [4, 8, 12]:
					_disc(img, x - (2 if y == 8 else 0), y, 2.0, a if (x + y) % 3 else b)
		"ingot":
			_rect(img, 2, 7, 13, 11, a)
			_rect(img, 4, 5, 11, 7, b)
		"shard":
			for i in 11:
				var w := 4 - absi(i - 5) / 2
				for d in range(w):
					_px(img, 6 + d + i / 3, 2 + i, a if d < w - 1 else b)
			_px(img, 8, 5, b.lightened(0.3))
		"gem":
			_disc(img, 8, 8, 4.5, a)
			_rect(img, 6, 6, 7, 7, b)
			_px(img, 8, 5, b.lightened(0.4))
		"star":
			for i in 5:
				var ang := -PI / 2 + i * TAU / 5.0
				_line(img, Vector2i(8, 8), Vector2i(8 + int(round(cos(ang) * 6.0)), 8 + int(round(sin(ang) * 6.0))), a)
			_disc(img, 8, 8, 2.5, a)
			_px(img, 8, 8, b)
		"orb":
			_disc(img, 8, 8, 5.5, a)
			_disc(img, 8, 8, 2.5, b)
		"fang":
			for i in 11:
				var w := maxi(1, 3 - i / 4)
				for d in range(w):
					_px(img, 6 + d + i / 3, 2 + i, a if d > 0 else b)
		"heart":
			_disc(img, 6, 7, 3.0, a)
			_disc(img, 10, 7, 3.0, a)
			for i in 6:
				for x in range(3 + i, 14 - i):
					_px(img, x, 9 + i, a)
			_px(img, 6, 6, b)
		"crest":
			_rect(img, 3, 3, 12, 9, a)
			for i in 5:
				_rect(img, 3 + i, 10 + i, 12 - i, 10 + i, a)
			_rect(img, 7, 4, 8, 11, b)
			_rect(img, 5, 6, 10, 7, b)
		"tail":
			for i in 12:
				_disc(img, 3 + i, 12 - i * 0.6 + sin(i * 0.8) * 1.5, 2.0 - i * 0.1, a if i < 8 else b)
		"mirror":
			_disc(img, 8, 7, 5.0, b)
			_disc(img, 8, 7, 3.5, b.lightened(0.4))
			_rect(img, 7, 12, 8, 15, a)
		"cog":
			_disc(img, 8, 8, 5.0, a)
			for i in 8:
				var ang := i * TAU / 8.0
				_px(img, 8 + int(round(cos(ang) * 6.5)), 8 + int(round(sin(ang) * 6.5)), a)
			_disc(img, 8, 8, 2.0, b)
		"eye":
			for x in range(2, 14):
				var h := int(round(sin((x - 2) / 11.0 * PI) * 4.0))
				for y in range(8 - h, 8 + h + 1):
					_px(img, x, y, a)
			_disc(img, 8, 8, 2.5, b)
			_px(img, 7, 7, Color.WHITE)
		"crown":
			_rect(img, 3, 8, 12, 12, a)
			for x in [3, 7, 8, 12]:
				_rect(img, x, 4, x, 8, a)
			_px(img, 5, 6, a)
			_px(img, 10, 6, a)
			_px(img, 7, 10, b)
			_px(img, 8, 10, b)
		"seal":
			_disc(img, 8, 8, 6.0, a)
			_disc(img, 8, 8, 4.5, a.darkened(0.2))
			for i in 4:
				var ang := i * TAU / 4.0 + PI / 4
				_line(img, Vector2i(8, 8), Vector2i(8 + int(round(cos(ang) * 3.0)), 8 + int(round(sin(ang) * 3.0))), b)
		"flask", "flask_big":
			var big := kind == "flask_big"
			_rect(img, 7, 2, 8, 5, Color("c8b898"))
			_disc(img, 8, 10 if not big else 9.5, 4.5 if not big else 5.5, Color(0.85, 0.9, 1.0, 1.0))
			_disc(img, 8, 11 if not big else 10.5, 3.5 if not big else 4.5, a)
			_px(img, 6, 9, b)
		"feather":
			for i in 12:
				var w := int(round(sin(i / 11.0 * PI) * 3.0))
				for d in range(-w, w + 1):
					_px(img, 3 + i + d, 13 - i + d, a)
					_px(img, 4 + i + d, 13 - i + d, a)
			_line(img, Vector2i(2, 14), Vector2i(13, 3), b)
		"bomb":
			_disc(img, 7, 9, 5.0, a)
			_px(img, 5, 7, a.lightened(0.4))
			_line(img, Vector2i(10, 5), Vector2i(12, 3), Color("c8b898"))
			_px(img, 13, 2, b)
			_px(img, 12, 2, b.lightened(0.3))
		"arrow":
			_line(img, Vector2i(2, 14), Vector2i(12, 4), b)
			for p in [Vector2i(13, 3), Vector2i(12, 3), Vector2i(13, 4), Vector2i(11, 3), Vector2i(13, 5), Vector2i(14, 2)]:
				_px(img, p.x, p.y, a)
			_px(img, 2, 12, Color("e8e0d0"))
			_px(img, 4, 14, Color("e8e0d0"))
			_px(img, 3, 12, Color("e8e0d0"))
			_px(img, 4, 13, Color("e8e0d0"))

# ---------------------------------------------------------------- 描く道具

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < SIZE and y < SIZE:
		img.set_pixel(x, y, c)

static func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(img, x, y, c)

static func _disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in SIZE:
		for x in SIZE:
			if Vector2(x + 0.5 - cx - 0.5, y + 0.5 - cy - 0.5).length() <= r:
				_px(img, x, y, c)

static func _line(img: Image, a: Vector2i, b: Vector2i, c: Color) -> void:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var t := 0.0 if n == 0 else float(i) / n
		_px(img, int(round(lerpf(a.x, b.x, t))), int(round(lerpf(a.y, b.y, t))), c)

## まわりに暗いふち（透明なマスで、となりに色のあるマス）を付ける。
static func _outline(img: Image) -> void:
	var edge: Array[Vector2i] = []
	for y in SIZE:
		for x in SIZE:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < SIZE and n.y < SIZE and img.get_pixel(n.x, n.y).a > 0.0 and img.get_pixel(n.x, n.y) != OUTLINE:
					edge.append(Vector2i(x, y))
					break
	for p in edge:
		img.set_pixel(p.x, p.y, OUTLINE)
