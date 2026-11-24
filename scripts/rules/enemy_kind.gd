class_name EnemyKind
extends RefCounted
## 敵の種類ごとの決まり。
## 敵1（WEAK）：弱いので段差を登り降りしない。体力1、体当たり。
## 敵2（MELEE）：体力2、1段まで登り降りし、近くのプレイヤーへ寄って叩く。体当たりはない。
## 撃つ敵（SHOOTER）：体力1、段差なし、2秒ごとに撃つ、体当たり。

enum Kind { WEAK, MELEE, SHOOTER }

static func hp(k: Kind) -> int:
	return 2 if k == Kind.MELEE else 1

static func climb(k: Kind) -> int:
	return 1 if k == Kind.MELEE else 0

static func shoots(k: Kind) -> bool:
	return k == Kind.SHOOTER

static func contact(k: Kind) -> bool:
	return k != Kind.MELEE
