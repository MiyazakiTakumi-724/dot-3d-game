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

signal shot(bullet: Bullet)
signal melee_hit
## 火の玉が弾けた（まわりにダメージ）
signal exploded(pos: Vector2, height: int)
## 投石兵が石を投げた（落ちる所・高さ・着くまでの秒・ダメージ）
signal lobbed(at: Vector2, height: int, delay: float, damage: int)

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
	walker.died.connect(queue_free)

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
	_wake_mimic()

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
	var alive_target := target.hp > 0
	if kind == EnemyKind.Kind.GHOST:
		walker.chase_range = EnemyKind.hearing(kind, target.crouching)
		_phase_t += delta
		faded = fmod(_phase_t, EnemyKind.GHOST_SOLID + EnemyKind.GHOST_FADED) >= EnemyKind.GHOST_SOLID
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
			face = Vector2.from_angle(rotate_toward(face.angle(), _to_target().angle(), SHIELD_TURN * delta))
			if not melee.is_winding_up():
				_walk(delta, alive_target)
		_:
			_walk(delta, alive_target)
	if EnemyKind.melee(kind) and awake and stunned <= 0.0:
		var was_winding := melee.is_winding_up()
		if alive_target and melee.update(delta, walker.pos, walker.height, target.mover.pos, target.mover.height):
			melee_hit.emit()
		if was_winding and not melee.is_winding_up() and kind == EnemyKind.Kind.MELEE:
			_retreat = 0.5  # 叩いたら少し下がる（当て逃げ）
	if can_shoot and alive_target:
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
	if _blink > 0.0:
		modulate.a = clampf(absf(_blink - 0.35) / 0.35, 0.0, 1.0)
	else:
		modulate.a = 1.0
	super._process(delta)

## ためている間は体を明るく光らせる（よけるための合図）。毒は緑、やけどは赤、遅いと青。
func _tint() -> void:
	var winding := melee.is_winding_up() or charge_phase == 1 or lunge_phase == 1 or (_fuse >= 0.0 and int(_fuse * 12.0) % 2 == 0)
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
		walker.chase(target.mover.pos, target.mover.height)
	walker.step(delta)

## 相手が近いと離れ、遠ければ往復する（射手・投石兵）。
func _keep_away(delta: float, alive_target: bool, flee: float) -> void:
	var d := _to_target()
	if alive_target and d.length() < flee and absi(target.mover.height - walker.height) <= 2:
		walker.dir = -d.normalized()
		walker.speed_mult = EnemyKind.speed_mult(kind) * 1.2
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
				_lunge_dir = d.normalized()
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
				_lunge_dir = d.normalized()
				walker.speed_mult = EnemyKind.speed_mult(kind) * 3.2
				Sfx.play("wing", walker.pos)
		2:
			_lunge_time += delta
			walker.dir = _lunge_dir
			walker.step(delta)
			if _lunge_time >= 0.5:
				lunge_phase = 0
				_rest = 2.6 if kind == EnemyKind.Kind.FLYER else 1.8
				_orbit = -_orbit
				walker.speed_mult = EnemyKind.speed_mult(kind)

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
			if _lunge_time >= SPEAR_WINDUP:
				lunge_phase = 2
				_lunge_time = 0.0
				Sfx.play("thrust", walker.pos, -4.0)
				if spear_hits(walker.pos, walker.height, _lunge_dir, target.mover.pos, target.mover.height):
					melee_hit.emit()
		2:
			_lunge_time += delta
			if _lunge_time >= 0.2:
				lunge_phase = 0
				_rest = 1.6

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
		lobbed.emit(target.mover.pos, target.mover.height, LOB_FLIGHT, attack)

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
	# 相手の体へまっすぐ撃つ。高い所からなら下まで届き、下からだと崖に当たりやすい
	var b := Bullet.new()
	b.aim(walker.pos, walker.height, target.mover.pos, target.mover.height, BULLET_SPEED)
	b.damage = attack
	shot.emit(b)

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
