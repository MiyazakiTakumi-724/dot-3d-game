class_name Loot
extends RefCounted
## 敵の落とし物（2026-11-25 の設計 4章）。お金は毎回、その地方の素材はよく、回復薬はときどき、装備はまれ。
## 装備は src に drop がある品物のうち、地方ごとに決めたランクのもの。割合は【提案】。

const MATERIAL_CHANCE := 0.6
const TOOL_CHANCE := 0.08
const GEAR_CHANCE := 0.03
## 擬態箱が装備を落とす割合
const MIMIC_GEAR_CHANCE := 0.4

const REGION_MATERIALS := {
	"はじまりの地": ["hide", "bone", "scrap", "wood", "herb"],
	"山岳": ["iron_ore", "snow", "bone", "scrap", "hide"],
	"草原": ["herb", "scale", "hide", "wood"],
	"廃城": ["old_steel", "silver", "scrap", "bone"],
	"溶岩": ["obsidian", "fire_stone", "bone", "scrap"],
	"神秘の塔": ["star_shard", "silver", "old_steel", "snow"],
}
## 地方ごとに落ちる装備のランク
const REGION_GEAR_RANKS := {
	"はじまりの地": [1],
	"山岳": [1, 2],
	"草原": [1, 2],
	"廃城": [2, 3],
	"溶岩": [2, 3],
	"神秘の塔": [3, 4],
}
## 地方ごとの敵の基本のレベル（倒したボスの数が足される）
const REGION_LEVEL := {"はじまりの地": 1, "山岳": 2, "草原": 2, "廃城": 3, "溶岩": 3, "神秘の塔": 5}

## 敵1体の落とし物 [[id, 数], ...]。loot_mult は特色（狩人の弓）で素材が落ちやすくなる倍率。
static func roll(region: String, level: int, rng: RandomNumberGenerator, loot_mult := 1.0) -> Array:
	var out: Array = [[ItemCatalog.MONEY, 4 + 3 * level + rng.randi_range(0, 4)]]  # 敵が強くなったので多め（2026-11-25 夜）
	var mats: Array = REGION_MATERIALS.get(region, REGION_MATERIALS["はじまりの地"])
	if rng.randf() < minf(1.0, MATERIAL_CHANCE * loot_mult):
		out.append([mats[rng.randi_range(0, mats.size() - 1)], 1])
	if rng.randf() < TOOL_CHANCE:
		out.append(["potion", 1])
	if rng.randf() < GEAR_CHANCE:
		var list := gear_pool(region)
		if not list.is_empty():
			out.append([list[rng.randi_range(0, list.size() - 1)], 1])
	return out

## 敵の種類ごとの落とし物。擬態箱はお金が4倍、素材を2つ、装備をよく落とす（balance-pass 4章）【提案】。
static func roll_kind(k: EnemyKind.Kind, region: String, level: int, rng: RandomNumberGenerator, loot_mult := 1.0) -> Array:
	var out := roll(region, level, rng, loot_mult)
	if k != EnemyKind.Kind.MIMIC:
		return out
	out[0][1] *= 4
	var mats: Array = REGION_MATERIALS.get(region, REGION_MATERIALS["はじまりの地"])
	for i in 2:
		out.append([mats[rng.randi_range(0, mats.size() - 1)], 1])
	var list := gear_pool(region)
	if not list.is_empty() and rng.randf() < MIMIC_GEAR_CHANCE:
		out.append([list[rng.randi_range(0, list.size() - 1)], 1])
	return out

## その地方の敵が落とす装備の一覧。
static func gear_pool(region: String) -> Array:
	var ranks: Array = REGION_GEAR_RANKS.get(region, [1])
	var out: Array = []
	for id in ItemCatalog.ITEMS:
		if "drop" in ItemCatalog.sources(id) and ItemCatalog.rank(id) in ranks:
			out.append(id)
	return out

static func region_level(region: String) -> int:
	return REGION_LEVEL.get(region, 1)
