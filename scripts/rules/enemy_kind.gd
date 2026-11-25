class_name EnemyKind
extends RefCounted
## 敵の種類ごとの決まり。体力と攻撃力はレベル1の値で、レベルで20%ずつ増える（design.md 17.1）。
## 経験値は、種類ごとの値 × レベル【提案】。2026-11-25 に6種類を足した（設計 4章）。数値は【提案】。
## WEAK スライム：段差なし、往復、体当たり。MELEE ゴブリン：1段登って寄り、ためて叩く。SHOOTER 射手：2秒ごとに撃つ。
## SHIELD 盾持ち：正面からの剣・矢・魔法を防ぐ（鉄球と背中からは通る）。SHADOW 影：体が見えない。寄って体当たり。
## FLYER コウモリ：飛ぶ（段差・水・奈落を越える）。CHARGER イノシシ：まっすぐ並ぶと突進する。
## BOMBER 火の玉：寄ってきて、そばで弾ける。GHOST 亡霊：足音を聞いて遠くから寄る（しゃがむと気づかれにくい）。

enum Kind { WEAK, MELEE, SHOOTER, SHIELD, SHADOW, FLYER, CHARGER, BOMBER, GHOST }

## [名前, 体力, 攻撃力, 経験値, 登れる段, 撃つ, 体当たり, ためて叩く, 速さの倍率, 寄ってくる距離（px、0は寄らない）]
const DATA := {
	Kind.WEAK: ["スライム", 5, 3, 2, 0, false, true, false, 1.0, 0.0],
	Kind.MELEE: ["ゴブリン", 10, 4, 4, 1, false, false, true, 1.0, 48.0],
	Kind.SHOOTER: ["射手", 5, 3, 3, 0, true, true, false, 1.0, 0.0],
	Kind.SHIELD: ["盾持ち", 14, 4, 6, 1, false, false, true, 0.8, 48.0],
	Kind.SHADOW: ["影", 7, 4, 5, 1, false, true, false, 1.3, 64.0],
	Kind.FLYER: ["コウモリ", 6, 3, 4, 9, false, true, false, 1.2, 72.0],
	Kind.CHARGER: ["イノシシ", 9, 6, 5, 0, false, true, false, 1.0, 0.0],
	Kind.BOMBER: ["火の玉", 6, 8, 5, 1, false, false, false, 1.1, 64.0],
	Kind.GHOST: ["亡霊", 9, 4, 6, 1, false, true, false, 0.9, 96.0],
}
## 亡霊が、しゃがんで歩くプレイヤーに気づく距離（px）
const GHOST_QUIET_RANGE := 24.0
## 火の玉が弾ける距離と、弾けたときに届く広さ（px）
const BOMB_TRIGGER := 14.0
const BOMB_RADIUS := 22.0
## イノシシの突進：横か縦にこの距離（px）以内で並ぶと、ためてから突進する
const CHARGE_RANGE := 96.0
const CHARGE_WINDUP := 0.6
const CHARGE_SPEED_MULT := 4.0
const CHARGE_SECONDS := 1.0

static func name_of(k: Kind) -> String:
	return DATA[k][0]

static func hp(k: Kind, level := 1) -> int:
	return Damage.enemy_scaled(DATA[k][1], level)

static func attack(k: Kind, level := 1) -> int:
	return Damage.enemy_scaled(DATA[k][2], level)

static func exp_reward(k: Kind, level := 1) -> int:
	return DATA[k][3] * level

static func climb(k: Kind) -> int:
	return DATA[k][4]

static func shoots(k: Kind) -> bool:
	return DATA[k][5]

static func contact(k: Kind) -> bool:
	return DATA[k][6]

## ためて叩く敵（MeleeAttack を使う）。
static func melee(k: Kind) -> bool:
	return DATA[k][7]

static func speed_mult(k: Kind) -> float:
	return DATA[k][8]

## 寄ってくる距離（px）。0なら寄らない。
static func chase_range(k: Kind) -> float:
	return DATA[k][9]

static func flies(k: Kind) -> bool:
	return k == Kind.FLYER

## 盾持ちが攻撃を防ぐか。facing は盾持ちの向き、from は攻撃してきた所、at は盾持ちの位置。正面の左右60°からの攻撃を防ぐ。
static func blocks(k: Kind, facing: Vector2, at: Vector2, from: Vector2) -> bool:
	if k != Kind.SHIELD or from == at:
		return false
	return facing.normalized().dot((from - at).normalized()) > 0.5

## 亡霊がプレイヤーに気づく距離。しゃがんで歩いていると短い。
static func hearing(k: Kind, crouching: bool) -> float:
	if k == Kind.GHOST and crouching:
		return GHOST_QUIET_RANGE
	return chase_range(k)
