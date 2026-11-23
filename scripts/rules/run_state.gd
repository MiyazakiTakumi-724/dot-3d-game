class_name RunState
extends RefCounted
## 冒険の状態。死んでもステージを読み込み直さないので、死んだときに何が残り何が戻るかをここで決める。
## 死んでも変わらないもの：拾い済みのもの、開けた扉、経験値、お金の半分。

enum PickupKind { MONEY, MATERIAL, HEAL, STRONG_BALL }

const ENEMY_MONEY := 10
const ENEMY_EXP := 1

var inventory := Inventory.new()
var grave: Gravestone = null
var checkpoint_cell: Vector2i
var _picked := {}
var _open_doors := {}

func _init(checkpoint: Vector2i) -> void:
	checkpoint_cell = checkpoint

## 死んだときの持ち物の移し替え。お金は半分（切り捨て）、ほかの持ち物はすべて墓石へ。
## 古い墓石は中身ごと消え、新しい墓石だけが残る。
func on_death(death_cell: Vector2i) -> Gravestone:
	var g := Gravestone.new()
	g.cell = death_cell
	g.money = inventory.money / 2
	g.materials = inventory.materials
	g.heals = inventory.heals
	g.has_strong_ball = inventory.has_strong_ball
	inventory.money -= g.money
	inventory.materials = 0
	inventory.heals = 0
	inventory.has_strong_ball = false
	grave = g
	return g

func break_grave() -> void:
	if grave == null:
		return
	inventory.money += grave.money
	inventory.materials += grave.materials
	inventory.heals += grave.heals
	inventory.has_strong_ball = inventory.has_strong_ball or grave.has_strong_ball
	grave = null

func on_enemy_killed() -> void:
	inventory.money += ENEMY_MONEY
	inventory.exp += ENEMY_EXP

## 拾えるものを拾う。一度拾ったものは死んでも復活しないので、2回目は false。
func collect(id: int, kind: PickupKind, amount: int) -> bool:
	if _picked.has(id):
		return false
	_picked[id] = true
	match kind:
		PickupKind.MONEY:
			inventory.money += amount
		PickupKind.MATERIAL:
			inventory.materials += amount
		PickupKind.HEAL:
			inventory.heals += amount
		PickupKind.STRONG_BALL:
			inventory.has_strong_ball = true
	return true

func is_picked(id: int) -> bool:
	return _picked.has(id)

func open_door(id: int) -> void:
	_open_doors[id] = true

func is_door_open(id: int) -> bool:
	return _open_doors.has(id)

## チェックポイントのマスか、その周り8マスにいるか。ここにいると全回復する。
func is_near_checkpoint(cell: Vector2i) -> bool:
	return absi(cell.x - checkpoint_cell.x) <= 1 and absi(cell.y - checkpoint_cell.y) <= 1
