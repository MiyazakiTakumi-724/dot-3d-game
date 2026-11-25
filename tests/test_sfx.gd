extends GutTest
## 効果音（2026-11-26 の3回目の直し）：コードで作った音と、遊んでいるときに鳴る所。

func before_each():
	Sfx.clear_history()

func test_every_sound_renders_short_and_in_range():
	assert_gt(SfxSynth.RECIPES.size(), 60, "たくさんの音")
	for name in SfxSynth.RECIPES:
		var w := SfxSynth.render(name)
		assert_gt(w.size(), 100, name)
		assert_lte(w.size(), int(SfxSynth.RATE * 2.0), "%s は2秒まで" % name)
		var peak := 0.0
		for x in w:
			peak = maxf(peak, absf(x))
		assert_gt(peak, 0.01, "%s は聞こえる" % name)
		assert_lte(peak, 0.951, name)

func test_same_name_same_sound():
	assert_eq(SfxSynth.render("hit"), SfxSynth.render("hit"))

func test_stream_is_16bit_mono():
	var s := Sfx.stream("coin")
	assert_eq(s.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_false(s.stereo)
	assert_eq(s.data.size(), SfxSynth.render("coin").size() * 2)

func test_far_sounds_are_skipped():
	Sfx.listener = Vector2.ZERO
	Sfx.play("hit", Vector2(Sfx.FAR + 10.0, 0))
	assert_eq(Sfx.count("hit"), 0)
	Sfx.play("hit", Vector2(40, 0))
	assert_eq(Sfx.count("hit"), 1)

func test_same_sound_not_twice_at_once():
	Sfx.play("coin")
	Sfx.play("coin")
	assert_eq(Sfx.count("coin"), 1)

func test_warm_step_prepares_all():
	var done := false
	for i in 400:
		if Sfx.warm_step(5.0):
			done = true
			break
	assert_true(done)

# ---------------------------------------------------------------- 遊んでいるときに鳴る所

var f

func _field():
	f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)
	Sfx.clear_history()

func test_walking_makes_footsteps():
	_field()
	f.player.anim.update(0.016, 3.0)
	for i in 12:
		f.player.anim.update(0.016, 3.0)
		if f.player.anim.stepped:
			break
	assert_true(f.player.anim.stepped, "歩くと足が着く")
	assert_eq(f.player.step_sound, "step_stone", "町は石畳")

func test_actions_play_sounds():
	_field()
	f.run.inventory.equipment.gain("sword_1")
	f.hotbar.select_slot(2, f.run.inventory.equipment)
	assert_true(f.swing_sword())
	assert_gt(Sfx.count("sword") + Sfx.count("thrust"), 0, "剣を振る音")
	f.hurt_player(3)
	assert_eq(Sfx.count("hurt"), 1, "攻撃を受けた音")
	f.toggle_map()
	assert_eq(Sfx.count("ui_open"), 1)
	f.notice("", 0.0)
	f._on_picked("money", 5)
	assert_eq(Sfx.count("coin"), 1)

func test_settings_turn_sound_off():
	_field()
	f.menu.set_sfx_level(0)
	assert_eq(Sfx.level, 0)
	assert_eq(f.settings.sfx_level, 0)
	f.menu.set_sfx_level(2)
	assert_eq(Sfx.level, 2)
