extends GutTest
## ストーリー（2026-11-26 の4回目の直し）：言葉は進み具合で変わる。霧の門と闇の砦の門。

func _run() -> RunState:
	return RunState.new("town", Vector2i(10, 10))

func test_flags_follow_progress() -> void:
	var r := _run()
	var f := Story.flags(r)
	assert_false(f["boss1"])
	assert_false(f["mist"])
	r.on_boss_killed("岩転がしの巨人", 0)
	assert_true(Story.flags(r)["boss1"])
	assert_false(Story.flags(r)["mist"])
	r.on_boss_killed("草むらの大蛇", 0)
	assert_true(Story.flags(r)["mist"], "ぬしを2体で霧が薄くなる")
	r.on_boss_killed(Story.DARK_KING, 0)
	assert_true(Story.flags(r)["dark_king"])

func test_lines_change_with_progress() -> void:
	var sena: Dictionary = Story.people("town")[0]
	var r := _run()
	var first := Story.lines(sena, Story.flags(r))
	assert_gt(first.size(), 0)
	r.on_boss_killed("岩転がしの巨人", 0)
	r.on_boss_killed("草むらの大蛇", 0)
	var later := Story.lines(sena, Story.flags(r))
	assert_ne(first, later, "霧が薄くなると、セナの言葉が変わる")

func test_mist_gate_and_keepsake_door() -> void:
	var r := _run()
	assert_false(r.can_open_door(Story.MIST_DOOR))
	assert_eq(r.mist_bosses_left(), 2)
	r.on_boss_killed("満ち引きする溶岩", 0)
	r.on_boss_killed("廃城の主", 0)
	assert_true(r.can_open_door(Story.MIST_DOOR))
	assert_false(r.can_open_door(Story.KEEP_DOOR))
	r.inventory.add(Story.KEEPSAKE)
	assert_true(r.can_open_door(Story.KEEP_DOOR), "村のお守りで闇の砦の門が開く")
	assert_true(ItemCatalog.is_key(Story.KEEPSAKE), "お守りは死んでも墓石に入らない")

func test_every_person_has_words_that_fit() -> void:
	var f := {}
	for area_id in Story.PEOPLE:
		for p in Story.people(area_id):
			for t in p["talk"]:
				for page in t[1]:
					var rows: PackedStringArray = String(page).split("\n")
					assert_lte(rows.size(), 3, "%s のページは3行まで" % p["id"])
					for row in rows:
						assert_lte(row.length(), 28, "%s の1行は28文字まで：%s" % [p["id"], row])
			assert_gt(Story.lines(p, f).size(), 0, "%s ははじめから話す" % p["id"])

func test_beats_hints_and_ending() -> void:
	for g in BossKind.DATA:
		if g != "ブライト":
			assert_gt(Story.boss_beat(g).size(), 0, "%s を倒したあとの言葉" % g)
	assert_eq(Story.GIMMICK_HINTS.size(), Gimmick.Kind.size())
	assert_gt(Story.PROLOGUE.size(), 3)
	var a := Story.ending({"dark_king": true})
	var b := Story.ending({"dark_king": false})
	assert_ne(a[2], b[2], "闇の王を倒したかで終わりの言葉が変わる")

func test_people_areas_exist() -> void:
	var w := Continent.build()
	for area_id in Story.PEOPLE:
		assert_not_null(w.area(area_id), area_id)

# ---------------------------------------------------------------- 町の人と看板（field）

func _field():
	var f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)
	return f

func _stand_next_to(f, cell: Vector2i) -> void:
	for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
		var c: Vector2i = cell + d
		if not f.map.is_wall(c) and not f.map.is_water(c):
			f.player.mover.place(c)
			return

func test_town_people_are_placed_and_talk() -> void:
	var f = _field()
	assert_false(f.dialogue.is_open(), "テストでは、はじまりの言葉は出さない")
	var ids := []
	for p in f._people:
		ids.append(p["person"]["id"])
		assert_true(f.map.is_wall(p["cell"]), "人のマスはふさぐ")
	for p in Story.people("town"):
		assert_has(ids, p["id"], "%s が町にいる" % p["id"])
	var sena: Dictionary = f._people[ids.find("sena")]
	_stand_next_to(f, sena["cell"])
	assert_string_contains(f.ui_message(), "話す")
	assert_true(f.try_talk())
	assert_true(f.dialogue.is_open())
	assert_false(f.player.controllable, "話している間は動けない")
	for i in 10:
		f.dialogue.advance()
	assert_false(f.dialogue.is_open())
	assert_true(f.player.controllable)

func test_people_do_not_cut_paths() -> void:
	var f = _field()
	for id in ["town", "mt_2", "gr_2", "cs_2", "lv_2", "tw_1"]:
		f.enter_area(id, _start(f, id))
		for p in f._people:
			var c: Vector2i = p["cell"]
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx != 0 or dy != 0:
						assert_false(f.map.is_wall(c + Vector2i(dx, dy)) and f.map.get_blocker(c + Vector2i(dx, dy)) == HeightMap.Blocker.NPC, "人は並べて置かない")

func _start(f, id: String) -> Vector2i:
	var a: AreaDef = f.world.area(id)
	var info: Dictionary = Continent.load_map(a)[1]
	return info.get("checkpoint", a.size() / 2)

func test_gimmick_hint_sign_near_gimmick() -> void:
	var f = _field()
	for aid in f.world.ids():
		var a: AreaDef = f.world.area(aid)
		if a.gimmicks.is_empty():
			continue
		f.enter_area(a.id, _start(f, a.id))
		var signs := 0
		for p in f._people:
			if String(p["person"]["id"]).begins_with("hint_"):
				signs += 1
		assert_gt(signs, 0, "%s に仕掛けのヒントの看板" % a.id)
		return

func test_boss_beat_is_queued() -> void:
	var f = _field()
	f._story_queue.append([0.1, "岩転がしの巨人", Story.boss_beat("岩転がしの巨人"), false])
	f._process(0.2)
	assert_true(f.dialogue.is_open())
	assert_eq(f.dialogue.speaker, "岩転がしの巨人")
