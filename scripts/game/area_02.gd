extends Node2D
## 試作2「死と取り返しの流れ」のエリア。死んでもシーンを読み込み直さず、中身を戻してチェックポイントから再開する。
## 操作：矢印/WASD 移動、左クリック 手に持つアイテムを使う（カーソルの方向）、1/2 手に持つアイテムを選ぶ、
## Tab インベントリ（使う鉄球を決める）、F 門を開ける、右ドラッグ or Q/E カメラ回転。鉄球は上を歩いて拾う。
## 敵は体力1で撃たず、体当たりしてくる（最初のステージなので簡単にしてある）。

## 空に浮かぶ箱庭の島。地図は2層（Terrain.parse_layers）。
## 高さの層：. ＝島の外、数字＝高さ（段）。真ん中の山（高さ5）は崖で囲まれていて、西の階段からしか登れない。
## 物の層：T ＝丸い木、P ＝とがった木、B ＝茂み、R ＝岩、F ＝花、~ ＝水、= ＝橋、_ ＝奈落、
## C ＝チェックポイント（たき火）、D ＝門、G ＝ゴール。
## 南西のたき火の草地から、南の橋で川を渡る → 東の段々畑（生け垣で折り返す）→ 北東の池 → 北の裂け目（細い道）
## → 北西の森（木の列で折り返す）→ 西の小道。西の小道から門を開けると、たき火の草地へすぐ戻れる。
## ゴールは山の上。西の小道の階段から登る。山の泉から南へ川が流れ、崖で滝になり、島のふちから落ちる。
const HEIGHTS := [
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	"..........................................222222222222222222222.....................................",
	"...................................3333333222222222222222222222222..................................",
	"................................333333333332222222222222222222222222................................",
	"..............................333333333333322222222222222222222222222...............................",
	"............................333333333333333222222222222332222222222222..............................",
	"..........................333333333333333333333333333333333333222222222.............................",
	".........................33333333333333333333333333333333333333322222222............................",
	".......................33333333333333333333333333333333333333333322222222...........................",
	"......................3333333333333333333333333333333333333333333322222222..........................",
	"....................2223333333333333333333333333333333333333333333322222222.........................",
	"..................2222223333333333333333333333333333333333333333333322222222........................",
	"................22222222233333333333333333333333333333333333333333333222222222......................",
	"..............222222222222223333333333333333333333333333333333333333322222222222....................",
	".............222222222222222222233333333333333333333333333333333333333222222222222..................",
	"............222222222222222222222223333333333333333333333333333333333333222222222222................",
	"...........222222222222222222222222223333333333333333333333333333333333333222222222222..............",
	"..........22222222222222222222222222223333333333333333333333333333333333333322222222222.............",
	".........22222222222222222222222222222233333333355553333333333333333333333333332222222222...........",
	".........222222222222222222222222222222333333355555555533333333333333333333333332222222222..........",
	".........222222222222222222222222222222233333555555555555333333333333333333333333322211111..........",
	".........2222222222222222222222222222222333555555555555555533333333333333333333333321111111.........",
	".........22222222222222222222222222222222355555555555555555553333333333333333333332211111111........",
	".........222222222222222222222222222225555555555555555555555555333333333333333333222111111111.......",
	".........222222222222222222222222225555555555555555555555555555533333333333333332222211111111.......",
	".........2222222222222222222222225555555555555555555555555555555533333333333333222222211111111......",
	".........22222222221111111111222255555555555555555555555555555555333333333333322222222211111111.....",
	"..........2222111111111111111112555555555555555555555555555555555533333333332222222222211111111.....",
	"..........11111111111111111111115555555555555555555555555555555555222222222222222222222211111111....",
	".........1111111111111111111111155555555555555555555555555555555555222222222222222222222211111111...",
	".........1111111111111111111111223344555555555555555555555555555555552222222222222222222221111111...",
	".........11111111111111111111112233445555555555555555555555555555555552222222222222222222211111111..",
	"........111111111111111111111115555555555555555555555555555555555555552222222222222222222221111111..",
	"........111111111111111111111115555555555555555555555555555555555555552222222222222222222221111111..",
	"........111111111111111111111115555555555555555555555555555555555555552222222222222222222221111111..",
	".......1111111111111111111111111555555555555555555555555555555555555552222222222222222222221111111..",
	".......1111111111111111111111111155555555555555555555555555555555555222222222222222222222211111111..",
	".......111111111111111111111111111155555555555555555555555555555552222222222222222222222221111111...",
	".......111111111111111111111111111111555555555555555555555555555111222222222222222222222211111111...",
	".......11111111111111111111111111111115555555555555555555555555111111222222222222222222211111111....",
	".......1111111111111111111111111111111155555555555555555555551111111111222222222222222111111111.....",
	".......111111111111111111111111111111115555555555555555555553111111111111111111111111111111111......",
	"........1111111111111111111111111111111155555555555555555553111111111111111111111111111111122.......",
	"........11111111111111111111111111111111155555555555555553331111111111111111111111111111111.........",
	"........1111111111111111111111111111111111555555555111133333111111111111111111111111111111..........",
	".........11111111111111111111111111111111111111111111133331111111111111111111111111111111...........",
	"..........111111111111111111111111111111111111111111111111111111111111111111111111111111............",
	"..........11111111111111111111111111111111111111111111111111111111111111111111111111111.............",
	"...........111111111111111111111111111111111111111111111111111111111111111111111111111..............",
	"...........111111111111111111111111111111111111111111111111111111111111111111111111111..............",
	"............1111111111111111111111111111111111111111111111111111111111111111111111111...............",
	"............111111111111111111111111111111111111111111111111111111111111111111111111................",
	".............1111111111111111111111111111111111111111111111111111111111111111111111.................",
	"..............11111111111111111111111111111111111111111111111111111111111111111111..................",
	"..............1111111111111111111111111111111111111111111111111111111111111111111...................",
	"................111111111111111111111111111111111111111111111111111111111111111.....................",
	".................111111111111111111111111111111111111111111111111111111111111.......................",
	"...................1111111111111111111111111111111111111111111111111111111..........................",
	"......................1111111111111111111111111111111111111111111111................................",
	".........................................1111111111111111111111.....................................",
	"..............................................1111111111111.........................................",
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
]
const OBJECTS := [
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	"............................................____.T.TBF..T._____.....................................",
	"...................................TT......T____T...T..B.T____.TT...................................",
	".................................BBTT.PT.....___B.........____..PBB.................................",
	"..............................BT...T......FP____.B..T.....____....B.................................",
	"..............................BB...F........____....................................................",
	"...........................T.T............._____..........____......TB..............................",
	"..........................T.P...F..........____..F........____........P.............................",
	".......................TP...T.....F........____...........____......................................",
	"......................BPTP..F..T......................P.._____......................................",
	"....................PB.P...B.T...B.........____....PT....____T......................................",
	"..................T..T.T....P.B............____........T.____.T.T...................................",
	"................B.TBPTT.PP.................____T.....T..P___........................................",
	"..............T.PPT..PT.....................___.....T....F.....F....................................",
	".............PPTPPP........................T___..............P.F..T...F.............................",
	"............T.TT.............TTPT.T.F...T...P......T...............F......F.....TF~~................",
	"...........PP............T...PPTPT.....F.TT..T..........F.....T....................~~~..............",
	".....................P.P.....TPT.P...........F....T.T....B.....T...TF.......F......T................",
	"................BBP.T.P......T..P.F.................BB......T....P...F...............BBPP...........",
	".............PBT.P.P..BPT..TPP.....TT.........P.T...............F...T..TT...........T.T.............",
	"..........FBTP.T.PP..TB.T.TT.F.F.....P..........F................B.......B.............T.T..........",
	"...........PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP.....T....T.T...T...B..............B..........T..........",
	"............BT.T..PBPPPT...PT.P..T.BF.PTBB..TT..................T..T.......................B........",
	"...............................P.B..TPPT.........................B.FT.......................B.......",
	"...................................TP..PFT.........................BB.T..TB......F..................",
	".........TT........................P.TB....B.T....G................BBBBBBBBBBBBBBBBBBBBBBBBBBB......",
	".........TTTTTTTTTTTTTTTTTTTTT..TP.P...PPB............~~~~~...T...FF..........T..T..........T.......",
	"..........PT.T.BT..BT..T.BTB.T....TP.P.PP.............~~~~~.............F..T.T.T....BT..............",
	"...........TT.T...TPT...T.T.P.....PB.P...........T...~~~~~~~.B................T.....T..F....TF......",
	".........T.T.........TPBBBP.................T..T.F....~~~~~............FB.......................F...",
	".........B.T.....TPT.TBB...................TPTT.......~~~~~BP.FF.....BBBBBBBBBBBBBBBBBBBBBBBBB..B...",
	".........TBT.BBTF...TB..................P..T..P......TT.~~~.....T.....BT..F..FB.............B.......",
	"........BTT..TB................BB...T.P..TB.............P~~P....T.....B................PT.T.TT......",
	"........TT.T..T.B.........B.T...TBPB..T....T............P~~~.BF.............................F....P..",
	"........T..TTBB........F.B..TBTT.P.P...............F.....~~~.........T..T.BT..................TP....",
	".......TBBBTT.......T......T.B.....F.............T....F.F~~~..P.........BBBBBBBBBBBBBBBBBBBBBBBBBB..",
	".......BP.T.......T...BPBTB.......F..........F...........~~~....B......BP..T.TT.......B........TBF..",
	".......BBT........T....................P.................~~~.....F..B.................T......T.TP...",
	".......RRRRRDRRRRRRRRRRRRRRRRRRRRRRRR..............P.....~~~..........T..F...T...B.....T...B........",
	".......RRRRR.RRRRRRRRRRRRRRRRRRRRRRRRRF........F....F.F..~~~.........B...........FF....F.FT....T....",
	"............................................F............~~~.BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB..B.....",
	"........B........T.T..........................F.........F~~F..F.........F....T......................",
	"............B....F..............F.......F..TP.P.........~~~...............TT.PB...........B.........",
	"..........F.......P........T...............B..F.....F...~~~...RR.........................T..........",
	"........BTT...T...............B............F..........PB~~~..TRR.B.T...F..P............B............",
	".........TT..................F....F.......B....T....FT.~~~.F...B....F.B.F.........T...TB............",
	"..........BT.......................FB...........B......~~~.T.....T....F................B............",
	"............T...........F..P..................T.....T..~~~...F..F.....F..P.......TB.................",
	"............B.........................P...............~~~...F..BT..B..............B.................",
	"..................C........................F......B..T~~~....T.F..RRR...............................",
	"............BT............F.....F...B..F..............~~~.T.......RRR.........T..T.P................",
	"..............................T....T..P............T..~~..B.......................F.................",
	"....................................................T~~~.PT......................T..................",
	"........................FF...........................~~~....................T.T..T..................",
	"...............F.T....T..............................===......................TPT...................",
	".................BT..................................~~~................RR....T.....................",
	"..................TB.....T.F.......T...............B.~~~.........B...T..RRTF........................",
	"...........................T...TPTPP.BB..............~~~.T..F..T..T..PT.RR..........................",
	"......................TFP..........B.BT..TBTB........~~~..FBB...T...................................",
	".........................................F...T...TBB.~~~B...........................................",
	"...............................................F.BT...~~.B..........................................",
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
	"....................................................................................................",
]
const PLAYER_START := Vector2i(19, 53)
## [開始マス, 向き]。最初のステージの敵は撃たない（体当たりだけ）。
const ENEMIES := [
	[Vector2i(47, 57), Vector2.DOWN],
	[Vector2i(57, 51), Vector2.DOWN],
	[Vector2i(68, 46), Vector2.DOWN],
	[Vector2i(82, 44), Vector2.DOWN],
	[Vector2i(86, 42), Vector2.RIGHT],
	[Vector2i(72, 40), Vector2.RIGHT],
	[Vector2i(80, 36), Vector2.DOWN],
	[Vector2i(94, 34), Vector2.RIGHT],
	[Vector2i(80, 32), Vector2.DOWN],
	[Vector2i(66, 28), Vector2.DOWN],
	[Vector2i(59, 19), Vector2.DOWN],
	[Vector2i(44, 20), Vector2.DOWN],
	[Vector2i(30, 17), Vector2.RIGHT],
	[Vector2i(17, 20), Vector2.RIGHT],
	[Vector2i(11, 28), Vector2.DOWN],
	[Vector2i(27, 28), Vector2.RIGHT],
	[Vector2i(37, 32), Vector2.DOWN],
]
const PICKUPS := [
	[Vector2i(29, 54), RunState.PickupKind.MONEY, 5],
	[Vector2i(63, 44), RunState.PickupKind.MONEY, 10],
	[Vector2i(91, 37), RunState.PickupKind.HEAL, 1],
	[Vector2i(68, 41), RunState.PickupKind.MATERIAL, 1],
	[Vector2i(97, 34), RunState.PickupKind.MONEY, 10],
	[Vector2i(72, 26), RunState.PickupKind.HEAL, 1],
	[Vector2i(58, 16), RunState.PickupKind.MONEY, 15],
	[Vector2i(49, 16), RunState.PickupKind.MATERIAL, 1],
	[Vector2i(34, 20), RunState.PickupKind.HEAL, 1],
	[Vector2i(13, 18), RunState.PickupKind.MONEY, 15],
	[Vector2i(14, 25), RunState.PickupKind.MATERIAL, 1],
	[Vector2i(27, 31), RunState.PickupKind.HEAL, 1],
	[Vector2i(39, 28), RunState.PickupKind.MONEY, 20],
	[Vector2i(80, 17), RunState.PickupKind.STRONG_BALL, 0],
]
## 門を開けるときに立つ奥側のマス。Terrain.parse_layers が返す doors と同じ順。
const DOOR_OPEN_FROM := [Vector2i(12, 40)]

const BULLET_HIT_RADIUS := 6.0
## 最初のステージの敵は、どの鉄球でも1発で倒せる。撃たずに体当たりしてくる。
const ENEMY_HP := 1
const FALL_SINK_PX := 40.0  ## 奈落に落ちる演出で沈む量（0.5秒で）

var map: HeightMap
var rules := MovementRules.new()
var run: RunState
var area_state := AreaState.new()
var hotbar := Hotbar.new()
var menu: InventoryMenu
## 鉄球が落ちるマスに出す、地面の影のような印
var aim_marker: StackSprite
var camera: StackCamera
var player: Player
var ball: Ball
var enemies: Array[Enemy] = []
var checkpoint: Vector2i
var goal: Vector2i
var doors: Array = []
var _bullets: Array = []  # [Bullet, StackSprite]
var _pickup_nodes := {}   # 拾えるものの id → StackSprite
var _door_nodes: Array = []
var _grave_node: StackSprite
var _world: Node2D
var _status: Label  ## 左上：体力・持ち物・手に持つアイテム
var _message: Label  ## 真ん中：門のヒント・やられた・クリア
var _guide: Label  ## 下：操作の説明
## 再開した後、墓石の取り返し方を出しておく残り秒数
var _grave_hint_time := 0.0
const GRAVE_HINT_SECONDS := 6.0
## 始めたときに、どこを目指すかを出しておく残り秒数
var _start_hint_time := 8.0

func _ready() -> void:
	map = HeightMap.new(Vector2i(HEIGHTS[0].length(), HEIGHTS.size()))
	var info := Terrain.parse_layers(HEIGHTS, OBJECTS, map)
	checkpoint = info["checkpoint"]
	goal = info["goal"]
	doors = info["doors"]
	run = RunState.new(checkpoint)
	camera = StackCamera.new()
	add_child(camera)
	_world = Node2D.new()
	add_child(_world)
	Terrain.build(map, camera, _world, info["deco"])
	Terrain.add_background(self)
	_build_markers()

	player = Player.new()
	player.setup(map, rules, PLAYER_START, camera)
	_world.add_child(player)
	camera.follow(player.mover.pos, player.mover.height * StackSprite.LEVEL_PX, 1.0)

	ball = Ball.new()
	ball.setup(player, map, rules, camera)
	ball.rules_ball.landed.connect(_on_ball_landed)
	_world.add_child(ball)

	aim_marker = _marker(PLAYER_START, _aim_model(), 1)
	aim_marker.force_hidden = true

	_spawn_enemies()
	_build_ui()
	menu = InventoryMenu.new()
	menu.setup(run)
	menu.close_requested.connect(close_inventory)
	add_child(menu)
	_maybe_screenshot()

func _process(delta: float) -> void:
	if area_state.update(delta):
		respawn()
	_step_bullets(delta)
	if area_state.result == AreaState.Result.PLAYING:
		if player.hp <= 0 or player.mover.fell:
			kill_player(player.mover.fell)
		else:
			_play_step()
	if area_state.is_falling():
		player.lift_px = maxf(-FALL_SINK_PX, player.lift_px - FALL_SINK_PX / AreaState.FALL_SECONDS * delta)
	elif area_state.result == AreaState.Result.DYING and player.mover.fell:
		player.modulate.a = 0.0
	_update_aim()
	camera.follow(player.mover.pos, player.mover.height * StackSprite.LEVEL_PX, delta)
	_grave_hint_time = maxf(0.0, _grave_hint_time - delta)
	_start_hint_time = maxf(0.0, _start_hint_time - delta)
	_update_ui()

## 遊んでいる間の毎フレームの処理：拾う、チェックポイントで回復、ゴール、キー操作。
func _play_step() -> void:
	var c := player.mover.cell()
	for i in PICKUPS.size():
		var p = PICKUPS[i]
		if p[0] == c and run.collect(i, p[1], p[2]):
			_pickup_nodes[i].queue_free()
			_pickup_nodes.erase(i)
	if run.is_near_checkpoint(c) and player.hp < Player.MAX_HP:
		player.set_hp(Player.MAX_HP)
	if c == goal:
		area_state.on_goal()
	# 敵の体当たり（無敵の間は Player.take_hit が受けない）
	for e in enemies:
		if is_instance_valid(e) and e.walker.touches(player.mover.pos, player.mover.height):
			player.take_hit()
			break
	# 落とした鉄球は上を歩くだけで拾う
	ball.rules_ball.try_pick_up(player.mover)
	# インベントリで決めた鉄球は、手に持っているときに反映する
	if ball.rules_ball.state == IronBall.State.HELD:
		ball.rules_ball.set_strong(run.inventory.ball_is_strong())

func _unhandled_input(event: InputEvent) -> void:
	if area_state.result != AreaState.Result.PLAYING:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		use_item()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				hotbar.select_slot(1)
			KEY_2:
				hotbar.select_slot(2)
			KEY_F:
				try_open_door()
			KEY_TAB:
				open_inventory()
			_:
				return
		get_viewport().set_input_as_handled()

## 手に持っているアイテムを使う（左クリック）。鉄球ならカーソルの方向の目の前に落とす。
func use_item() -> bool:
	if area_state.result != AreaState.Result.PLAYING or not player.controllable:
		return false
	match hotbar.selected:
		Hotbar.Item.IRON_BALL:
			return ball.rules_ball.drop_at(player.mover, map, _aim_point())
		Hotbar.Item.HEAL:
			return use_heal()
	return false

func open_inventory() -> bool:
	if area_state.result != AreaState.Result.PLAYING:
		return false
	menu.open()
	_message.text = ""  # 止まっている間は真ん中の言葉を消す（メニューと重ならないように）
	get_tree().paused = true
	return true

func close_inventory() -> void:
	menu.close()
	get_tree().paused = false

## カーソルの方を向かせ、鉄球が落ちるマスに印を出す。
func _update_aim() -> void:
	var playing := area_state.result == AreaState.Result.PLAYING
	if playing:
		player.aim_screen = get_viewport().get_mouse_position()
	else:
		player.aim_screen = null
	var target := IronBall.reach_point(player.mover.pos, _aim_point())
	var show := playing and hotbar.selected == Hotbar.Item.IRON_BALL \
		and ball.rules_ball.state == IronBall.State.HELD and IronBall.can_drop_at(target, map)
	aim_marker.force_hidden = not show
	if show:
		aim_marker.world_pos = target
		aim_marker.base_height = map.get_height(HeightMap.world_to_cell(target))

## カーソルが指している地面の点。
func _aim_point() -> Vector2:
	return camera.pick_ground(get_viewport().get_mouse_position(), map, 8)

## 死亡処理を始める。墓石を置き（古い墓石は消える）、操作を止める。
func kill_player(fell: bool) -> void:
	if not area_state.on_player_died(fell):
		return
	var c := player.mover.last_safe_cell if fell else player.mover.cell()
	_remove_grave_marker()
	run.on_death(c)
	map.set_blocker(c, HeightMap.Blocker.GRAVE)
	_grave_node = _marker(c, _grave_model(), 2)
	player.controllable = false

## チェックポイントから再開する。敵は全員復活し、飛んでいる弾は消える。
## 拾い済みのもの・開けた扉・墓石はそのまま。
func respawn() -> void:
	for e in enemies:
		if is_instance_valid(e):
			# queue_free した敵も、このフレームの残りで _process が走って弾を撃てるので、先に切り離す
			e.shot.disconnect(_on_enemy_shot)
			e.set_process(false)
			e.queue_free()
	enemies.clear()
	_spawn_enemies()
	for b in _bullets:
		b[1].queue_free()
	_bullets.clear()
	ball.rules_ball.return_to_hand()
	ball.rules_ball.set_strong(run.inventory.ball_is_strong())  # 強い鉄球は墓石に入っているので普通に戻る
	player.mover.place(PLAYER_START)
	camera.focus_height = player.mover.height * StackSprite.LEVEL_PX  # 飛んで戻るので、画面をすべらせない
	player.set_hp(Player.MAX_HP)
	player.clear_invulnerable()
	player.lift_px = 0.0
	player.modulate.a = 1.0
	player.controllable = true
	if run.grave != null:
		_grave_hint_time = GRAVE_HINT_SECONDS

## 門の奥側の前のマス（DOOR_OPEN_FROM）に立っていれば、向きに関係なく開ける。開けたら true。
func try_open_door() -> bool:
	for i in doors.size():
		if run.is_door_open(i):
			continue
		if player.mover.cell() == DOOR_OPEN_FROM[i]:
			run.open_door(i)
			map.set_blocker(doors[i], HeightMap.Blocker.NONE)
			_door_nodes[i].queue_free()
			return true
	return false

func _can_open_door_here() -> bool:
	for i in doors.size():
		if not run.is_door_open(i) and player.mover.cell() == DOOR_OPEN_FROM[i]:
			return true
	return false

func use_heal() -> bool:
	if not run.inventory.try_use_heal(player.hp, Player.MAX_HP):
		return false
	player.set_hp(player.hp + 1)
	return true

func _spawn_enemies() -> void:
	for e in ENEMIES:
		var enemy := Enemy.new()
		enemy.setup(map, e[0], e[1], player, camera, Enemy.SHOOT_INTERVAL, ENEMY_HP)
		enemy.can_shoot = false
		enemy.shot.connect(_on_enemy_shot)
		enemy.walker.died.connect(run.on_enemy_killed)
		_world.add_child(enemy)
		enemies.append(enemy)

func _step_bullets(delta: float) -> void:
	for i in range(_bullets.size() - 1, -1, -1):
		var b: Bullet = _bullets[i][0]
		var s: StackSprite = _bullets[i][1]
		b.step(delta, map)
		var playing := area_state.result == AreaState.Result.PLAYING
		if playing and player.hp > 0 and b.hits(player.mover.pos, player.mover.height, BULLET_HIT_RADIUS):
			b.alive = false
			player.take_hit()
		if not b.alive or not map.in_bounds(HeightMap.world_to_cell(b.pos)):
			s.queue_free()
			_bullets.remove_at(i)
			continue
		s.world_pos = b.pos

func _on_enemy_shot(b: Bullet) -> void:
	if area_state.result != AreaState.Result.PLAYING:
		return
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = b.pos
	s.base_height = b.height
	s.lift_px = 3
	s.draw_bias = 3
	s.sort_by_cell = true
	s.set_model(VoxelModel.sphere(2, Color("ffd23f")))
	s.refresh()  # 最初のフレームから弾の位置に出す
	_world.add_child(s)
	_bullets.append([b, s])

func _on_ball_landed(land_pos: Vector2, damage: int) -> void:
	if run.grave != null and IronBall.touches_cell(land_pos, run.grave.cell):
		_remove_grave_marker()  # 墓石のマスを空けてから中身を戻す（break_grave で grave が null になるため）
		run.break_grave()
	for e in enemies:
		if is_instance_valid(e) and e.walker.alive and IronBall.hits(land_pos, ball.rules_ball.height, e.walker.pos, e.walker.height):
			e.walker.take_damage(damage)

func _remove_grave_marker() -> void:
	if run.grave != null:
		map.set_blocker(run.grave.cell, HeightMap.Blocker.NONE)
	if _grave_node != null:
		_grave_node.queue_free()
		_grave_node = null

## チェックポイント（たき火）、ゴール（旗）、扉、拾えるものを置く。
func _build_markers() -> void:
	_marker(checkpoint, _bonfire_model(), 1)
	_marker(goal, _flag_model(), 1)
	for d in doors:
		_door_nodes.append(_marker(d, _door_model(), 1))
	for i in PICKUPS.size():
		var p = PICKUPS[i]
		_pickup_nodes[i] = _marker(p[0], _pickup_model(p[1]), 1)

func _marker(cell: Vector2i, model: VoxelModel, bias: int) -> StackSprite:
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = HeightMap.cell_center(cell)
	s.base_height = map.get_height(cell)
	s.sort_by_cell = true
	s.draw_bias = bias
	s.set_model(model)
	s.refresh()
	_world.add_child(s)
	return s

func _aim_model() -> VoxelModel:
	return VoxelModel.box(Vector3i(14, 14, 1), Color(0, 0, 0, 0.35))

## 墓石：遠くからでも見つけやすい、背の高い白っぽい石。
func _grave_model() -> VoxelModel:
	var m := VoxelModel.box(Vector3i(10, 6, 22), Color("d8d4e8"))
	for z in range(14, 18):  # 十字の横棒
		for x in range(2, 8):
			m.set_voxel(Vector3i(x, 0, z), Color("6c5c9a"))
	for z in range(10, 21):
		m.set_voxel(Vector3i(4, 0, z), Color("6c5c9a"))
		m.set_voxel(Vector3i(5, 0, z), Color("6c5c9a"))
	return m

func _bonfire_model() -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(10, 10, 9)
	for y in 10:
		for x in 10:
			for z in 2:
				m.set_voxel(Vector3i(x, y, z), Color("5b3a22"))
	for z in range(2, 9):
		var r := 4 - z / 2
		for y in range(5 - r, 5 + r):
			for x in range(5 - r, 5 + r):
				m.set_voxel(Vector3i(x, y, z), Color("ff8c1a") if z < 6 else Color("ffd23f"))
	return m

## ゴール：石の台の上の、大きな旗。遠くからでも見つけやすいように高くする。
func _flag_model() -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(14, 14, 34)
	for z in 3:
		for y in range(1, 13):
			for x in range(1, 13):
				m.set_voxel(Vector3i(x, y, z), Color("c9c3b4") if (x + y + z) % 5 != 0 else Color("a8a293"))
	for z in range(3, 34):
		for y in range(6, 8):
			for x in range(6, 8):
				m.set_voxel(Vector3i(x, y, z), Color("f0efe8"))
	for z in range(23, 33):
		for x in range(8, 14):
			var c := Color("e8c23a") if (x + z) % 4 != 0 else Color("f5d96a")
			m.set_voxel(Vector3i(x, 6, z), c)
			m.set_voxel(Vector3i(x, 7, z), c)
	return m

func _door_model() -> VoxelModel:
	var m := VoxelModel.box(Vector3i(14, 14, 20), Color("7a5230"))
	for z in 20:
		for y in 14:
			m.set_voxel(Vector3i(6, y, z), Color("5b3a22"))
	return m

func _pickup_model(kind: RunState.PickupKind) -> VoxelModel:
	match kind:
		RunState.PickupKind.MONEY:
			return VoxelModel.box(Vector3i(4, 4, 2), Color("ffd23f"))
		RunState.PickupKind.MATERIAL:
			return VoxelModel.box(Vector3i(4, 4, 4), Color("a0785a"))
		RunState.PickupKind.HEAL:
			return VoxelModel.box(Vector3i(4, 4, 5), Color("ff6fa8"))
		_:
			return VoxelModel.sphere(4, Color("7a2230"))

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_status = UiText.label()
	_status.position = Vector2(4, 2)
	layer.add_child(_status)
	_message = UiText.label(true)
	_message.position = Vector2(0, 112)
	_message.size = Vector2(320, 40)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_message)
	_guide = UiText.label()
	_guide.position = Vector2(4, 166)
	_guide.modulate.a = 0.8
	_guide.text = "クリック:使う　1・2:持ちかえ　Tab:持ち物　右ドラッグ:カメラ"
	layer.add_child(_guide)
	_update_ui()

func _update_ui() -> void:
	var inv := run.inventory
	var hearts := ""
	for i in Player.MAX_HP:
		hearts += "●" if i < player.hp else "○"
	var text := "体力 %s　お金 %d　素材 %d　経験 %d\n" % [hearts, inv.money, inv.materials, inv.exp]
	var ball_name := "鉄球（強い）" if ball.rules_ball.strong else "鉄球"
	var heal_name := "回復×%d" % inv.heals
	if hotbar.selected == Hotbar.Item.IRON_BALL:
		text += "[1 %s]　 2 %s" % [ball_name, heal_name]
	else:
		text += " 1 %s　[2 %s]" % [ball_name, heal_name]
	_status.text = text
	_message.text = ui_message()

## 画面の真ん中に出す言葉。なければ空。
func ui_message() -> String:
	match area_state.result:
		AreaState.Result.DYING:
			return "やられた…\nたき火から やり直す"
		AreaState.Result.CLEAR:
			return "クリア！"
	if _can_open_door_here():
		return "F：門を開ける"
	if _grave_hint_time > 0.0:
		return "死んだ場所に墓石がある\n鉄球を落として壊すと、持ち物が戻る"
	if _start_hint_time > 0.0:
		return "WASD・矢印：移動\n島をめぐって、山の上の旗をめざそう"
	return ""

## `-- --screenshot=path.png` で数フレーム後に画面を保存して終了する（確認用）。
## `--angle=0.8` でカメラ角度、`--player=x,y` でプレイヤー位置を変えられる。`--fps` で平均FPSを出す。`--inventory` でインベントリを開いた画面。
func _maybe_screenshot() -> void:
	var path := ""
	var measure_fps := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screenshot="):
			path = a.trim_prefix("--screenshot=")
		elif a.begins_with("--angle="):
			camera.angle = float(a.trim_prefix("--angle="))
		elif a.begins_with("--player="):
			var p := a.trim_prefix("--player=").split(",")
			player.mover.place(Vector2i(int(p[0]), int(p[1])))
			camera.focus_height = player.mover.height * StackSprite.LEVEL_PX
		elif a == "--fps":
			measure_fps = true
		elif a == "--inventory":
			get_tree().create_timer(0.05).timeout.connect(open_inventory)
	if path == "":
		return
	var start := Time.get_ticks_msec()
	var frames := 120 if measure_fps else 10
	for i in frames:
		await get_tree().process_frame
	if measure_fps:
		print("FPS: %.1f" % (frames * 1000.0 / (Time.get_ticks_msec() - start)))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
