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

## 剣を振っている間は振る姿（slash）。技能「突き」なら突く姿（thrust）で、前へ踏み込む
func test_sword_poses_and_lunge():
	a.play_swing(0.2)
	assert_eq(a.pose(), "slash")
	a.update(0.25, 0.0)
	assert_eq(a.pose(), "")
	a.play_swing(0.2, true)
	a.update(0.1, 0.0)
	assert_eq(a.pose(), "thrust")
	assert_gt(a.forward_px(), 0.0)
	assert_eq(a.twist(), 0.0)  # 突きは体をひねらない
	a.play_spin(0.3)
	assert_eq(a.pose(), "slash")

## 弓を溜めている間は引く姿。溜めきると引ききった姿。放すと少し後ろへ反動
func test_bow_draw_and_loose():
	a.set_charge(0.5)
	assert_eq(a.pose(), "draw")
	a.set_charge(1.0)
	assert_eq(a.pose(), "draw_full")
	a.set_charge(-1.0)
	a.play_loose()
	assert_eq(a.pose(), "")
	assert_lt(a.forward_px(), 0.0)
	a.update(HeroAnim.LOOSE_TIME, 0.0)
	assert_eq(a.forward_px(), 0.0)

## 杖をふるう・薬を飲む・門を押す姿は、それぞれ少しの間。杖の先が光る
func test_cast_drink_push():
	a.play_cast()
	assert_eq(a.pose(), "cast")
	assert_gt(a.cast_flash(), 0.0)
	a.update(HeroAnim.CAST_TIME, 0.0)
	assert_eq(a.pose(), "")
	assert_eq(a.cast_flash(), 0.0)
	a.play_drink()
	assert_eq(a.pose(), "drink")
	a.update(HeroAnim.DRINK_TIME, 0.0)
	a.play_push()
	assert_eq(a.pose(), "push")

## よじ登っている間は両手を上げ、進むほど体が上がる
func test_climb_pose_lifts():
	a.set_climb(0.5)
	assert_eq(a.pose(), "climb")
	assert_gt(a.climb_lift(), 0.0)
	a.set_climb(0.0)
	assert_eq(a.climb_lift(), 0.0)

## ダメージを受けると一瞬赤く光り、後ろへのけぞる
func test_hurt_flash_and_recoil():
	a.play_hurt()
	assert_gt(a.hurt_flash(), 0.0)
	assert_lt(a.forward_px(), 0.0)
	a.update(HeroAnim.HURT_TIME, 0.0)
	assert_eq(a.hurt_flash(), 0.0)

## 倒れると、ひざをついてから横たわる（歩いても変わらない）。奈落に落ちるときは両手を上げる。再開で元に戻る
func test_die_and_revive():
	a.play_die()
	a.update(0.05, 0.0)
	assert_gt(a.dip_layers(), 0)
	a.update(HeroAnim.KNEEL_TIME, 3.0)
	assert_eq(a.pose(), "down")
	a.revive()
	assert_eq(a.pose(), "")
	a.play_fall()
	assert_eq(a.pose(), "climb")
	a.revive()
	assert_eq(a.pose(), "")
