class_name BossDecoy
extends StackSprite
## 宝箱の王のにせものの宝箱（balance-pass 5章）。動かず、噛みつかない。1回当てると壊れる。
## field.targets() に入るので、剣・矢・魔法・鉄球が当たる（本物と同じ言葉 hit_rule・on_hit・flash を持つ）。
## 本物との違いは、背中の金のしっぽがないこと（カメラを回すと見える）。

var walker: EnemyWalker
var _hit_flash := 0.0

func setup(map: HeightMap, cell: Vector2i, cam: StackCamera) -> void:
	camera = cam
	walker = EnemyWalker.new(map, cell, Vector2.DOWN, 1, 0)
	walker.speed_mult = 0.0
	walker.chase_range = 0.0
	sort_by_cell = true
	draw_bias = 1
	shadow_radius = 7.0
	voxel_scale = BossModels.DRAW_SCALE
	outline_color = Player.OUTLINE_COLOR
	turn = Vector2.DOWN.angle() - PI / 2
	set_model(BossModels.model("宝箱の王", "decoy"))
	world_pos = walker.pos
	base_height = walker.height
	walker.died.connect(queue_free)

func _sort_map() -> HeightMap:
	return walker.map if walker != null else null

func move_to(cell: Vector2i) -> void:
	walker.pos = HeightMap.cell_center(cell)
	walker.height = maxi(0, walker.map.get_height(cell))
	world_pos = walker.pos
	base_height = walker.height

func flash() -> void:
	_hit_flash = 0.2

func blocks(_from: Vector2) -> bool:
	return false

func hit_rule(_source: String, _from: Vector2) -> String:
	return ""

func on_hit(_source: String) -> void:
	pass

func _process(delta: float) -> void:
	_hit_flash = maxf(0.0, _hit_flash - delta)
	self_modulate = Color(1.8, 1.8, 1.8) if _hit_flash > 0.0 else Color.WHITE
	world_pos = walker.pos
	base_height = walker.height
	super._process(delta)
