class_name InventoryMenu
extends CanvasLayer
## インベントリ画面（design.md 11章。参考：Core Keeper）。Tab で開閉する。開いている間も世界は止まらない。
## 「装備」のページ：真ん中に主人公の姿、その左に武器の枠、右に防具の枠。枠を選ぶと、右側に持っているランクが並び、
## クリックで装備するランクを決める。下に持ち物（所持数は無限）。
## 「ステータス」のページ：レベルアップでもらったポイントを、6つの項目に振る。3ポイントごとに技能を覚える。

signal close_requested
## ポイントを振った（体力の最大や足の速さを反映してもらう）
signal stats_changed

enum Page { EQUIP, STATS }

const PANEL_POS := Vector2(8, 6)
const PANEL_SIZE := Vector2(304, 168)
const PORTRAIT_CENTER := Vector2(92, 104)  ## パネルの中の、主人公の足元の位置
const PORTRAIT_SCALE := 4.0
const PORTRAIT_TURN := 0.8  ## 主人公の姿が回る速さ（1秒あたりのラジアン）

## ランクごとの特性（design.md 7章）。ここに足していく。
const TRAITS := {
	Equipment.Slot.BALL: {2: "当たる範囲が広い"},
}

var run: RunState
var page: Page = Page.EQUIP
var selected_slot: Equipment.Slot = Equipment.Slot.BALL
var _panel: ColorRect
var _page_buttons := {}
var _equip_root: Control
var _stats_root: Control
var _slot_buttons := {}
var _detail_title: Label
var _rank_box: VBoxContainer
var _items: Label
var _stats_header: Label
var _stat_rows := {}  # Stat → [points Label, + Button, effect Label, skill Label]
var _portrait_cam: StackCamera
var _portrait: StackSprite

func setup(r: RunState) -> void:
	run = r
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	_panel.color = Color(0.05, 0.07, 0.1, 1.0)
	_panel.position = PANEL_POS
	_panel.size = PANEL_SIZE
	add_child(_panel)
	_page_buttons[Page.EQUIP] = _button(_panel, "装備", Vector2(4, 3), func(): show_page(Page.EQUIP))
	_page_buttons[Page.STATS] = _button(_panel, "ステータス", Vector2(42, 3), func(): show_page(Page.STATS))
	var hint := _label(_panel, "Tab：閉じる", Vector2(244, 6))
	hint.modulate.a = 0.7
	_build_equip_page()
	_build_stats_page()
	_panel.hide()

func _build_equip_page() -> void:
	_equip_root = _page_root()
	# 主人公の姿（ゆっくり回る）。輪切りを重ねる描き方はゲームの中と同じで、整数倍に大きくする。
	_portrait_cam = StackCamera.new()
	_portrait_cam.set_process(false)
	_portrait_cam.set_process_unhandled_input(false)
	add_child(_portrait_cam)
	var holder := Node2D.new()
	holder.scale = Vector2.ONE * PORTRAIT_SCALE
	holder.position = PORTRAIT_CENTER - StackCamera.SCREEN_CENTER * PORTRAIT_SCALE
	_equip_root.add_child(holder)
	_portrait = StackSprite.new()
	_portrait.camera = _portrait_cam
	_portrait.always_redraw = true
	_portrait.shadow_radius = 4.0
	_portrait.set_model(Player.body_model())
	holder.add_child(_portrait)
	# 左に武器、右に防具の枠
	for i in Equipment.WEAPONS.size():
		var slot: Equipment.Slot = Equipment.WEAPONS[i]
		_slot_buttons[slot] = _button(_equip_root, "", Vector2(4, 26 + i * 20), func(): select_slot(slot))
	for i in Equipment.ARMOR.size():
		var slot: Equipment.Slot = Equipment.ARMOR[i]
		_slot_buttons[slot] = _button(_equip_root, "", Vector2(124, 36 + i * 20), func(): select_slot(slot))
	_detail_title = _label(_equip_root, "", Vector2(176, 26))
	_rank_box = VBoxContainer.new()
	_rank_box.position = Vector2(176, 42)
	_rank_box.add_theme_constant_override("separation", 2)
	_equip_root.add_child(_rank_box)
	_items = _label(_equip_root, "", Vector2(176, 120))

func _build_stats_page() -> void:
	_stats_root = _page_root()
	_stats_header = _label(_stats_root, "", Vector2(6, 26))
	var stats := [PlayerStats.Stat.VITALITY, PlayerStats.Stat.ATTACK, PlayerStats.Stat.SWORD,
		PlayerStats.Stat.BOW, PlayerStats.Stat.GUN, PlayerStats.Stat.MOVE]
	for i in stats.size():
		var stat: PlayerStats.Stat = stats[i]
		var y := 44 + i * 20
		_label(_stats_root, PlayerStats.NAMES[stat], Vector2(6, y + 3))
		var pts := _label(_stats_root, "", Vector2(62, y + 3))
		var plus := _button(_stats_root, "＋", Vector2(80, y), func(): allocate(stat))
		var effect := _label(_stats_root, "", Vector2(104, y + 3))
		var skill := _label(_stats_root, "", Vector2(186, y + 3))
		_stat_rows[stat] = [pts, plus, effect, skill]

func _page_root() -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size = PANEL_SIZE
	_panel.add_child(c)
	return c

func is_open() -> bool:
	return _panel.visible

func open() -> void:
	refresh()
	_panel.show()

func close() -> void:
	_panel.hide()

func show_page(p: Page) -> void:
	page = p
	refresh()

func select_slot(slot: Equipment.Slot) -> void:
	selected_slot = slot
	refresh()

## 選んでいる枠の、rank のものを装備する。持っていなければ false。
func choose(rank: int) -> bool:
	if not run.inventory.equipment.equip(selected_slot, rank):
		return false
	refresh()
	return true

## 撃つ矢の種類を選ぶ。使えない種類（技能がない）は選べない。
func choose_arrow(kind: Arrow.Kind) -> bool:
	if not Arrow.usable(kind, run.stats.skills_in(PlayerStats.Stat.BOW)):
		return false
	run.inventory.arrow_kind = kind
	refresh()
	return true

func _add_arrow_choices() -> void:
	var inv := run.inventory
	_label(_rank_box, "撃つ矢", Vector2.ZERO)
	for k in [Arrow.Kind.NORMAL, Arrow.Kind.POISON]:
		var kind: Arrow.Kind = k
		var mark := "●" if inv.arrow_kind == kind else "○"
		var text := "%s %s ×%d" % [mark, Arrow.NAMES[kind], inv.arrow_count(kind)]
		if not Arrow.usable(kind, run.stats.skills_in(PlayerStats.Stat.BOW)):
			text += "（技能で使える）"
		var b := _button(_rank_box, text, Vector2.ZERO, func(): choose_arrow(kind))
		b.disabled = not Arrow.usable(kind, run.stats.skills_in(PlayerStats.Stat.BOW))

func allocate(stat: PlayerStats.Stat) -> bool:
	if not run.stats.allocate(stat):
		return false
	stats_changed.emit()
	refresh()
	return true

## 武器の枠に出す名前。ランク2以上は★と数字を付ける。
static func weapon_label(slot: Equipment.Slot, rank: int) -> String:
	if rank <= 0:
		return "%s －" % Equipment.NAMES[slot]
	if rank == 1:
		return Equipment.NAMES[slot]
	return "%s★%d" % [Equipment.NAMES[slot], rank]

func refresh() -> void:
	_equip_root.visible = page == Page.EQUIP
	_stats_root.visible = page == Page.STATS
	var pts := run.stats.points
	_page_buttons[Page.STATS].text = "ステータス" + ("（%d）" % pts if pts > 0 else "")
	for p in _page_buttons:
		_page_buttons[p].modulate = Color.WHITE if p == page else Color(1, 1, 1, 0.55)
	if page == Page.EQUIP:
		_refresh_equip()
	else:
		_refresh_stats()

func _refresh_equip() -> void:
	var eq := run.inventory.equipment
	for slot in _slot_buttons:
		var b: Button = _slot_buttons[slot]
		b.text = weapon_label(slot, eq.effective(slot))
		b.modulate = Color(1.0, 0.9, 0.5) if slot == selected_slot else Color.WHITE
	_detail_title.text = Equipment.NAMES[selected_slot] + ("（武器）" if Equipment.WEAPONS.has(selected_slot) else "の防具")
	for c in _rank_box.get_children():
		_rank_box.remove_child(c)
		c.queue_free()
	var ranks := eq.ranks(selected_slot)
	var grave_ranks: Array = []
	if run.grave != null:
		grave_ranks = run.grave.equipment.get(selected_slot, [])
	if ranks.is_empty() and grave_ranks.is_empty():
		var l := _label(_rank_box, "まだ持っていない", Vector2.ZERO)
		l.modulate.a = 0.7
	for rank in ranks:
		var mark := "●" if rank == eq.effective(selected_slot) else "○"
		var text := "%s ランク%d　攻撃＋%d" % [mark, rank, Equipment.rank_attack(rank)]
		var t: String = TRAITS.get(selected_slot, {}).get(rank, "")
		if t != "":
			text += "\n　" + t
		var r: int = rank
		_button(_rank_box, text, Vector2.ZERO, func(): choose(r))
	for rank in grave_ranks:
		var l := _label(_rank_box, "× ランク%d：墓石の中にある" % rank, Vector2.ZERO)
		l.modulate.a = 0.7
	if selected_slot == Equipment.Slot.BOW:
		_add_arrow_choices()
	var inv := run.inventory
	_items.text = "回復 ×%d　素材 ×%d\n矢 ×%d　毒矢 ×%d　弾 ×%d\nお金 %d" % [inv.heals, inv.materials,
		inv.arrow_count(Arrow.Kind.NORMAL), inv.arrow_count(Arrow.Kind.POISON), inv.ammo, inv.money]

func _refresh_stats() -> void:
	var st := run.stats
	_stats_header.text = "Lv%d　経験 %d/%d　ポイント %d　（3ポイントごとに技能）" % [st.level, st.exp_in_level(), st.exp_level_span(), st.points]
	for stat in _stat_rows:
		var row: Array = _stat_rows[stat]
		var n := st.points_in(stat)
		row[0].text = str(n)
		row[1].disabled = st.points <= 0
		row[2].text = _effect_text(stat)
		row[3].text = _skill_text(stat)

func _effect_text(stat: PlayerStats.Stat) -> String:
	var st := run.stats
	match stat:
		PlayerStats.Stat.VITALITY:
			return "最大体力 %d" % st.max_hp()
		PlayerStats.Stat.ATTACK:
			return "攻撃力 %d" % st.attack()
		PlayerStats.Stat.MOVE:
			return "足の速さ＋%d%%" % roundi((st.move_speed_mult() - 1.0) * 100.0)
	return "威力＋%d%%" % (st.points_in(stat) * 10)

## 技能の欄：覚えた数と、次に覚える技能まであと何ポイントか。
func _skill_text(stat: PlayerStats.Stat) -> String:
	var names: Array = PlayerStats.SKILLS.get(stat, [])
	if names.is_empty():
		return ""
	var st := run.stats
	var learned := mini(st.skills_in(stat), names.size())
	if learned >= names.size():
		return "技能をすべて覚えた"
	var left := PlayerStats.POINTS_PER_SKILL - st.points_in(stat) % PlayerStats.POINTS_PER_SKILL
	return "次：%s（あと%d）" % [names[learned], left]

func _process(delta: float) -> void:
	if is_open() and page == Page.EQUIP:
		_portrait_cam.angle = wrapf(_portrait_cam.angle + PORTRAIT_TURN * delta, -PI, PI)

func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_TAB or event.physical_keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		close_requested.emit()

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
	b.text = text
	b.position = pos
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiText.style_button(b)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b
