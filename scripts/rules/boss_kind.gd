class_name BossKind
extends RefCounted
## ボスの数値と落とし物（2026-11-25 の設計 5章）。落とし物はランク4の装備とボスの素材（ブライトは素材だけ）。
## 体力・攻撃力は、倒したボスの数で少しずつ上がる（1体ごとに10%）。数値は【提案】。
## 双子は2体で1つのボス（名前「双子」）。像の名前「双子（左）」「双子（右）」は group で「双子」にまとめる。

## 名前 → [体力, 攻撃力, 経験値, 落とし物 [[id, 数], ...]]
const DATA := {
	"岩転がしの巨人": [120, 8, 60, [["sword_giant", 1], ["giant_core", 1]]],
	"草むらの大蛇": [110, 8, 60, [["bow_serpent", 1], ["serpent_fang", 1]]],
	"満ち引きする溶岩": [130, 9, 70, [["staff_lava", 1], ["lava_heart", 1]]],
	"廃城の主": [140, 10, 70, [["armor_knight", 1], ["crest", 1]]],
	"岩窟のぬし": [150, 10, 80, [["ball_rock", 1], ["cave_gem", 1]]],
	"溶岩洞のぬし": [140, 11, 80, [["ball_lava", 1], ["flame_tail", 1]]],
	"双子": [90, 10, 120, [["bow_twin", 1], ["twin_mirror", 1], ["star_shard", 2]]],
	"らせん塔の番人": [180, 12, 100, [["armor_wind", 1], ["gear", 1], ["star_shard", 2]]],
	"ブライト": [220, 13, 150, [["bright_eye", 1], ["star_shard", 5]]],
}

static func group(statue_name: String) -> String:
	return "双子" if statue_name.begins_with("双子") else statue_name

static func hp(boss_name: String, bosses_defeated := 0) -> int:
	return int(DATA[group(boss_name)][0] * (1.0 + 0.1 * bosses_defeated))

static func attack(boss_name: String, bosses_defeated := 0) -> int:
	return int(DATA[group(boss_name)][1] * (1.0 + 0.1 * bosses_defeated))

static func exp_reward(boss_name: String) -> int:
	return DATA[group(boss_name)][2]

static func drops(boss_name: String) -> Array:
	return DATA[group(boss_name)][3]
