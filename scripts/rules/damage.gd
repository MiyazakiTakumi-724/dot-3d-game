class_name Damage
extends RefCounted
## ダメージの式（design.md 17章）。小数は切り捨て、最低でも1は入る。

## 掛け算の誤差で 7.5 が 7.4999… になって切り捨てがずれないように、少しだけ足してから切り捨てる。
static func _floor(x: float) -> int:
	return maxi(1, int(floor(x + 0.0001)))

## 2026-11-25 夜（2回目の直し）に式を見直した（docs/superpowers/specs/2026-11-25-tuning-2.md 2章）。
## つよさの基本を5から10にして、どの武器の倍率も半分にした（はじめのダメージは前と同じ）。
## 武器のポイントは1つで5%（前は10%）。鉄球がレベルで勝手に強くなる分はやめた（伸びはつよさと装備だけ）。
## 武器ごとの倍率
const BALL_RATE := 0.5
const SWORD_RATE := 0.3
const BOW_RATE := 0.5
const MAGIC_RATE := 0.5
## 武器のポイント1つで伸びる割合
const POINT_RATE := 0.05

## 鉄球：つよさ × 0.5 ×（1 ＋ 落とした高さ × 0.5）。
## 自分より高い所へは落とせないが、念のため負の高さは0として扱う。
static func iron_ball(attack: int, drop_levels: int) -> int:
	return _floor(attack * BALL_RATE * (1.0 + maxi(0, drop_levels) * 0.5))

## 剣：つよさ × 0.3 ×（1 ＋ 剣のポイント × 0.05）。落下斬りは ×（1 ＋ 落ちた段数 × 0.5）、
## 技能「落下斬り強化」があれば 0.5 が 0.75 になる。
static func sword(attack: int, points: int, fall_levels: int, strong_fall := false) -> int:
	var fall_rate := 0.75 if strong_fall else 0.5
	return _floor(attack * SWORD_RATE * (1.0 + points * POINT_RATE) * (1.0 + maxi(0, fall_levels) * fall_rate))

## 高さ attacker_h から、高さ target_h の相手を攻撃できるか。下から上へは、1段でも当たらない（2026-11-24 決定）。
## 主人公の攻撃にも、敵の攻撃にも使う。高い所から攻めて威力が増えるのは鉄球だけ（同じ日に、剣と魔法の上乗せはやめた）。
static func can_hit(attacker_h: int, target_h: int) -> bool:
	return target_h <= attacker_h

## 弓：つよさ × 0.5 × チャージ率 × 矢の倍率 ×（1 ＋ 弓のポイント × 0.05）。
## lower_levels は技能「高所射撃」で数える、自分より低い段数（×（1 ＋ 段数 × 0.5））。
static func bow(attack: int, rate: float, mult: float, points: int, lower_levels := 0) -> int:
	return _floor(attack * BOW_RATE * rate * mult * (1.0 + points * POINT_RATE) * (1.0 + maxi(0, lower_levels) * 0.5))

## 魔法：つよさ × 0.5 × 魔法の倍率（Magic.POWER）×（1 ＋ 魔法のポイント × 0.05）。
static func magic(attack: int, power: float, points: int) -> int:
	return _floor(attack * MAGIC_RATE * power * (1.0 + points * POINT_RATE))

## 敵の攻撃が主人公に与えるダメージ。簡単モードでは半分。守り（defense）の数だけ減る（最低1）。
static func enemy_hit(enemy_attack: int, easy := false, defense := 0) -> int:
	return maxi(1, _floor(enemy_attack * (0.5 if easy else 1.0)) - defense)

## 敵の体力・攻撃力：レベルが1上がるごとに、レベル1の値の15%ずつ増える（2026-11-25 夜に20%から下げた。主人公の伸びを下げたので）。
const ENEMY_GROWTH := 0.15
static func enemy_scaled(base: int, level: int) -> int:
	return _floor(base * (1.0 + (level - 1) * ENEMY_GROWTH))
