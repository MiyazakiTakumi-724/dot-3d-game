class_name Enemy
extends StackSprite
## 敵の見た目と動き。種類（EnemyKind）で動きが変わる（設計 2026-11-25 の4章、夜に賢くした：balance-pass 4章）。
## ためている間は体が明るく光る（よけるための合図）。形は EnemyModels。
## スライム：近づくと、ためて跳びかかる。ゴブリン：寄って、ためて叩き（melee_hit）、少し下がる。
## 射手：近づかれると離れる。2秒ごとに撃ち（shot）、3回に1回は3発続けて撃つ。盾持ち：ゆっくり向き直り、ためて叩く。
## 影：体が見えず地面の影だけ。近づくと、ためて跳びこむ。コウモリ・蜂：飛んで回り、ときどき狙って急降下する。
## イノシシ：縦か横に並ぶと、ためて突進。壁にぶつかると目を回す。火の玉：寄って、そばでためて弾ける（exploded）。
## 亡霊：足音を聞いて遠くから寄る。すけたり見えたりする。槍兵：少し離れて構え、ためて長く突く（melee_hit）。
## 投石兵：石を山なりに投げる（lobbed。落ちる所は field が影を出す）。近づかれると逃げる。
## 魔術師：ときどき消えて別の所に現れ、3方向に遅い弾を撃つ。甲虫：かたい。鉄球でひっくり返る。
## 擬態箱：宝箱のふりをしていて、近づくか攻撃されると目を覚まし、寄って噛みつく。
##
## 2026-11-26（4回目の直し）：イノシシのほかの敵に技を足した（_think で選び、_act でためてから走る・跳ぶ。走っている間に触れると当たる）。
## 主人公の動きを先読みする（_lead）。数値は【提案】。
## スライム：跳びかかりを2回続けることがある。倒すと小さい2匹に分かれる（split）。
## ゴブリン：先読みして寄る。少し離れていると跳び斬り、遠いとナイフを投げる。落ちてくる矢を横へよける。叩いたあとに続けて斬ることがある。
## 射手：先読みして撃つ。3発を扇に撃つこともある。間合いの間は横へ回る。近づかれると跳び下がる。
## 盾持ち：正面に近いと盾で突き飛ばす。防いだらすぐ叩き返す。背中に回られると速く向き直る。
## 影：ジグザグに寄る。ときどき主人公の背中へ消えて現れ、すぐ跳びこむ。跳びこんだあと下がる。
## コウモリ・蜂：先読みして急降下。コウモリは2回続けることがある。蜂は離れていると針を飛ばす。
## 火の玉：ふらふら寄り、近いと先読みして飛びこむ。剣で叩くとすぐ弾ける（矢で落とす）。
## 亡霊：すけたあと、主人公の背中に現れる。見えている間、のろいの弾を撃つ。
## 槍兵：ための前半は狙いを合わせ続ける。踏みこんで突く。2回続けて突くことがある。近すぎると槍を回して払う。
## 投石兵：先読みして投げる。3回に1回は3つまとめて。近いと突き飛ばす。
## 魔術師：3方向の弾と、先読みの速い弾をかわりばんこ。近いとまわりに弾を撃って消える。スライムを2回まで呼ぶ（summon）。
## 甲虫：縦か横に並ぶと丸まって転がる（壁にぶつかるとひっくり返る）。近いと角で突く。
## 擬態箱：目を覚ますと、跳んで噛みつく。遠いと金貨を3方向に吐く。

signal shot(bullet: Bullet)
signal melee_hit
## 火の玉が弾けた（まわりにダメージ）
signal exploded(pos: Vector2, height: int)
## 投石兵が石を投げた（落ちる所・高さ・着くまでの秒・ダメージ）
signal lobbed(at: Vector2, height: int, delay: float, damage: int)
## スライムが分かれた（倒れた所・高さ）
signal split(pos: Vector2, height: int)
## 魔術師が手下を呼ぶ
signal summon(kind: EnemyKind.Kind, pos: Vector2)

const SHOOT_INTERVAL := 2.0
const SHOOT_RANGE := 140.0
const BULLET_SPEED := 80.0
## 飛ぶ敵が浮いている高さ（px）
const FLY_LIFT := 12.0
## 火の玉がためる時間
const BOMB_FUSE := 0.6
## 跳びかかる（スライム・影）・急降下する（コウモリ・蜂）：ためる秒、跳ぶ秒、速さの倍率、次までの秒
const POUNCE_WINDUP := 0.45
const POUNCE_TIME := 0.35
const POUNCE_SPEED := 3.6
const POUNCE_REST := 1.6
## 槍兵：構える距離、突きの届く距離、ためる秒
const SPEAR_KEEP := 26.0
const SPEAR_REACH := 34.0
const SPEAR_WINDUP := 0.7
## 投石兵：逃げはじめる距離、投げる間、石が着くまで
const LOB_FLEE := 56.0
const LOB_INTERVAL := 2.6
const LOB_FLIGHT := 1.0
const LOB_RANGE := 130.0
## 魔術師：消えて現れる間
const MAGE_BLINK := 4.5
## 射手が離れはじめる距離
const SHOOTER_FLEE := 40.0
## 盾持ちが向き直る速さ（ラジアン／秒）
const SHIELD_TURN := 1.6
## 擬態箱が目を覚ます距離
const MIMIC_WAKE := 22.0

var walker: EnemyWalker
var kind: EnemyKind.Kind = EnemyKind.Kind.WEAK
var melee := MeleeAttack.new()
var target: Player
## false なら撃たない
var can_shoot := true
var level := 1
## 攻撃力（体当たり・叩く・弾のダメージのもと）
var attack := 1
var _cooldown := SHOOT_INTERVAL
## イノシシの突進：0 なし、1 ためている、2 走っている
var charge_phase := 0
var _charge_time := 0.0
var _charge_dir := Vector2.ZERO
## 火の玉がためている残り秒（負ならためていない）
var _fuse := -1.0
var _bob := 0.0
## 当たったときに少しの間だけ光る（影の敵は、この間だけ体が見える）
var _hit_flash := 0.0
## 跳びかかり・急降下・突き：0 なし、1 ためている、2 動いている
var lunge_phase := 0
var _lunge_time := 0.0
var _lunge_dir := Vector2.ZERO
var _rest := 1.0
## 叩いたあと下がる残り秒（ゴブリン）
var _retreat := 0.0
## 目を回している残り秒（イノシシ）・ひっくり返っている残り秒（甲虫）
var stunned := 0.0
var flipped := 0.0
## 亡霊がすけているか
var faded := false
var _phase_t := 0.0
## 射手の撃った回数（3回に1回は3発）
var _volleys := 0
var _burst_left := 0
## 盾持ちの向き（盾の向き）
var face := Vector2.DOWN
## 擬態箱が目を覚ましたか
var awake := true
## ボスが呼んだ手下（倒しても落とし物はなく、戻ってもこない）
var minion := false
## 魔術師：消えている残り秒（正なら消えている）、現れる所の候補
var _blink := 0.0
var _home := Vector2.ZERO
var _orbit := 1.0
## 技（2026-11-26）：ためて（_act_wind）から、向き _act_dir へ _act_t 秒走る（跳ぶ）。_act_r 以内に触れると当たる
var field  ## field.gd（落ちてくる矢を調べる incoming_arrow）。テストではないこともある
var _act := ""
var _act_t := 0.0
var _act_wind := 0.0
var _act_dir := Vector2.ZERO
var _act_speed := 1.0
var _act_r := 0.0
var _act_hit := false
var _act_lift := 0.0
var _act_len := 0.0
var _skill_cd := 1.5  ## 技の待ち
var _dodge_cd := 0.0
var _combo := -1.0  ## 叩いたあと続けて斬るまでの秒（ゴブリン）
var _pv := Vector2.ZERO  ## 主人公の速さ（先読み）
var _last_tp := Vector2.INF
var _summons_left := 2
var _was_faded := false
## スライムの分かれた小さい方（もう分かれない）
var small := false
## 使った技の名前（テスト用）
var moves_used: Array = []

func setup(map: HeightMap, start_cell: Vector2i, start_dir: Vector2, p: Player, cam: StackCamera, enemy_kind: EnemyKind.Kind = EnemyKind.Kind.WEAK, first_shot_delay: float = SHOOT_INTERVAL, enemy_level := 1) -> void:
	kind = enemy_kind
	level = enemy_level
	attack = EnemyKind.attack(kind, level)
	walker = EnemyWalker.new(map, start_cell, start_dir, EnemyKind.hp(kind, level), EnemyKind.climb(kind))
	walker.chase_range = EnemyKind.chase_range(kind)
	walker.speed_mult = EnemyKind.speed_mult(kind)
	walker.flying = EnemyKind.flies(kind)
	can_shoot = kind == EnemyKind.Kind.SHOOTER
	target = p
	camera = cam
	draw_bias = 1
	sort_by_cell = true
	always_redraw = true  # 向きが変わる
	shadow_radius = 7.5 if kind != EnemyKind.Kind.WASP else 4.5
	voxel_scale = EnemyModels.DRAW_SCALE
	walker.touch_radius = EnemyWalker.TOUCH_RADIUS + EnemyModels.BODY_EXTRA
	outline_color = Player.OUTLINE_COLOR
	_cooldown = first_shot_delay
	_home = walker.pos
	face = start_dir.normalized() if start_dir != Vector2.ZERO else Vector2.DOWN
	_orbit = 1.0 if (start_cell.x + start_cell.y) % 2 == 0 else -1.0
	if kind == EnemyKind.Kind.MIMIC:
		awake = false
		walker.chase_range = 0.0
		walker.speed_mult = 0.0
	if kind == EnemyKind.Kind.LOBBER or kind == EnemyKind.Kind.MAGE:
		_cooldown = first_shot_delay * 0.6
	set_model(EnemyModels.model(kind, awake))
	walker.died.connect(_on_died)

func _on_died() -> void:
	if kind == EnemyKind.Kind.WEAK and not small and not minion:
		split.emit(walker.pos, walker.height)
	queue_free()

## スライムの分かれた小さい方にする（体力は4割、小さく描く）。
func make_small() -> void:
	small = true
	minion = true
	walker.max_hp = maxi(1, int(walker.max_hp * 0.4))
	walker.hp = walker.max_hp
	voxel_scale = EnemyModels.DRAW_SCALE * 0.65
	shadow_radius = 5.0
	_rest = 0.6

func _sort_map() -> HeightMap:
	return walker.map if walker != null else null

## 当たった（影の敵は少しの間だけ姿を見せる）。
func flash() -> void:
	_hit_flash = 0.25

## 浮いているか（剣と鉄球が届かない）。
func airborne() -> bool:
	return EnemyKind.flies(kind)

## 盾が前から防ぐか（from は攻撃してきた所）。
func blocks(from: Vector2) -> bool:
	return EnemyKind.blocks(kind, face, walker.pos, from)

## 攻撃がどう当たるか（EnemyKind.hit_rule）。
func hit_rule(source: String, from: Vector2) -> String:
	return EnemyKind.hit_rule(kind, source, face, walker.pos, from,
		{"flipped": flipped > 0.0, "faded": faded, "stunned": stunned > 0.0})

## 攻撃が当たったあと（甲虫は鉄球でひっくり返る。擬態箱は目を覚ます）。
func on_hit(source: String) -> void:
	if kind == EnemyKind.Kind.BEETLE and source in ["ball", "bomb"]:
		flipped = EnemyKind.FLIP_SECONDS
		_end_act()
	if kind == EnemyKind.Kind.BOMBER and source == "sword" and walker.alive and (_fuse < 0.0 or _fuse > 0.1):
		_fuse = 0.08  # 剣で叩くとすぐ弾ける
		_end_act()
		_note("burst")
	_wake_mimic()

## 盾で防いだ（盾持ちはすぐ叩き返す）。
func on_blocked() -> void:
	if kind == EnemyKind.Kind.SHIELD and _act == "" and stunned <= 0.0:
		_start_act("counter", 0.2, 0.18, 3.2, _to_target().normalized(), 15.0)

func _wake_mimic() -> void:
	if kind == EnemyKind.Kind.MIMIC and not awake:
		awake = true
		Sfx.play("bite", walker.pos)
		walker.chase_range = EnemyKind.chase_range(kind)
		walker.speed_mult = EnemyKind.speed_mult(kind)
		_rest = 0.4
		set_model(EnemyModels.model(kind, true))

## 体当たりでダメージを与えるか（field が触れたときに使う）。
func touch_hurts() -> bool:
	if not EnemyKind.contact(kind) or faded or flipped > 0.0 or stunned > 0.0:
		return false
	return true

func _to_target() -> Vector2:
	return target.mover.pos - walker.pos

func _process(delta: float) -> void:
	_hit_flash = maxf(0.0, _hit_flash - delta)
	_rest = maxf(0.0, _rest - delta)
	stunned = maxf(0.0, stunned - delta)
	flipped = maxf(0.0, flipped - delta)
	_skill_cd = maxf(0.0, _skill_cd - delta)
	_dodge_cd = maxf(0.0, _dodge_cd - delta)
	_track(delta)
	var alive_target := target.hp > 0
	if kind == EnemyKind.Kind.GHOST:
		walker.chase_range = EnemyKind.hearing(kind, target.crouching)
		_phase_t += delta
		faded = fmod(_phase_t, EnemyKind.GHOST_SOLID + EnemyKind.GHOST_FADED) >= EnemyKind.GHOST_SOLID
		if _was_faded and not faded and alive_target:
			_appear_behind(22.0)  # すけたあと、主人公の背中に現れる
		_was_faded = faded
	if _act != "":
		_step_act(delta, alive_target)
	elif stunned <= 0.0 and flipped <= 0.0 and awake and alive_target and _fuse < 0.0 and _blink <= 0.0 and _think(delta):
		pass  # 技を始めた
	else:
		_update_kind(delta, alive_target)
	if _combo >= 0.0:
		_combo -= delta
		if _combo < 0.0 and _act == "" and alive_target and stunned <= 0.0:
			_start_act("combo", 0.12, 0.2, 3.0, _to_target().normalized(), 13.0)
	if EnemyKind.melee(kind) and awake and stunned <= 0.0 and _act == "":
		var was_winding := melee.is_winding_up()
		if alive_target and melee.update(delta, walker.pos, walker.height, target.mover.pos, target.mover.height):
			melee_hit.emit()
			if kind == EnemyKind.Kind.MELEE and randf() < 0.45:
				_combo = 0.2  # 続けて斬る
		if was_winding and not melee.is_winding_up() and kind == EnemyKind.Kind.MELEE and _combo < 0.0:
			_retreat = 0.5  # 叩いたら少し下がる（当て逃げ）
	if can_shoot and alive_target and _act == "":
		_update_shooter(delta)
	_tint()
	_bob += delta
	world_pos = walker.pos
	base_height = walker.height
	if walker.flying:
		var low := lunge_phase == 2
		lift_px = (4.0 if low else FLY_LIFT) + sin(_bob * (9.0 if kind == EnemyKind.Kind.WASP else 5.0)) * 2.0
	else:
		lift_px = 0.0
	if _act != "" and _act_wind <= 0.0 and _act_lift > 0.0 and _act_len > 0.0:
		lift_px += sin(clampf(1.0 - _act_t / _act_len, 0.0, 1.0) * PI) * _act_lift
	if _blink > 0.0:
		modulate.a = clampf(absf(_blink - 0.35) / 0.35, 0.0, 1.0)
	else:
		modulate.a = 1.0
	super._process(delta)

## 種類ごとのふだんの動き（技を使っていないとき）。
func _update_kind(delta: float, alive_target: bool) -> void:
	match kind:
		EnemyKind.Kind.CHARGER:
			if stunned <= 0.0:
				_update_charge(delta)
		EnemyKind.Kind.BOMBER:
			if _fuse >= 0.0:
				_fuse -= delta
				if _fuse < 0.0:
					exploded.emit(walker.pos, walker.height)
					walker.take_damage(walker.hp)
					return
			else:
				_walk(delta, alive_target)
				if alive_target and walker.pos.distance_to(target.mover.pos) < EnemyKind.BOMB_TRIGGER and absi(walker.height - target.mover.height) <= 1:
					_fuse = BOMB_FUSE
		EnemyKind.Kind.WEAK, EnemyKind.Kind.SHADOW:
			_update_pounce(delta, alive_target, 30.0 if kind == EnemyKind.Kind.WEAK else 40.0)
		EnemyKind.Kind.FLYER, EnemyKind.Kind.WASP:
			_update_flyer(delta, alive_target)
		EnemyKind.Kind.SHOOTER:
			_keep_away(delta, alive_target, SHOOTER_FLEE)
		EnemyKind.Kind.LOBBER:
			_keep_away(delta, alive_target, LOB_FLEE)
			_update_lob(delta, alive_target)
		EnemyKind.Kind.MAGE:
			_update_mage(delta, alive_target)
		EnemyKind.Kind.SPEAR:
			_update_spear(delta, alive_target)
		EnemyKind.Kind.BEETLE:
			if flipped <= 0.0:
				_walk(delta, alive_target)
		EnemyKind.Kind.MIMIC:
			if not awake:
				if alive_target and _to_target().length() < MIMIC_WAKE:
					_wake_mimic()
			elif _rest <= 0.0 and not melee.is_winding_up():
				_walk(delta, alive_target)
		EnemyKind.Kind.MELEE:
			if _retreat > 0.0:
				_retreat -= delta
				walker.dir = -_to_target().normalized()
				walker.step(delta)
			elif not melee.is_winding_up():
				_walk(delta, alive_target)
		EnemyKind.Kind.SHIELD:
			var behind := face.dot(_to_target().normalized()) < -0.3
			face = Vector2.from_angle(rotate_toward(face.angle(), _to_target().angle(), SHIELD_TURN * (1.8 if behind else 1.0) * delta))
			if not melee.is_winding_up():
				_walk(delta, alive_target)
		_:
			_walk(delta, alive_target)

## ためている間は体を明るく光らせる（よけるための合図）。毒は緑、やけどは赤、遅いと青。
func _tint() -> void:
	var winding := melee.is_winding_up() or charge_phase == 1 or lunge_phase == 1 or (_fuse >= 0.0 and int(_fuse * 12.0) % 2 == 0) \
		or (_act != "" and _act_wind > 0.0)
	if winding or _hit_flash > 0.0:
		self_modulate = Color(1.8, 1.8, 1.8)
	elif stunned > 0.0 or flipped > 0.0:
		self_modulate = Color(1.3, 1.2, 0.6) if int(_bob * 6.0) % 2 == 0 else Color(1, 1, 1)
	elif walker.is_poisoned():
		self_modulate = Color(1.4, 0.8, 0.6) if walker.is_burning() else Color(0.7, 1.3, 0.6)
	elif walker.is_slowed():
		self_modulate = Color(0.7, 0.9, 1.5)
	else:
		self_modulate = Color.WHITE
	if kind == EnemyKind.Kind.GHOST:
		self_modulate.a = 0.25 if faded else 0.75

## ふつうに歩く（近ければ寄っていく）。
func _walk(delta: float, alive_target: bool) -> void:
	if alive_target and walker.chase_range > 0.0:
		var goal := target.mover.pos
		if kind == EnemyKind.Kind.MELEE:
			goal = _lead(0.5)  # 先読みして回りこむ
		walker.chase(goal, target.mover.height)
		var d := _to_target().length()
		if kind in [EnemyKind.Kind.SHADOW, EnemyKind.Kind.BOMBER] and d > 26.0 and d < walker.chase_range:
			# ジグザグ・ふらふら寄る
			var side := _to_target().normalized().orthogonal() * sin(_bob * (6.0 if kind == EnemyKind.Kind.SHADOW else 3.5)) * 0.9
			walker.dir = (_to_target().normalized() + side).normalized()
	walker.step(delta)

## 相手が近いと離れ、遠ければ往復する（射手・投石兵）。
func _keep_away(delta: float, alive_target: bool, flee: float) -> void:
	var d := _to_target()
	if alive_target and d.length() < flee and absi(target.mover.height - walker.height) <= 2:
		walker.dir = -d.normalized()
		walker.speed_mult = EnemyKind.speed_mult(kind) * 1.2
	elif alive_target and kind == EnemyKind.Kind.SHOOTER and d.length() < flee + 70.0:
		# 間合いの間は横へ回る（ときどき向きを変える）
		if int(_bob / 2.5) != int((_bob - delta) / 2.5):
			_orbit = -_orbit
		walker.dir = (d.normalized().orthogonal() * _orbit + d.normalized() * clampf((d.length() - flee - 30.0) / 30.0, -0.6, 0.6)).normalized()
		walker.speed_mult = EnemyKind.speed_mult(kind)
	else:
		walker.speed_mult = EnemyKind.speed_mult(kind)
	walker.step(delta)

## スライム・影：近づくと、ためて跳びかかる（跳んでいる間に触れると体当たり）。
func _update_pounce(delta: float, alive_target: bool, trigger: float) -> void:
	match lunge_phase:
		0:
			var d := _to_target()
			if alive_target and _rest <= 0.0 and d.length() < trigger and target.mover.height == walker.height:
				lunge_phase = 1
				_lunge_time = 0.0
				_lunge_dir = (_lead(POUNCE_WINDUP * 0.6) - walker.pos).normalized()
				_note("pounce")
				walker.dir = _lunge_dir
			else:
				_walk(delta, alive_target)
		1:
			_lunge_time += delta
			if _lunge_time >= POUNCE_WINDUP:
				lunge_phase = 2
				_lunge_time = 0.0
				walker.speed_mult = EnemyKind.speed_mult(kind) * POUNCE_SPEED
				Sfx.play("slime" if kind == EnemyKind.Kind.WEAK else "enemy_jump", walker.pos)
		2:
			_lunge_time += delta
			walker.dir = _lunge_dir
			walker.step(delta)
			if _lunge_time >= POUNCE_TIME:
				lunge_phase = 0
				_rest = POUNCE_REST
				walker.speed_mult = EnemyKind.speed_mult(kind)
				if kind == EnemyKind.Kind.WEAK and randf() < 0.45:
					_rest = 0.15  # もう1回跳ぶ
					_note("hop2")
				elif kind == EnemyKind.Kind.SHADOW:
					_start_act("fade_back", 0.0, 0.4, 2.0, -_to_target())  # 跳びこんだあと下がる

## コウモリ・蜂：相手のまわりを回り、ときどき狙って急降下し、また離れる。
func _update_flyer(delta: float, alive_target: bool) -> void:
	var d := _to_target()
	match lunge_phase:
		0:
			if alive_target and d.length() < walker.chase_range:
				var radius := 36.0 if kind == EnemyKind.Kind.FLYER else 26.0
				var tangent := d.normalized().orthogonal() * _orbit
				var radial := d.normalized() * clampf((d.length() - radius) / 16.0, -1.0, 1.0)
				walker.dir = (tangent + radial).normalized()
				walker.step(delta)
				if _rest <= 0.0:
					lunge_phase = 1
					_lunge_time = 0.0
			else:
				walker.step(delta)
		1:
			_lunge_time += delta
			if _lunge_time >= (0.35 if kind == EnemyKind.Kind.FLYER else 0.25):
				lunge_phase = 2
				_lunge_time = 0.0
				_lunge_dir = (_lead(0.3) - walker.pos).normalized()
				walker.speed_mult = EnemyKind.speed_mult(kind) * 3.2
				Sfx.play("wing", walker.pos)
				_note("dive")
		2:
			_lunge_time += delta
			walker.dir = _lunge_dir
			walker.step(delta)
			if _lunge_time >= 0.5:
				lunge_phase = 0
				_rest = 2.6 if kind == EnemyKind.Kind.FLYER else 1.8
				_orbit = -_orbit
				walker.speed_mult = EnemyKind.speed_mult(kind)
				if kind == EnemyKind.Kind.FLYER and randf() < 0.4:
					_rest = 0.4  # もう1回急降下する
					_note("dive2")

## 槍兵：少し離れて構え、ためてから長く突く（向きはためはじめで決まる。横へよければ当たらない）。
func _update_spear(delta: float, alive_target: bool) -> void:
	var d := _to_target()
	match lunge_phase:
		0:
			if alive_target and d.length() < walker.chase_range and absi(target.mover.height - walker.height) <= 1:
				if d.length() > SPEAR_KEEP + 4.0:
					walker.chase(target.mover.pos, target.mover.height)
					walker.step(delta)
				elif d.length() < SPEAR_KEEP - 8.0:
					walker.dir = -d.normalized()
					walker.step(delta)
				face = d.normalized()
				if _rest <= 0.0 and d.length() < SPEAR_REACH:
					lunge_phase = 1
					_lunge_time = 0.0
					_lunge_dir = d.normalized()
					face = _lunge_dir
			else:
				walker.step(delta)
		1:
			_lunge_time += delta
			if _lunge_time < SPEAR_WINDUP * 0.55 and alive_target:
				_lunge_dir = (_lead(SPEAR_WINDUP - _lunge_time) - walker.pos).normalized()  # 狙いを合わせ続ける
				face = _lunge_dir
			if _lunge_time >= SPEAR_WINDUP:
				lunge_phase = 2
				_lunge_time = 0.0
				Sfx.play("thrust", walker.pos, -4.0)
				_note("thrust")
				# 踏みこんで突く
				var c := HeightMap.world_to_cell(walker.pos + _lunge_dir * 10.0)
				if walker.can_enter(c):
					walker.pos += _lunge_dir * 10.0
				if spear_hits(walker.pos, walker.height, _lunge_dir, target.mover.pos, target.mover.height):
					melee_hit.emit()
		2:
			_lunge_time += delta
			if _lunge_time >= 0.2:
				lunge_phase = 0
				_rest = 1.6
				if randf() < 0.4:
					_rest = 0.0  # もう1回突く（ためは短い）
					lunge_phase = 1
					_lunge_time = SPEAR_WINDUP * 0.45
					_note("thrust2")

## 槍の突きが当たるか：向き dir の左右およそ25°、SPEAR_REACH まで。同じ高さか1段下。
static func spear_hits(at: Vector2, h: int, dir: Vector2, p: Vector2, ph: int) -> bool:
	var d := p - at
	if d.length() > SPEAR_REACH or not Damage.can_hit(h, ph) or h - ph > 1:
		return false
	return d.length() < 4.0 or dir.normalized().dot(d.normalized()) > 0.9

## 投石兵：相手のいる所へ石を山なりに投げる（壁を越える。落ちる所は field が影で出す）。
func _update_lob(delta: float, alive_target: bool) -> void:
	_cooldown -= delta
	if not alive_target or _cooldown > 0.0:
		return
	var d := _to_target()
	if d.length() <= LOB_RANGE and Damage.can_hit(walker.height, target.mover.height):
		_cooldown = LOB_INTERVAL
		_hit_flash = 0.15
		_volleys += 1
		var at := _lead(LOB_FLIGHT * 0.8)  # 先読みして投げる
		lobbed.emit(at, target.mover.height, LOB_FLIGHT, attack)
		if _volleys % 3 == 0:
			var side := d.normalized().orthogonal() * 18.0
			lobbed.emit(at + side, target.mover.height, LOB_FLIGHT + 0.15, attack)
			lobbed.emit(at - side, target.mover.height, LOB_FLIGHT + 0.3, attack)
			_note("volley")

## 魔術師：ときどき消えて別の所に現れ、3方向に遅い弾を撃つ。
func _update_mage(delta: float, alive_target: bool) -> void:
	if _blink > 0.0:
		var before := _blink
		_blink -= delta
		if before > 0.35 and _blink <= 0.35:
			_teleport()
		return
	_cooldown -= delta
	_phase_t += delta
	if _phase_t >= MAGE_BLINK and alive_target and _to_target().length() < 110.0:
		_phase_t = 0.0
		_blink = 0.7
		return
	var d := _to_target()
	if alive_target and _cooldown <= 0.0 and d.length() < SHOOT_RANGE and Damage.can_hit(walker.height, target.mover.height):
		_cooldown = 2.4
		_volleys += 1
		if _volleys % 2 == 0:
			_shoot_at(_lead(d.length() / 90.0), 90.0)  # 先読みの速い弾
			_note("bolt")
			return
		for a in [-0.4, 0.0, 0.4]:
			var b := Bullet.new()
			b.aim(walker.pos, walker.height, walker.pos + d.rotated(a), target.mover.height, 46.0)
			b.damage = attack
			shot.emit(b)

## 魔術師が、もとの所のまわりの、相手から少し離れた歩けるマスへ移る。
func _teleport() -> void:
	var map := walker.map
	var best := walker.pos
	var best_score := -1.0
	for i in 12:
		var c := HeightMap.world_to_cell(_home) + Vector2i(randi_range(-4, 4), randi_range(-4, 4))
		if not map.in_bounds(c) or map.is_wall(c) or map.is_pit(c) or map.is_water(c) or walker.forbidden.has(c):
			continue
		var p := HeightMap.cell_center(c)
		var dist := p.distance_to(target.mover.pos)
		var score := 100.0 - absf(dist - 64.0)
		if dist > 32.0 and score > best_score:
			best_score = score
			best = p
	walker.pos = best
	walker.height = maxi(0, map.get_height(walker.cell()))
	Sfx.play("teleport", best, -4.0)

## 射手：2秒ごとに撃つ。3回に1回は、0.2秒おきに3発続けて撃つ。
func _update_shooter(delta: float) -> void:
	_cooldown -= delta
	var to_player := _to_target()
	# 自分より高い所にいる相手は撃たない（下から上へは当たらない）
	if _cooldown > 0.0 or to_player.length() > SHOOT_RANGE or not Damage.can_hit(walker.height, target.mover.height):
		return
	if _burst_left > 0:
		_burst_left -= 1
		_cooldown = 0.2 if _burst_left > 0 else SHOOT_INTERVAL
	else:
		_volleys += 1
		if _volleys % 3 == 0:
			_burst_left = 2
			_cooldown = 0.2
		else:
			_cooldown = SHOOT_INTERVAL
	# 先読みして、相手の体へまっすぐ撃つ。高い所からなら下まで届き、下からだと崖に当たりやすい
	var aim := _lead(to_player.length() / BULLET_SPEED)
	var spread := _burst_left == 0 and _volleys % 4 == 2
	for a in ([-0.3, 0.0, 0.3] if spread else [0.0]):
		var b := Bullet.new()
		b.aim(walker.pos, walker.height, walker.pos + (aim - walker.pos).rotated(a), target.mover.height, BULLET_SPEED)
		b.damage = attack
		shot.emit(b)
	if spread:
		_note("spread")

## イノシシ：同じ高さで縦か横に並ぶと、ためてから、その向きへ速く走る。時間で止まる。壁にぶつかると目を回す。
func _update_charge(delta: float) -> void:
	match charge_phase:
		0:
			var d := _to_target()
			var lined := absf(d.x) < 6.0 or absf(d.y) < 6.0
			if target.hp > 0 and lined and d.length() < EnemyKind.CHARGE_RANGE and target.mover.height == walker.height:
				charge_phase = 1
				_charge_time = 0.0
				_charge_dir = (Vector2(signf(d.x), 0) if absf(d.x) > absf(d.y) else Vector2(0, signf(d.y)))
				walker.dir = _charge_dir
			else:
				walker.step(delta)
		1:
			_charge_time += delta
			if _charge_time >= EnemyKind.CHARGE_WINDUP:
				charge_phase = 2
				_charge_time = 0.0
				walker.speed_mult = EnemyKind.CHARGE_SPEED_MULT
				Sfx.play("growl", walker.pos)
		2:
			_charge_time += delta
			walker.dir = _charge_dir
			var before := walker.pos
			walker.step(delta)
			var bumped := walker.pos.distance_to(before) < 0.01 or walker.dir != _charge_dir
			if _charge_time >= EnemyKind.CHARGE_SECONDS or bumped:
				charge_phase = 0
				walker.speed_mult = EnemyKind.speed_mult(kind)
				if bumped:
					stunned = EnemyKind.STUN_SECONDS

# ---------------------------------------------------------------- 技（2026-11-26 の4回目の直し）

func _note(move: String) -> void:
	moves_used.append(move)

## 主人公の速さを覚える（先読み）。
func _track(delta: float) -> void:
	if target == null:
		return
	if _last_tp != Vector2.INF and delta > 0.0:
		var v := (target.mover.pos - _last_tp) / delta
		if v.length() < 200.0:
			_pv = _pv.lerp(v, clampf(delta * 6.0, 0.0, 1.0))
	_last_tp = target.mover.pos

## t 秒後に主人公がいそうな所。
func _lead(t: float) -> Vector2:
	return target.mover.pos + _pv * t

## ためて（wind 秒、体が光る）から、dir へ time 秒走る（速さの倍率 speed）。r が0より大きければ、走っている間に触れると当たる。lift は跳ぶ高さ。
func _start_act(name_: String, wind: float, time: float, speed: float, dir: Vector2, r := 0.0, lift := 0.0) -> void:
	_act = name_
	_act_wind = wind
	_act_t = time
	_act_len = time
	_act_speed = speed
	_act_dir = dir.normalized() if dir != Vector2.ZERO else walker.dir
	_act_r = r
	_act_hit = false
	_act_lift = lift
	walker.dir = _act_dir
	if kind in [EnemyKind.Kind.SHIELD, EnemyKind.Kind.SPEAR]:
		face = _act_dir
	_note(name_)

func _step_act(delta: float, alive_target: bool) -> void:
	if _act_wind > 0.0:
		_act_wind -= delta
		if _act_wind <= 0.0:
			Sfx.play("enemy_jump" if _act_lift > 0.0 else "dash", walker.pos, -4.0, 0.1)
		return
	_act_t -= delta
	walker.dir = _act_dir
	walker.speed_mult = EnemyKind.speed_mult(kind) * _act_speed
	var before := walker.pos
	if _act_speed > 0.0:
		walker.step(delta)
	if _act_r > 0.0 and not _act_hit and alive_target and _reaches(_act_r):
		_act_hit = true
		melee_hit.emit()
	var bumped := _act_speed > 0.0 and walker.pos.distance_to(before) < 0.01
	if _act_t <= 0.0 or bumped:
		var was := _act
		_end_act()
		_after_act(was, bumped)

## 主人公に届くか（同じ高さか1段下まで。下から上へは届かない）。
func _reaches(r: float) -> bool:
	var ph := target.mover.height
	return walker.pos.distance_to(target.mover.pos) <= r and Damage.can_hit(walker.height, ph) and walker.height - ph <= 1

func _end_act() -> void:
	if _act == "":
		return
	_act = ""
	_act_wind = 0.0
	walker.speed_mult = EnemyKind.speed_mult(kind)

## 技のあと（続けて動く・ひっくり返る）。
func _after_act(was: String, bumped: bool) -> void:
	match was:
		"roll":
			if bumped:
				flipped = 1.6  # 壁にぶつかってひっくり返る
				Sfx.play("land", walker.pos)
		"lunge", "combo":
			if kind == EnemyKind.Kind.MELEE and randf() < 0.5:
				_retreat = 0.35
		"shadow_step":
			lunge_phase = 1
			_lunge_time = POUNCE_WINDUP * 0.5
			_lunge_dir = _to_target().normalized()

## 弾を撃つ（to へ、主人公の高さへ）。
func _shoot_at(to: Vector2, speed: float) -> void:
	if not Damage.can_hit(walker.height, target.mover.height):
		return
	var b := Bullet.new()
	b.aim(walker.pos, walker.height, to, target.mover.height, speed)
	b.damage = attack
	shot.emit(b)

## 歩けるマスか（主人公の背中へ現れるときなど）。
func _open(c: Vector2i) -> bool:
	var map := walker.map
	return map.in_bounds(c) and not map.is_wall(c) and not map.is_pit(c) and not map.is_water(c) and not walker.forbidden.has(c)

## 主人公の背中（向きの反対）の dist px 先へ消えて現れる。現れたら true。
func _appear_behind(dist: float) -> bool:
	var back := -target.mover.facing.normalized()
	for k in [0.0, 0.6, -0.6, 1.2, -1.2]:
		var at := target.mover.pos + back.rotated(k) * dist
		var c := HeightMap.world_to_cell(at)
		if not _open(c) or absi(walker.map.get_height(c) - target.mover.height) > 1:
			continue
		walker.pos = at
		walker.height = walker.map.get_height(c)
		_hit_flash = 0.2
		Sfx.play("teleport", at, -6.0)
		_note("behind")
		return true
	return false

## 技を選ぶ。始めたら true（このフレームはふだんの動きをしない）。
func _think(_delta: float) -> bool:
	var to := _to_target()
	var d := to.length()
	var same := absi(target.mover.height - walker.height) <= 1 and Damage.can_hit(walker.height, target.mover.height)
	match kind:
		EnemyKind.Kind.MELEE:
			if _dodge_cd <= 0.0 and field != null and field.has_method("incoming_arrow"):
				var land: Vector2 = field.incoming_arrow(walker.pos, 14.0)
				if land != Vector2.INF:
					_dodge_cd = 1.4
					if randf() < 0.75:
						var away := (walker.pos - land)
						var side := to.normalized().orthogonal()
						if away.length() > 0.1 and side.dot(away) < 0.0:
							side = -side
						_start_act("dodge", 0.0, 0.25, 3.2, side)
						return true
			if _skill_cd <= 0.0 and same and d > 22.0 and d < 52.0 and _retreat <= 0.0:
				_skill_cd = 2.2
				_start_act("lunge", 0.35, 0.3, 3.6, _lead(0.45) - walker.pos, 13.0, 6.0)
				return true
			if _skill_cd <= 0.0 and same and d > 64.0 and d < 130.0:
				_skill_cd = 2.8
				_hit_flash = 0.15
				_shoot_at(_lead(d / 110.0), 110.0)  # ナイフを投げる
				_note("knife")
				return false
		EnemyKind.Kind.SHOOTER:
			if _skill_cd <= 0.0 and d < 22.0:
				_skill_cd = 3.0
				_start_act("leap_back", 0.05, 0.3, 3.5, -to, 0.0, 8.0)
				return true
		EnemyKind.Kind.SHIELD:
			var front := face.normalized().dot(to.normalized()) > 0.7
			if _skill_cd <= 0.0 and same and front and d < 30.0 and d > 10.0:
				_skill_cd = 2.6
				_start_act("bash", 0.4, 0.25, 3.5, to, 14.0)
				return true
		EnemyKind.Kind.SHADOW:
			if _skill_cd <= 0.0 and d > 34.0 and d < 96.0 and lunge_phase == 0:
				_skill_cd = 5.0
				if _appear_behind(26.0):
					_start_act("shadow_step", 0.0, 0.01, 0.0, _to_target())
					return true
		EnemyKind.Kind.FLYER, EnemyKind.Kind.WASP:
			if kind == EnemyKind.Kind.WASP and _skill_cd <= 0.0 and d > 40.0 and d < 110.0 and lunge_phase == 0:
				_skill_cd = 2.6
				_hit_flash = 0.12
				_shoot_at(_lead(d / 95.0), 95.0)  # 針を飛ばす
				_note("sting")
		EnemyKind.Kind.BOMBER:
			if _skill_cd <= 0.0 and same and d > 20.0 and d < 56.0:
				_skill_cd = 3.0
				_start_act("rush", 0.25, 0.45, 3.0, _lead(0.4) - walker.pos)
				return true
		EnemyKind.Kind.GHOST:
			if not faded and _skill_cd <= 0.0 and d > 30.0 and d < 110.0:
				_skill_cd = 3.5
				_hit_flash = 0.15
				_shoot_at(_lead(d / 50.0), 50.0)  # のろいの弾
				_note("curse")
		EnemyKind.Kind.SPEAR:
			if _skill_cd <= 0.0 and same and d < 15.0 and lunge_phase == 0:
				_skill_cd = 2.5
				_start_act("sweep", 0.45, 0.05, 0.0, to, 24.0)
				return true
		EnemyKind.Kind.LOBBER:
			if _skill_cd <= 0.0 and same and d < 18.0:
				_skill_cd = 2.5
				_start_act("shove", 0.3, 0.15, 2.5, to, 14.0)
				return true
		EnemyKind.Kind.MAGE:
			if _skill_cd <= 0.0 and d < 34.0:
				_skill_cd = 4.0
				for i in 8:
					var b := Bullet.new()
					b.aim(walker.pos, walker.height, walker.pos + Vector2.from_angle(i * TAU / 8.0) * 40.0, walker.height, 55.0)
					b.damage = attack
					shot.emit(b)
				_note("nova")
				_blink = 0.7  # まわりに撃って消える
				_phase_t = 0.0
				return true
			if _summons_left > 0 and _phase_t >= MAGE_BLINK * 0.8 and d < 110.0 and randf() < 0.01:
				_summons_left -= 1
				summon.emit(EnemyKind.Kind.WEAK, walker.pos + Vector2.from_angle(randf() * TAU) * 18.0)
				_note("summon")
		EnemyKind.Kind.BEETLE:
			var lined := absf(to.x) < 8.0 or absf(to.y) < 8.0
			if _skill_cd <= 0.0 and same and lined and d > 24.0 and d < 90.0:
				_skill_cd = 3.5
				var dir := Vector2(signf(to.x), 0) if absf(to.x) > absf(to.y) else Vector2(0, signf(to.y))
				_start_act("roll", 0.5, 0.9, 3.2, dir, 12.0)
				return true
			if _skill_cd <= 0.0 and same and d < 18.0:
				_skill_cd = 2.0
				_start_act("horn", 0.35, 0.15, 2.5, to, 14.0)
				return true
		EnemyKind.Kind.MIMIC:
			if _skill_cd <= 0.0 and same and d > 24.0 and d < 60.0:
				_skill_cd = 2.5
				_start_act("leap", 0.35, 0.45, 3.2, _lead(0.4) - walker.pos, 14.0, 14.0)
				return true
			if _skill_cd <= 0.0 and d > 64.0 and d < 120.0:
				_skill_cd = 3.0
				for a in [-0.35, 0.0, 0.35]:
					_shoot_at(walker.pos + to.rotated(a), 60.0)  # 金貨を吐く
				_note("coins")
	return false

func _draw() -> void:
	if camera == null:
		return
	var dir := face if kind in [EnemyKind.Kind.SHIELD, EnemyKind.Kind.SPEAR] else walker.dir
	var face_angle := dir.angle() - PI / 2
	if kind == EnemyKind.Kind.SHADOW:
		# 影の敵は体が見えない（地面の影だけ）。当たった直後と、ためている間だけ姿が出る
		draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.45))
		if _hit_flash <= 0.0 and lunge_phase != 1:
			return
	else:
		_draw_shadow()
	var flip := flipped > 0.0
	var n := _layers.size()
	if flip:
		_layers.reverse()  # ひっくり返った甲虫は上下を逆に描く
	_draw_stack(face_angle - camera.angle)
	if flip:
		_layers.reverse()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var top := -n * layer_step()
	if stunned > 0.0 or flip:
		for k in 3:
			var a := _bob * 5.0 + k * TAU / 3.0
			draw_rect(Rect2(Vector2(cos(a) * 5.0, top - 3.0 + sin(a) * 1.5) - Vector2.ONE, Vector2(2, 2)), Color("ffe066"))
	# 傷ついたら頭の上に体力のバーを出す（擬態箱は目を覚ますまで出さない）
	if walker.alive and walker.hp < walker.max_hp and awake:
		var y := top - 6.0
		draw_rect(Rect2(-6, y, 12, 2), Color(0.1, 0.05, 0.05))
		draw_rect(Rect2(-6, y, 12.0 * walker.hp / walker.max_hp, 2), Color("e74c3c"))
