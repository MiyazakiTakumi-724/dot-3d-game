extends GutTest

var world: WorldMap

func _exit(edge: ExitDef.Edge, from: int, to: int, target: String) -> ExitDef:
	var e := ExitDef.new()
	e.edge = edge
	e.from = from
	e.to = to
	e.target = target
	return e

func before_each():
	world = WorldMap.new()
	var a := AreaDef.new()
	a.id = "a"
	a.origin = Vector2i(0, 0)
	a.map_size = Vector2i(4, 3)
	a.exits = [_exit(ExitDef.Edge.EAST, 1, 2, "b")]
	var b := AreaDef.new()
	b.id = "b"
	b.origin = Vector2i(4, 0)
	b.map_size = Vector2i(5, 3)
	b.exits = [_exit(ExitDef.Edge.WEST, 1, 2, "a")]
	world.add(a)
	world.add(b)

func test_exit_through_needs_outward_push():
	assert_not_null(world.exit_through("a", Vector2i(3, 1), Vector2i(1, 0)))
	assert_null(world.exit_through("a", Vector2i(3, 1), Vector2i(0, 1)))
	assert_null(world.exit_through("a", Vector2i(3, 0), Vector2i(1, 0)))

func test_arrival_is_one_cell_inside_matching_exit():
	var ex := world.exit_through("a", Vector2i(3, 2), Vector2i(1, 0))
	assert_eq_deep(world.arrival("a", ex, Vector2i(3, 2)), {"area": "b", "cell": Vector2i(1, 2)})

func test_arrival_back_the_other_way():
	var ex := world.exit_through("b", Vector2i(0, 1), Vector2i(-1, 0))
	assert_eq_deep(world.arrival("b", ex, Vector2i(0, 1)), {"area": "a", "cell": Vector2i(2, 1)})

func test_problems_empty_for_matching_exits():
	assert_eq(world.problems(), [])

func test_problems_reports_misaligned_exit():
	world.area("b").exits[0].from = 0
	world.area("b").exits[0].to = 0
	assert_gt(world.problems().size(), 0)

func test_problems_reports_overlap():
	world.area("b").origin = Vector2i(3, 0)
	assert_gt(world.problems().size(), 0)

func test_problems_reports_missing_target():
	world.area("a").exits[0].target = "nowhere"
	assert_gt(world.problems().size(), 0)

func test_entry_safe_cells_radius_3():
	var safe := world.area("b").entry_safe_cells()
	assert_true(safe.has(Vector2i(3, 1)))
	assert_false(safe.has(Vector2i(4, 1)))

func test_exit_cells_on_edge():
	var cells := world.area("a").exits[0].cells(Vector2i(4, 3))
	assert_eq(cells, [Vector2i(3, 1), Vector2i(3, 2)])
