class_name Recipes
extends RefCounted
## 鍛冶屋で作れる物（2026-11-25 の設計 2・3章）。1行は [作る物の id, 数, {素材の id: 数}, お金]。
## ランク5の装備は、ここでしか手に入らない（星のかけらとボスの素材を使う）。数は【提案】。
## 2026-11-25 夜（2回目の直し）：ランク4は力の結晶（Lv6以上の敵が落とす）、ランク5はいにしえの結晶（Lv10以上の敵）も要る。

const LIST := [
	# 道具と矢
	["potion", 1, {"herb": 2}, 0],
	["potion_m", 1, {"herb": 4}, 5],
	["potion_l", 1, {"herb": 6, "scale": 1}, 10],
	["ether", 1, {"herb": 3, "silver": 1}, 5],
	["bomb", 1, {"fire_stone": 1, "scrap": 2}, 5],
	["arrow", 10, {"wood": 1, "scrap": 1}, 0],
	["arrow_poison", 5, {"wood": 1, "scale": 1}, 0],
	["arrow_fire", 5, {"wood": 1, "fire_stone": 1}, 0],
	["arrow_iron", 5, {"wood": 1, "iron_ore": 1}, 0],
	# ランク1
	["sword_1", 1, {"wood": 2, "scrap": 2}, 10],
	["bow_1", 1, {"wood": 3, "hide": 1}, 10],
	["staff_none_1", 1, {"wood": 3, "herb": 1}, 10],
	["armor_1", 1, {"hide": 2}, 5],
	# ランク2
	["ball_heavy", 1, {"scrap": 4, "iron_ore": 2}, 50],
	["ball_wide", 1, {"scrap": 3, "bone": 3}, 50],
	["sword_light", 1, {"scrap": 3, "wood": 2}, 50],
	["sword_bronze", 1, {"scrap": 5}, 60],
	["bow_short", 1, {"wood": 4, "hide": 2}, 50],
	["bow_long", 1, {"wood": 5, "bone": 2}, 60],
	["staff_fire_2", 1, {"wood": 3, "bone": 2, "herb": 2}, 60],
	["staff_ice_2", 1, {"wood": 3, "snow": 2}, 60],
	["armor_leather", 1, {"hide": 5}, 40],
	["armor_travel", 1, {"hide": 3, "herb": 3}, 50],
	# ランク3
	["ball_spike", 1, {"iron_ore": 4, "bone": 4}, 120],
	["ball_chain", 1, {"iron_ore": 5, "scrap": 4}, 120],
	["ball_ember", 1, {"fire_stone": 4, "scrap": 4}, 120],
	["sword_poison", 1, {"scale": 4, "scrap": 4}, 120],
	["sword_long", 1, {"iron_ore": 5, "wood": 3}, 120],
	["sword_drain", 1, {"bone": 6, "silver": 2}, 140],
	["bow_hunter", 1, {"wood": 5, "hide": 5, "scale": 2}, 120],
	["bow_poison", 1, {"wood": 4, "scale": 4}, 120],
	["bow_heavy", 1, {"wood": 5, "iron_ore": 4}, 130],
	["staff_fire_3", 1, {"wood": 4, "fire_stone": 4}, 140],
	["staff_ice_3", 1, {"wood": 4, "snow": 5}, 140],
	["staff_heal_3", 1, {"wood": 4, "herb": 8}, 140],
	["armor_chain", 1, {"iron_ore": 4, "scrap": 6}, 120],
	["armor_scout", 1, {"hide": 6, "scale": 3}, 120],
	["armor_mage", 1, {"silver": 3, "herb": 5}, 140],
	# ランク4（ボスの素材と地方の素材と、Lv6以上の敵が落とす力の結晶）
	["ball_rock", 1, {"cave_gem": 1, "iron_ore": 10, "power_crystal": 2}, 400],
	["ball_lava", 1, {"flame_tail": 1, "obsidian": 8, "power_crystal": 2}, 400],
	["ball_quake", 1, {"giant_core": 1, "iron_ore": 8, "bone": 6, "power_crystal": 2}, 400],
	["sword_giant", 1, {"giant_core": 1, "iron_ore": 8, "old_steel": 4, "power_crystal": 2}, 450],
	["sword_flame", 1, {"lava_heart": 1, "obsidian": 8, "power_crystal": 2}, 420],
	["sword_frost", 1, {"snow": 10, "old_steel": 6, "power_crystal": 2}, 420],
	["bow_serpent", 1, {"serpent_fang": 1, "scale": 8, "wood": 6, "power_crystal": 2}, 420],
	["bow_twin", 1, {"twin_mirror": 1, "wood": 10, "power_crystal": 2}, 450],
	["bow_wind", 1, {"serpent_fang": 1, "scale": 6, "snow": 4, "power_crystal": 2}, 420],
	["staff_lava", 1, {"lava_heart": 1, "fire_stone": 8, "power_crystal": 2}, 450],
	["staff_thunder", 1, {"queen_sting": 1, "silver": 6, "old_steel": 4, "power_crystal": 2}, 450],
	["staff_frost", 1, {"snow": 10, "silver": 5, "power_crystal": 2}, 420],
	["armor_knight", 1, {"crest": 1, "old_steel": 10, "power_crystal": 2}, 450],
	["armor_wind", 1, {"gear": 1, "silver": 6, "hide": 6, "power_crystal": 2}, 450],
	["armor_life", 1, {"king_crown": 1, "herb": 12, "scale": 4, "power_crystal": 2}, 450],
	# ランク5（作るだけ。星のかけら・ボスの素材と、Lv10以上の敵が落とすいにしえの結晶）
	["ball_star", 1, {"star_shard": 5, "giant_core": 1, "cave_gem": 1, "ancient_crystal": 3}, 800],
	["ball_meteor", 1, {"star_shard": 5, "lava_heart": 1, "flame_tail": 1, "ancient_crystal": 3}, 800],
	["sword_star", 1, {"star_shard": 5, "giant_core": 1, "old_steel": 8, "ancient_crystal": 3}, 800],
	["sword_king", 1, {"star_shard": 5, "crest": 1, "lava_heart": 1, "ancient_crystal": 3}, 800],
	["sword_dusk", 1, {"star_shard": 3, "dark_crest": 1, "dark_shard": 6, "ancient_crystal": 3}, 800],  # 闇の王の紋章（2026-11-26）
	["bow_star", 1, {"star_shard": 5, "serpent_fang": 1, "wood": 10, "ancient_crystal": 3}, 800],
	["bow_sun", 1, {"star_shard": 5, "twin_mirror": 1, "queen_sting": 1, "fire_stone": 6, "ancient_crystal": 3}, 800],
	["staff_star", 1, {"star_shard": 5, "bright_eye": 1, "fire_stone": 6, "ancient_crystal": 3}, 800],
	["staff_storm", 1, {"star_shard": 5, "gear": 1, "snow": 8, "ancient_crystal": 3}, 800],
	["armor_star", 1, {"star_shard": 5, "crest": 1, "king_crown": 1, "silver": 6, "ancient_crystal": 3}, 800],
	["armor_dragon", 1, {"star_shard": 5, "flame_tail": 1, "obsidian": 8, "ancient_crystal": 3}, 800],
]

## 今作れるか（素材とお金が足りて、装備ならまだ持っていない）。
static func can_make(inv: Inventory, index: int) -> bool:
	var r: Array = LIST[index]
	if inv.money < r[3]:
		return false
	if ItemCatalog.exists(r[0]) and inv.equipment.has(r[0]):
		return false
	var mats: Dictionary = r[2]
	for m in mats:
		if inv.count(m) < mats[m]:
			return false
	return true

## 作る。作れなければ false。
static func make(inv: Inventory, index: int) -> bool:
	if not can_make(inv, index):
		return false
	var r: Array = LIST[index]
	var mats: Dictionary = r[2]
	for m in mats:
		inv.take(m, mats[m])
	inv.money -= r[3]
	inv.add(r[0], r[1])
	return true

static func makes(id: String) -> bool:
	for r in LIST:
		if r[0] == id:
			return true
	return false

## 材料の説明（例：「丈夫な枝2 鉄くず2」）。
static func cost_text(index: int) -> String:
	var r: Array = LIST[index]
	var parts: Array[String] = []
	var mats: Dictionary = r[2]
	for m in mats:
		parts.append("%s%d" % [ItemCatalog.name_of(m), mats[m]])
	if r[3] > 0:
		parts.append("%dG" % r[3])
	return " ".join(parts)
