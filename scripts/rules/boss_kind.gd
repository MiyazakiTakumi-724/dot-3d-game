class_name BossKind
extends RefCounted
## ボスの数値と落とし物（2026-11-25 の設計 5章、夜に直した）。落とし物はボスの素材（ランク4の装備を作るのに使う）とお金。
## 装備は落とさない（倒してすぐ強い装備にならないように。作るのに地方の素材と、Lv6以上の敵が落とす力の結晶も要る）。
## 体力・攻撃力は、倒したボスの数で少しずつ上がる（1体ごとに10%）。数値は【提案】。
## 双子は2体で1つのボス（名前「双子」）。像の名前「双子（左）」「双子（右）」は group で「双子」にまとめる。

## 名前 → [体力, 攻撃力, 経験値, 落とし物 [[id, 数], ...]]
const DATA := {
	"岩転がしの巨人": [360, 12, 120, [["giant_core", 2], ["money", 150]]],
	"草むらの大蛇": [330, 12, 120, [["serpent_fang", 2], ["money", 150]]],
	"満ち引きする溶岩": [400, 14, 140, [["lava_heart", 2], ["money", 180]]],
	"廃城の主": [420, 15, 140, [["crest", 2], ["money", 180]]],
	"岩窟のぬし": [450, 15, 160, [["cave_gem", 2], ["money", 200]]],
	"溶岩洞のぬし": [420, 16, 160, [["flame_tail", 2], ["money", 200]]],
	"女王蜂": [300, 14, 160, [["queen_sting", 2], ["money", 200]]],
	"宝箱の王": [380, 15, 160, [["king_crown", 2], ["money", 300]]],
	"双子": [260, 16, 220, [["twin_mirror", 2], ["star_shard", 2]]],
	"らせん塔の番人": [520, 17, 200, [["gear", 2], ["star_shard", 2]]],
	"ブライト": [660, 18, 300, [["bright_eye", 1], ["star_shard", 5]]],
	"闇の王": [600, 17, 260, [["dark_crest", 2], ["money", 300]]],  # 霧の谷の砦（2026-11-26）
}

## 体力がこの割合以下になると2段目（攻撃が増える）
const PHASE2_RATIO := 0.5

## 今の段（1か2）。
static func phase(hp_now: int, hp_max: int) -> int:
	return 2 if hp_now <= hp_max * PHASE2_RATIO else 1

## 浮いているボス（剣と鉄球が届かない）
static func flies(boss_name: String) -> bool:
	return group(boss_name) == "女王蜂"

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
