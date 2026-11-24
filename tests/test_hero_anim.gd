extends GutTest
## 主人公の動き（HeroAnim）。歩いた距離で足を出し、鉄球を放す・拾う・剣を振る・着地の動きを、時間で決める。

var a: HeroAnim

func before_each():
	a = HeroAnim.new()

## 止まっている間は立ち姿。歩き出すとすぐ足を出し、STEP_PX ごとに 左足→そろえる→右足→そろえる をくり返す
func test_walk_cycle_by_distance():
	assert_eq(a.pose(), "")
	a.update(0.016, 1.0)
	assert_eq(a.pose(), "step_l")
	a.update(0.016, HeroAnim.STEP_PX)
	assert_eq(a.pose(), "")
	a.update(0.016, HeroAnim.STEP_PX)
	assert_eq(a.pose(), "step_r")
	a.update(0.016, HeroAnim.STEP_PX)
	assert_eq(a.pose(), "")
	a.update(0.016, HeroAnim.STEP_PX)
	assert_eq(a.pose(), "step_l")
	a.update(0.016, 0.0)  # 止まったら立ち姿に戻る
	assert_eq(a.pose(), "")

## 足を出しているときは、体が少し（本当の画面の1px）下がる
func test_body_bobs_on_steps():
	assert_eq(a.bob(), 0.0)
	a.update(0.016, 1.0)
	assert_gt(a.bob(), 0.0)
	a.update(0.016, HeroAnim.STEP_PX)
	assert_eq(a.bob(), 0.0)

## 鉄球を放すと、少しの間「両手を前に出した」姿になる（歩いていても）
func test_release_pose_for_a_moment():
	a.play_release()
	a.update(0.016, 3.0)
	assert_eq(a.pose(), "release")
	a.update(HeroAnim.RELEASE_TIME, 3.0)
	assert_ne(a.pose(), "release")

## 拾うときは、かがんでから戻る（下の輪切りを描かない数が、途中で増えて最後は0）
func test_pickup_dips_and_returns():
	a.play_pickup()
	a.update(HeroAnim.PICKUP_TIME * 0.5, 0.0)
	assert_gt(a.dip_layers(), 0)
	a.update(HeroAnim.PICKUP_TIME, 0.0)
	assert_eq(a.dip_layers(), 0)

## 剣を振ると、体が剣を持つ側（−）からもう片側（＋）へひねる。回転斬りは1回転する
func test_swing_twists_and_spin_turns():
	assert_eq(a.twist(), 0.0)
	a.play_swing(0.2)
	var first := a.twist()
	a.update(0.15, 0.0)
	var later := a.twist()
	assert_lt(first, 0.0)
	assert_gt(later, 0.0)
	a.update(0.1, 0.0)
	assert_eq(a.twist(), 0.0)
	a.play_spin(0.4)
	a.update(0.2, 0.0)
	assert_almost_eq(a.twist(), PI, 0.01)
	a.update(0.3, 0.0)
	assert_eq(a.twist(), 0.0)

## 飛び降りて着いたとき、体が少し縮んでから戻る
func test_land_squash():
	assert_eq(a.stretch(), 1.0)
	a.play_land()
	assert_lt(a.stretch(), 1.0)
	a.update(HeroAnim.LAND_TIME, 0.0)
	assert_eq(a.stretch(), 1.0)
