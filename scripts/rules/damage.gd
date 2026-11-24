class_name Damage
extends RefCounted
## ダメージの式（design.md 17章）。小数は切り捨て、最低でも1は入る。

## 掛け算の誤差で 7.5 が 7.4999… になって切り捨てがずれないように、少しだけ足してから切り捨てる。
static func _floor(x: float) -> int:
	return maxi(1, int(floor(x + 0.0001)))

## 鉄球：攻撃力 ×（1 ＋ 落とした高さ × 0.5）×（1 ＋（レベル − 1）× 0.1）。
## 自分より高い所へは落とせないが、念のため負の高さは0として扱う。
static func iron_ball(attack: int, drop_levels: int, level: int) -> int:
	return _floor(attack * (1.0 + maxi(0, drop_levels) * 0.5) * (1.0 + (level - 1) * 0.1))

## 剣：攻撃力 × 0.6 ×（1 ＋ 剣のポイント × 0.1）。落下斬りは ×（1 ＋ 落ちた段数 × 0.5）、
## 技能「落下斬り強化」があれば 0.5 が 0.75 になる。
static func sword(attack: int, points: int, fall_levels: int, strong_fall := false) -> int:
	var fall_rate := 0.75 if strong_fall else 0.5
	return _floor(attack * 0.6 * (1.0 + points * 0.1) * (1.0 + maxi(0, fall_levels) * fall_rate))

## 敵の攻撃が主人公に与えるダメージ。簡単モードでは半分。
static func enemy_hit(enemy_attack: int, easy := false) -> int:
	return _floor(enemy_attack * (0.5 if easy else 1.0))

## 敵の体力・攻撃力：レベルが1上がるごとに、レベル1の値の20%ずつ増える。
static func enemy_scaled(base: int, level: int) -> int:
	return _floor(base * (1.0 + (level - 1) * 0.2))
