extends GutTest
## セーブとロード（2026-11-26 独自の開発1）。冒険の状態を JSON にして user:// に書き、読み戻すと同じになる。

const DIR := "user://test_saves/"

func before_each():
	SaveGame.dir = DIR
	for i in range(1, SaveGame.SLOTS + 1):
		SaveGame.erase(i)

func after_all():
	for i in range(1, SaveGame.SLOTS + 1):
		SaveGame.erase(i)
	SaveGame.dir = SaveGame.DEFAULT_DIR

func _played() -> RunState:
	var r := RunState.new("town", Vector2i(5, 6))
	r.stats.add_exp(200)
	r.stats.allocate(PlayerStats.Stat.SWORD)
	r.inventory.money = 321
	r.inventory.add("sword_bronze")
	r.inventory.add("arrow", 12)
	r.inventory.add("potion", 3)
	r.inventory.arrow_kind = Arrow.Kind.POISON
	r.inventory.tool_id = "potion"
	r.inventory.equipment.equip("sword_bronze")
	r.on_boss_killed("草むらの大蛇", 10)
	r.collect("hills:3", "money", 5)
	r.open_door("mt_boss")
	r.open_gimmick("rocks:g0")
	r.visit("hills")
	r.set_checkpoint("gr_2", Vector2i(9, 4))
	r.on_death("gr_3", Vector2i(2, 3))
	r.play_time = 125.5
	r.flags["memory_1"] = true
	r.kills[EnemyKind.Kind.MELEE] = 4
	return r

func test_run_state_round_trip():
	var r := _played()
	var d: Dictionary = JSON.parse_string(JSON.stringify(r.to_dict()))  # 本当のファイルと同じく、一度文字にする
	var back := RunState.new("town", Vector2i(1, 1))
	back.load_dict(d)
	assert_eq(back.stats.level, r.stats.level)
	assert_eq(back.stats.exp, r.stats.exp)
	assert_eq(back.stats.points, r.stats.points)
	assert_eq(back.stats.points_in(PlayerStats.Stat.SWORD), 1)
	assert_eq(back.inventory.money, r.inventory.money)
	assert_eq(back.inventory.count("potion"), 0, "道具は墓石の中")
	assert_eq(back.grave.counts.get("potion", 0), 3)
	assert_eq(back.grave.area_id, "gr_3")
	assert_eq(back.grave.cell, Vector2i(2, 3))
	assert_eq(back.grave.equipment, ["sword_bronze"])
	assert_eq(back.inventory.equipment.chosen(Equipment.Slot.SWORD), "sword_bronze", "好みは残る")
	assert_eq(back.inventory.arrow_kind, Arrow.Kind.POISON)
	assert_true(back.is_boss_defeated("草むらの大蛇"))
	assert_eq(back.bosses_defeated, 1)
	assert_true(back.is_picked("hills:3"))
	assert_true(back.is_door_open("mt_boss"))
	assert_true(back.is_gimmick_open("rocks:g0"))
	assert_true(back.has_visited("hills"))
	assert_eq(back.checkpoint_area, "gr_2")
	assert_eq(back.checkpoint_cell, Vector2i(9, 4))
	assert_eq(back.bonfire_areas(), ["town", "gr_2"])
	assert_eq(back.bonfire_cell("town"), Vector2i(5, 6))
	assert_almost_eq(back.play_time, 125.5, 0.01)
	assert_true(back.flags.get("memory_1", false))
	assert_eq(back.kills.get(EnemyKind.Kind.MELEE, 0), 4)

func test_load_replaces_everything_in_place():
	# 画面が持っている参照（stats・inventory）を作り直さず、中身だけを入れ替える
	var r := RunState.new("town", Vector2i(1, 1))
	var stats := r.stats
	var inv := r.inventory
	r.inventory.add("potion", 9)
	r.flags["x"] = true
	r.load_dict(RunState.new("rocks", Vector2i(2, 2)).to_dict())
	assert_same(r.stats, stats)
	assert_same(r.inventory, inv)
	assert_eq(r.inventory.count("potion"), 0)
	assert_false(r.flags.has("x"))
	assert_eq(r.checkpoint_area, "rocks")

func test_slots_write_read_and_summary():
	assert_false(SaveGame.exists(1))
	var r := _played()
	assert_true(SaveGame.write(1, r, "丘陵"))
	assert_true(SaveGame.exists(1))
	assert_false(SaveGame.exists(2))
	var s := SaveGame.summary(1)
	assert_eq(s["level"], r.stats.level)
	assert_eq(s["place"], "丘陵")
	assert_eq(s["bosses"], 1)
	assert_eq(SaveGame.time_text(s["play_time"]), "0:02")
	var back := RunState.new("town", Vector2i(1, 1))
	assert_true(SaveGame.read(1, back))
	assert_eq(back.inventory.money, r.inventory.money)
	SaveGame.erase(1)
	assert_false(SaveGame.exists(1))

func test_broken_file_is_ignored():
	var f := FileAccess.open(SaveGame.path(2), FileAccess.WRITE)
	f.store_string("{こわれた")
	f.close()
	assert_false(SaveGame.read(2, RunState.new("town", Vector2i(1, 1))))
	assert_true(SaveGame.summary(2).is_empty())

func test_time_text():
	assert_eq(SaveGame.time_text(59.0), "0:00")
	assert_eq(SaveGame.time_text(3600.0 * 2 + 60 * 5), "2:05")

func test_settings_round_trip():
	var s := GameSettings.new()
	s.easy_mode = true
	s.soft_flash = true
	s.sfx_level = 1
	s.fullscreen = false
	s.shake = false
	s.slow_turn = true
	var path := DIR + "settings_test.json"
	assert_true(s.save_file(path))
	var t := GameSettings.new()
	assert_true(t.load_file(path))
	assert_true(t.easy_mode)
	assert_true(t.soft_flash)
	assert_eq(t.sfx_level, 1)
	assert_false(t.fullscreen)
	assert_false(t.shake)
	assert_true(t.slow_turn)
	DirAccess.remove_absolute(path)
