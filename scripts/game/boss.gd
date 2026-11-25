class_name Boss
extends StackSprite
## ボス（2026-11-25 の設計 5章。夜に作り直した：balance-pass 5章）。名前で戦い方が変わる。数値は BossKind。
## 近づくと動き出す（wake）。倒したボスは戻らない（field.gd が RunState.on_boss_killed で覚える）。死んだら体力が戻る（エリアを作り直すので）。
## 体力が半分を切ると2段目（phase 2）になり、攻撃が増える。攻撃の入り方は hit_rule（敵と同じ言葉）。
##
## 岩転がしの巨人：岩棚から岩を投げる（3回に1回は3つに分かれる）。同じ高さで踏みつけ。2段目：下の地面を端から端へ大岩を転がす。
## 草むらの大蛇：カメラの向きが合うときだけ見える。噛みつき、尾で払う（まわり）。2段目：もぐって足元から出る（影が先に出る）、毒の息。
## 満ち引きする溶岩：満ち引き、引いたとき火を3方向に吐く（そのときだけ攻撃が効く）。2段目：満ち引きが速く、地面から火柱（先に印）。
## 廃城の主：足音で追い、横に広く斬る（しゃがむか高い所でよける）。2段目：まっすぐ突進する。亡霊を呼ぶ。
## 岩窟のぬし：ゆっくり寄って叩く、まわりに岩を落とす。2段目：丸まって転がる。壁にぶつかると目を回す（その間は2倍）。
## 溶岩洞のぬし：走り回り、通った跡が燃える。2段目：跳びかかり、着いた所のまわりに炎の輪。
## 双子：片方がいつも、カメラから見てもう片方の真後ろに隠れる。2段目：隠れる方が入れ替わる。片方が倒れると、残りが怒って速くなる。
## らせん塔の番人：ゆっくり回り、正面に立つと撃つ。背中だけ効く。2段目：回る向きが変わり、まわりを薙ぐ。
## ブライト：背中の目が光をためて画面を白くする。背中だけ効く。2段目：光の雨（落ちる所に印）、影を呼ぶ。
## 女王蜂：浮いている（剣・鉄球は届かない）。針を3本撃ち、蜂を呼ぶ。2段目：急降下して、しばらく地面に降りる（その間は剣も届く）。
## 宝箱の王：にせものの宝箱（BossDecoy）にまぎれ、本物だけが噛みつく。ときどき入れ替わる（2段目は速い）。
##   本物は背中に金のしっぽがある（カメラを回すと見分けられる）。
##
## 2026-11-25 夜（2回目の直し）に、どのボスにも技を足した（docs/superpowers/specs/2026-11-25-tuning-2.md 5章）：
## 巨人：地面を叩いて、主人公の足元に奈落を開ける（ひびが出てから開く。落ちると死ぬ）。2段目は巨人から主人公へ向かう列。
## 大蛇：少し離れると、ためて突進して噛みつく。2段目：地面から出たとき、まわりの土が盛り上がる（輪の印）。
## 溶岩：引いたとき、溶岩の玉も落とす（印が先）。2段目：炎の車輪が部屋を端から端へ転がる。
## 廃城の主：離れると、剣を振って3方向に衝撃波。2段目：地面を割る（主人公へ向かう印の列）。
## 岩窟のぬし：ときどき地響きで、まわりに奈落を開ける。2段目：大岩を転がしてくる。
## 溶岩洞のぬし：離れると、ためて火を5方向に吐く。2段目：火の雨。
## 双子：前に立つ方が、ためて突進する。2段目：後ろの方も3方向に撃つ。
## 番人：床に十字の印が出て、火柱が立つ（2段目は斜めの十字と交互）。
## ブライト：ときどき別の所へ消えて現れる（背中を取り直す）。2段目：回る光の柱の列。
## 女王蜂：ときどき針を8方向に撃つ。2段目：急降下して降りたときにも8方向。
## 宝箱の王：ときどき本物だけが口を開けて金貨を吐く（見分ける合図にもなる）。2段目：擬態箱を1つ呼ぶ。

const WAKE_RANGE := 120.0
const SNAKE_VIEW := 0.7  ## 大蛇が見えるカメラの角度の幅（ラジアン、片側）
const LAVA_CYCLE := 10.0
const LAVA_FLOOD := 4.0  ## 1回の満ち引きのうち、満ちている秒数
const LAVA_CYCLE_2 := 7.0  ## 2段目の満ち引き
const LAVA_FLOOD_2 := 3.0
const LAVA_LOW := 1  ## この高さまでが溶岩につかる
const BRIGHT_CHARGE := 1.0
const BRIGHT_FLASH := 1.5
const BRIGHT_PERIOD := 4.5
## 呼んだ手下の数の上限
const MAX_MINIONS := 3
## 宝箱の王：にせものの数、入れ替わるまでの秒（1段目・2段目）、本物が噛みつく距離
const DECOYS := 4
const CHEST_SHUFFLE := 6.0
const CHEST_SHUFFLE_2 := 3.5
const CHEST_BITE := 24.0
## 目を回している秒（岩窟のぬしが壁にぶつかったとき）
const STUN_SECONDS := 2.5
## 女王蜂が浮いている高さ（px）と、急降下のあと地面にいる秒
const QUEEN_LIFT := 14.0
const QUEEN_LANDED := 1.8
## 巨人・岩窟のぬしが奈落を開ける間（秒）。ひびが出てから開くまで、開いている秒
const GIANT_QUAKE := 7.0
const GIANT_QUAKE_2 := 5.5
const GOLEM_QUAKE := 8.0
const PIT_WARN := 1.3
const PIT_OPEN := 5.0

var boss_name := ""
var group := ""
var walker: EnemyWalker
var attack := 1
var active := false
## field.gd（hurt_player・boss_shot・boss_strike・boss_roll・spawn_minion・add_boss_part・flash_screen・effect_at・notice・player・camera）
var field: Node
## 双子のもう片方
var partner: Boss
## 双子の後ろに隠れる方
var hider := false
## 1段目・2段目
var phase := 1
## 目を回している残り秒（その間は2倍入る）
var stunned := 0.0
## 双子の片方が倒れて怒っている
var enraged := false
## 宝箱の王のにせもの
var decoys: Array = []
## 宝箱の王が口を開けている残り秒
var open_time := 0.0
## 女王蜂が地面に降りている残り秒（その間は剣と鉄球も届く）
var landed := 0.0
## 大蛇がもぐっている残り秒（その間は攻撃が効かない）
var burrow := 0.0

var _t := 0.0
var _cool := 1.5
var _wind := -1.0  ## ためている残り秒（負ならためていない）
var _wind_kind := ""
var _hit_flash := 0.0
var _visible_body := true
var _rocks: Array = []  # 岩窟のぬしの落とす岩 [位置, 残り秒]
var _trail_clock := 0.0
var _home := Vector2.ZERO
var _turn := 0.0  ## 番人・ブライトの向き（ラジアン）
var _spin := 1.0  ## 番人の回る向き
var _view_angle := 0.0  ## 大蛇が見えるカメラの角度
var _glow := false  ## ブライトが光をためている
var _moves := 0  ## 攻撃の回数（3回に1回の技など）
var _clock1 := 0.0  ## 1段目から使う、足した技の時計（2026-11-25 夜の2回目の直し）
var _clock2 := 0.0  ## 2段目の技の時計
var _clock3 := 0.0  ## 2段目に足した技の時計
var _summon := 0.0  ## 手下を呼ぶ時計
var _dash_dir := Vector2.ZERO
var _dash_time := 0.0  ## 突進・転がり・跳びかかりの残り秒
var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _burrow_spot := Vector2.ZERO
var _burrow_mark: StackSprite
var _shuffle := CHEST_SHUFFLE
var _minions: Array = []
var _base_speed := 1.0

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
		"女王蜂":
			walker.flying = true
			walker.speed_mult = 1.4
		"宝箱の王":
			walker.speed_mult = 0.0
			walker.chase_range = 0.0
	_base_speed = walker.speed_mult
	sort_by_cell = true
	always_redraw = true
	draw_bias = 1
	shadow_radius = 9.0 if group != "宝箱の王" else 7.0
	voxel_scale = BossModels.VOXEL_SCALE
	outline_color = Player.OUTLINE_COLOR
	set_model(BossModels.model(group))
	walker.died.connect(_on_died)

func _on_died() -> void:
	for d in decoys:
		if is_instance_valid(d):
			d.queue_free()
	decoys.clear()
	if is_instance_valid(_burrow_mark):
		_burrow_mark.queue_free()
	queue_free()

## 近づいたら動き出す。宝箱の王は、にせものを並べる。
func wake() -> void:
	if active:
		return
	active = true
	if group == "宝箱の王":
		_refill_decoys()

## 背中の向き（番人・ブライト）。前は _turn。宝箱の王は前（+y）を向いたまま。
func facing() -> Vector2:
	if group in ["らせん塔の番人", "ブライト"]:
		return Vector2.from_angle(_turn)
	if group == "宝箱の王":
		return Vector2.DOWN
	return walker.dir

func _sort_map() -> HeightMap:
	return walker.map if walker != null else null

func flash() -> void:
	_hit_flash = 0.2

## 攻撃が防がれるか。背中にしか効かないボスは、正面と横からを防ぐ。溶岩は満ちている間は効かない。大蛇は見えない間ともぐっている間は効かない。
func blocks(from: Vector2) -> bool:
	match group:
		"らせん塔の番人", "ブライト":
			return facing().dot((from - walker.pos).normalized()) > -0.4
		"満ち引きする溶岩":
			return _lava_flooded()
		"草むらの大蛇":
			return not _visible_body or burrow > 0.0
	return false

func blocks_ball(land: Vector2) -> bool:
	return blocks(land)

## 浮いているか（女王蜂。降りている間は浮いていない）
func airborne() -> bool:
	return group == "女王蜂" and landed <= 0.0

## 攻撃（source：sword・arrow・magic・ball・bomb）がどう当たるか。field.damage_target が使う（EnemyKind.hit_rule と同じ言葉）。
func hit_rule(source: String, from: Vector2) -> String:
	if airborne() and source in ["sword", "ball"]:
		return "miss"
	var blocked := blocks_ball(from) if source in ["ball", "bomb"] else blocks(from)
	if blocked:
		return "block"
	if stunned > 0.0:
		return "weak"
	return ""

## 攻撃が当たったあと（宝箱の王は口を開けて噛み返し、すぐ入れ替わる）。
func on_hit(_source: String) -> void:
	if group == "宝箱の王" and active:
		open_time = maxf(open_time, 1.0)
		_cool = 0.0
		_shuffle = minf(_shuffle, 0.8)

## 体当たりでダメージを与えるか（宝箱のふりをしている間・もぐっている間・目を回している間は与えない）
func touch_hurts() -> bool:
	if not active:
		return false
	if group == "宝箱の王":
		return open_time > 0.0
	if group == "草むらの大蛇" and burrow > 0.0:
		return false
	return stunned <= 0.0

## 1回の満ち引きは、引いている間から始まる（入ってすぐ溶岩につからないように）。2段目は速い。
func _lava_flooded() -> bool:
	var cycle := LAVA_CYCLE if phase == 1 else LAVA_CYCLE_2
	var flood := LAVA_FLOOD if phase == 1 else LAVA_FLOOD_2
	return fmod(_t, cycle) >= cycle - flood

## 溶岩が満ちているか（field が床のダメージに使う）
func lava_flooded() -> bool:
	return group == "満ち引きする溶岩" and active and _lava_flooded()

func _player() -> Player:
	return field.player

## 双子は2体の体力の合計で段を決める。
func _phase_hp() -> Vector2i:
	if group == "双子" and partner != null and is_instance_valid(partner):
		return Vector2i(walker.hp + partner.walker.hp, walker.max_hp + partner.walker.max_hp)
	return Vector2i(walker.hp, walker.max_hp)

func _check_phase() -> void:
	if phase == 2:
		return
	var h := _phase_hp()
	if BossKind.phase(h.x, h.y) == 2:
		phase = 2
		_clock2 = 0.0
		field.camera.shake(3.0)
		if group != "双子" or not hider:
			field.notice("%sが怒った！" % group, 2.0)
		match group:
			"廃城の主":
				_call_minions(EnemyKind.Kind.GHOST, 2)
			"宝箱の王":
				_shuffle = minf(_shuffle, 0.5)

func _process(delta: float) -> void:
	_hit_flash = maxf(0.0, _hit_flash - delta)
	stunned = maxf(0.0, stunned - delta)
	open_time = maxf(0.0, open_time - delta)
	var p := _player()
	if not active and p.mover.pos.distance_to(walker.pos) < WAKE_RANGE:
		wake()
	if active and walker.alive:
		_check_phase()
		if group == "双子" and not enraged and partner != null and (not is_instance_valid(partner) or not partner.walker.alive):
			enraged = true
			hider = false
			walker.speed_mult = _base_speed * 1.6
			field.notice("双子の片方が倒れた\nもう片方が怒っている！", 2.0)
	if active and walker.alive and p.hp > 0 and stunned <= 0.0:
		_t += delta
		_cool -= delta * (1.6 if enraged else 1.0)
		_clock1 += delta
		_clock2 += delta
		if phase == 2:
			_clock3 += delta
		_summon += delta
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
			"女王蜂": _queen(delta, p)
			"宝箱の王": _chest_king(delta, p)
	_step_rocks(delta)
	_look()
	super._process(delta)

## 色と姿（ためている間は光る。目を回していると黄色く点滅。2段目は少し赤い）。
func _look() -> void:
	if _wind >= 0.0 or _hit_flash > 0.0 or _glow:
		self_modulate = Color(1.8, 1.8, 1.8)
	elif stunned > 0.0:
		self_modulate = Color(1.3, 1.2, 0.6) if int(_t * 8.0) % 2 == 0 else Color.WHITE
	elif walker.is_poisoned():
		self_modulate = Color(1.4, 0.8, 0.6) if walker.is_burning() else Color(0.7, 1.3, 0.6)
	elif walker.is_slowed():
		self_modulate = Color(0.7, 0.9, 1.5)
	elif phase == 2:
		self_modulate = Color(1.15, 0.9, 0.9)
	else:
		self_modulate = Color.WHITE
	world_pos = walker.pos
	base_height = walker.height
	turn = facing().angle() - PI / 2
	lift_px = 0.0
	if group == "女王蜂":
		lift_px = 2.0 if landed > 0.0 else QUEEN_LIFT + sin(_t * 6.0) * 2.0
	elif group == "溶岩洞のぬし" and _wind_kind == "leaping":
		var k := clampf(1.0 - _dash_time / 0.5, 0.0, 1.0)
		lift_px = sin(k * PI) * 26.0
	if group == "岩窟のぬし":
		var want := "curl" if _wind_kind == "rolling" or stunned > 0.0 else ""
		_use_model(want)
	elif group == "宝箱の王":
		_use_model("open" if open_time > 0.0 or _wind >= 0.0 else "")

var _variant := ""
func _use_model(v: String) -> void:
	if v != _variant:
		_variant = v
		set_model(BossModels.model(group, v))

## ためてから攻撃する。ためが終わったら kind を返す（なければ ""）。ためている間は、ほかの技は始まらない。
func _windup(delta: float, seconds: float, kind: String, start: bool) -> String:
	if _wind < 0.0:
		if start and _cool <= 0.0:
			_wind = seconds
			_wind_kind = kind
		return ""
	if _wind_kind != kind:
		return ""
	_wind -= delta
	if _wind < 0.0:
		_cool = 1.2
		_moves += 1
		return _wind_kind
	return ""

func _chase(delta: float, p: Player) -> void:
	if _wind >= 0.0 or _dash_time > 0.0:
		return  # ためている間は動かない
	walker.chase(p.mover.pos, p.mover.height)
	walker.step(delta)

func _dist(p: Player) -> float:
	return walker.pos.distance_to(p.mover.pos)

func _near(p: Player, r: float) -> bool:
	return _dist(p) < r and absi(p.mover.height - walker.height) <= 1

func _throw(p: Player, speed := 70.0, spread := 0.0) -> void:
	var b := Bullet.new()
	var to := p.mover.pos
	if spread != 0.0:
		to = walker.pos + (p.mover.pos - walker.pos).rotated(spread)
	b.aim(walker.pos, walker.height, to, p.mover.height, speed)
	b.damage = attack
	field.boss_shot(b)

## 扇のように n 方向へ撃つ。
func _fan(p: Player, speed: float, n := 3, width := 0.35) -> void:
	for i in n:
		_throw(p, speed, (i - (n - 1) * 0.5) * width)

## 手下を呼ぶ（いる数が MAX_MINIONS より少ないときだけ）。
func _call_minions(kind: EnemyKind.Kind, n: int) -> void:
	for i in n:
		if minion_count() >= MAX_MINIONS:
			return
		var at := walker.pos + Vector2.from_angle(randf() * TAU) * 24.0
		var e = field.spawn_minion(kind, at)
		if e != null:
			_minions.append(e)

func minion_count() -> int:
	_minions = _minions.filter(func(e): return is_instance_valid(e) and e.walker.alive)
	return _minions.size()

## まっすぐ走る（突進・転がり・急降下）。壁にぶつかると止まり、true を返す。
func _dash(delta: float, mult: float) -> bool:
	_dash_time -= delta
	walker.dir = _dash_dir
	walker.speed_mult = mult
	var before := walker.pos
	walker.step(delta)
	var bumped := walker.pos.distance_to(before) < 0.01 or walker.dir != _dash_dir
	if bumped or _dash_time <= 0.0:
		_dash_time = 0.0
		walker.speed_mult = _base_speed
	return bumped

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
		_moves += 1
		if _moves % 3 == 0:
			_fan(p, 60.0)  # 3つに分かれる岩
		else:
			_throw(p, 60.0)
	# 2段目：下の地面を、端から端へ大岩を転がす（横によける）
	if phase == 2 and _clock2 >= 5.0:
		_clock2 = 0.0
		_moves += 1
		var map := walker.map
		var horizontal := _moves % 2 == 0
		var row := p.mover.pos
		var far := _moves % 4 >= 2
		var start := Vector2(4.0, row.y) if horizontal else Vector2(row.x, 4.0)
		if far:
			start = Vector2(map.size.x * HeightMap.CELL_PX - 4.0, row.y) if horizontal else Vector2(row.x, map.size.y * HeightMap.CELL_PX - 4.0)
		var dir := Vector2(1, 0) if horizontal else Vector2(0, 1)
		field.boss_roll(start, -dir if far else dir, attack)
	# 地割れ：地面を叩いて、主人公の足元に奈落を開ける（ひびが出てから開く）。2段目は巨人から主人公へ向かう列も
	if _clock1 >= (GIANT_QUAKE if phase == 1 else GIANT_QUAKE_2) and _wind < 0.0:
		_clock1 = 0.0
		field.camera.shake(3.5)
		field.effect_at(Props.rain_ring(30.0), walker.pos, walker.height, 0.3)
		field.boss_pits(_quake_cells(p), PIT_WARN, PIT_OPEN)

## 巨人の地割れで開くマス。1段目は主人公の足元を含む2×2、2段目はそれに巨人から主人公へ向かう列を足す。
func _quake_cells(p: Player) -> Array:
	var pc := p.mover.cell()
	var off := Vector2i(-1 if randf() < 0.5 else 0, -1 if randf() < 0.5 else 0)
	var cells: Array = []
	for dx in 2:
		for dy in 2:
			cells.append(pc + off + Vector2i(dx, dy))
	if phase == 2:
		var d := (p.mover.pos - walker.pos).normalized()
		for k in range(2, 9):
			cells.append(HeightMap.world_to_cell(walker.pos + d * k * HeightMap.CELL_PX))
	return cells

func _snake(delta: float, p: Player) -> void:
	if int(_t / 6.0) != int((_t - delta) / 6.0):
		_view_angle = wrapf(_view_angle + PI * 0.75, -PI, PI)  # 見える向きが替わる
	var cam_angle: float = field.camera.angle
	_visible_body = absf(wrapf(cam_angle - _view_angle, -PI, PI)) < SNAKE_VIEW
	# 2段目：もぐって、主人公の足元から出る。影が追ってきて、止まってから出る
	if burrow > 0.0:
		burrow -= delta
		if burrow > 0.5:
			_burrow_spot = p.mover.pos
		if is_instance_valid(_burrow_mark):
			_burrow_mark.world_pos = _burrow_spot
		if burrow <= 0.0:
			burrow = 0.0
			if is_instance_valid(_burrow_mark):
				_burrow_mark.queue_free()
			var c := HeightMap.world_to_cell(_burrow_spot)
			var map := walker.map
			if map.in_bounds(c) and not map.is_wall(c) and not map.is_pit(c) and not map.is_water(c):
				walker.pos = _burrow_spot
				walker.height = map.get_height(c)
			field.effect_at(Props.rain_ring(14.0), walker.pos, walker.height, 0.3)
			field.camera.shake(2.5)
			if _near(p, 14.0):
				field.hurt_player(attack)
			_cool = 1.0
			# 2段目：出たところのまわりの土が盛り上がる（輪の印。少しあとに当たる）
			for i in 6:
				field.boss_strike(walker.pos + Vector2.from_angle(i * TAU / 6.0) * 26.0, 0.7, 9.0, attack, Props.rain_ring(10.0))
		return
	if _dash_time > 0.0:
		_dash(delta, 4.0)  # 突進して噛みつく
		if _near(p, 14.0):
			field.hurt_player(attack)
			_dash_time = 0.0
			walker.speed_mult = _base_speed
		return
	if phase == 2 and _clock2 >= 7.0 and _wind < 0.0:
		_clock2 = 0.0
		burrow = 1.6
		_burrow_spot = p.mover.pos
		_burrow_mark = field.effect_at(Props.aim_shadow(), _burrow_spot, p.mover.height, 1.6)
		_burrow_mark.set_meta("steady", true)
		return
	_chase(delta, p)
	var tail := _moves % 3 == 2
	if _windup(delta, 0.7 if tail else 0.6, "tail" if tail else "bite", _near(p, 22.0)) != "":
		if tail:
			field.effect_at(Props.rain_ring(26.0), walker.pos, walker.height, 0.25)  # 尾で払う（まわり）
			if _near(p, 28.0):
				field.hurt_player(attack)
		elif _near(p, 24.0):
			field.hurt_player(attack)
	# 少し離れていると、ためて突進して噛みつく（見えているときだけ）
	if _windup(delta, 0.6, "lunge", _visible_body and _clock1 >= 4.0 and _dist(p) > 34.0 and _dist(p) < 80.0) == "lunge":
		_clock1 = 0.0
		_dash_dir = (p.mover.pos - walker.pos).normalized()
		_dash_time = 0.45
	# 2段目：離れていると毒の息（遅い弾を5方向）
	if phase == 2 and _cool <= 0.0 and _wind < 0.0 and _dist(p) > 40.0 and _visible_body:
		_cool = 3.5
		_fan(p, 42.0, 5, 0.25)

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
		_cool = 1.6
		_moves += 1
		_fan(p, 80.0)  # 火を3方向に吐く
		if _moves % 2 == 0:
			# 溶岩の玉も落とす（主人公の所と、そのそば。印が先に出る）
			field.boss_strike(p.mover.pos, 1.1, 10.0, attack, Props.flame(0))
			field.boss_strike(p.mover.pos + Vector2.from_angle(randf() * TAU) * 20.0, 1.1, 10.0, attack, Props.flame(1))
	# 2段目：地面から火柱（先に印が出る）
	if phase == 2 and _clock2 >= 3.0:
		_clock2 = 0.0
		for i in 3:
			var at := p.mover.pos + (Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(12.0, 26.0))
			field.boss_strike(at, 0.9, 10.0, attack, Props.pillar())
	# 2段目：炎の車輪が、主人公のいる列を端から端へ転がる
	if phase == 2 and _clock3 >= 6.0:
		_clock3 = 0.0
		_moves += 1
		var horizontal := _moves % 2 == 0
		var start := Vector2(4.0, p.mover.pos.y) if horizontal else Vector2(p.mover.pos.x, 4.0)
		field.boss_roll(start, Vector2(1, 0) if horizontal else Vector2(0, 1), attack, Props.flame(2))

func _knight(delta: float, p: Player) -> void:
	walker.chase_range = 60.0 if p.crouching else 240.0  # 足音で追ってくる
	if _dash_time > 0.0:
		_dash(delta, 4.5)
		if _near(p, 12.0):
			field.hurt_player(attack)
			_dash_time = 0.0
			walker.speed_mult = _base_speed
		return
	_chase(delta, p)
	if _windup(delta, 0.9, "sweep", _dist(p) < 30.0) == "sweep":
		field.effect_at(Props.rain_ring(34.0), walker.pos, walker.height, 0.25)
		# 横に広く斬る。しゃがむか、騎士より高い所にいればよけられる
		if _dist(p) < 36.0 and not p.crouching and Damage.can_hit(walker.height, p.mover.height):
			field.hurt_player(attack)
	# 離れていると、剣を振って3方向に衝撃波
	if _windup(delta, 0.7, "wave", _clock1 >= 5.0 and _dist(p) > 44.0 and _dist(p) < 120.0 and Damage.can_hit(walker.height, p.mover.height)) == "wave":
		_clock1 = 0.0
		_fan(p, 65.0, 3, 0.3)
	# 2段目：地面を割る（主人公へ向かう印の列が、手前から順に弾ける）
	if phase == 2 and _clock3 >= 6.0 and _wind < 0.0:
		_clock3 = 0.0
		var d := (p.mover.pos - walker.pos).normalized()
		for k in range(1, 7):
			field.boss_strike(walker.pos + d * k * 14.0, 0.5 + k * 0.12, 9.0, attack, Props.rain_ring(10.0))
	# 2段目：離れているとまっすぐ突進する。亡霊を呼ぶ
	if phase == 2:
		if _windup(delta, 0.6, "dash", _dist(p) > 40.0 and _dist(p) < 140.0 and p.mover.height == walker.height) == "dash":
			_dash_dir = (p.mover.pos - walker.pos).normalized()
			_dash_time = 0.7
		if _summon >= 14.0:
			_summon = 0.0
			_call_minions(EnemyKind.Kind.GHOST, 2)

func _golem(delta: float, p: Player) -> void:
	if _wind_kind == "rolling" and _dash_time > 0.0:
		var bumped := _dash(delta, 5.0)
		if _near(p, 12.0):
			field.hurt_player(attack)
		if bumped:
			stunned = STUN_SECONDS  # 壁にぶつかって目を回す（その間は2倍）
			field.camera.shake(3.0)
			field.effect_at(Props.rain_ring(16.0), walker.pos, walker.height, 0.3)
		if _dash_time <= 0.0:
			_wind_kind = ""
		return
	_chase(delta, p)
	if _windup(delta, 0.8, "slam", _dist(p) < 26.0) == "slam":
		field.camera.shake(3.0)
		field.effect_at(Props.rain_ring(24.0), walker.pos, walker.height, 0.3)
		if _near(p, 26.0):
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
	# 地響き：ときどき地面を揺らして、まわり（2〜3マス先）に奈落を開ける
	if _clock1 >= GOLEM_QUAKE and _wind < 0.0 and _dist(p) < 100.0:
		_clock1 = 0.0
		field.camera.shake(3.0)
		var cells: Array = []
		var c0 := walker.cell()
		for i in 6:
			var a := randf() * TAU
			cells.append(c0 + Vector2i((Vector2.from_angle(a) * randf_range(2.0, 3.5)).round()))
		cells.append(p.mover.cell())
		field.boss_pits(cells, PIT_WARN, PIT_OPEN - 1.0)
	# 2段目：大岩を、主人公の方へまっすぐ転がしてくる
	if phase == 2 and _clock3 >= 7.0 and _wind < 0.0:
		_clock3 = 0.0
		var d := p.mover.pos - walker.pos
		field.boss_roll(walker.pos, Vector2(signf(d.x), 0) if absf(d.x) > absf(d.y) else Vector2(0, signf(d.y)), attack)
	# 2段目：丸まって、主人公の方へ転がる（縦か横にまっすぐ）
	if phase == 2 and _windup(delta, 0.8, "roll", _dist(p) > 30.0 and _clock2 >= 4.0) == "roll":
		_clock2 = 0.0
		var d := p.mover.pos - walker.pos
		_dash_dir = Vector2(signf(d.x), 0) if absf(d.x) > absf(d.y) else Vector2(0, signf(d.y))
		_dash_time = 2.0
		_wind_kind = "rolling"

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
	if _wind_kind == "leaping" and _dash_time > 0.0:
		_dash_time -= delta
		var k := clampf(1.0 - _dash_time / 0.5, 0.0, 1.0)
		walker.pos = _leap_from.lerp(_leap_to, k)
		var c := walker.cell()
		if walker.map.in_bounds(c):
			walker.height = walker.map.get_height(c)
		if _dash_time <= 0.0:
			_wind_kind = ""
			field.camera.shake(2.5)
			for i in 8:  # 着いた所のまわりに炎の輪
				var a := i * TAU / 8.0
				field.boss_fire(walker.pos + Vector2.from_angle(a) * 18.0, walker.height, 2.5, maxi(1, attack / 2))
			if _near(p, 14.0):
				field.hurt_player(attack)
		return
	_chase(delta, p)
	_trail_clock += delta
	if _trail_clock >= 0.25:
		_trail_clock = 0.0
		field.boss_fire(walker.pos, walker.height, 3.0, maxi(1, attack / 2))  # 通った跡が燃える
	# 離れていると、ためて火を5方向に吐く
	if _windup(delta, 0.5, "breath", _clock1 >= 4.0 and _dist(p) > 30.0 and _dist(p) < 100.0) == "breath":
		_clock1 = 0.0
		_fan(p, 70.0, 5, 0.22)
	# 2段目：火の雨（主人公のまわりに印が出て、少しあとに落ちる）
	if phase == 2 and _clock3 >= 5.0:
		_clock3 = 0.0
		for i in 3:
			var at := p.mover.pos + (Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(14.0, 28.0))
			field.boss_strike(at, 1.0, 10.0, attack, Props.flame(i % 3))
	# 2段目：ためて跳びかかる
	if phase == 2 and _windup(delta, 0.5, "leap", _clock2 >= 4.0 and _dist(p) < 100.0) == "leap":
		_clock2 = 0.0
		_leap_from = walker.pos
		_leap_to = p.mover.pos
		var c := HeightMap.world_to_cell(_leap_to)
		var map := walker.map
		if not map.in_bounds(c) or map.is_wall(c) or map.is_pit(c) or map.is_water(c):
			_leap_to = walker.pos
		_dash_time = 0.5
		_wind_kind = "leaping"

func _twin(delta: float, p: Player) -> void:
	# 2段目：隠れる方が5秒ごとに入れ替わる
	if phase == 2 and not enraged and partner != null and is_instance_valid(partner) and not hider and _clock2 >= 5.0:
		_clock2 = 0.0
		hider = true
		partner.hider = false
		partner._clock2 = 0.0
	if _dash_time > 0.0:
		_dash(delta, 4.0)  # 前に立つ方の突進
		if _near(p, 14.0):
			field.hurt_player(attack)
			_dash_time = 0.0
			walker.speed_mult = _base_speed
		return
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
	if _windup(delta, 0.5, "hit", _near(p, 20.0)) == "hit":
		if _dist(p) < 22.0:
			field.hurt_player(attack)
	# 前に立つ方は、少し離れると、ためて突進する
	if not hider and _windup(delta, 0.6, "charge", _clock1 >= 5.0 and _dist(p) > 30.0 and _dist(p) < 100.0) == "charge":
		_clock1 = 0.0
		_dash_dir = (p.mover.pos - walker.pos).normalized()
		_dash_time = 0.45
	if (hider or enraged) and _cool <= 0.0 and _wind < 0.0:
		_cool = 2.5
		if enraged or phase == 2:
			_fan(p, 75.0)  # 2段目は後ろの方も3方向
		else:
			_throw(p, 70.0)

func _guardian(delta: float, p: Player) -> void:
	# 2段目：回る向きが5秒ごとに変わり、速くなる
	if phase == 2 and int(_t / 5.0) != int((_t - delta) / 5.0):
		_spin = -_spin
	_turn = wrapf(_turn + (0.6 if phase == 1 else 1.0) * _spin * delta, -PI, PI)  # ゆっくり回る
	var to_p := (p.mover.pos - walker.pos)
	if _cool <= 0.0 and _wind < 0.0 and to_p.length() < 140.0 and facing().dot(to_p.normalized()) > 0.6:
		_cool = 1.8
		_throw(p, 75.0)
	if _windup(delta, 0.7, "swipe", to_p.length() < 24.0) == "swipe":
		if _near(p, 26.0):
			field.hurt_player(attack)
	# 床に十字の印が出て、少しあとに火柱が立つ（2段目はまっすぐの十字と斜めの十字が交互）
	if _clock1 >= 6.0:
		_clock1 = 0.0
		_moves += 1
		var tilt := PI / 4.0 if phase == 2 and _moves % 2 == 0 else 0.0
		for k in 4:
			var d := Vector2.from_angle(k * PI / 2.0 + tilt)
			for r in [2, 3, 4]:
				field.boss_strike(walker.pos + d * r * HeightMap.CELL_PX, 1.1, 8.0, attack, Props.pillar())
	# 2段目：ためて、まわりを薙ぐ（離れればよけられる）
	if phase == 2 and _windup(delta, 0.9, "spin", _clock2 >= 6.0 and to_p.length() < 60.0) == "spin":
		_clock2 = 0.0
		field.effect_at(Props.rain_ring(32.0), walker.pos, walker.height, 0.3)
		if _near(p, 34.0):
			field.hurt_player(attack)

func _bright(delta: float, p: Player) -> void:
	# ゆっくり主人公の方を向く（背中の目は反対を向く）
	var want := (p.mover.pos - walker.pos).angle()
	_turn = rotate_toward(_turn, want, 0.5 * delta)
	var phase_t := fmod(_t, BRIGHT_PERIOD)
	var charging := phase_t > BRIGHT_PERIOD - BRIGHT_CHARGE
	_glow = charging  # 光をためている間は光って見える
	if int(_t / BRIGHT_PERIOD) != int((_t - delta) / BRIGHT_PERIOD):
		# 光る瞬間：背中の目が画面の手前を向いていたら、画面が白くなる
		var toward_viewer: Vector2 = field.camera.screen_dir_to_world(Vector2.DOWN)
		if (-facing()).dot(toward_viewer) > 0.5:
			field.flash_screen(BRIGHT_FLASH)
	if not charging and _cool <= 0.0:
		_cool = 1.6
		_throw(p, 80.0)
	# ときどき消えて、別の所に現れる（背中を取り直さなければならない）
	if _clock1 >= 10.0 and not charging:
		_clock1 = 0.0
		_teleport()
	# 2段目：光の雨（落ちる所に印）と、影を呼ぶ
	if phase == 2:
		if _clock2 >= 5.0:
			_clock2 = 0.0
			for i in 5:
				var at := p.mover.pos + (Vector2.ZERO if i == 0 else Vector2.from_angle(i * TAU / 4.0 + randf()) * randf_range(14.0, 30.0))
				field.boss_strike(at, 1.0, 10.0, attack, Props.pillar())
		if _summon >= 12.0:
			_summon = 0.0
			_call_minions(EnemyKind.Kind.SHADOW, 2)
		# 回る光の柱の列（4方向へ、手前から順に）
		if _clock3 >= 7.0:
			_clock3 = 0.0
			_moves += 1
			var base := _moves * 0.5
			for k in 4:
				var d := Vector2.from_angle(base + k * PI / 2.0)
				for r in range(1, 5):
					field.boss_strike(walker.pos + d * r * 14.0, 0.6 + r * 0.15, 8.0, attack, Props.pillar())

## ブライトが別の所へ移る（もとの所のまわりの、同じ高さで歩けるマス）。煙が出る。
func _teleport() -> void:
	var map := walker.map
	var c0 := HeightMap.world_to_cell(_home)
	for i in 20:
		var c := c0 + Vector2i(randi_range(-4, 4), randi_range(-3, 3))
		if c == walker.cell() or not map.in_bounds(c) or map.is_wall(c) or map.is_pit(c) or map.is_water(c) or walker.forbidden.has(c):
			continue
		if map.get_height(c) != walker.height:
			continue
		field.effect_at(Props.rain_ring(14.0), walker.pos, walker.height, 0.35)
		walker.pos = HeightMap.cell_center(c)
		field.effect_at(Props.rain_ring(14.0), walker.pos, walker.height, 0.35)
		return

func _queen(delta: float, p: Player) -> void:
	if landed > 0.0:
		landed -= delta  # 急降下のあと、しばらく地面にいる（剣も届く）
		return
	if _wind_kind == "diving" and _dash_time > 0.0:
		_dash(delta, 3.5)
		if _dist(p) < 12.0:
			field.hurt_player(attack)
		if _dash_time <= 0.0:
			_wind_kind = ""
			landed = QUEEN_LANDED
			field.effect_at(Props.rain_ring(14.0), walker.pos, walker.height, 0.3)
			_fan(p, 60.0, 8, TAU / 8.0)  # 降りたときにも針を8方向
		return
	# 主人公のまわりを回る
	var d := p.mover.pos - walker.pos
	if _wind < 0.0 and d.length() > 0.1:
		var tangent := d.normalized().orthogonal()
		var radial := d.normalized() * clampf((d.length() - 48.0) / 16.0, -1.0, 1.0)
		walker.dir = (tangent + radial).normalized()
		walker.step(delta)
	if _cool <= 0.0 and _wind < 0.0 and d.length() < 150.0:
		_cool = 1.8
		_fan(p, 70.0)  # 針を3本
	if _summon >= 9.0:
		_summon = 0.0
		_call_minions(EnemyKind.Kind.WASP, 2)
	# ときどき針を8方向に撃つ
	if _clock1 >= 7.0 and _wind < 0.0:
		_clock1 = 0.0
		_fan(p, 60.0, 8, TAU / 8.0)
	# 2段目：ためて急降下
	if phase == 2 and _windup(delta, 0.5, "dive", _clock2 >= 5.0 and d.length() < 110.0) == "dive":
		_clock2 = 0.0
		_dash_dir = (p.mover.pos - walker.pos).normalized()
		_dash_time = 0.6
		_wind_kind = "diving"

func _chest_king(delta: float, p: Player) -> void:
	_shuffle -= delta
	if _shuffle <= 0.0 and _wind < 0.0:
		_shuffle = CHEST_SHUFFLE if phase == 1 else CHEST_SHUFFLE_2
		_shuffle_places()
		return
	# ときどき本物だけが口を開けて、金貨を3方向に吐く（見分ける合図にもなる）
	if _clock1 >= 5.0 and _wind < 0.0:
		_clock1 = 0.0
		open_time = maxf(open_time, 0.7)
		_fan(p, 55.0, 3, 0.35)
	# 2段目：擬態箱を1つ呼ぶ（いる間は呼ばない）
	if phase == 2 and _clock3 >= 12.0 and minion_count() == 0:
		_clock3 = 0.0
		_call_minions(EnemyKind.Kind.MIMIC, 1)
	# 本物だけが噛みつく
	if _windup(delta, 0.5, "bite", _dist(p) < CHEST_BITE - 2.0 and absi(p.mover.height - walker.height) <= 1) == "bite":
		open_time = 0.8
		field.effect_at(Props.rain_ring(16.0), walker.pos, walker.height, 0.2)
		if _near(p, CHEST_BITE):
			field.hurt_player(attack)

## にせものを DECOYS 個にそろえる（まわりの平らで歩けるマスに）。
func _refill_decoys() -> void:
	decoys = decoys.filter(func(d): return is_instance_valid(d) and d.walker.alive)
	var used := {walker.cell(): true}
	for d in decoys:
		used[d.walker.cell()] = true
	for c in _chest_spots():
		if decoys.size() >= DECOYS:
			break
		if used.has(c):
			continue
		used[c] = true
		var d := BossDecoy.new()
		d.setup(walker.map, c, camera)
		field.add_boss_part(d)
		decoys.append(d)

## 宝箱を置けるマス（もとの所のまわり、同じ高さで歩ける所）。毎回まぜる。
func _chest_spots() -> Array:
	var out := []
	var c0 := HeightMap.world_to_cell(_home)
	var map := walker.map
	for dy in range(-3, 4):
		for dx in range(-4, 5):
			var c := c0 + Vector2i(dx, dy)
			if (dx + dy) % 2 != 0 or c == c0:
				continue
			if not map.in_bounds(c) or map.is_wall(c) or map.is_pit(c) or map.is_water(c) or walker.forbidden.has(c):
				continue
			if map.get_height(c) != map.get_height(c0):
				continue
			out.append(c)
	out.shuffle()
	return out

## 本物とにせものが場所を入れ替える（煙が出る）。壊れたにせものは足りない分だけ戻る。
func _shuffle_places() -> void:
	_refill_decoys()
	var cells := [walker.cell()]
	for d in decoys:
		cells.append(d.walker.cell())
	cells.shuffle()
	walker.pos = HeightMap.cell_center(cells[0])
	walker.height = walker.map.get_height(cells[0])
	for i in decoys.size():
		decoys[i].move_to(cells[i + 1])
	for c in cells:
		field.effect_at(Props.rain_ring(8.0), HeightMap.cell_center(c), walker.map.get_height(c), 0.25)

func _draw() -> void:
	if camera == null:
		return
	if burrow > 0.0:
		return  # もぐっている間は、足元の影（印）だけ
	if not _visible_body and group in ["草むらの大蛇", "満ち引きする溶岩"]:
		_draw_shadow()  # 大蛇は見えない向きのとき、溶岩は満ちている間は、影だけ
		return
	super._draw()
