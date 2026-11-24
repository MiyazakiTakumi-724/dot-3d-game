class_name RunState
extends RefCounted
## 冒険の状態。死んでもステージを読み込み直さないので、死んだときに何が残り何が戻るかをここで決める。
## 死んでも変わらないもの：拾い済みのもの、開けた扉、レベル・経験値・振り分け（stats）、お金の半分。

## 武器（SWORD など）の amount はランク
enum PickupKind { MONEY, MATERIAL, HEAL, STRONG_BALL, SWORD, BOW, ARROWS, POISON_ARROWS, STAFF_FIRE, ARMOR }

const ENEMY_MONEY := 10

var inventory := Inventory.new()
var stats := PlayerStats.new()
## 倒したボスの数。1体ごとに世界中の敵のレベルが1上がる（design.md 8章）
var bosses_defeated := 0
var grave: Gravestone = null
var checkpoint_area: String
var checkpoint_cell: Vector2i
## 拾い済みの id（"エリア:番号"）と、開けた門の id。エリアをまたいで覚える
var _picked := {}
var _open_doors := {}

func _init(cp_area: String, checkpoint: Vector2i) -> void:
	checkpoint_area = cp_area
	checkpoint_cell = checkpoint

## 死んだときの持ち物の移し替え。お金は半分（切り捨て）、ほかの持ち物はすべて墓石へ。
## 古い墓石は中身ごと消え、新しい墓石だけが残る。
func on_death(area_id: String, death_cell: Vector2i) -> Gravestone:
	var g := Gravestone.new()
	g.area_id = area_id
	g.cell = death_cell
	g.money = inventory.money / 2
	g.materials = inventory.materials
	g.heals = inventory.heals
	g.equipment = inventory.equipment.take_for_grave()
	g.arrows = inventory.arrows
	inventory.arrows = {}
	inventory.money -= g.money
	inventory.materials = 0
	inventory.heals = 0
	grave = g
	return g

func break_grave() -> void:
	if grave == null:
		return
	inventory.money += grave.money
	inventory.materials += grave.materials
	inventory.heals += grave.heals
	inventory.equipment.restore(grave.equipment)
	for k in grave.arrows:
		inventory.add_arrows(k, grave.arrows[k])
	grave = null

## 敵を倒したときのお金と経験値。上がったレベルの数を返す。
func on_enemy_killed(kind: EnemyKind.Kind, level: int) -> int:
	inventory.money += ENEMY_MONEY
	return stats.add_exp(EnemyKind.exp_reward(kind, level))

## base_level（その敵のレベル）の敵が、今出てくるときのレベル。
func enemy_level(base_level: int) -> int:
	return base_level + bosses_defeated

## 拾えるものを拾う。一度拾ったものは死んでも復活しないので、2回目は false。
func collect(id: String, kind: PickupKind, amount: int) -> bool:
	if _picked.has(id):
		return false
	_picked[id] = true
	take_drop(kind, amount)
	return true

## 拾ったものを持ち物に入れる（敵の落とし物は拾い済みとして覚えないので、こちらを直接使う）。
func take_drop(kind: PickupKind, amount: int) -> void:
	match kind:
		PickupKind.MONEY:
			inventory.money += amount
		PickupKind.MATERIAL:
			inventory.materials += amount
		PickupKind.HEAL:
			inventory.heals += amount
		PickupKind.STRONG_BALL:
			inventory.equipment.gain(Equipment.Slot.BALL, 2)
		PickupKind.SWORD:
			inventory.equipment.gain(Equipment.Slot.SWORD, amount)
		PickupKind.BOW:
			inventory.equipment.gain(Equipment.Slot.BOW, amount)
		PickupKind.ARROWS:
			inventory.add_arrows(Arrow.Kind.NORMAL, amount)
		PickupKind.POISON_ARROWS:
			inventory.add_arrows(Arrow.Kind.POISON, amount)
		PickupKind.STAFF_FIRE:
			inventory.equipment.gain(Equipment.Slot.STAFF_FIRE, amount)
		PickupKind.ARMOR:
			inventory.equipment.gain(Equipment.Slot.ARMOR, amount)

func is_picked(id: String) -> bool:
	return _picked.has(id)

func open_door(id: String) -> void:
	_open_doors[id] = true

func is_door_open(id: String) -> bool:
	return _open_doors.has(id)

## チェックポイントのマスか、その周り8マスにいるか。ここにいると全回復する。
## 落ちているものを拾える距離（マスの中心から）。
const PICK_RADIUS := 14.0

## pos（高さ h）に立って、cell（高さ cell_h）に落ちているものに手が届くか。
static func can_reach_pickup(pos: Vector2, h: int, cell: Vector2i, cell_h: int) -> bool:
	return h == cell_h and pos.distance_to(HeightMap.cell_center(cell)) <= PICK_RADIUS

func is_near_checkpoint(area_id: String, cell: Vector2i) -> bool:
	return area_id == checkpoint_area and absi(cell.x - checkpoint_cell.x) <= 1 and absi(cell.y - checkpoint_cell.y) <= 1
