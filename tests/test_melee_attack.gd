extends GutTest

func test_hits_after_windup_when_still_close():
	var a := MeleeAttack.new()
	assert_false(a.update(0.1, Vector2.ZERO, 0, Vector2(10, 0), 0))
	assert_true(a.is_winding_up())
	assert_true(a.update(0.5, Vector2.ZERO, 0, Vector2(10, 0), 0))

## 下から上へは叩けない（1段でも上なら当たらない）。1段下へは届く
func test_cannot_hit_upward():
	assert_false(MeleeAttack.in_reach(Vector2.ZERO, 0, Vector2(10, 0), 1))
	assert_true(MeleeAttack.in_reach(Vector2.ZERO, 1, Vector2(10, 0), 0))
	assert_false(MeleeAttack.in_reach(Vector2.ZERO, 2, Vector2(10, 0), 0))

func test_dodge_by_moving_away_or_two_levels_up():
	var a := MeleeAttack.new()
	a.update(0.1, Vector2.ZERO, 0, Vector2(10, 0), 0)
	assert_false(a.update(0.5, Vector2.ZERO, 0, Vector2(30, 0), 0))
	var b := MeleeAttack.new()
	b.update(0.1, Vector2.ZERO, 0, Vector2(10, 0), 0)
	assert_false(b.update(0.5, Vector2.ZERO, 0, Vector2(10, 0), 2))

func test_cooldown_before_next_windup():
	var a := MeleeAttack.new()
	a.update(0.1, Vector2.ZERO, 0, Vector2(10, 0), 0)
	a.update(0.5, Vector2.ZERO, 0, Vector2(10, 0), 0)
	a.update(0.5, Vector2.ZERO, 0, Vector2(10, 0), 0)
	assert_false(a.is_winding_up())

func test_no_windup_when_far():
	var a := MeleeAttack.new()
	a.update(0.1, Vector2.ZERO, 0, Vector2(30, 0), 0)
	assert_false(a.is_winding_up())
