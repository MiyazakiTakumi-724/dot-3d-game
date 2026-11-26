class_name EnemyKind
extends RefCounted
## 敵の種類ごとの決まり。体力と攻撃力はレベル1の値で、レベルで20%ずつ増える（design.md 17.1）。
## 経験値は、種類ごとの値 × レベル【提案】。2026-11-25 に6種類を足し（設計 4章）、夜にさらに6種類を足して
## 基準の数値を上げた（体力はおよそ3倍、攻撃力はおよそ1.6倍。`2026-11-25-balance-pass.md` 4章）。数値は【提案】。
## 動き方は scripts/game/enemy.gd。2026-11-25 夜（2回目の直し）：イノシシのほかは、どの敵も1段は登れる（浮いている敵は段差を越える）。
## WEAK スライム：近づくと、ためて跳びかかる。MELEE ゴブリン：寄って、ためて叩き、少し下がる。
## SHOOTER 射手：近づかれると離れる。ときどき3発続けて撃つ。SHIELD 盾持ち：正面からの剣・矢・魔法を防ぎ、ゆっくり向き直る。
## SHADOW 影：体が見えない。近づくと跳びこむ。FLYER コウモリ：飛ぶ。回って急降下する。剣と鉄球は当たらない。
## CHARGER イノシシ：まっすぐ並ぶと突進する。壁にぶつかると目を回す（その間ダメージ×2）。
## BOMBER 火の玉：寄ってきて、そばで弾ける。GHOST 亡霊：足音を聞いて遠くから寄る。すけている間は攻撃がすり抜ける。
## SPEAR 槍兵：少し離れて構え、ためて長く突く。LOBBER 投石兵：石を山なりに投げる（落ちる所に影）。近づかれると逃げる。
## MAGE 魔術師：ときどき消えて別の所に現れ、3方向に遅い弾を撃つ。BEETLE 甲虫：かたい殻（剣・矢・魔法は1だけ）。
## 鉄球でひっくり返すと、その間はふつうに入る。WASP 蜂：小さく速く飛ぶ。剣と鉄球は当たらない。
## MIMIC 擬態箱：宝箱のふりをしていて、近づくと噛みつく。よい物を落とす。
## 2026-11-26（4回目の直し、霧の谷）：WOLF 狼：すばやく、まわりを回ってから跳びかかる。見つけると遠吠えして群れが速くなる。
## DARK_KNIGHT 黒騎士：重い鎧。正面からの矢を防ぐ。離れると剣の衝撃波、中くらいの間合いで突進、近いと回転斬り。

enum Kind { WEAK, MELEE, SHOOTER, SHIELD, SHADOW, FLYER, CHARGER, BOMBER, GHOST, SPEAR, LOBBER, MAGE, BEETLE, WASP, MIMIC, WOLF, DARK_KNIGHT }

## [名前, 体力, 攻撃力, 経験値, 登れる段, 撃つ, 体当たり, ためて叩く, 速さの倍率, 寄ってくる距離（px、0は寄らない）]
const DATA := {
	Kind.WEAK: ["スライム", 14, 4, 4, 1, false, true, false, 1.0, 56.0],
	Kind.MELEE: ["ゴブリン", 28, 6, 7, 1, false, false, true, 1.05, 64.0],
	Kind.SHOOTER: ["射手", 16, 5, 6, 1, true, true, false, 1.0, 0.0],
	Kind.SHIELD: ["盾持ち", 40, 6, 10, 1, false, false, true, 0.8, 64.0],
	Kind.SHADOW: ["影", 22, 6, 9, 1, false, true, false, 1.2, 72.0],
	Kind.FLYER: ["コウモリ", 14, 5, 7, 9, false, true, false, 1.2, 88.0],
	Kind.CHARGER: ["イノシシ", 30, 8, 9, 0, false, true, false, 1.0, 0.0],
	Kind.BOMBER: ["火の玉", 16, 12, 8, 1, false, false, false, 1.1, 64.0],
	Kind.GHOST: ["亡霊", 26, 6, 10, 1, false, true, false, 0.9, 96.0],
	Kind.SPEAR: ["槍兵", 32, 8, 10, 1, false, false, false, 0.9, 80.0],
	Kind.LOBBER: ["投石兵", 20, 6, 8, 1, false, false, false, 0.9, 0.0],
	Kind.MAGE: ["魔術師", 22, 7, 12, 1, true, false, false, 0.8, 0.0],
	Kind.BEETLE: ["甲虫", 30, 7, 10, 1, false, true, false, 0.8, 48.0],
	Kind.WASP: ["蜂", 9, 4, 4, 9, false, true, false, 1.6, 104.0],
	Kind.MIMIC: ["擬態箱", 40, 10, 16, 1, false, false, true, 1.25, 72.0],
	Kind.WOLF: ["狼", 24, 7, 9, 1, false, true, false, 1.35, 112.0],
	Kind.DARK_KNIGHT: ["黒騎士", 64, 11, 22, 1, false, false, true, 0.85, 88.0],
}
## 亡霊が、しゃがんで歩くプレイヤーに気づく距離（px）
const GHOST_QUIET_RANGE := 24.0
## 火の玉が弾ける距離と、弾けたときに届く広さ（px）
const BOMB_TRIGGER := 14.0
const BOMB_RADIUS := 22.0
## イノシシの突進：横か縦にこの距離（px）以内で並ぶと、ためてから突進する。壁にぶつかると STUN_SECONDS 目を回す
const CHARGE_RANGE := 96.0
const CHARGE_WINDUP := 0.6
const CHARGE_SPEED_MULT := 4.0
const CHARGE_SECONDS := 1.0
const STUN_SECONDS := 2.0
## 甲虫が鉄球でひっくり返っている時間
const FLIP_SECONDS := 3.0
## 亡霊：見えている時間と、すけている時間
const GHOST_SOLID := 2.5
const GHOST_FADED := 1.5

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

## 浮いている敵（段差・水・奈落を越える。剣と鉄球は当たらない）
static func flies(k: Kind) -> bool:
	return k == Kind.FLYER or k == Kind.WASP

## 盾持ちが攻撃を防ぐか。facing は盾持ちの向き、from は攻撃してきた所、at は盾持ちの位置。正面の左右60°からの攻撃を防ぐ。
static func blocks(k: Kind, facing: Vector2, at: Vector2, from: Vector2) -> bool:
	if k != Kind.SHIELD or from == at:
		return false
	return facing.normalized().dot((from - at).normalized()) > 0.5

## 攻撃（source：sword・arrow・magic・ball・bomb）がどう当たるか。state は敵の今の様子
## （flipped 甲虫がひっくり返っている、faded 亡霊がすけている、stunned イノシシが目を回している）。
## "" ふつうに入る / "miss" 届かない（浮いている敵に剣・鉄球）/ "pass" すり抜ける / "block" 盾で防ぐ /
## "armor" かたい（1だけ入る）/ "weak" 弱っている（×2）
static func hit_rule(k: Kind, source: String, facing: Vector2, at: Vector2, from: Vector2, state := {}) -> String:
	if flies(k) and source in ["sword", "ball"]:
		return "miss"
	if k == Kind.GHOST and state.get("faded", false):
		return "pass"
	if k == Kind.SHIELD and source in ["sword", "arrow", "magic"] and blocks(k, facing, at, from):
		return "block"
	if k == Kind.DARK_KNIGHT and source == "arrow" and from != at and facing.normalized().dot((from - at).normalized()) > 0.5:
		return "block"  # 黒騎士は正面からの矢を剣ではじく
	if k == Kind.BEETLE and not state.get("flipped", false) and source in ["sword", "arrow", "magic"]:
		return "armor"
	if state.get("stunned", false):
		return "weak"
	return ""

## 武器の得意・不得意（2026-11-26 の4回目の直し）【提案】。弱点は×1.5、効きにくいと×0.5。
## 矢が効きにくい敵を多くして、弓だけでは進みにくくする。剣・鉄球・魔法にもそれぞれ得意な相手がいる。
const WEAK_MULT := 1.5
const RESIST_MULT := 0.5
## 種類 → {攻撃: 倍率}（ない攻撃は1）
const AFFINITY := {
	Kind.WEAK: {"sword": WEAK_MULT, "arrow": RESIST_MULT},
	Kind.SHOOTER: {"sword": WEAK_MULT},
	Kind.SHIELD: {"ball": WEAK_MULT, "bomb": WEAK_MULT, "arrow": RESIST_MULT},
	Kind.SHADOW: {"magic": WEAK_MULT, "arrow": RESIST_MULT},
	Kind.FLYER: {"arrow": WEAK_MULT, "magic": WEAK_MULT},
	Kind.BOMBER: {"arrow": WEAK_MULT, "magic": RESIST_MULT},
	Kind.GHOST: {"magic": WEAK_MULT, "arrow": RESIST_MULT},
	Kind.SPEAR: {"ball": WEAK_MULT, "arrow": RESIST_MULT},
	Kind.LOBBER: {"arrow": WEAK_MULT},
	Kind.MAGE: {"sword": WEAK_MULT, "magic": RESIST_MULT},
	Kind.BEETLE: {"ball": WEAK_MULT, "bomb": WEAK_MULT},
	Kind.WASP: {"magic": WEAK_MULT},
	Kind.MIMIC: {"magic": WEAK_MULT, "bomb": WEAK_MULT, "arrow": RESIST_MULT},
	Kind.WOLF: {"sword": WEAK_MULT, "arrow": RESIST_MULT},
	Kind.DARK_KNIGHT: {"magic": WEAK_MULT, "ball": WEAK_MULT, "arrow": RESIST_MULT},
}

static func affinity(k: Kind, source: String) -> float:
	return AFFINITY.get(k, {}).get(source, 1.0)

## 亡霊がプレイヤーに気づく距離。しゃがんで歩いていると短い。
static func hearing(k: Kind, crouching: bool) -> float:
	if k == Kind.GHOST and crouching:
		return GHOST_QUIET_RANGE
	return chase_range(k)
