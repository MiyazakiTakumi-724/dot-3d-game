class_name EnemyKind
extends RefCounted
## 敵の種類ごとの決まり。体力と攻撃力はレベル1の値で、レベルで20%ずつ増える（design.md 17.1）。
## 敵1（WEAK）：一番弱い敵。体力5、攻撃力3。段差を登り降りしない。体当たり。
## 敵2（MELEE）：体力10、攻撃力4【提案】。1段まで登り降りし、近くのプレイヤーへ寄って叩く。体当たりはない。
## 撃つ敵（SHOOTER）：体力5、攻撃力3【提案】。段差なし、2秒ごとに撃つ、体当たり。
## 倒したときの経験値は、種類ごとの値 × レベル【提案】。

enum Kind { WEAK, MELEE, SHOOTER }

static func hp(k: Kind, level := 1) -> int:
	return Damage.enemy_scaled(10 if k == Kind.MELEE else 5, level)

static func attack(k: Kind, level := 1) -> int:
	return Damage.enemy_scaled(4 if k == Kind.MELEE else 3, level)

static func exp_reward(k: Kind, level := 1) -> int:
	return (4 if k == Kind.MELEE else 2) * level

static func climb(k: Kind) -> int:
	return 1 if k == Kind.MELEE else 0

static func shoots(k: Kind) -> bool:
	return k == Kind.SHOOTER

static func contact(k: Kind) -> bool:
	return k != Kind.MELEE
