class_name Shop
extends RefCounted
## お店の品ぞろえと買い物（2026-11-25 の設計 3章）。値段は【提案】。
## 品ぞろえの1行は [品物の id, 値段, 一度に買う数]。装備はもう持っていれば買えない。
## 町：道具屋・武器屋（鍛冶屋は Recipes）。旅の商人は地方の休憩所にいて、地方ごとに品ぞろえが違う。

const NAMES := {
	"tool": "道具屋",
	"weapon": "武器屋",
	"smith": "鍛冶屋",
	"山岳": "旅の商人（山岳）",
	"草原": "旅の商人（草原）",
	"廃城": "旅の商人（廃城）",
	"溶岩": "旅の商人（溶岩）",
	"霧の谷": "旅の商人（霧の谷）",
}

const STOCK := {
	"tool": [["hook", 80, 1], ["potion", 15, 1], ["potion_m", 40, 1], ["ether", 30, 1], ["feather", 60, 1], ["bomb", 30, 1],
		["arrow", 15, 10], ["arrow_poison", 30, 5]],
	"weapon": [["sword_1", 40, 1], ["bow_1", 40, 1], ["staff_none_1", 40, 1], ["armor_1", 30, 1],
		["ball_heavy", 150, 1], ["sword_light", 150, 1], ["sword_bronze", 160, 1], ["bow_short", 150, 1], ["bow_long", 160, 1],
		["staff_fire_2", 180, 1], ["staff_ice_2", 180, 1], ["armor_leather", 120, 1], ["armor_travel", 140, 1]],
	"山岳": [["potion", 15, 1], ["potion_m", 40, 1], ["swift", 40, 1], ["arrow", 15, 10], ["arrow_iron", 40, 5],
		["ball_chain", 400, 1], ["bow_heavy", 420, 1]],
	"草原": [["potion", 15, 1], ["potion_m", 40, 1], ["power", 50, 1], ["arrow", 15, 10], ["arrow_fire", 40, 5],
		["sword_long", 420, 1], ["staff_heal_3", 450, 1]],
	"廃城": [["potion_m", 40, 1], ["guard", 50, 1], ["ether", 30, 1], ["arrow", 15, 10], ["feather", 60, 1],
		["armor_chain", 450, 1]],
	"溶岩": [["potion_m", 40, 1], ["potion_l", 100, 1], ["ether", 30, 1], ["bomb", 30, 1], ["power", 50, 1], ["guard", 50, 1]],
	"霧の谷": [["potion_m", 40, 1], ["potion_l", 100, 1], ["ether", 30, 1], ["bomb", 30, 1], ["arrow_iron", 40, 5], ["swift", 40, 1]],
}

## その店で、今その行を買えるか。
static func can_buy(inv: Inventory, shop_id: String, index: int) -> bool:
	var row: Array = STOCK[shop_id][index]
	if inv.money < row[1]:
		return false
	if ItemCatalog.is_key(row[0]) and inv.count(row[0]) > 0:
		return false  # 大事な物（鉤縄）は1つだけ
	return not (ItemCatalog.exists(row[0]) and inv.equipment.has(row[0]))

## 買う。買えなければ false。
static func buy(inv: Inventory, shop_id: String, index: int) -> bool:
	if not can_buy(inv, shop_id, index):
		return false
	var row: Array = STOCK[shop_id][index]
	inv.money -= row[1]
	inv.add(row[0], row[2])
	return true

## 品物がどこかの店で売られているか。
static func sells(id: String) -> bool:
	for k in STOCK:
		for row in STOCK[k]:
			if row[0] == id:
				return true
	return false
