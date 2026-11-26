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
##
## 2026-11-26（4回目の直し）：どのボスにも大技を4〜6つ足した（_special_move。数秒ごとに、段と距離に合う技を前と違うものから選ぶ。
## 大技の前は体が光る（_tele）。連続技は _later で少しあとに動きを入れる）。離れたまま FAR_LIMIT 秒たつと、詰めてくる技（_punish_far）を使う。
## 構え（BossGuard）を剣・鉄球・爆弾で削りきると崩れて目を回す（弓で逃げながら撃ち続けるだけでは勝てない）。

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
## 大技（2026-11-26）
const FAR_RANGE := 96.0  ## これより離れている時間を数える
const FAR_LIMIT := 4.0  ## 離れたままこれだけたつと詰めてくる
const SPECIAL_MIN := 3.0
const SPECIAL_MAX := 5.0
var _far_t := 0.0
var _special := 4.0
var _last_special := ""
var _tele := 0.0  ## 大技の前に光っている残り秒（その間は動かない）
var _plan: Array = []  ## [残り秒, Callable]：少しあとにする動き（連続技）
var _pv := Vector2.ZERO  ## 主人公の速さ（先読みに使う）
var _last_ppos := Vector2.INF
var _leap_time := 0.0  ## 跳んでいる残り秒
var _leap_total := 0.5
var _leap_land := ""
var _rush_t := 0.0  ## まっすぐ走る残り秒（体当たり）
var _rush_mult := 4.0
var _orbit_t := 0.0  ## 主人公のまわりを回る残り秒
var _orbit_end: Callable
var _orbit_dir := 1.0
## 使った大技の名前（テスト用）
var specials_used: Array = []
## 構え（崩し、2026-11-26）。剣・鉄球・爆弾で削りきると崩れて目を回す
var guard: BossGuard

func setup(f: Node, name_: String, cell: Vector2i, map: HeightMap, cam: StackCamera, defeated := 0) -> void:
	field = f
	boss_name = name_
	group = BossKind.group(name_)
	camera = cam
	attack = BossKind.attack(name_, defeated)
	var hp := BossKind.hp(name_, defeated)
	walker = EnemyWalker.new(map, cell, Vector2.DOWN, hp, 1)
	guard = BossGuard.new(hp, BossGuard.WEAK.get(group, ""))
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
		"闇の王":
			walker.speed_mult = 1.25
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
	shadow_radius = 16.0 if group != "宝箱の王" else 12.0
	voxel_scale = BossModels.DRAW_SCALE
	walker.touch_radius = EnemyWalker.TOUCH_RADIUS + BossModels.BODY_EXTRA
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

## 画面をゆらし、地響きの音を鳴らす（2026-11-26）。
func _boom(amount: float) -> void:
	field.camera.shake(amount)
	Sfx.play("stomp" if amount >= 2.5 else "land", walker.pos)

## 近づいたら動き出す。宝箱の王は、にせものを並べる。
func wake() -> void:
	if active:
		return
	active = true
	Sfx.play("roar", walker.pos)
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
	var blocked := blocks_ball(from) if source in ["ball", "bomb", "boulder"] else blocks(from)
	if blocked:
		return "block"
	if stunned > 0.0:
		return "weak"
	return ""

## 構えを通したダメージ（field.damage_target が使う）。構えを削りきると崩れて目を回す（STAGGER 秒、その間は×2）。
func guard_damage(source: String, dmg: int) -> int:
	if stunned > 0.0:
		return dmg
	var out := maxi(1, roundi(dmg * guard.mult(source)))
	if guard.hit(source, dmg):
		stunned = BossGuard.STAGGER
		_interrupt()
		_boom(2.0)
	return out

## 崩れたとき：ためている技・連続技・走り・跳びをやめる（跳んでいたら、着く所に下ろす）。
func _interrupt() -> void:
	_wind = -1.0
	_dash_time = 0.0
	_rush_t = 0.0
	_orbit_t = 0.0
	_tele = 0.0
	_plan.clear()
	if _leap_time > 0.0:
		_leap_time = 0.0
		walker.pos = _leap_to
		_fix_height()
	if _wind_kind in ["leaping", "rolling", "diving"]:
		_wind_kind = ""
	walker.speed_mult = _base_speed

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
		_boom(3.0)
		Sfx.play("phase")
		Sfx.play("roar", walker.pos)
		if group != "双子" or not hider:
			field.notice("%sが怒った！" % group, 2.0)
		match group:
			"廃城の主":
				_call_minions(EnemyKind.Kind.GHOST, 2)
			"闇の王":
				_call_minions(EnemyKind.Kind.WOLF, 2)
			"宝箱の王":
				_shuffle = minf(_shuffle, 0.5)

func _process(delta: float) -> void:
	_hit_flash = maxf(0.0, _hit_flash - delta)
	stunned = maxf(0.0, stunned - delta)
	if active:
		guard.update(delta)
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
		_track(delta, p)
		_step_plan(delta)
		if not _generic_motion(delta, p):
			_far_t = _far_t + delta if _dist(p) > FAR_RANGE else maxf(0.0, _far_t - delta * 2.0)
			_special -= delta * (1.35 if phase == 2 else 1.0)
			if _free():
				if _far_t >= FAR_LIMIT:
					_far_t = 0.0
					_special = maxf(_special, 2.0)
					_punish_far(p)
				elif _special <= 0.0:
					_special = randf_range(SPECIAL_MIN, SPECIAL_MAX)
					_special_move(p)
			if _tele <= 0.0:
				_dispatch(delta, p)
	_step_rocks(delta)
	_look()
	super._process(delta)

func _dispatch(delta: float, p: Player) -> void:
	match group:
		"岩転がしの巨人": _giant(delta, p)
		"草むらの大蛇": _snake(delta, p)
		"満ち引きする溶岩": _lava(delta, p)
		"廃城の主", "闇の王": _knight(delta, p)
		"岩窟のぬし": _golem(delta, p)
		"溶岩洞のぬし": _salamander(delta, p)
		"双子": _twin(delta, p)
		"らせん塔の番人": _guardian(delta, p)
		"ブライト": _bright(delta, p)
		"女王蜂": _queen(delta, p)
		"宝箱の王": _chest_king(delta, p)

## 色と姿（ためている間は光る。目を回していると黄色く点滅。2段目は少し赤い）。
func _look() -> void:
	if _wind >= 0.0 or _hit_flash > 0.0 or _glow or (_tele > 0.0 and int(_tele * 10.0) % 2 == 0):
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
	if _leap_time > 0.0:
		lift_px = sin(clampf(1.0 - _leap_time / _leap_total, 0.0, 1.0) * PI) * 30.0
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
			Sfx.play("growl", walker.pos, -5.0, 0.15)  # ためる合図
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
	if _wind >= 0.0 or _dash_time > 0.0 or _tele > 0.0:
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
	if walker.speed_mult != mult:
		Sfx.play("dash", walker.pos)  # 走りだした
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
		_boom(3.0)
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
		_boom(3.5)
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
			_boom(2.5)
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
			_call_minions(EnemyKind.Kind.GHOST if group == "廃城の主" else EnemyKind.Kind.WOLF, 2)

func _golem(delta: float, p: Player) -> void:
	if _wind_kind == "rolling" and _dash_time > 0.0:
		var bumped := _dash(delta, 5.0)
		if _near(p, 12.0):
			field.hurt_player(attack)
		if bumped:
			stunned = STUN_SECONDS  # 壁にぶつかって目を回す（その間は2倍）
			_boom(3.0)
			field.effect_at(Props.rain_ring(16.0), walker.pos, walker.height, 0.3)
		if _dash_time <= 0.0:
			_wind_kind = ""
		return
	_chase(delta, p)
	if _windup(delta, 0.8, "slam", _dist(p) < 26.0) == "slam":
		_boom(3.0)
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
		_boom(3.0)
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
			_boom(2.5)
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
		Sfx.play("teleport", walker.pos)
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
		if _dash_time <= 0.0 and _dives_left > 0:
			_dives_left -= 1
			_dash_dir = (_lead(p, 0.3) - walker.pos).normalized()
			_dash_time = 0.6
			return
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

# ---------------------------------------------------------------- 大技（2026-11-26 の4回目の直し）

## 大技を始めてよいか（ためている・走っている・跳んでいる・もぐっている間は始めない）。
func _free() -> bool:
	return _wind < 0.0 and _dash_time <= 0.0 and _tele <= 0.0 and _leap_time <= 0.0 and _rush_t <= 0.0 \
		and _orbit_t <= 0.0 and burrow <= 0.0 and landed <= 0.0 and not (_wind_kind in ["leaping", "rolling", "diving"])

## 主人公の速さを覚える（先読みに使う）。
func _track(delta: float, p: Player) -> void:
	if _last_ppos != Vector2.INF and delta > 0.0:
		var v := (p.mover.pos - _last_ppos) / delta
		if v.length() < 200.0:
			_pv = _pv.lerp(v, clampf(delta * 6.0, 0.0, 1.0))
	_last_ppos = p.mover.pos

## t 秒後に主人公がいそうな所。
func _lead(p: Player, t: float) -> Vector2:
	return p.mover.pos + _pv * t

func _later(t: float, f: Callable) -> void:
	_plan.append([t, f])

func _step_plan(delta: float) -> void:
	var i := 0
	while i < _plan.size():
		_plan[i][0] -= delta
		if _plan[i][0] <= 0.0:
			var f: Callable = _plan[i][1]
			_plan.remove_at(i)
			if walker.alive and stunned <= 0.0 and f.is_valid():
				f.call()
		else:
			i += 1

## 体を光らせて t 秒ためてから f をする（その間は動かない）。
func _telegraph(t: float, f: Callable) -> void:
	_tele = t
	Sfx.play("growl", walker.pos, -4.0, 0.15)
	_later(t, f)

## 跳ぶ・走る・回る（大技の動き）。動いている間は true（ふだんの戦い方はしない）。
func _generic_motion(delta: float, p: Player) -> bool:
	_tele = maxf(0.0, _tele - delta)
	if _leap_time > 0.0:
		_leap_time -= delta
		var k := clampf(1.0 - _leap_time / _leap_total, 0.0, 1.0)
		walker.pos = _leap_from.lerp(_leap_to, k)
		if _leap_time <= 0.0:
			_leap_time = 0.0
			walker.pos = _leap_to
			_fix_height()
			_land(p)
		return true
	if _rush_t > 0.0:
		_rush_t -= delta
		walker.dir = _dash_dir
		walker.speed_mult = _rush_mult
		var before := walker.pos
		walker.step(delta)
		if _near(p, 14.0):
			field.hurt_player(attack)
		if walker.pos.distance_to(before) < 0.01 or _rush_t <= 0.0:
			_rush_t = 0.0
			walker.speed_mult = _base_speed
		return true
	if _orbit_t > 0.0:
		_orbit_t -= delta
		var d := p.mover.pos - walker.pos
		if d.length() > 0.1:
			var tangent := d.normalized().orthogonal() * _orbit_dir
			var radial := d.normalized() * clampf((d.length() - 40.0) / 16.0, -1.0, 1.0)
			walker.dir = (tangent + radial).normalized()
			walker.speed_mult = maxf(_base_speed, 1.0) * 1.8
			walker.step(delta)
		if _orbit_t <= 0.0:
			walker.speed_mult = _base_speed
			if _orbit_end.is_valid():
				_orbit_end.call()
		return true
	return false

func _fix_height() -> void:
	var c := walker.cell()
	if walker.map.in_bounds(c):
		walker.height = maxi(0, walker.map.get_height(c))

## 降りられるマス（to のマスか、そのまわり）。なければ (-9999, -9999)。
func _landing_cell(to: Vector2) -> Vector2i:
	var map := walker.map
	var c0 := HeightMap.world_to_cell(to)
	for off in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
		var c: Vector2i = c0 + off
		if map.in_bounds(c) and not map.is_wall(c) and not map.is_pit(c) and not map.is_water(c) and not walker.forbidden.has(c):
			return c
	return Vector2i(-9999, -9999)

## to へ跳ぶ（seconds 秒。着く所に影が出る）。着いたら land の技。跳べなければ false。
func _leap(to: Vector2, seconds: float, land: String) -> bool:
	var c := _landing_cell(to)
	if c.x == -9999:
		return false
	_leap_from = walker.pos
	_leap_to = to if HeightMap.world_to_cell(to) == c else HeightMap.cell_center(c)
	_leap_total = seconds
	_leap_time = seconds
	_leap_land = land
	Sfx.play("enemy_jump", walker.pos)
	var s: StackSprite = field.effect_at(Props.aim_shadow(), _leap_to, walker.map.get_height(c), seconds)
	if s != null:
		s.set_meta("steady", true)
	return true

func _leap_at(p: Player, seconds: float, land: String) -> void:
	_leap(_lead(p, seconds * 0.5), seconds, land)

func _leap_home(seconds: float) -> void:
	_left_home = false
	_leap(_home, seconds, "slam")

## 跳んで着いた（まわりに衝撃。land で技が足される）。
func _land(p: Player) -> void:
	_boom(3.0)
	field.effect_at(Props.rain_ring(28.0), walker.pos, walker.height, 0.3)
	if _near(p, 26.0):
		field.hurt_player(attack)
	match _leap_land:
		"fire":
			for i in 8:
				field.boss_fire(walker.pos + Vector2.from_angle(i * TAU / 8.0) * 18.0, walker.height, 2.5, maxi(1, attack / 2))
		"ring":
			_ring(8, 60.0, randf() * TAU)
		"quake":
			var cells: Array = []
			var c0 := walker.cell()
			for i in 6:
				cells.append(c0 + Vector2i((Vector2.from_angle(i * TAU / 6.0 + randf() * 0.5) * randf_range(2.0, 3.0)).round()))
			field.boss_pits(cells, PIT_WARN, PIT_OPEN - 1.5)

## まっすぐ走る（体当たり）。
func _rush(dir: Vector2, seconds: float, mult: float) -> void:
	if dir == Vector2.ZERO:
		return
	_dash_dir = dir.normalized()
	_rush_t = seconds
	_rush_mult = mult
	Sfx.play("dash", walker.pos)

func _rush_at(p: Player, seconds: float, mult: float) -> void:
	_rush(p.mover.pos - walker.pos, seconds, mult)

## 主人公のまわりを seconds 秒回り、そのあと end をする。
func _orbit(seconds: float, end: Callable) -> void:
	_orbit_t = seconds
	_orbit_end = end
	_orbit_dir = -1.0 if randf() < 0.5 else 1.0

## 向き angle へ弾を撃つ（高さは主人公の低い方へ合わせる）。
func _shoot_dir(angle: float, speed: float) -> void:
	var p := _player()
	var b := Bullet.new()
	b.aim(walker.pos, walker.height, walker.pos + Vector2.from_angle(angle) * 60.0, mini(walker.height, p.mover.height), speed)
	b.damage = attack
	field.boss_shot(b)

## まわり n 方向へ弾を撃つ。
func _ring(n: int, speed: float, offset := 0.0) -> void:
	for i in n:
		_shoot_dir(offset + i * TAU / n, speed)

## to へ弾を撃つ。
func _throw_at(to: Vector2, speed: float) -> void:
	var p := _player()
	if not Damage.can_hit(walker.height, p.mover.height):
		return
	var b := Bullet.new()
	b.aim(walker.pos, walker.height, to, p.mover.height, speed)
	b.damage = attack
	field.boss_shot(b)

## 先読みして撃つ。
func _aimed_shot(p: Player, lead: float, speed: float) -> void:
	_throw_at(_lead(p, lead), speed)

## 少しあとに落ちる攻撃（印が先に出る）。
func _strike(at: Vector2, delay: float, r: float, model: VoxelModel = null) -> void:
	field.boss_strike(at, delay, r, attack, model if model != null else Props.rain_ring(r))

## 主人公の今いる所に落ちる攻撃。
func _strike_on(p: Player, delay: float, r: float, model: VoxelModel) -> void:
	_strike(p.mover.pos, delay, r, model)

## from から dir へ n 個並ぶ攻撃（手前から順に落ちる）。
func _strike_line(from: Vector2, dir: Vector2, n: int, spacing: float, d0: float, dstep: float, r: float, model: VoxelModel) -> void:
	var d := dir.normalized()
	for k in range(1, n + 1):
		_strike(from + d * k * spacing, d0 + k * dstep, r, model)

## center のまわりの輪（radii の順に外へ広がる）。gap の向きだけ空いている（そこへ逃げる）。
func _ring_wave(center: Vector2, radii: Array, n: int, gap: float, d0: float, dstep: float, model: VoxelModel = null) -> void:
	for j in radii.size():
		var r: float = radii[j]
		var count := maxi(5, int(n * r / radii[radii.size() - 1]))
		for i in count:
			var a := i * TAU / count
			if absf(wrapf(a - gap, -PI, PI)) < 0.45:
				continue
			_strike(center + Vector2.from_angle(a) * r, d0 + j * dstep, 9.0, model)

## 主人公のまわりに石や光が降る（先読みした所のまわり）。
func _rain_around(p: Player, n: int, spread: float, model: VoxelModel) -> void:
	var c := _lead(p, 0.6)
	for i in n:
		var at := c if i == 0 else c + Vector2.from_angle(randf() * TAU) * randf_range(10.0, spread)
		_strike(at, randf_range(0.8, 1.4), 10.0, model)

## 尾や腕でまわりを払う。
func _sweep(r: float, low_dodge := false) -> void:
	var p := _player()
	field.effect_at(Props.rain_ring(r), walker.pos, walker.height, 0.25)
	Sfx.play("sword", walker.pos)
	if _dist(p) < r + 2.0 and absi(p.mover.height - walker.height) <= 1 and not (low_dodge and p.crouching):
		field.hurt_player(attack)

## 前と違う大技を選ぶ（テスト用に覚える）。
func _choose(opts: Array) -> String:
	var pool := opts.filter(func(o): return o != _last_special)
	if pool.is_empty():
		pool = opts
	var pick: String = pool[randi() % pool.size()]
	_last_special = pick
	specials_used.append(pick)
	return pick

## 炎を置く（燃える跡）。
func _fire_at(at: Vector2) -> void:
	var c := HeightMap.world_to_cell(at)
	if walker.map.in_bounds(c) and not walker.map.is_wall(c):
		field.boss_fire(at, walker.map.get_height(c), 2.5, maxi(1, attack / 2))

## 主人公のそば（2〜3マス）の歩けるマスへ消えて現れる。
func _blink_near(p: Player) -> void:
	var map := walker.map
	for i in 24:
		var at := p.mover.pos + Vector2.from_angle(randf() * TAU) * randf_range(32.0, 48.0)
		var c := HeightMap.world_to_cell(at)
		if not map.in_bounds(c) or map.is_wall(c) or map.is_pit(c) or map.is_water(c) or walker.forbidden.has(c):
			continue
		if absi(map.get_height(c) - p.mover.height) > 1:
			continue
		field.effect_at(Props.rain_ring(14.0), walker.pos, walker.height, 0.35)
		Sfx.play("teleport", walker.pos)
		walker.pos = HeightMap.cell_center(c)
		_fix_height()
		field.effect_at(Props.rain_ring(14.0), walker.pos, walker.height, 0.35)
		return

## ボスごとの大技。
func _special_move(p: Player) -> void:
	match group:
		"岩転がしの巨人": _sp_giant(p)
		"草むらの大蛇": _sp_snake(p)
		"満ち引きする溶岩": _sp_lava(p)
		"廃城の主", "闇の王": _sp_knight(p)
		"岩窟のぬし": _sp_golem(p)
		"溶岩洞のぬし": _sp_salamander(p)
		"双子": _sp_twin(p)
		"らせん塔の番人": _sp_guardian(p)
		"ブライト": _sp_bright(p)
		"女王蜂": _sp_queen(p)
		"宝箱の王": _sp_chest(p)

## 離れたままでいると、詰めてくる（弓で逃げながら撃ち続けるだけでは勝てない）。
func _punish_far(p: Player) -> void:
	specials_used.append("punish")
	match group:
		"岩転がしの巨人":
			_telegraph(0.5, _rain_around.bind(p, 8, 40.0, Props.crack_rock()))
			_later(1.0, _quake_at.bind(p))
		"草むらの大蛇":
			_start_burrow(p)
		"満ち引きする溶岩":
			_lava_wave(p)
			for i in 3:
				_later(i * 0.5, _strike_on.bind(p, 0.8, 11.0, Props.flame(i % 3)))
		"廃城の主", "闇の王":
			_telegraph(0.4, _leap_at.bind(p, 0.6, "ring"))
		"岩窟のぬし":
			_telegraph(0.6, _golem_roll.bind(p))
		"溶岩洞のぬし":
			_telegraph(0.35, _leap_at.bind(p, 0.5, "fire"))
		"双子":
			_telegraph(0.35, _lunge_at.bind(p))
		"らせん塔の番人":
			_gears(p)
			_later(0.4, _ring.bind(12, 55.0, randf() * TAU))
		"ブライト":
			_blink_near(p)
			_later(0.4, _fan.bind(p, 80.0, 5, 0.2))
		"女王蜂":
			_telegraph(0.35, _queen_dive.bind(p, 0))
		"宝箱の王":
			_coin_rain(p)
			_later(0.3, _chest_dash.bind(p))

func _quake_at(p: Player) -> void:
	_boom(3.0)
	field.boss_pits(_quake_cells(p), PIT_WARN, PIT_OPEN - 1.0)

# 巨人：石の雨・3連投げ・広がる地響きの輪（すき間へ逃げる）・2段目は跳び降りて踏みつけ、また岩棚へ戻る
var _left_home := false  ## 巨人が岩棚から跳び降りている
func _sp_giant(p: Player) -> void:
	if _left_home:
		_left_home = false
		_choose(["go_home"])
		_telegraph(0.4, _leap_home.bind(0.8))
		return
	var opts := ["rock_rain", "volley", "shock_ring"]
	if phase == 2:
		opts.append("leap_down")
	match _choose(opts):
		"rock_rain":
			_telegraph(0.6, _rain_around.bind(p, 6 if phase == 1 else 9, 34.0, Props.crack_rock()))
		"volley":
			_tele = 0.4
			for i in 3:
				_later(0.4 + i * 0.35, _aimed_shot.bind(p, 0.6, 72.0))
		"shock_ring":
			_telegraph(0.7, _giant_ring)
		"leap_down":
			_left_home = true
			_telegraph(0.6, _leap_at.bind(p, 0.8, "slam"))
			_later(6.0, _leap_home.bind(0.8))

func _giant_ring() -> void:
	_boom(3.5)
	_ring_wave(walker.pos, [32.0, 48.0, 64.0, 80.0], 14, randf() * TAU, 0.5, 0.3)

# 大蛇：2回続けて突進・まわりを回ってから噛みつく・毒のつば・2段目は尾の3連払い。離れていると、もぐって足元から出る
func _sp_snake(p: Player) -> void:
	var opts := ["double_lunge", "coil", "spit"]
	if phase == 2:
		opts.append("tail_combo")
	match _choose(opts):
		"double_lunge":
			_telegraph(0.4, _lunge_at.bind(p))
			_later(1.2, _lunge_at.bind(p))
		"coil":
			_orbit(1.6, _lunge_at.bind(p))
		"spit":
			_tele = 0.4
			for i in 3:
				_later(0.4 + i * 0.25, _strike_on.bind(p, 0.9, 11.0, Props.rain_ring(11.0)))
		"tail_combo":
			_telegraph(0.5, _sweep.bind(26.0))
			_later(1.0, _sweep.bind(30.0))
			_later(1.5, _sweep.bind(36.0))

func _lunge_at(p: Player) -> void:
	_dash_dir = (p.mover.pos - walker.pos).normalized()
	_dash_time = 0.45

func _start_burrow(p: Player) -> void:
	specials_used.append("burrow")
	burrow = 1.6
	_burrow_spot = p.mover.pos
	_burrow_mark = field.effect_at(Props.aim_shadow(), _burrow_spot, p.mover.height, 1.6)
	_burrow_mark.set_meta("steady", true)

# 溶岩：らせんの火・追ってくる溶岩の手・まわりの噴火・2段目は火の玉を呼ぶ。離れていると溶岩の波
func _sp_lava(p: Player) -> void:
	var opts := ["spiral", "lava_hand", "eruption"]
	if phase == 2:
		opts.append("bombers")
	match _choose(opts):
		"spiral":
			_tele = 0.5
			var base := randf() * TAU
			var arms := 1 if phase == 1 else 2
			for i in 16:
				for a in arms:
					_later(0.5 + i * 0.09, _shoot_dir.bind(base + i * 0.4 + a * PI, 60.0))
		"lava_hand":
			for i in 3:
				_later(i * 0.5, _strike_on.bind(p, 0.8, 11.0, Props.flame(i % 3)))
		"eruption":
			for i in 8:
				var at := _home + Vector2.from_angle(i * TAU / 8.0 + randf() * 0.4) * randf_range(30.0, 90.0)
				_strike(at, randf_range(0.9, 1.5), 11.0, Props.flame(i % 3))
		"bombers":
			_call_minions(EnemyKind.Kind.BOMBER, 2)

func _lava_wave(p: Player) -> void:
	_moves += 1
	var horizontal := _moves % 2 == 0
	var map := walker.map
	var far := Vector2(map.size.x * HeightMap.CELL_PX - 4.0, p.mover.pos.y) if horizontal else Vector2(p.mover.pos.x, map.size.y * HeightMap.CELL_PX - 4.0)
	field.boss_roll(far, Vector2(-1, 0) if horizontal else Vector2(0, -1), attack, Props.flame(2))

# 廃城の主（闇の王）：3連斬り・跳び斬り・5方向の衝撃波・2段目は亡霊の剣が十字に降る。離れていると跳び斬り
# 闇の王はさらに：闇の弾の輪を2回・主人公のそばへ消えて現れて斬る
func _sp_knight(p: Player) -> void:
	var opts := ["combo", "leap_slash", "wave5"]
	if phase == 2:
		opts.append("swords")
	if group == "闇の王":
		opts.append_array(["dark_ring", "blink_slash"])
	match _choose(opts):
		"combo":
			_telegraph(0.45, _sweep.bind(34.0, true))
			_later(0.5, _rush_at.bind(p, 0.18, 3.5))
			_later(0.85, _sweep.bind(34.0, true))
			_later(1.25, _thrust.bind(p))
		"leap_slash":
			_telegraph(0.5, _leap_at.bind(p, 0.6, "ring"))
		"wave5":
			_telegraph(0.5, _fan.bind(p, 65.0, 5, 0.25))
		"swords":
			var c := p.mover.pos
			for k in 4:
				_strike(c + Vector2.from_angle(k * PI / 2.0 + PI / 4.0) * 22.0, 0.9, 9.0, Props.pillar())
			_strike(c, 1.3, 10.0, Props.pillar())
		"dark_ring":
			_telegraph(0.5, _ring.bind(12, 60.0, randf() * TAU))
			_later(1.0, _ring.bind(12, 60.0, randf() * TAU))
		"blink_slash":
			_telegraph(0.35, _blink_near.bind(p))
			_later(0.75, _sweep.bind(34.0, true))

func _thrust(p: Player) -> void:
	_strike_line(walker.pos, p.mover.pos - walker.pos, 4, 14.0, 0.25, 0.06, 8.0, Props.rain_ring(8.0))

# 岩窟のぬし：大岩を3つ投げる・まわりを閉じる岩の輪（すき間から出る）・肩で突進・2段目は跳んで地響き。離れていると丸まって転がる
func _sp_golem(p: Player) -> void:
	var opts := ["boulder_toss", "cage", "shoulder"]
	if phase == 2:
		opts.append("leap_quake")
	match _choose(opts):
		"boulder_toss":
			_telegraph(0.6, _boulders.bind(p))
		"cage":
			_telegraph(0.5, _cage.bind(p))
		"shoulder":
			_telegraph(0.5, _rush_at.bind(p, 0.5, 4.0))
		"leap_quake":
			_telegraph(0.6, _leap_at.bind(p, 0.8, "quake"))

func _boulders(p: Player) -> void:
	var c := _lead(p, 1.0)
	var side := (c - walker.pos).normalized().orthogonal() * 22.0
	for off in [Vector2.ZERO, side, -side]:
		_strike(c + off, 1.2, 12.0, Props.crack_rock())

func _cage(p: Player) -> void:
	var c := p.mover.pos
	var gap := randf() * TAU
	var radii := [36.0, 24.0, 12.0]
	for j in radii.size():
		var r: float = radii[j]
		var count: int = [10, 7, 4][j]
		for i in count:
			var a: float = i * TAU / count
			if j < 2 and absf(wrapf(a - gap, -PI, PI)) < 0.5:
				continue
			_strike(c + Vector2.from_angle(a) * r, 1.0 + j * 0.4, 9.0, Props.crack_rock())

func _golem_roll(p: Player) -> void:
	var d := p.mover.pos - walker.pos
	_dash_dir = Vector2(signf(d.x), 0) if absf(d.x) > absf(d.y) else Vector2(0, signf(d.y))
	_dash_time = 2.0
	_wind_kind = "rolling"

# 溶岩洞のぬし：薙ぎ払う火炎・地を這う炎の列・尾を回す・跳びかかり。離れていると跳びかかる
func _sp_salamander(p: Player) -> void:
	match _choose(["flamethrower", "fire_line", "tail_spin", "leap"]):
		"flamethrower":
			_tele = 0.4
			var base := (p.mover.pos - walker.pos).angle()
			for i in 12:
				_later(0.4 + i * 0.1, _shoot_dir.bind(base - 0.6 + i * 0.11, 85.0))
		"fire_line":
			var d := (p.mover.pos - walker.pos).normalized()
			for k in range(1, 9):
				_later(k * 0.08, _fire_at.bind(walker.pos + d * k * 12.0))
		"tail_spin":
			_telegraph(0.6, _sweep.bind(30.0))
			_later(0.65, _ring.bind(8, 60.0, randf() * TAU))
		"leap":
			_telegraph(0.35, _leap_at.bind(p, 0.5, "fire"))

# 双子：2回続けて突進・6方向の弾を2回・主人公をはさむ所へ跳ぶ（後ろの方は弾だけ）
func _sp_twin(p: Player) -> void:
	if hider and not enraged:
		_choose(["ring6"])
		_telegraph(0.4, _ring.bind(6, 65.0, (p.mover.pos - walker.pos).angle()))
		_later(0.9, _ring.bind(6, 65.0, (p.mover.pos - walker.pos).angle() + PI / 6.0))
		return
	match _choose(["double_charge", "ring6", "flank"]):
		"double_charge":
			_telegraph(0.4, _lunge_at.bind(p))
			_later(1.2, _lunge_at.bind(p))
		"ring6":
			_telegraph(0.4, _ring.bind(6, 65.0, 0.0))
			_later(0.9, _ring.bind(6, 65.0, PI / 6.0))
		"flank":
			var other: Vector2 = partner.walker.pos if partner != null and is_instance_valid(partner) else walker.pos
			var away := (p.mover.pos - other)
			away = away.normalized() if away.length() > 0.1 else Vector2.RIGHT
			_telegraph(0.3, _leap.bind(p.mover.pos + away * 36.0, 0.5, "ring"))

# 番人：回る光の線・壁から転がる歯車・12方向の弾を2回・2段目は2本の線
func _sp_guardian(p: Player) -> void:
	var opts := ["laser", "gears", "ring12"]
	if phase == 2:
		opts.append("double_laser")
	match _choose(opts):
		"laser", "double_laser":
			_tele = 0.6
			var beams := 2 if _last_special == "double_laser" else 1
			for k in 8:
				for b in beams:
					_later(0.6 + k * 0.15, _beam.bind(_turn + k * 0.3 * _spin + b * PI, 0.45))
		"gears":
			_gears(p)
		"ring12":
			_telegraph(0.4, _ring.bind(12, 55.0, randf() * TAU))
			_later(1.0, _ring.bind(12, 55.0, randf() * TAU))

func _beam(angle: float, delay: float) -> void:
	_strike_line(walker.pos, Vector2.from_angle(angle), 5, HeightMap.CELL_PX, delay, 0.0, 8.0, Props.pillar())

func _gears(p: Player) -> void:
	field.boss_roll(Vector2(4.0, p.mover.pos.y), Vector2(1, 0), attack)
	field.boss_roll(Vector2(p.mover.pos.x, 4.0), Vector2(0, 1), attack)

# ブライト：光の輪を2回・先読みの光弾5つ・追ってくる闇の手・そばへ消えて現れる・2段目は8方向の光の柱
func _sp_bright(p: Player) -> void:
	var opts := ["light_ring", "homing", "dark_hands", "blink"]
	if phase == 2:
		opts.append("star")
	match _choose(opts):
		"light_ring":
			_telegraph(0.5, _ring.bind(16, 50.0, 0.0))
			_later(1.0, _ring.bind(16, 50.0, TAU / 32.0))
		"homing":
			for i in 5:
				_later(i * 0.25, _aimed_shot.bind(p, 0.4, 85.0))
		"dark_hands":
			for i in 3:
				_later(i * 0.5, _strike_on.bind(p, 0.8, 11.0, Props.pillar()))
		"blink":
			_blink_near(p)
			_later(0.4, _fan.bind(p, 80.0, 5, 0.2))
		"star":
			for k in 8:
				_strike_line(walker.pos, Vector2.from_angle(k * TAU / 8.0 + randf() * 0.2), 5, 14.0, 0.6, 0.12, 8.0, Props.pillar())

# 女王蜂：急降下（2段目は3回続けて）・針の雨・らせんの針・2段目は蜂を呼ぶ
var _dives_left := 0
func _sp_queen(p: Player) -> void:
	var opts := ["dive", "sting_rain", "spiral"]
	if phase == 2:
		opts.append_array(["triple_dive", "guards"])
	match _choose(opts):
		"dive":
			_telegraph(0.4, _queen_dive.bind(p, 0))
		"triple_dive":
			_telegraph(0.4, _queen_dive.bind(p, 2))
		"sting_rain":
			_tele = 0.3
			_rain_around(p, 6, 30.0, Props.rain_ring(10.0))
		"spiral":
			_tele = 0.3
			var base := randf() * TAU
			for i in 12:
				_later(0.3 + i * 0.1, _shoot_dir.bind(base + i * 0.52, 65.0))
		"guards":
			_call_minions(EnemyKind.Kind.WASP, 2)

func _queen_dive(p: Player, more: int) -> void:
	_dives_left = more
	_dash_dir = (_lead(p, 0.3) - walker.pos).normalized()
	_dash_time = 0.6
	_wind_kind = "diving"

# 宝箱の王：金貨の雨・本物が走って噛みつく・すぐ入れ替わる・2段目はにせものも金貨を吐く
func _sp_chest(p: Player) -> void:
	var opts := ["coin_rain", "chest_dash", "shuffle"]
	if phase == 2:
		opts.append("fake_spit")
	match _choose(opts):
		"coin_rain":
			_coin_rain(p)
		"chest_dash":
			_chest_dash(p)
		"shuffle":
			_shuffle = 0.0
		"fake_spit":
			open_time = maxf(open_time, 0.6)
			for d in decoys:
				if is_instance_valid(d) and d.walker.alive:
					var b := Bullet.new()
					b.aim(d.walker.pos, d.walker.height, p.mover.pos, p.mover.height, 55.0)
					b.damage = attack
					field.boss_shot(b)

func _coin_rain(p: Player) -> void:
	open_time = maxf(open_time, 0.8)
	_rain_around(p, 7, 32.0, Props.pickup("money"))

func _chest_dash(p: Player) -> void:
	open_time = maxf(open_time, 1.2)
	_telegraph(0.35, _rush_at.bind(p, 0.6, 4.0))


func _draw() -> void:
	if camera == null:
		return
	if burrow > 0.0:
		return  # もぐっている間は、足元の影（印）だけ
	if not _visible_body and group in ["草むらの大蛇", "満ち引きする溶岩"]:
		_draw_shadow()  # 大蛇は見えない向きのとき、溶岩は満ちている間は、影だけ
		return
	super._draw()
