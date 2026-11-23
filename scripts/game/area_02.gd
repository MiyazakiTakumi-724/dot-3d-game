extends Node2D
## 試作2「死と取り返しの流れ」のエリア。死んでもシーンを読み込み直さず、中身を戻してチェックポイントから再開する。
## 操作：矢印/WASD 移動、右ドラッグ or Q/E カメラ回転、X 鉄球を落とす、Z 拾う・扉を開ける、C 回復、1/2 鉄球の切り替え

## 数字 = 高さ（段）、# = 壁、_ = 奈落、C = チェックポイント、D = 扉、G = ゴール
## 左上の安全地帯から、帯状の道を右・左と折り返して下へ進む。左端の縦の通路は、扉を開けると近道になる。
const LAYOUT := [
	"################################################",
	"#0000000000000012333333333210000000000000000000#",
	"#0C00000000000000033333333000000000000000000000#",
	"#0000000000000000000000000000000000000000000000#",
	"#00##########################################00#",
	"#00#0000000000000000000000000000000000000000000#",
	"#00#00000000000000#0000000#0000000#000000000000#",
	"#00#0000000000000000000000000000000000000000000#",
	"#00#00##########################################",
	"#00#0000001111111111222222222211111111110000000#",
	"#00#0000000000000000000000000000000000000000000#",
	"#00#0000000000000000000000000000000000000000000#",
	"#00##########################################00#",
	"#00#0000000000000000000000000122222222000000000#",
	"#00D0000000000000000000000000122222222000000000#",
	"#00#0000000000000000000000000000000000000000000#",
	"#00#00##########################################",
	"#00#00000000000_________________000000000000000#",
	"#00#00000000000_________________000000000000000#",
	"#00#0000000000000000000000000000000000000000000#",
	"#00##########################################00#",
	"#00#0000000000000000________0000000000000000000#",
	"#00#0000000000000000000000000000000000000000000#",
	"#00#0000000000000000________0000000000000000000#",
	"#00#00##########################################",
	"#00#000000000000000001233333333321000000000000G#",
	"#00#0000000000000000000000000000000000000000000#",
	"################################################",
]
const PLAYER_START := Vector2i(3, 2)
## [開始マス, 向き, 最初に撃つまでの秒数]
const ENEMIES := [
	[Vector2i(20, 3), Vector2.RIGHT, 1.5],
	[Vector2i(36, 2), Vector2.LEFT, 2.0],
	[Vector2i(30, 7), Vector2.LEFT, 1.8],
	[Vector2i(12, 5), Vector2.RIGHT, 2.4],
	[Vector2i(25, 10), Vector2.LEFT, 1.2],
	[Vector2i(8, 11), Vector2.RIGHT, 2.6],
	[Vector2i(33, 15), Vector2.LEFT, 1.6],
	[Vector2i(15, 13), Vector2.RIGHT, 2.2],
	[Vector2i(40, 17), Vector2.RIGHT, 1.5],
	[Vector2i(8, 18), Vector2.LEFT, 2.0],
	[Vector2i(35, 22), Vector2.LEFT, 1.7],
	[Vector2i(27, 26), Vector2.RIGHT, 1.4],
	[Vector2i(40, 25), Vector2.LEFT, 2.3],
]
## [マス, 種類, 量]。配列の添字を拾い済みの判定に使う。
const PICKUPS := [
	[Vector2i(10, 2), RunState.PickupKind.MONEY, 5],
	[Vector2i(30, 5), RunState.PickupKind.MONEY, 10],
	[Vector2i(44, 10), RunState.PickupKind.MONEY, 10],
	[Vector2i(10, 22), RunState.PickupKind.MONEY, 15],
	[Vector2i(35, 26), RunState.PickupKind.MONEY, 20],
	[Vector2i(22, 1), RunState.PickupKind.MATERIAL, 1],
	[Vector2i(40, 14), RunState.PickupKind.MATERIAL, 1],
	[Vector2i(30, 25), RunState.PickupKind.MATERIAL, 1],
	[Vector2i(44, 6), RunState.PickupKind.HEAL, 1],
	[Vector2i(6, 13), RunState.PickupKind.HEAL, 1],
	[Vector2i(44, 19), RunState.PickupKind.HEAL, 1],
	[Vector2i(5, 15), RunState.PickupKind.STRONG_BALL, 0],
]
## 扉を開けるときに立つ奥側のマス。Terrain.parse が返す doors と同じ順。
const DOOR_OPEN_FROM := [Vector2i(4, 14)]

var map: HeightMap
var rules := MovementRules.new()
var camera: StackCamera
var player: Player
var checkpoint: Vector2i
var goal: Vector2i
var doors: Array = []
var _world: Node2D

func _ready() -> void:
	map = HeightMap.new(Vector2i(LAYOUT[0].length(), LAYOUT.size()))
	var info := Terrain.parse(LAYOUT, map)
	checkpoint = info["checkpoint"]
	goal = info["goal"]
	doors = info["doors"]
	camera = StackCamera.new()
	add_child(camera)
	_world = Node2D.new()
	add_child(_world)
	Terrain.build(map, camera, _world)

	player = Player.new()
	player.setup(map, rules, PLAYER_START, camera)
	_world.add_child(player)
	_maybe_screenshot()

func _process(_delta: float) -> void:
	camera.focus = player.mover.pos

## `-- --screenshot=path.png` で数フレーム後に画面を保存して終了する（確認用）。
## `--angle=0.8` でカメラ角度、`--player=x,y` でプレイヤー位置を変えられる。`--fps` で平均FPSを出す。
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
		elif a == "--fps":
			measure_fps = true
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
