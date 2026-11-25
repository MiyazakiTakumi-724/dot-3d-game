extends GutTest
## レベル・経験値・振り分け（design.md 11章、17章）。

var s: PlayerStats

func before_each():
	s = PlayerStats.new()

func test_initial_values():
	assert_eq(s.level, 1)
	assert_eq(s.exp, 0)
	assert_eq(s.points, 0)
	assert_eq(s.max_hp(), PlayerStats.BASE_HP)
	assert_eq(s.attack(), 10)

## レベル n から n+1 へは 4 × n × n の経験値（2026-11-25 夜の2回目の直しで、前の 5 × n から上げた）
func test_exp_needed_grows_with_level():
	assert_eq(PlayerStats.exp_to_reach(1), 0)
	assert_eq(PlayerStats.exp_to_reach(2), 4)
	assert_eq(PlayerStats.exp_to_reach(3), 20)
	assert_eq(PlayerStats.exp_to_reach(4), 56)
	assert_eq(PlayerStats.exp_to_reach(10), 1140)

## レベルが1つ上がると、ポイントは1つ（前は2つ）
func test_level_up_gives_points():
	assert_eq(PlayerStats.POINTS_PER_LEVEL, 1)
	assert_eq(s.add_exp(3), 0)
	assert_eq(s.level, 1)
	assert_eq(s.add_exp(1), 1)
	assert_eq(s.level, 2)
	assert_eq(s.points, 1)

func test_big_exp_gives_several_levels():
	assert_eq(s.add_exp(56), 3)
	assert_eq(s.level, 4)
	assert_eq(s.points, 3)

func test_exp_progress_in_level():
	s.add_exp(10)
	assert_eq(s.exp_in_level(), 6)
	assert_eq(s.exp_level_span(), 16)

func test_allocate_needs_points():
	assert_false(s.allocate(PlayerStats.Stat.ATTACK))
	s.add_exp(4)
	assert_true(s.allocate(PlayerStats.Stat.ATTACK))
	assert_eq(s.points_in(PlayerStats.Stat.ATTACK), 1)
	assert_eq(s.points, PlayerStats.POINTS_PER_LEVEL - 1)

func test_vitality_and_attack_raise_base_values():
	s.add_exp(PlayerStats.exp_to_reach(3))
	s.allocate(PlayerStats.Stat.VITALITY)
	s.allocate(PlayerStats.Stat.ATTACK)
	assert_eq(PlayerStats.HP_PER_POINT, 2)
	assert_eq(s.max_hp(), PlayerStats.BASE_HP + 2)
	assert_eq(s.attack(), 11)

func test_equipment_adds_to_values():
	assert_eq(s.max_hp(3), PlayerStats.BASE_HP + 3)
	assert_eq(s.attack(2), 12)

func test_move_points_make_faster():
	assert_eq(s.move_speed_mult(), 1.0)
	s.add_exp(4)
	s.allocate(PlayerStats.Stat.MOVE)
	assert_gt(s.move_speed_mult(), 1.0)

func test_skill_every_three_points():
	s.add_exp(PlayerStats.exp_to_reach(4))
	for i in 2:
		s.allocate(PlayerStats.Stat.SWORD)
	assert_eq(s.skills_in(PlayerStats.Stat.SWORD), 0)
	s.allocate(PlayerStats.Stat.SWORD)
	assert_eq(s.skills_in(PlayerStats.Stat.SWORD), 1)

## 魔法：3ポイントで魔法2つ目、6で最大マナ＋10、9で魔法3つ目（2026-11-24 決定）
func test_magic_points_unlock_slots_and_mana():
	var st := PlayerStats.new()
	st.add_exp(PlayerStats.exp_to_reach(10))
	assert_eq(st.spell_slots(), 1)
	assert_eq(st.max_mana(), 50)
	for i in 3:
		st.allocate(PlayerStats.Stat.MAGIC)
	assert_eq(st.spell_slots(), 2)
	assert_eq(st.max_mana(), 50)
	for i in 3:
		st.allocate(PlayerStats.Stat.MAGIC)
	assert_eq(st.spell_slots(), 2)
	assert_eq(st.max_mana(), 60)
	for i in 3:
		st.allocate(PlayerStats.Stat.MAGIC)
	assert_eq(st.spell_slots(), 3)
	assert_eq(PlayerStats.SKILLS[PlayerStats.Stat.MAGIC], ["魔法2つ目", "最大マナ＋10", "魔法3つ目"])
	assert_eq(PlayerStats.NAMES[PlayerStats.Stat.MAGIC], "魔法")
