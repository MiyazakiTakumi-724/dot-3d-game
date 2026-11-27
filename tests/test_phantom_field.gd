extends GutTest
## 幻の橋・記憶のかけら・装飾品（2026-11-26 独自の開発1）を、画面の中で確かめる。

var f

func before_each():
	f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)

func _enter(id: String) -> void:
	f.enter_area(id, Vector2i(1, 1))

func test_every_reward_area_has_a_phantom_bridge():
	for id in Story.PHANTOM_REWARDS:
		_enter(id)
		assert_not_null(f.phantom, "%s に幻の橋がある" % id)
		if f.phantom != null:
			assert_eq(f.map.get_height(f.phantom.goal), f.phantom.height, "%s：向こうは同じ高さ" % id)

func test_no_bridge_in_town():
	assert_null(f.phantom)

func test_bridge_appears_only_from_its_angle():
	_enter("hills")
	var b: PhantomBridge = f.phantom
	f.camera.angle = b.view_angle() + PI
	f._step_phantom(0.1)
	assert_false(b.solid)
	for c in b.cells:
		assert_lt(f.map.get_height(c), b.height)
	f.camera.angle = b.view_angle()
	f._step_phantom(0.1)
	assert_true(b.solid, "印の目の向きから見ると、橋がある")
	for c in b.cells:
		assert_eq(f.map.get_height(c), b.height)

func test_turning_away_on_the_bridge_drops_the_hero():
	_enter("hills")
	var b: PhantomBridge = f.phantom
	f.camera.angle = b.view_angle()
	f._step_phantom(0.1)
	f.player.mover.place(b.cells[0])
	assert_eq(f.player.mover.height, b.height)
	f.camera.angle = b.view_angle() + PI
	for i in 10:
		f._step_phantom(0.1)
	assert_false(b.solid)
	assert_lt(f.player.mover.height, b.height, "足場が消えて、下へ落ちた")

func test_chest_beyond_gives_a_memory_fragment():
	_enter("hills")
	assert_eq(Story.phantom_reward("hills"), "frag:1")
	f.player.mover.place(f._phantom_chest_cell)
	assert_true(f.phantom_chest_here())
	assert_true(f.try_open_chest())
	assert_true(f.run.flags.get(Story.fragment_flag(1), false))
	assert_true(f.dialogue.is_open(), "かけらの言葉を見せる")
	assert_false(f.phantom_chest_here(), "1回だけ")
	f.dialogue.close()

func test_chest_beyond_gives_a_charm_that_works():
	_enter("lv_7")
	assert_eq(Story.phantom_reward("lv_7"), Charms.CAPE)
	var drop0: int = f.rules.max_drop
	f.player.mover.place(f._phantom_chest_cell)
	assert_true(f.open_phantom_chest())
	assert_true(Charms.has(f.run.inventory, Charms.CAPE))
	assert_eq(f.rules.max_drop, drop0 + Charms.CAPE_DROP, "羽根のマントで、飛び降りられる段数が増える")

func test_charms_are_kept_on_death_and_saved():
	f.run.inventory.add(Charms.HAWK, 1)
	var r0: float = f._bow_range()
	f.run.inventory.add(Charms.EYE, 1)
	assert_almost_eq(f._bow_range(), r0, 0.001)
	var d: Dictionary = f.run.to_dict()
	var other := RunState.new("town", Vector2i(5, 6))
	other.load_dict(d)
	assert_true(Charms.has(other.inventory, Charms.HAWK), "セーブに残る")
	assert_true(ItemCatalog.is_key(Charms.HAWK), "大事な物なので、死んでも墓石に入らない")

func test_fragments_change_the_dark_king_scene_and_the_ending():
	for i in Story.FRAGMENTS.size():
		f.run.flags[Story.fragment_flag(i + 1)] = true
	var fl := Story.flags(f.run)
	assert_true(fl["all_frags"])
	assert_eq(Story.boss_beat_for(Story.DARK_KING, fl), Story.GARDE_BEAT)
	assert_eq(Story.ending(fl), Story.TRUE_PRELUDE, "このあと最後の選択（2026-11-27）")
	fl["all_frags"] = false
	assert_eq(Story.ending(fl), Story.BAD_ENDING)

func test_journal_lists_kills_fragments_and_charms():
	var rows := JournalPanel.bestiary_rows(f.run)
	assert_eq(rows.size(), EnemyKind.DATA.size() + 1)
	assert_eq(rows[1][0], "？？？", "倒していない魔物は伏せる")
	f.run.on_enemy_killed(EnemyKind.Kind.WEAK, 1)
	f.run.kills[EnemyKind.Kind.SHIELD] = 2
	rows = JournalPanel.bestiary_rows(f.run)
	var shield_row := ""
	for r in rows:
		if r[0].begins_with("盾持ち"):
			shield_row = r[0]
	assert_string_contains(shield_row, "×2")
	assert_string_contains(shield_row, "弱点：鉄球")
	var charms := JournalPanel.charm_rows(f.run)
	assert_eq(charms.size(), Charms.ALL.size() + 1)
	f.run.inventory.add(Charms.RING, 1)
	assert_string_contains(JournalPanel.charm_rows(f.run)[0][0], "1 / 7")
	f.menu.open()
	f.menu.show_page(InventoryMenu.Page.JOURNAL)
	f.run.flags[Story.fragment_flag(3)] = true
	f.menu.journal.select_fragment(3)
	assert_eq(f.menu.journal.selected_fragment, 3)
	f.menu.journal.select_fragment(5)
	assert_eq(f.menu.journal.selected_fragment, 3, "持っていないかけらは読めない")
	f.menu.close()
