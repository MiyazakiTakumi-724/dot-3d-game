extends GutTest
## マナ：最大は50（ステータスの魔法で＋10）。戦っている間も、毎秒1.5ずつ戻る【提案】

func test_starts_full():
	var m := Mana.new()
	assert_eq(m.value, 50.0)
	assert_eq(m.max_value, 50)

func test_spend_and_regen():
	var m := Mana.new()
	assert_true(m.try_spend(20))
	assert_eq(m.value, 30.0)
	m.update(2.0)
	assert_eq(m.value, 33.0)
	m.update(100.0)
	assert_eq(m.value, 50.0)
	m.value = 4.0
	assert_false(m.try_spend(5))
	assert_eq(m.value, 4.0)

## 最大が上がると、増えた分だけ今のマナも増える。下がったら今のマナを切り詰める
func test_set_max():
	var m := Mana.new()
	m.value = 40.0
	m.set_max(60)
	assert_eq(m.value, 50.0)
	m.set_max(50)
	assert_eq(m.value, 50.0)
