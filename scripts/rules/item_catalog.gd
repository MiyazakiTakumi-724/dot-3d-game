class_name ItemCatalog
extends RefCounted
## 品物の一覧（2026-11-25 の設計 `docs/superpowers/specs/2026-11-25-full-game-design.md` 2章）。
## 品物は4つに分ける：装備（GEAR）・素材（MATERIALS）・道具（TOOLS）・矢（ARROWS）。どれも id で持つ。
## 装備は枠（Equipment.Slot）とランク（1〜5）と特色（traits）を持つ。ランク1は枠ごとに1つで特色なし。
## src は手に入れ方：shop（お店）・craft（鍛冶屋で作る）・drop（敵の落とし物）・chest（宝箱）。
## 宝箱だけの装備はない。ランク5は作るだけ。数値は【提案】。
## 2026-11-25 夜：ボスは装備を落とさず、ボスの素材を落とす（ランク4は作る）。
## 同じ夜の2回目の直しで、装備のレベル制限をやめた。代わりにランク4は「力の結晶」（Lv6以上の敵だけが落とす）、
## ランク5は「いにしえの結晶」（Lv10以上の敵だけ）がないと作れない（Loot.LEVEL_MATERIALS・Recipes）。
##
## 特色（traits）のキー：
##   atk つよさ＋n / rate 剣を振る速さ× / reach 剣の届く長さ×・鉄球の届く距離× / radius 鉄球の当たる範囲×
##   charge 弓の溜めの速さ× / range 弓の届く距離× / multi 一度に撃つ矢の数 / poison 当てると毒 / burn 当てるとやけど
##   slow 当てると遅くする / drain 当てると いのち＋n / def 守り（受けるダメージ−n）/ hp 最大いのち＋n / mana 最大マナ＋n
##   speed 足の速さ＋割合 / regen 5秒ごとに いのち＋n / cost 魔法のマナ× / loot 素材が落ちる割合×

const ITEMS := {
	# ---- 鉄球
	"ball_1": {"slot": Equipment.Slot.BALL, "rank": 1, "name": "鉄球", "src": ["start"]},
	"ball_heavy": {"slot": Equipment.Slot.BALL, "rank": 2, "name": "重い鉄球", "traits": {"atk": 2}, "src": ["shop", "craft", "chest"]},
	"ball_wide": {"slot": Equipment.Slot.BALL, "rank": 2, "name": "広がる鉄球", "traits": {"radius": 1.4}, "src": ["craft", "drop"]},
	"ball_spike": {"slot": Equipment.Slot.BALL, "rank": 3, "name": "とげ鉄球", "traits": {"poison": 1}, "src": ["craft", "drop"]},
	"ball_chain": {"slot": Equipment.Slot.BALL, "rank": 3, "name": "鎖の鉄球", "traits": {"reach": 1.5}, "src": ["shop", "craft"]},
	"ball_ember": {"slot": Equipment.Slot.BALL, "rank": 3, "name": "焼け玉", "traits": {"burn": 1}, "src": ["craft"]},
	"ball_rock": {"slot": Equipment.Slot.BALL, "rank": 4, "name": "岩窟の鉄球", "traits": {"radius": 1.5, "atk": 3}, "src": ["craft"]},
	"ball_lava": {"slot": Equipment.Slot.BALL, "rank": 4, "name": "溶岩の鉄球", "traits": {"burn": 1, "radius": 1.3}, "src": ["craft"]},
	"ball_quake": {"slot": Equipment.Slot.BALL, "rank": 4, "name": "地鳴りの鉄球", "traits": {"slow": 1, "radius": 1.3}, "src": ["craft"]},
	"ball_star": {"slot": Equipment.Slot.BALL, "rank": 5, "name": "星の鉄球", "traits": {"atk": 5, "radius": 1.6, "reach": 1.4}, "src": ["craft"]},
	"ball_meteor": {"slot": Equipment.Slot.BALL, "rank": 5, "name": "流星の鉄球", "traits": {"burn": 1, "slow": 1, "radius": 1.5}, "src": ["craft"]},
	# ---- 剣
	"sword_1": {"slot": Equipment.Slot.SWORD, "rank": 1, "name": "剣", "src": ["shop", "craft", "drop"]},
	"sword_light": {"slot": Equipment.Slot.SWORD, "rank": 2, "name": "軽い剣", "traits": {"rate": 1.3}, "src": ["shop", "craft", "drop"]},
	"sword_bronze": {"slot": Equipment.Slot.SWORD, "rank": 2, "name": "青銅の剣", "traits": {"atk": 2}, "src": ["shop", "craft", "chest"]},
	"sword_poison": {"slot": Equipment.Slot.SWORD, "rank": 3, "name": "毒の剣", "traits": {"poison": 1}, "src": ["craft", "drop"]},
	"sword_long": {"slot": Equipment.Slot.SWORD, "rank": 3, "name": "長剣", "traits": {"reach": 1.4}, "src": ["shop", "craft"]},
	"sword_drain": {"slot": Equipment.Slot.SWORD, "rank": 3, "name": "吸いとる剣", "traits": {"drain": 1}, "src": ["craft"]},
	"sword_giant": {"slot": Equipment.Slot.SWORD, "rank": 4, "name": "巨人の大剣", "traits": {"atk": 3, "reach": 1.3}, "src": ["craft"]},
	"sword_flame": {"slot": Equipment.Slot.SWORD, "rank": 4, "name": "炎の剣", "traits": {"burn": 1, "atk": 1}, "src": ["craft"]},
	"sword_frost": {"slot": Equipment.Slot.SWORD, "rank": 4, "name": "霜の剣", "traits": {"slow": 1, "rate": 1.2}, "src": ["craft", "drop"]},
	"sword_star": {"slot": Equipment.Slot.SWORD, "rank": 5, "name": "星の剣", "traits": {"atk": 5, "rate": 1.2, "reach": 1.3}, "src": ["craft"]},
	"sword_king": {"slot": Equipment.Slot.SWORD, "rank": 5, "name": "王の剣", "traits": {"drain": 1, "burn": 1, "atk": 3}, "src": ["craft"]},
	"sword_dusk": {"slot": Equipment.Slot.SWORD, "rank": 5, "name": "宵闇の剣", "traits": {"drain": 1, "slow": 1, "atk": 4}, "src": ["craft"]},
	# ---- 弓
	"bow_1": {"slot": Equipment.Slot.BOW, "rank": 1, "name": "弓", "src": ["shop", "craft", "drop"]},
	"bow_short": {"slot": Equipment.Slot.BOW, "rank": 2, "name": "短弓", "traits": {"charge": 1.5}, "src": ["shop", "craft"]},
	"bow_long": {"slot": Equipment.Slot.BOW, "rank": 2, "name": "長弓", "traits": {"range": 1.3}, "src": ["shop", "craft", "drop"]},
	"bow_hunter": {"slot": Equipment.Slot.BOW, "rank": 3, "name": "狩人の弓", "traits": {"loot": 1.5, "atk": 1}, "src": ["craft", "drop"]},
	"bow_poison": {"slot": Equipment.Slot.BOW, "rank": 3, "name": "毒の弓", "traits": {"poison": 1}, "src": ["craft", "chest"]},
	"bow_heavy": {"slot": Equipment.Slot.BOW, "rank": 3, "name": "剛弓", "traits": {"atk": 3, "charge": 0.8}, "src": ["shop", "craft"]},
	"bow_serpent": {"slot": Equipment.Slot.BOW, "rank": 4, "name": "大蛇の弓", "traits": {"poison": 1, "range": 1.3}, "src": ["craft"]},
	"bow_twin": {"slot": Equipment.Slot.BOW, "rank": 4, "name": "二連の弓", "traits": {"multi": 2}, "src": ["craft"]},
	"bow_wind": {"slot": Equipment.Slot.BOW, "rank": 4, "name": "風の弓", "traits": {"charge": 2.0, "range": 1.2}, "src": ["craft", "drop"]},
	"bow_star": {"slot": Equipment.Slot.BOW, "rank": 5, "name": "星の弓", "traits": {"atk": 5, "range": 1.5, "charge": 1.5}, "src": ["craft"]},
	"bow_sun": {"slot": Equipment.Slot.BOW, "rank": 5, "name": "日輪の弓", "traits": {"burn": 1, "multi": 2, "atk": 2}, "src": ["craft"]},
	# ---- 杖（spells は覚える順。数はランクで決まる範囲：spell_range）
	"staff_none_1": {"slot": Equipment.Slot.STAFF, "rank": 1, "name": "無の杖", "spells": [Magic.Spell.NULL_BOLT], "src": ["shop", "craft", "drop"]},
	"staff_fire_2": {"slot": Equipment.Slot.STAFF, "rank": 2, "name": "炎の小杖", "spells": [Magic.Spell.FIREBALL], "src": ["shop", "craft"]},
	"staff_ice_2": {"slot": Equipment.Slot.STAFF, "rank": 2, "name": "氷の小杖", "spells": [Magic.Spell.ICE_SHARD], "src": ["shop", "craft", "drop"]},
	"staff_fire_3": {"slot": Equipment.Slot.STAFF, "rank": 3, "name": "炎の杖", "spells": [Magic.Spell.FIREBALL, Magic.Spell.FIRE_PILLAR], "src": ["craft", "chest"]},
	"staff_ice_3": {"slot": Equipment.Slot.STAFF, "rank": 3, "name": "氷の杖", "spells": [Magic.Spell.ICE_SHARD], "traits": {"cost": 0.7}, "src": ["craft", "drop"]},
	"staff_heal_3": {"slot": Equipment.Slot.STAFF, "rank": 3, "name": "癒しの杖", "spells": [Magic.Spell.NULL_BOLT, Magic.Spell.HEAL], "src": ["shop", "craft"]},
	"staff_lava": {"slot": Equipment.Slot.STAFF, "rank": 4, "name": "溶岩の杖", "spells": [Magic.Spell.FIREBALL, Magic.Spell.FIRE_PILLAR], "traits": {"cost": 0.8, "atk": 2}, "src": ["craft"]},
	"staff_thunder": {"slot": Equipment.Slot.STAFF, "rank": 4, "name": "雷の杖", "spells": [Magic.Spell.NULL_BOLT, Magic.Spell.THUNDER], "src": ["craft", "drop"]},
	"staff_frost": {"slot": Equipment.Slot.STAFF, "rank": 4, "name": "霜の大杖", "spells": [Magic.Spell.ICE_SHARD, Magic.Spell.HEAL], "traits": {"mana": 15}, "src": ["craft"]},
	"staff_star": {"slot": Equipment.Slot.STAFF, "rank": 5, "name": "星の杖", "spells": [Magic.Spell.FIREBALL, Magic.Spell.FIRE_PILLAR, Magic.Spell.FIRE_RAIN], "traits": {"atk": 3}, "src": ["craft"]},
	"staff_storm": {"slot": Equipment.Slot.STAFF, "rank": 5, "name": "嵐の杖", "spells": [Magic.Spell.ICE_SHARD, Magic.Spell.THUNDER, Magic.Spell.HEAL], "traits": {"cost": 0.8}, "src": ["craft"]},
	# ---- 防具（ランク1つにつき最大いのち＋4。そのうえに特色）
	"armor_1": {"slot": Equipment.Slot.ARMOR, "rank": 1, "name": "布の服", "src": ["shop", "craft"]},
	"armor_leather": {"slot": Equipment.Slot.ARMOR, "rank": 2, "name": "革の服", "traits": {"def": 1}, "src": ["shop", "craft", "drop"]},
	"armor_travel": {"slot": Equipment.Slot.ARMOR, "rank": 2, "name": "旅人の服", "traits": {"speed": 0.1}, "src": ["shop", "craft"]},
	"armor_chain": {"slot": Equipment.Slot.ARMOR, "rank": 3, "name": "鎖かたびら", "traits": {"def": 2}, "src": ["shop", "craft"]},
	"armor_scout": {"slot": Equipment.Slot.ARMOR, "rank": 3, "name": "斥候の服", "traits": {"speed": 0.15}, "src": ["craft", "drop"]},
	"armor_mage": {"slot": Equipment.Slot.ARMOR, "rank": 3, "name": "魔導の衣", "traits": {"mana": 15}, "src": ["craft", "chest"]},
	"armor_knight": {"slot": Equipment.Slot.ARMOR, "rank": 4, "name": "騎士の鎧", "traits": {"def": 3}, "src": ["craft"]},
	"armor_wind": {"slot": Equipment.Slot.ARMOR, "rank": 4, "name": "疾風の服", "traits": {"speed": 0.25}, "src": ["craft"]},
	"armor_life": {"slot": Equipment.Slot.ARMOR, "rank": 4, "name": "命の衣", "traits": {"regen": 1}, "src": ["craft", "drop"]},
	"armor_star": {"slot": Equipment.Slot.ARMOR, "rank": 5, "name": "星の鎧", "traits": {"def": 4, "speed": 0.1}, "src": ["craft"]},
	"armor_dragon": {"slot": Equipment.Slot.ARMOR, "rank": 5, "name": "竜鱗の鎧", "traits": {"def": 3, "regen": 1, "hp": 10}, "src": ["craft"]},
}

## 素材（名前と、主に出る所）
const MATERIALS := {
	"hide": {"name": "獣の皮", "where": "どこでも"},
	"bone": {"name": "骨", "where": "どこでも"},
	"scrap": {"name": "鉄くず", "where": "どこでも"},
	"wood": {"name": "丈夫な枝", "where": "どこでも"},
	"herb": {"name": "薬草", "where": "どこでも・草原"},
	"iron_ore": {"name": "鉄鉱石", "where": "山岳"},
	"snow": {"name": "雪の結晶", "where": "山岳"},
	"scale": {"name": "蛇のうろこ", "where": "草原"},
	"old_steel": {"name": "古い鋼", "where": "廃城"},
	"silver": {"name": "銀のかけら", "where": "廃城"},
	"obsidian": {"name": "黒曜石", "where": "溶岩"},
	"fire_stone": {"name": "火の石", "where": "溶岩"},
	"star_shard": {"name": "星のかけら", "where": "神秘の塔"},
	"mist_moss": {"name": "霧のこけ", "where": "霧の谷"},
	"dark_shard": {"name": "闇のかけら", "where": "霧の谷"},
	# 強い敵だけが落とす素材（ランク4・5を作るのに要る。地方は問わない）
	"power_crystal": {"name": "力の結晶", "where": "Lv6以上の敵（ランク4を作るのに要る）"},
	"ancient_crystal": {"name": "いにしえの結晶", "where": "Lv10以上の敵（ランク5を作るのに要る）"},
	# ボスの素材
	"giant_core": {"name": "巨人の核", "where": "岩転がしの巨人"},
	"serpent_fang": {"name": "大蛇の牙", "where": "草むらの大蛇"},
	"lava_heart": {"name": "溶岩の心臓", "where": "満ち引きする溶岩"},
	"crest": {"name": "城主の紋章", "where": "廃城の主"},
	"cave_gem": {"name": "岩窟の宝石", "where": "岩窟のぬし"},
	"flame_tail": {"name": "火とかげの尾", "where": "溶岩洞のぬし"},
	"twin_mirror": {"name": "双子の鏡", "where": "双子"},
	"gear": {"name": "番人の歯車", "where": "らせん塔の番人"},
	"bright_eye": {"name": "ブライトの瞳", "where": "ブライト"},
	"queen_sting": {"name": "女王の針", "where": "女王蜂"},
	"king_crown": {"name": "王の宝冠", "where": "宝箱の王"},
	"dark_crest": {"name": "闇の王の紋章", "where": "闇の王"},
}

## 大事な物（地方の印）。ボスの間の前の門を開ける鍵で、死んでも墓石に入らない
const KEYS := {
	"seal_mt": {"name": "山岳の印", "info": "3つ集めると、巨人の岩棚への門が開く"},
	"seal_gr": {"name": "草原の印", "info": "3つ集めると、大蛇の草むらへの門が開く"},
	"seal_cs": {"name": "廃城の印", "info": "3つ集めると、王の間への門が開く"},
	"seal_lv": {"name": "溶岩の印", "info": "3つ集めると、満ち引きのくぼ地への門が開く"},
	"keepsake": {"name": "村のお守り", "info": "灯りの村の家の跡に残っていた。闇の砦の門が開く"},
	"hook": {"name": "鉤縄", "info": "R でカーソルの所へ投げる。1〜3段上の地面へ体を引き上げ、敵は手前へ引き寄せる（高い所の敵は引きずり下ろす）"},
}

## 道具（5番で手に持って使う）。効果：heal いのち（-1 で全部）/ mana マナ / buff 一時の強化 [種類, 量, 秒] / warp 最後のたき火へ / bomb 投げる
const TOOLS := {
	"potion": {"name": "回復薬", "heal": 10, "info": "いのち＋10"},
	"potion_m": {"name": "回復薬・中", "heal": 25, "info": "いのち＋25"},
	"potion_l": {"name": "回復薬・大", "heal": -1, "info": "いのちが全部戻る"},
	"ether": {"name": "マナの薬", "mana": 30, "info": "マナ＋30"},
	"power": {"name": "力の薬", "buff": ["atk", 3, 30.0], "info": "30秒 つよさ＋3"},
	"guard": {"name": "守りの薬", "buff": ["def", 2, 30.0], "info": "30秒 守り＋2"},
	"swift": {"name": "速さの薬", "buff": ["speed", 0.3, 30.0], "info": "30秒 足＋30%"},
	"feather": {"name": "帰りの羽", "warp": true, "info": "最後に休んだ たき火へ戻る"},
	"bomb": {"name": "爆弾", "bomb": 30, "info": "カーソルの所へ投げる。まわりに30ダメージ（甲虫はひっくり返る）"},
}

## 矢（Arrow.Kind と同じ順）
const ARROWS := {
	"arrow": {"name": "矢"},
	"arrow_poison": {"name": "毒矢"},
	"arrow_fire": {"name": "火矢"},
	"arrow_iron": {"name": "鉄の矢"},
}

## お金の id（拾いもの・落とし物で使う）
const MONEY := "money"

## 一覧（ITEMS）の中の順番。同じランクの品物を並べるときに使う。
static func order(id: String) -> int:
	var i := ITEMS.keys().find(id)
	if i >= 0:
		return i
	for t in 3 + 1:
		var table: Dictionary = [MATERIALS, TOOLS, ARROWS, KEYS][t]
		i = table.keys().find(id)
		if i >= 0:
			return (t + 1) * 1000 + i
	return 9999

## 装備の品物か。
static func exists(id: String) -> bool:
	return ITEMS.has(id)

static func is_material(id: String) -> bool:
	return MATERIALS.has(id)

static func is_tool_item(id: String) -> bool:
	return TOOLS.has(id)

static func is_arrow(id: String) -> bool:
	return ARROWS.has(id)

static func is_key(id: String) -> bool:
	return KEYS.has(id)

## 数で持つ品物（素材・道具・矢・大事な物）か。
static func is_counted(id: String) -> bool:
	return is_material(id) or is_tool_item(id) or is_arrow(id) or is_key(id)

## どれかの品物か（お金も含む）。
static func known(id: String) -> bool:
	return id == MONEY or exists(id) or is_counted(id)

static func slot(id: String) -> Equipment.Slot:
	return ITEMS[id]["slot"]

static func rank(id: String) -> int:
	return ITEMS[id]["rank"] if ITEMS.has(id) else 0

static func name_of(id: String) -> String:
	if id == MONEY:
		return "お金"
	for table in [ITEMS, MATERIALS, TOOLS, ARROWS, KEYS]:
		if table.has(id):
			return table[id]["name"]
	return ""

## 矢の説明
const ARROW_INFO := {
	"arrow": "弓で撃つ。ふつうの矢",
	"arrow_poison": "当てると毒（弓の技能「矢の種類」で使える）",
	"arrow_fire": "当てるとやけど（弓の技能「矢の種類」で使える）",
	"arrow_iron": "威力×1.5（弓の技能「矢の種類」で使える）",
}

## カーソルを合わせたときに出す説明（何に使うか・どこで手に入るか）。空にはならない。
static func describe(id: String) -> String:
	if id == MONEY:
		return "お店で買い物をし、鍛冶屋で作るのに使う。死ぬと半分を墓石に残す"
	if ITEMS.has(id):
		var lines: Array[String] = []
		var t := trait_of(id)
		if slot(id) == Equipment.Slot.STAFF:
			var names: Array[String] = []
			for sp in spells(id):
				names.append(Magic.NAMES[sp])
			lines.append("魔法：" + "・".join(names))
			if t != "":
				lines.append(t)
		else:
			lines.append(t if t != "" else "特色なし")
		var how: Array[String] = []
		for src in sources(id):
			var w: String = {"shop": "お店", "craft": "鍛冶屋", "drop": "敵", "chest": "宝箱", "start": "はじめから"}.get(src, "")
			if w != "":
				how.append(w)
		lines.append("手に入る所：" + "・".join(how))
		return "\n".join(lines)
	if MATERIALS.has(id):
		return "素材（鍛冶屋で使う）。出る所：%s" % MATERIALS[id]["where"]
	if TOOLS.has(id):
		return TOOLS[id]["info"] + "（5で持って使う）"
	if ARROWS.has(id):
		return ARROW_INFO[id]
	if KEYS.has(id):
		return KEYS[id]["info"] + "。死んでもなくならない"
	return "？"

static func sources(id: String) -> Array:
	return ITEMS[id].get("src", []) if ITEMS.has(id) else []

static func traits(id: String) -> Dictionary:
	return ITEMS[id].get("traits", {}) if ITEMS.has(id) else {}

## 特色の値（なければ dflt）。
static func trait_value(id: String, key: String, dflt = 0):
	return traits(id).get(key, dflt)

## 特色の説明（なければ空）。
static func trait_of(id: String) -> String:
	if is_tool_item(id):
		return TOOLS[id]["info"]
	var parts: Array[String] = []
	var t := traits(id)
	for k in t:
		parts.append(_describe(k, t[k]))
	return "・".join(parts)

static func _describe(k: String, v) -> String:
	match k:
		"atk": return "つよさ＋%d" % v
		"rate": return "振る速さ×%s" % _num(v)
		"reach": return "届く×%s" % _num(v)
		"radius": return "当たる範囲×%s" % _num(v)
		"charge": return "溜め×%s" % _num(v)
		"range": return "飛ぶ距離×%s" % _num(v)
		"multi": return "%d本撃つ" % v
		"poison": return "毒"
		"burn": return "やけど"
		"slow": return "遅くする"
		"drain": return "当てると いのち＋%d" % v
		"def": return "守り%d" % v
		"hp": return "いのち＋%d" % v
		"mana": return "マナ＋%d" % v
		"speed": return "足＋%d%%" % roundi(v * 100.0)
		"regen": return "5秒ごとに いのち＋%d" % v
		"cost": return "マナ×%s" % _num(v)
		"loot": return "素材が落ちやすい"
	return k

static func _num(v: float) -> String:
	return String.num(v, 2).trim_suffix("0").trim_suffix(".") if v != int(v) else str(int(v))

## 杖の魔法（覚える順）。杖でなければ空。
static func spells(id: String) -> Array:
	return ITEMS[id].get("spells", []) if ITEMS.has(id) else []

## ステータスの魔法の数（spell_slots）までの、杖の魔法。
static func usable_spells(id: String, spell_slots: int) -> Array:
	return spells(id).slice(0, spell_slots)

## 杖のランクごとの魔法の数（最小, 最大）。1〜2は1つ、3は1〜2、4は2つ、5は2〜3（2026-11-25、ランク5までにした）。
static func spell_range(r: int) -> Vector2i:
	if r <= 2:
		return Vector2i(1, 1)
	if r == 3:
		return Vector2i(1, 2)
	if r == 4:
		return Vector2i(2, 2)
	return Vector2i(2, 3)

## 画面に出す名前。ランク2以上は★とランクを付ける。
static func label(id: String) -> String:
	if not ITEMS.has(id):
		return name_of(id)
	var r := rank(id)
	return name_of(id) if r <= 1 else "%s★%d" % [name_of(id), r]

## 枠とランクの品物（一覧の順）。
static func of(s: Equipment.Slot, r: int) -> Array:
	var out: Array = []
	for id in ITEMS:
		if ITEMS[id]["slot"] == s and ITEMS[id]["rank"] == r:
			out.append(id)
	return out
