extends GutTest
## 曲（2026-11-27）：曲はコードで作る。同じ名前なら同じ曲で、つなぎ目なく繰り返せる長さ。地方とボスで曲が変わる。

func test_every_track_renders_a_loop_of_whole_bars():
	for name in BgmSynth.TRACKS:
		var t: Dictionary = BgmSynth.TRACKS[name]
		var s := BgmSynth.render(name, 1)
		var want := int(round(1 * 4 * 60.0 / float(t["bpm"]) * BgmSynth.RATE))
		assert_eq(s.size(), want, "%s は1小節ちょうど" % name)
		var peak := 0.0
		var energy := 0.0
		for v in s:
			peak = maxf(peak, absf(v))
			energy += v * v
		assert_true(peak <= 1.0, "%s は割れない" % name)
		assert_true(energy > 10.0, "%s は音が鳴っている" % name)

func test_same_name_same_music():
	var a := BgmSynth.render("field", 1)
	var b := BgmSynth.render("field", 1)
	assert_eq(a.size(), b.size())
	assert_eq(a[1234], b[1234])

func test_every_theme_has_a_track():
	for theme in ["town", "grass", "mountain", "castle", "lava", "tower", "mist"]:
		assert_true(BgmSynth.TRACKS.has(Bgm.track_for(theme)), theme)
	assert_eq(Bgm.track_for("grass", "草むらの大蛇"), "boss")
	assert_eq(Bgm.track_for("tower", "ブライト"), "last")
	assert_eq(Bgm.track_for("mist", "闇の王"), "last")
	assert_eq(Bgm.track_for("grass", "", true), "title")

func test_field_picks_the_track():
	var f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)
	assert_null(f.bgm, "テストでは鳴らさない")
	assert_eq(f.music_track(), "town")
	f.enter_area("mv_1", Vector2i(5, 5))
	assert_eq(f.music_track(), "mist")

func test_volume_setting_is_saved():
	var s := GameSettings.new()
	s.bgm_level = 1
	var path := "user://test_settings_bgm.json"
	s.save_file(path)
	var q := GameSettings.new()
	q.load_file(path)
	assert_eq(q.bgm_level, 1)
	DirAccess.remove_absolute(path)
