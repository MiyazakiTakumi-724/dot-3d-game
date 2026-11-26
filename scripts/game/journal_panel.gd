class_name JournalPanel
extends Control
## 記録のページ（2026-11-26 独自の開発1）【提案】。インベントリ画面の「記録」。テラリアの図鑑やコアキーパーの記録のように、
## 見つけたもの・倒したものを読み返せる。3つの欄：記憶のかけら（12。番号を押すと言葉）・魔物の図鑑（倒した数と弱点）・装飾品。

enum Tab { FRAGMENTS, BESTIARY, CHARMS }

const SIZE := Vector2(304, 144)

var run: RunState
var tab: Tab = Tab.FRAGMENTS
var selected_fragment := 0
var _tab_buttons := {}
var _frag_root: Control
var _frag_buttons: Array[Button] = []
var _frag_head: Label
var _frag_text: Label
var _list_root: Control
var _list_box: VBoxContainer

func setup(r: RunState) -> void:
	run = r
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tab_buttons[Tab.FRAGMENTS] = _button(self, "記憶のかけら", Vector2(6, 0), func(): show_tab(Tab.FRAGMENTS))
	_tab_buttons[Tab.BESTIARY] = _button(self, "魔物の図鑑", Vector2(80, 0), func(): show_tab(Tab.BESTIARY))
	_tab_buttons[Tab.CHARMS] = _button(self, "装飾品", Vector2(144, 0), func(): show_tab(Tab.CHARMS))
	# 記憶のかけら：左に番号（2列×6）、右に言葉
	_frag_root = Control.new()
	_frag_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frag_root)
	_frag_head = _label(_frag_root, "", Vector2(6, 18))
	for i in Story.FRAGMENTS.size():
		var n := i + 1
		var b := _button(_frag_root, "", Vector2(6 + (i / 6) * 44, 32 + (i % 6) * 17), func(): select_fragment(n))
		b.custom_minimum_size = Vector2(40, 15)
		_frag_buttons.append(b)
	_frag_text = _label(_frag_root, "", Vector2(96, 34))
	_frag_text.size = Vector2(204, 100)
	_frag_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # 言葉の間の空白で折り返す
	# 図鑑と装飾品：スクロールする行
	_list_root = Control.new()
	_list_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_list_root)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(6, 18)
	scroll.size = Vector2(292, 124)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_root.add_child(scroll)
	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 1)
	scroll.add_child(_list_box)
	refresh()

func show_tab(t: Tab) -> void:
	tab = t
	refresh()

func select_fragment(n: int) -> void:
	if run.flags.get(Story.fragment_flag(n), false):
		selected_fragment = n
	refresh()

func refresh() -> void:
	if run == null:
		return
	for t in _tab_buttons:
		_tab_buttons[t].modulate = Color(1.0, 0.92, 0.6) if t == tab else Color(1, 1, 1, 0.6)
	_frag_root.visible = tab == Tab.FRAGMENTS
	_list_root.visible = tab != Tab.FRAGMENTS
	match tab:
		Tab.FRAGMENTS:
			_refresh_fragments()
		Tab.BESTIARY:
			_fill(bestiary_rows(run))
		Tab.CHARMS:
			_fill(charm_rows(run))

func _refresh_fragments() -> void:
	var got := Story.fragment_count(run.flags)
	_frag_head.text = "ガルドの記憶　%d / %d　（幻の橋の向こうにある）" % [got, Story.FRAGMENTS.size()]
	for i in _frag_buttons.size():
		var n := i + 1
		var have: bool = run.flags.get(Story.fragment_flag(n), false)
		_frag_buttons[i].text = ("%d ★" % n) if have else ("%d ？" % n)
		_frag_buttons[i].disabled = not have
		_frag_buttons[i].modulate = Color(1.0, 0.92, 0.6) if n == selected_fragment else Color.WHITE
	if selected_fragment > 0:
		_frag_text.text = Story.fragment(selected_fragment)
	elif got > 0:
		_frag_text.text = "番号を押すと、かけらの記憶を読み返せる。"
	else:
		_frag_text.text = "まだ ひとつも 見つけていない。\n床の瞳の印を 探し、その目が 向く方を 画面の上にして 見てみよう。"

func _fill(rows: Array) -> void:
	for c in _list_box.get_children():
		_list_box.remove_child(c)
		c.queue_free()
	for r in rows:
		var l := _label(_list_box, r[0], Vector2.ZERO)
		if r[1]:
			l.modulate = Color(1, 1, 1, 0.45)

## 魔物の図鑑の行 [文字, うすく出すか]。倒したことのない魔物は名前を伏せる。
static func bestiary_rows(r: RunState) -> Array:
	var out: Array = []
	var seen := 0
	for k in EnemyKind.DATA:
		if int(r.kills.get(k, 0)) > 0:
			seen += 1
	out.append(["倒した魔物の種類　%d / %d" % [seen, EnemyKind.DATA.size()], false])
	for k in EnemyKind.DATA:
		var n := int(r.kills.get(k, 0))
		if n == 0:
			out.append(["？？？", true])
			continue
		var weak: Array = []
		var resist: Array = []
		for src in EnemyKind.AFFINITY.get(k, {}):
			var m: float = EnemyKind.AFFINITY[k][src]
			(weak if m > 1.0 else resist).append(BossGuard.SOURCE_NAMES.get(src, src))
		var line := "%s　×%d" % [EnemyKind.DATA[k][0], n]
		if not weak.is_empty():
			line += "　弱点：" + "・".join(weak)
		if not resist.is_empty():
			line += "　効きにくい：" + "・".join(resist)
		if EnemyKind.knock_mult(k) <= 0.0:
			line += "　押せない"
		out.append([line, false])
	return out

## 装飾品の行。持っていない物は、ありかの手がかりだけ。
static func charm_rows(r: RunState) -> Array:
	var out: Array = [["装飾品　%d / %d　（持っているだけで効く）" % [Charms.owned(r.inventory), Charms.ALL.size()], false]]
	for id in Charms.ALL:
		if Charms.has(r.inventory, id):
			out.append(["%s：%s" % [ItemCatalog.name_of(id), ItemCatalog.KEYS[id]["info"].trim_prefix("装飾品。")], false])
		else:
			out.append(["？？？　" + ("町の道具屋に ありそうだ" if id == Charms.QUIVER else "幻の橋の向こうに ありそうだ"), true])
	return out

func _label(parent: Node, text: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiText.style(l)
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, pos: Vector2, on_press: Callable) -> Button:
	var b := Button.new()
	UiText.style_button(b)
	b.text = text
	b.position = pos
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b
