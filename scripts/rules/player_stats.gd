class_name PlayerStats
extends RefCounted
## 主人公のレベル・経験値・振り分け（design.md 11章、17章）。死んでもすべて残る。
## レベルが上がるとポイントがもらえ、6つの項目に1つずつ振る。振るとその項目の基本の値が少し上がり、
## 同じ項目に3ポイント振るごとに技能を1つ覚える（技能の中身は後の段階で作る）。
## 数値のうち、17.1 にないもの（必要経験値・ポイント数・1ポイントで上がる量）は【提案】の仮の値。

enum Stat { VITALITY, ATTACK, SWORD, BOW, MAGIC, MOVE }

const NAMES := {
	Stat.VITALITY: "いのち",
	Stat.ATTACK: "つよさ",
	Stat.SWORD: "剣",
	Stat.BOW: "弓",
	Stat.MAGIC: "魔法",
	Stat.MOVE: "体の動き",
}

## 項目ごとの技能と覚える順番（design.md 11章）。体力・攻撃力に技能を付けるかは未定（16章）。
const SKILLS := {
	Stat.SWORD: ["落下斬り強化", "突き", "回転斬り"],  # 斬り上げは上へ攻撃できない決まりにしたので突きに替えた
	Stat.BOW: ["矢の種類", "高所射撃", "連射"],
	Stat.MAGIC: ["魔法2つ目", "最大マナ＋10", "魔法3つ目"],  # 2026-11-24 決定
	Stat.MOVE: ["しゃがみ", "受け身", "よじ登り"],
}

const BASE_HP := 10
const BASE_ATTACK := 5
const HP_PER_POINT := 2
const ATTACK_PER_POINT := 1
const SPEED_PER_POINT := 0.03  ## 体の動き1ポイントで足が3%速くなる
const POINTS_PER_LEVEL := 2
const POINTS_PER_SKILL := 3
const EXP_STEP := 5  ## レベル n から n+1 へは n × 5 の経験値

var level := 1
## これまでにもらった経験値の合計
var exp := 0
## まだ振っていないポイント
var points := 0
var _alloc := {}

## レベル lv になるのに必要な経験値の合計。
static func exp_to_reach(lv: int) -> int:
	return EXP_STEP * (lv - 1) * lv / 2

## 経験値をもらう。上がったレベルの数を返す。
func add_exp(n: int) -> int:
	exp += n
	var gained := 0
	while exp >= exp_to_reach(level + 1):
		level += 1
		points += POINTS_PER_LEVEL
		gained += 1
	return gained

## 今のレベルに入ってからの経験値と、次のレベルまでの幅（画面に出す用）。
func exp_in_level() -> int:
	return exp - exp_to_reach(level)

func exp_level_span() -> int:
	return exp_to_reach(level + 1) - exp_to_reach(level)

func allocate(stat: Stat) -> bool:
	if points <= 0:
		return false
	points -= 1
	_alloc[stat] = points_in(stat) + 1
	return true

func points_in(stat: Stat) -> int:
	return _alloc.get(stat, 0)

## 覚えた技能の数。
func skills_in(stat: Stat) -> int:
	return points_in(stat) / POINTS_PER_SKILL

## 最大体力。equip は装備で足される分。
func max_hp(equip := 0) -> int:
	return BASE_HP + points_in(Stat.VITALITY) * HP_PER_POINT + equip

## 攻撃力。equip は手に持つ武器（と防具）で足される分。
func attack(equip := 0) -> int:
	return BASE_ATTACK + points_in(Stat.ATTACK) * ATTACK_PER_POINT + equip

## 同時に使える魔法の数（1〜3）。魔法に3ポイントで2つ、9ポイントで3つ。
func spell_slots() -> int:
	var n := skills_in(Stat.MAGIC)
	return 1 + (1 if n >= 1 else 0) + (1 if n >= 3 else 0)

## 最大マナ。魔法に6ポイントで＋10。
func max_mana() -> int:
	return Mana.BASE_MAX + (MANA_BONUS if skills_in(Stat.MAGIC) >= 2 else 0)

const MANA_BONUS := 10

func move_speed_mult() -> float:
	return 1.0 + points_in(Stat.MOVE) * SPEED_PER_POINT
