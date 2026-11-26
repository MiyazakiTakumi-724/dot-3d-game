extends GutTest
## タイトル画面・はじめから・つづきから・止める画面・設定（2026-11-26 独自の開発1）。

var f

func before_each():
	SaveGame.dir = "user://test_saves/"
	for i in range(1, SaveGame.SLOTS + 1):
		SaveGame.erase(i)
	f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)

func after_each():
	Engine.time_scale = 1.0
	get_tree().paused = false

func after_all():
	for i in range(1, SaveGame.SLOTS + 1):
		SaveGame.erase(i)
	SaveGame.dir = SaveGame.DEFAULT_DIR

func test_tests_do_not_save():
	assert_eq(f.save_slot, 0)
	assert_false(f.autosave(), "テストではセーブしない")
	assert_false(f.in_title, "テストではタイトルを出さない")

func test_title_hides_the_hero_and_rotates_the_camera():
	f.show_title()
	assert_true(f.in_title)
	assert_true(f.title_menu.is_open())
	assert_false(f.player.visible)
	assert_false(f.hud.visible)
	var a: float = f.camera.angle
	f._process(0.5)
	assert_ne(f.camera.angle, a, "うしろで町をゆっくり回して見せる")

func test_new_game_writes_a_save_and_starts_in_town():
	f.show_title()
	f.start_new_game(2)
	assert_false(f.in_title)
	assert_true(f.player.visible)
	assert_true(f.hud.visible)
	assert_eq(f.area.id, Continent.START_AREA)
	assert_true(SaveGame.exists(2))
	assert_eq(f.save_slot, 2)
	assert_true(f.dialogue.is_open(), "はじまりの言葉")

func test_continue_restores_the_adventure_at_the_last_bonfire():
	f.start_new_game(1)
	f.dialogue.close()
	f.run.inventory.money = 777
	f.run.stats.add_exp(100)
	f.run.set_checkpoint("rocks", Vector2i(3, 3))
	var lv: int = f.run.stats.level
	assert_true(f.autosave())
	# 変えてから読み戻す
	f.run.inventory.money = 1
	f.show_title()
	assert_true(f.load_game(1))
	assert_eq(f.run.inventory.money, 777)
	assert_eq(f.run.stats.level, lv)
	assert_eq(f.area.id, "rocks", "最後に休んだたき火から")
	assert_eq(f.player.hp, f.player.max_hp)

func test_new_game_over_an_old_save_starts_fresh():
	f.start_new_game(1)
	f.run.inventory.money = 500
	f.run.on_boss_killed("草むらの大蛇", 10)
	f.autosave()
	f.show_title()
	f.start_new_game(1)
	assert_eq(f.run.inventory.money, 0)
	assert_false(f.run.is_boss_defeated("草むらの大蛇"))
	assert_eq(SaveGame.summary(1)["bosses"], 0)

func test_resting_at_a_bonfire_saves():
	f.start_new_game(3)
	f.dialogue.close()
	SaveGame.erase(3)
	var cp: Vector2i = f._campfire_cell
	f.run.set_checkpoint("rocks", Vector2i(1, 1))  # 町のたき火から離れた所にしておく
	f.player.mover.place(cp + Vector2i(1, 0))
	f._play_step()
	assert_true(SaveGame.exists(3))

func test_escape_pauses_and_resumes():
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_ESCAPE
	ev.pressed = true
	f._unhandled_input(ev)
	assert_true(f.pause_menu.is_open())
	assert_true(get_tree().paused)
	f.pause_menu.close()
	assert_false(get_tree().paused)

func test_pause_settings_share_the_same_settings():
	f.pause_menu.open()
	f.pause_menu.show_settings(true)
	assert_true(f.pause_menu.settings_shown())
	f.pause_menu._settings_panel.set_value("shake", false)
	assert_false(f.settings.shake)
	assert_false(f.camera.shake_enabled, "ゆれを切ると画面もゆれない")
	f.pause_menu.close()

func test_slow_turn_slows_time_only_while_turning():
	f.settings.slow_turn = true
	f.camera.turning = true
	f._update_time_scale()
	assert_almost_eq(Engine.time_scale, GameSettings.SLOW_TURN_SCALE, 0.001)
	f.camera.turning = false
	f._update_time_scale()
	assert_eq(Engine.time_scale, 1.0)
	f.settings.slow_turn = false
	f.camera.turning = true
	f._update_time_scale()
	assert_eq(Engine.time_scale, 1.0, "設定を切っていればふつう")

func test_title_slot_text():
	assert_eq(TitleMenu.slot_text(1), "1　（空き）")
	f.start_new_game(1)
	assert_string_contains(TitleMenu.slot_text(1), "Lv1")
	assert_string_contains(TitleMenu.slot_text(1), "はじまりの町")
