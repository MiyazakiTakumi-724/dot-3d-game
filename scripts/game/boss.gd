class_name Boss
extends StackSprite
## ボス（2026-11-25 の設計 5章）。名前で戦い方が変わる。数値は BossKind。
## 近づくと動き出す（wake）。倒したボスは戻らない（field.gd が RunState.on_boss_killed で覚える）。死んだら体力が戻る（エリアを作り直すので）。
## 攻撃が効くか：blocks(from) が true なら防ぐ（背中にしか効かないボスなど）。鉄球は blocks_ball(落ちた点)。
##
## 岩転がしの巨人：高い岩棚から岩を投げる。同じ高さまで登ると、ためてから踏みつける（まわりに）。
## 草むらの大蛇：草の中を動き、カメラの向きが合うときだけ姿が見える。ためてから噛みつく。
## 満ち引きする溶岩：溶岩が満ちると低い所にいるとダメージ。引いたとき、低い所に顔を出して火を吐く（そのときだけ攻撃が効く）。
## 廃城の主：足音で追ってくる騎士。ためてから広く横に斬る（しゃがむか、高い所へ逃げればよける）。
## 岩窟のぬし：ゆっくり寄り、ためて叩く。まわりに岩を落とす（落ちる所に影が出る）。
## 溶岩洞のぬし：速く走り回り、通った跡が燃える。
## 双子：2体。片方はいつも、カメラから見てもう片方の真後ろに隠れるよう動く。カメラを回すと見分けられる。
## らせん塔の番人：ゆっくり回る。背中の弱点にしか攻撃が効かない。正面に立つと弾を撃つ。
## ブライト：背中の目が光をため（約1秒）、光る瞬間に目が画面の手前を向いていると画面が白くなる。目（背中）にしか攻撃が効かない。

const WAKE_RANGE := 120.0
const SNAKE_VIEW := 0.7  ## 大蛇が見えるカメラの角度の幅（ラジアン、片側）
const LAVA_CYCLE := 10.0
const LAVA_FLOOD := 4.0  ## 1回の満ち引きのうち、満ちている秒数
const LAVA_LOW := 1  ## この高さまでが溶岩につかる
const BRIGHT_CHARGE := 1.0
const BRIGHT_FLASH := 1.5
const BRIGHT_PERIOD := 4.5

var boss_name := ""
var group := ""
var walker: EnemyWalker
var attack := 1
var active := false
## field.gd（hurt_player・boss_shot・flash_screen・effect_at・player・camera）
var field: Node
## 双子のもう片方
var partner: Boss
## 双子の後ろに隠れる方
var hider := false

var _t := 0.0
var _cool := 1.5
var _wind := -1.0  ## ためている残り秒（負ならためていない）
var _wind_kind := ""
var _hit_flash := 0.0
var _visible_body := true
var _rocks: Array = []  # 岩窟のぬしの落とす岩 [位置, 残り秒, StackSprite]
var _trail_clock := 0.0
var _home := Vector2.ZERO
var _turn := 0.0  ## 番人・ブライトの向き（ラジアン）
var _view_angle := 0.0  ## 大蛇が見えるカメラの角度
var _glow := false  ## ブライトが光をためている

func setup(f: Node, name_: String, cell: Vector2i, map: HeightMap, cam: StackCamera, defeated := 0) -> void:
	field = f
	boss_name = name_
	group = BossKind.group(name_)
	camera = cam
	attack = BossKind.attack(name_, defeated)
	var hp := BossKind.hp(name_, defeated)
	walker = EnemyWalker.new(map, cell, Vector2.DOWN, hp, 1)
	walker.chase_range = 400.0
	_home = walker.pos
	match group:
		"岩転がしの巨人":
			walker.climb = 0  # 岩棚から下りない
			walker.chase_range = 64.0
		"草むらの大蛇":
			walker.speed_mult = 1.6
		"満ち引きする溶岩":
			walker.speed_mult = 0.0
		"廃城の主":
			walker.speed_mult = 1.1
		"岩窟のぬし":
			walker.speed_mult = 0.6
		"溶岩洞のぬし":
			walker.speed_mult = 2.4
		"らせん塔の番人", "ブライト":
			walker.speed_mult = 0.0
	sort_by_cell = true
	always_redraw = true
	draw_bias = 1
	shadow_radius = 9.0
	outline_color = Player.OUTLINE_COLOR
	set_model(model_for(group))
	walker.died.connect(queue_free)

## 近づいたら動き出す。
func wake() -> void:
	active = true

## 背中の向き（番人・ブライト）。前は _turn。
func facing() -> Vector2:
	if group in ["らせん塔の番人", "ブライト"]:
		return Vector2.from_angle(_turn)
	return walker.dir

func _sort_map() -> HeightMap:
	return walker.map if walker != null else null

func flash() -> void:
	_hit_flash = 0.2

## 攻撃が防がれるか。背中にしか効かないボスは、正面と横からを防ぐ。溶岩は満ちている間は効かない。大蛇は見えない間は効かない。
func blocks(from: Vector2) -> bool:
	match group:
		"らせん塔の番人", "ブライト":
			return facing().dot((from - walker.pos).normalized()) > -0.4
		"満ち引きする溶岩":
			return _lava_flooded()
		"草むらの大蛇":
			return not _visible_body
	return false

func blocks_ball(land: Vector2) -> bool:
	return blocks(land)

## 1回の満ち引きは、引いている間（LAVA_CYCLE − LAVA_FLOOD 秒）から始まる（入ってすぐ溶岩につからないように）。
func _lava_flooded() -> bool:
	return fmod(_t, LAVA_CYCLE) >= LAVA_CYCLE - LAVA_FLOOD

## 溶岩が満ちているか（field が床のダメージに使う）
func lava_flooded() -> bool:
	return group == "満ち引きする溶岩" and active and _lava_flooded()

func _player() -> Player:
	return field.player

func _process(delta: float) -> void:
	_hit_flash = maxf(0.0, _hit_flash - delta)
	var p := _player()
	if not active and p.mover.pos.distance_to(walker.pos) < WAKE_RANGE:
		wake()
	if active and walker.alive and p.hp > 0:
		_t += delta
		_cool -= delta
		match group:
			"岩転がしの巨人": _giant(delta, p)
			"草むらの大蛇": _snake(delta, p)
			"満ち引きする溶岩": _lava(delta, p)
			"廃城の主": _knight(delta, p)
			"岩窟のぬし": _golem(delta, p)
			"溶岩洞のぬし": _salamander(delta, p)
			"双子": _twin(delta, p)
			"らせん塔の番人": _guardian(delta, p)
			"ブライト": _bright(delta, p)
	_step_rocks(delta)
	if _wind >= 0.0 or _hit_flash > 0.0 or _glow:
		self_modulate = Color(1.8, 1.8, 1.8)
	elif walker.is_poisoned():
		self_modulate = Color(1.4, 0.8, 0.6) if walker.is_burning() else Color(0.7, 1.3, 0.6)
	elif walker.is_slowed():
		self_modulate = Color(0.7, 0.9, 1.5)
	else:
		self_modulate = Color.WHITE
	world_pos = walker.pos
	base_height = walker.height
	turn = facing().angle() - PI / 2
	super._process(delta)

## ためてから攻撃する。ためが終わったら kind を返す（なければ ""）。
func _windup(delta: float, seconds: float, kind: String, start: bool) -> String:
	if _wind < 0.0:
		if start and _cool <= 0.0:
			_wind = seconds
			_wind_kind = kind
		return ""
	_wind -= delta
	if _wind < 0.0:
		_cool = 1.2
		return _wind_kind
	return ""

func _chase(delta: float, p: Player) -> void:
	if _wind >= 0.0:
		return  # ためている間は動かない
	walker.chase(p.mover.pos, p.mover.height)
	walker.step(delta)

func _dist(p: Player) -> float:
	return walker.pos.distance_to(p.mover.pos)

func _throw(p: Player, speed := 70.0) -> void:
	var b := Bullet.new()
	b.aim(walker.pos, walker.height, p.mover.pos, p.mover.height, speed)
	b.damage = attack
	field.boss_shot(b)

# ---------------------------------------------------------------- それぞれの戦い方

func _giant(delta: float, p: Player) -> void:
	_chase(delta, p)
	var same := p.mover.height == walker.height
	if _windup(delta, 0.8, "stomp", same and _dist(p) < 36.0) == "stomp":
		field.effect_at(Props.rain_ring(30.0), walker.pos, walker.height, 0.3)
		field.camera.shake(3.0)
		if _dist(p) < 30.0 and p.mover.height == walker.height:
			field.hurt_player(attack)
	if not same and _cool <= 0.0 and _wind < 0.0 and Damage.can_hit(walker.height, p.mover.height):
		_cool = 2.2
		_throw(p, 60.0)

func _snake(delta: float, p: Player) -> void:
	if int(_t / 6.0) != int((_t - delta) / 6.0):
		_view_angle = wrapf(_view_angle + PI * 0.75, -PI, PI)  # 見える向きが替わる
	var cam_angle: float = field.camera.angle
	_visible_body = absf(wrapf(cam_angle - _view_angle, -PI, PI)) < SNAKE_VIEW
	_chase(delta, p)
	if _windup(delta, 0.6, "bite", _dist(p) < 22.0 and absi(p.mover.height - walker.height) <= 1) == "bite":
		if _dist(p) < 24.0 and absi(p.mover.height - walker.height) <= 1:
			field.hurt_player(attack)

func _lava(delta: float, p: Player) -> void:
	var flooded := _lava_flooded()
	_visible_body = not flooded
	if flooded:
		_trail_clock += delta
		if _trail_clock >= 0.35:
			_trail_clock = 0.0
			var off := Vector2.from_angle(randf() * TAU) * randf() * 120.0
			var c := HeightMap.world_to_cell(_home + off)
			if walker.map.in_bounds(c) and walker.map.get_height(c) <= LAVA_LOW and not walker.map.is_wall(c):
				field.effect_at(Props.flame(randi() % 3), HeightMap.cell_center(c), walker.map.get_height(c), 0.6)
	elif _cool <= 0.0:
		_cool = 1.4
		_throw(p, 80.0)

func _knight(delta: float, p: Player) -> void:
	walker.chase_range = 60.0 if p.crouching else 240.0  # 足音で追ってくる
	_chase(delta, p)
	if _windup(delta, 0.9, "sweep", _dist(p) < 30.0) == "sweep":
		field.effect_at(Props.rain_ring(34.0), walker.pos, walker.height, 0.25)
		# 横に広く斬る。しゃがむか、騎士より高い所にいればよけられる
		if _dist(p) < 36.0 and not p.crouching and Damage.can_hit(walker.height, p.mover.height):
			field.hurt_player(attack)

func _golem(delta: float, p: Player) -> void:
	_chase(delta, p)
	if _windup(delta, 0.8, "slam", _dist(p) < 26.0) == "slam":
		field.camera.shake(3.0)
		field.effect_at(Props.rain_ring(24.0), walker.pos, walker.height, 0.3)
		if _dist(p) < 26.0 and absi(p.mover.height - walker.height) <= 1:
			field.hurt_player(attack)
	if int(_t / 4.0) != int((_t - delta) / 4.0):
		for i in 3:
			var at := p.mover.pos + Vector2.from_angle(randf() * TAU) * randf() * 28.0
			var c := HeightMap.world_to_cell(at)
			if not walker.map.in_bounds(c):
				continue
			var s: StackSprite = field.effect_at(Props.aim_shadow(), at, walker.map.get_height(c), 1.0)
			s.set_meta("steady", true)
			_rocks.append([at, 1.0])

func _step_rocks(delta: float) -> void:
	for i in range(_rocks.size() - 1, -1, -1):
		_rocks[i][1] -= delta
		if _rocks[i][1] > 0.0:
			continue
		var at: Vector2 = _rocks[i][0]
		_rocks.remove_at(i)
		var c := HeightMap.world_to_cell(at)
		field.effect_at(Props.rain_ring(10.0), at, walker.map.get_height(c), 0.25)
		var p := _player()
		if p.hp > 0 and p.mover.pos.distance_to(at) < 11.0:
			field.hurt_player(maxi(1, attack / 2))

func _salamander(delta: float, p: Player) -> void:
	_chase(delta, p)
	_trail_clock += delta
	if _trail_clock >= 0.25:
		_trail_clock = 0.0
		field.boss_fire(walker.pos, walker.height, 3.0, maxi(1, attack / 2))  # 通った跡が燃える

func _twin(delta: float, p: Player) -> void:
	if hider and partner != null and is_instance_valid(partner) and partner.walker.alive:
		# カメラから見て、相手の真後ろ（画面の奥）に回りこむ
		var back: Vector2 = field.camera.screen_dir_to_world(Vector2.UP) * 18.0
		var spot: Vector2 = partner.walker.pos + back
		var d: Vector2 = spot - walker.pos
		if d.length() > 2.0:
			walker.dir = d.normalized()
			walker.step(delta)
	else:
		_chase(delta, p)
	if _windup(delta, 0.5, "hit", _dist(p) < 20.0 and absi(p.mover.height - walker.height) <= 1) == "hit":
		if _dist(p) < 22.0:
			field.hurt_player(attack)
	if hider and _cool <= 0.0 and _wind < 0.0:
		_cool = 2.5
		_throw(p, 70.0)

func _guardian(delta: float, p: Player) -> void:
	_turn = wrapf(_turn + 0.6 * delta, -PI, PI)  # ゆっくり回る
	var to_p := (p.mover.pos - walker.pos)
	if _cool <= 0.0 and to_p.length() < 140.0 and facing().dot(to_p.normalized()) > 0.6:
		_cool = 1.8
		_throw(p, 75.0)
	if _windup(delta, 0.7, "swipe", to_p.length() < 24.0) == "swipe":
		if _dist(p) < 26.0 and absi(p.mover.height - walker.height) <= 1:
			field.hurt_player(attack)

func _bright(delta: float, p: Player) -> void:
	# ゆっくり主人公の方を向く（背中の目は反対を向く）
	var want := (p.mover.pos - walker.pos).angle()
	_turn = rotate_toward(_turn, want, 0.5 * delta)
	var phase := fmod(_t, BRIGHT_PERIOD)
	var charging := phase > BRIGHT_PERIOD - BRIGHT_CHARGE
	_glow = charging  # 光をためている間は光って見える
	if int(_t / BRIGHT_PERIOD) != int((_t - delta) / BRIGHT_PERIOD):
		# 光る瞬間：背中の目が画面の手前を向いていたら、画面が白くなる
		var toward_viewer: Vector2 = field.camera.screen_dir_to_world(Vector2.DOWN)
		if (-facing()).dot(toward_viewer) > 0.5:
			field.flash_screen(BRIGHT_FLASH)
	if not charging and _cool <= 0.0:
		_cool = 1.6
		_throw(p, 80.0)

# ---------------------------------------------------------------- 姿

## ボスの形（ゲームの座標のボクセル、前は +y）。
static func model_for(g: String) -> VoxelModel:
	var m := VoxelModel.new()
	match g:
		"岩転がしの巨人", "岩窟のぬし":
			var stone := Color("8d8f94") if g == "岩転がしの巨人" else Color("5f6168")
			m.size = Vector3i(22, 18, 26)
			VoxelDraw.ellipsoid(m, Vector3(11, 9, 12), Vector3(9, 7, 10), stone)
			VoxelDraw.ellipsoid(m, Vector3(11, 10, 22), Vector3(5, 5, 4), stone.lightened(0.1))
			VoxelDraw.fill(m, Vector3i(1, 7, 6), Vector3i(4, 11, 16), stone.darkened(0.15))
			VoxelDraw.fill(m, Vector3i(17, 7, 6), Vector3i(20, 11, 16), stone.darkened(0.15))
			m.set_voxel(Vector3i(9, 15, 22), Color("ffcf4a"))
			m.set_voxel(Vector3i(13, 15, 22), Color("ffcf4a"))
		"草むらの大蛇":
			m.size = Vector3i(14, 26, 10)
			for i in 6:
				VoxelDraw.ellipsoid(m, Vector3(7 + sin(i * 1.3) * 3.0, 3 + i * 4, 3), Vector3(3, 3, 3), Color("5f8f4a"))
			VoxelDraw.ellipsoid(m, Vector3(7, 23, 5), Vector3(4, 3, 3), Color("6fa05a"))
			m.set_voxel(Vector3i(5, 25, 6), Color("ffe14a"))
			m.set_voxel(Vector3i(9, 25, 6), Color("ffe14a"))
		"満ち引きする溶岩":
			m.size = Vector3i(18, 18, 14)
			VoxelDraw.ellipsoid(m, Vector3(9, 9, 6), Vector3(8, 8, 6), Color("7a2a1a"))
			VoxelDraw.ellipsoid(m, Vector3(9, 12, 9), Vector3(5, 4, 3), Color("ff8a2a"))
			m.set_voxel(Vector3i(6, 16, 9), Color("fff0a0"))
			m.set_voxel(Vector3i(12, 16, 9), Color("fff0a0"))
		"廃城の主":
			m.size = Vector3i(16, 14, 24)
			VoxelDraw.fill(m, Vector3i(4, 4, 0), Vector3i(11, 9, 14), Color("5a5470"))
			VoxelDraw.ellipsoid(m, Vector3(8, 7, 18), Vector3(4, 4, 4), Color("8a8fa0"))
			VoxelDraw.fill(m, Vector3i(6, 11, 18), Vector3i(10, 11, 18), Color("2a2030"))
			VoxelDraw.rod(m, Vector3(14, 8, 10), Vector3(14, 13, 22), Color("d0d4dc"), 1)  # 大剣
			VoxelDraw.fill(m, Vector3i(2, 3, 12), Vector3i(13, 10, 14), Color("7a2a3a"))  # 肩の布
		"溶岩洞のぬし":
			m.size = Vector3i(12, 22, 8)
			VoxelDraw.ellipsoid(m, Vector3(6, 11, 3), Vector3(4, 9, 3), Color("9a3a2a"))
			VoxelDraw.ellipsoid(m, Vector3(6, 19, 4), Vector3(3, 3, 3), Color("c8502a"))
			VoxelDraw.fill(m, Vector3i(5, 0, 2), Vector3i(6, 3, 3), Color("ffb03a"))  # 燃える尾
		"双子":
			m.size = Vector3i(12, 12, 20)
			VoxelDraw.ellipsoid(m, Vector3(6, 6, 7), Vector3(5, 4, 7), Color("c9c3b6"))
			VoxelDraw.ellipsoid(m, Vector3(6, 6, 16), Vector3(4, 4, 4), Color("e6e0d2"))
			m.set_voxel(Vector3i(4, 10, 16), Color("4a6aff"))
			m.set_voxel(Vector3i(8, 10, 16), Color("4a6aff"))
		"らせん塔の番人":
			m.size = Vector3i(18, 16, 26)
			VoxelDraw.fill(m, Vector3i(3, 3, 0), Vector3i(14, 12, 20), Color("b8b2a4"))
			VoxelDraw.ellipsoid(m, Vector3(9, 8, 22), Vector3(5, 5, 4), Color("cfc8b8"))
			VoxelDraw.fill(m, Vector3i(6, 0, 8), Vector3i(11, 2, 14), Color("ff5a3a"))  # 背中の弱点（光る核）
			m.set_voxel(Vector3i(7, 13, 22), Color("3a3a3a"))
			m.set_voxel(Vector3i(11, 13, 22), Color("3a3a3a"))
		"ブライト":
			m.size = Vector3i(20, 18, 28)
			VoxelDraw.ellipsoid(m, Vector3(10, 9, 13), Vector3(8, 7, 13), Color("e8e2f0"))
			VoxelDraw.ellipsoid(m, Vector3(10, 1, 18), Vector3(4, 2, 4), Color("ffe866"))  # 背中の目
			m.set_voxel(Vector3i(10, 0, 18), Color("2a2a60"))
			VoxelDraw.fill(m, Vector3i(7, 16, 20), Vector3i(13, 16, 21), Color("9a90b0"))
		_:
			m = VoxelModel.box(Vector3i(16, 16, 16), Color("9a968e"))
	return VoxelShade.apply(m)

func _draw() -> void:
	if camera == null:
		return
	if not _visible_body and group in ["草むらの大蛇", "満ち引きする溶岩"]:
		_draw_shadow()  # 大蛇は見えない向きのとき、溶岩は満ちている間は、影だけ
		return
	super._draw()
