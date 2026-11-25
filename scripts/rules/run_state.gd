class_name RunState
extends RefCounted
## 冒険の状態。死んでもステージを読み込み直さないので、死んだときに何が残り何が戻るかをここで決める。
## 死んでも変わらないもの：拾い済みのもの、開けた扉、レベル・経験値・振り分け（stats）、お金の半分。

var inventory := Inventory.new()
var stats := PlayerStats.new()
## 倒したボスの数。1体ごとに世界中の敵のレベルが1上がる（design.md 8章）
var bosses_defeated := 0
## 倒したボスの名前（倒したボスは戻らない）
var _bosses := {}
## 封印を開けるのに要る、4つの地方のボス
const REGION_BOSSES := ["岩転がしの巨人", "草むらの大蛇", "満ち引きする溶岩", "廃城の主"]
var grave: Gravestone = null
var checkpoint_area: String
var checkpoint_cell: Vector2i
## 拾い済みの id（"エリア:番号"）と、開けた門の id。エリアをまたいで覚える
var _picked := {}
var _open_doors := {}
## 開けた仕掛け（Gimmick の id）と、行ったことのあるエリア（全体マップに出す）
var _open_gimmicks := {}
var _visited := {}

## 神秘の塔の封印の門。地方のボスを SEAL_BOSSES 体倒すと開けられる（2026-11-25 の設計）
const SEAL_DOOR := "tower_seal"
const SEAL_BOSSES := 4
## ブライトを倒した（ゲームの終わり）
var cleared := false

## ボスの間の前の門（地方の印が SEALS_PER_DOOR 個あると開く）。門の id → 印の id
const BOSS_DOORS := {"mt_boss": "seal_mt", "gr_boss": "seal_gr", "cs_boss": "seal_cs", "lv_boss": "seal_lv"}
const SEALS_PER_DOOR := 3

## 休んだことのあるたき火（エリア → たき火のマス）と、休んだ順（2026-11-26 の4回目の直し：たき火から移動できる）
var _bonfires := {}
var _bonfire_order: Array[String] = []

func _init(cp_area: String, checkpoint: Vector2i) -> void:
	checkpoint_area = cp_area
	checkpoint_cell = checkpoint
	_remember_bonfire(cp_area, checkpoint)

func _remember_bonfire(area_id: String, cell: Vector2i) -> void:
	if not _bonfires.has(area_id):
		_bonfire_order.append(area_id)
	_bonfires[area_id] = cell

## 休んだことのあるたき火のエリア（休んだ順）。
func bonfire_areas() -> Array[String]:
	return _bonfire_order.duplicate()

func bonfire_cell(area_id: String) -> Vector2i:
	return _bonfires.get(area_id, Vector2i(-1, -1))

## 休んだことのあるたき火へ移る（そこで休んだことになる）。行けなければ false。
func travel_to(area_id: String) -> bool:
	if not _bonfires.has(area_id):
		return false
	set_checkpoint(area_id, _bonfires[area_id])
	return true

## ボスの間の前の門を開けるのに、あと何個の印が要るか（ほかの門は0）。
func seals_left(door_id: String) -> int:
	if not BOSS_DOORS.has(door_id):
		return 0
	return maxi(0, SEALS_PER_DOOR - inventory.count(BOSS_DOORS[door_id]))

## 死んだときの持ち物の移し替え。お金は半分（切り捨て）、ほかの持ち物（素材・道具・矢・ランク2以上の装備）はすべて墓石へ。
## 古い墓石は中身ごと消え、新しい墓石だけが残る。
func on_death(area_id: String, death_cell: Vector2i) -> Gravestone:
	var g := Gravestone.new()
	g.area_id = area_id
	g.cell = death_cell
	g.money = inventory.money / 2
	g.counts = {}
	var keep := {}
	for id in inventory.counts:
		if ItemCatalog.is_key(id):
			keep[id] = inventory.counts[id]  # 地方の印は墓石に入れない
		else:
			g.counts[id] = inventory.counts[id]
	inventory.counts = keep
	g.equipment = inventory.equipment.take_for_grave()
	inventory.money -= g.money
	grave = g
	return g

func break_grave() -> void:
	if grave == null:
		return
	inventory.money += grave.money
	for id in grave.counts:
		inventory.add(id, grave.counts[id])
	inventory.equipment.restore(grave.equipment)
	grave = null

## 敵を倒したときの経験値。上がったレベルの数を返す（落とし物は Loot で決める）。
func on_enemy_killed(kind: EnemyKind.Kind, level: int) -> int:
	return stats.add_exp(EnemyKind.exp_reward(kind, level))

## ボスを倒した。経験値をもらい、世界の敵のレベルが上がる。上がったレベルの数を返す。
func on_boss_killed(boss_name: String, exp_reward: int) -> int:
	if _bosses.has(boss_name):
		return 0
	_bosses[boss_name] = true
	bosses_defeated += 1
	if boss_name == "ブライト":
		cleared = true
	return stats.add_exp(exp_reward)

func is_boss_defeated(boss_name: String) -> bool:
	return _bosses.has(boss_name)

## base_level（その敵のレベル）の敵が、今出てくるときのレベル。
func enemy_level(base_level: int) -> int:
	return base_level + bosses_defeated

## 拾えるもの（品物の id と数）を拾う。一度拾ったものは死んでも復活しないので、2回目は false。
func collect(id: String, item: String, amount: int) -> bool:
	if _picked.has(id):
		return false
	_picked[id] = true
	take_drop(item, amount)
	return true

## 拾ったものを持ち物に入れる（敵の落とし物は拾い済みとして覚えないので、こちらを直接使う）。
func take_drop(item: String, amount: int) -> void:
	inventory.add(item, amount)

func is_picked(id: String) -> bool:
	return _picked.has(id)

func open_door(id: String) -> void:
	_open_doors[id] = true

func is_door_open(id: String) -> bool:
	return _open_doors.has(id)

## その門を今開けられるか。封印の門はボスを倒した数、ボスの間の前の門は地方の印の数で決まる。
func can_open_door(id: String) -> bool:
	if id == SEAL_DOOR:
		return seal_bosses_left() == 0
	if id == Story.MIST_DOOR:
		return mist_bosses_left() == 0
	if id == Story.KEEP_DOOR:
		return inventory.count(Story.KEEPSAKE) > 0
	return seals_left(id) == 0

## 霧の門（霧の谷への門、2026-11-26）を開けるのに、あと何体の地方のぬしを倒せばよいか。
func mist_bosses_left() -> int:
	return maxi(0, Story.MIST_BOSSES - (REGION_BOSSES.size() - seal_bosses_left()))

## 封印を解くのに、あと何体の地方のボスを倒せばよいか。
func seal_bosses_left() -> int:
	var n := 0
	for b in REGION_BOSSES:
		if not _bosses.has(b):
			n += 1
	return n

func open_gimmick(id: String) -> void:
	_open_gimmicks[id] = true

func is_gimmick_open(id: String) -> bool:
	return _open_gimmicks.has(id)

func visit(area_id: String) -> void:
	_visited[area_id] = true

func has_visited(area_id: String) -> bool:
	return _visited.has(area_id)

func visited_ids() -> Array:
	return _visited.keys()

## たき火で休むと、死んだときに戻る所がそこになる。
func set_checkpoint(area_id: String, cell: Vector2i) -> void:
	checkpoint_area = area_id
	checkpoint_cell = cell
	_remember_bonfire(area_id, cell)

## 死んだあと再開するマス（たき火のすぐ南。地図を作るときに空けておく）。
func respawn_cell() -> Vector2i:
	return checkpoint_cell + Vector2i(0, 1)

## チェックポイントのマスか、その周り8マスにいるか。ここにいると全回復する。
## 落ちているものを拾える距離（マスの中心から）。
const PICK_RADIUS := 14.0

## pos（高さ h）に立って、cell（高さ cell_h）に落ちているものに手が届くか。
static func can_reach_pickup(pos: Vector2, h: int, cell: Vector2i, cell_h: int) -> bool:
	return h == cell_h and pos.distance_to(HeightMap.cell_center(cell)) <= PICK_RADIUS

func is_near_checkpoint(area_id: String, cell: Vector2i) -> bool:
	return area_id == checkpoint_area and absi(cell.x - checkpoint_cell.x) <= 1 and absi(cell.y - checkpoint_cell.y) <= 1
