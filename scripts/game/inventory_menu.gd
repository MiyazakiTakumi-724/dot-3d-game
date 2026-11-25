class_name InventoryMenu
extends CanvasLayer
## インベントリ画面（design.md 11章。参考：Core Keeper）。Tab で開閉する。開いている間も世界は止まらない。
## 「装備」のページ：真ん中に主人公の姿、その左に武器の枠（鉄球・剣・弓・杖）、右に防具の枠。枠を選ぶと、右側に
## その種類の持っている品物が並び、クリックで装備するものを決める（杖なら、無の杖・炎の杖…から選ぶ）。下に持ち物（所持数は無限）。
## 「ステータス」のページ：レベルアップでもらったポイントを、6つの項目に振る。3ポイントごとに技能を覚える。
## 「持ち物」のページ：お金・道具・矢・素材の数と説明（2026-11-25 に足した）。

signal close_requested
## ポイントを振った・防具を替えた（体力の最大や足の速さを反映してもらう）
signal stats_changed
## 技能を覚えた（技能の名前）
signal skill_learned(skill: String)

enum Page { EQUIP, STATS, ITEMS, SETTINGS }

const PANEL_POS := Vector2(8, 6)
const PANEL_SIZE := Vector2(304, 168)
const PORTRAIT_CENTER := Vector2(92, 104)  ## パネルの中の、主人公の足元の位置
const PORTRAIT_SCALE := 4.0
const PORTRAIT_TURN := 0.8  ## 主人公の姿が回る速さ（1秒あたりのラジアン）

var run: RunState
var settings: GameSettings
var page: Page = Page.EQUIP
var selected_slot: Equipment.Slot = Equipment.Slot.BALL
var _panel: ColorRect
var _page_buttons := {}
var _equip_root: Control
var _stats_root: Control
var _slot_buttons := {}
var _detail_title: Label
var _rank_box: VBoxContainer
var _listed: Array = []  # 今並べている品物の id
var _items: Label
var _stats_header: Label
var _stat_rows := {}  # Stat → [points Label, + Button, effect Label, skill Label]
var _portrait_cam: StackCamera
var _portrait: StackSprite

func setup(r: RunState, s: GameSettings = null) -> void:
	run = r
	settings = s if s != null else GameSettings.new()
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	_panel.color = Color(0.05, 0.07, 0.1, 1.0)
	_panel.position = PANEL_POS
	_panel.size = PANEL_SIZE
	add_child(_panel)
	_page_buttons[Page.EQUIP] = _button(_panel, "装備", Vector2(4, 3), func(): show_page(Page.EQUIP))
	_page_buttons[Page.STATS] = _button(_panel, "ステータス", Vector2(42, 3), func(): show_page(Page.STATS))
	_page_buttons[Page.ITEMS] = _button(_panel, "持ち物", Vector2(130, 3), func(): show_page(Page.ITEMS))
	_page_buttons[Page.SETTINGS] = _button(_panel, "設定", Vector2(176, 3), func(): show_page(Page.SETTINGS))
	var hint := _label(_panel, "Tab：閉じる", Vector2(244, 6))
	hint.modulate.a = 0.7
	_build_equip_page()
	_build_stats_page()
	_build_items_page()
	_build_settings_page()
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
	_portrait.voxel_scale = HeroModel.VOXEL_SCALE
	_portrait.outline_color = Player.OUTLINE_COLOR
	_portrait.set_model(HeroModel.build("", ""))
	holder.add_child(_portrait)
	# 左に武器、右に防具の枠
	for i in Equipment.WEAPONS.size():
		var slot: Equipment.Slot = Equipment.WEAPONS[i]
		_slot_buttons[slot] = _button(_equip_root, "", Vector2(4, 26 + i * 20), func(): select_slot(slot))
	for i in Equipment.ARMOR.size():
		var slot: Equipment.Slot = Equipment.ARMOR[i]
		_slot_buttons[slot] = _button(_equip_root, "", Vector2(124, 56 + i * 20), func(): select_slot(slot))
	_detail_title = _label(_equip_root, "", Vector2(176, 26))
	# 品物が多くても収まるように、スクロールできる箱に並べる
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(176, 42)
	scroll.size = Vector2(124, 82)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_equip_root.add_child(scroll)
	_rank_box = VBoxContainer.new()
	_rank_box.add_theme_constant_override("separation", 2)
	scroll.add_child(_rank_box)
	_items = _label(_equip_root, "", Vector2(176, 128))

func _build_stats_page() -> void:
	_stats_root = _page_root()
	_stats_header = _label(_stats_root, "", Vector2(6, 26))
	var stats := [PlayerStats.Stat.VITALITY, PlayerStats.Stat.ATTACK, PlayerStats.Stat.SWORD,
		PlayerStats.Stat.BOW, PlayerStats.Stat.MAGIC, PlayerStats.Stat.MOVE]
	for i in stats.size():
		var stat: PlayerStats.Stat = stats[i]
		var y := 44 + i * 20
		_label(_stats_root, PlayerStats.NAMES[stat], Vector2(6, y + 3))
		var pts := _label(_stats_root, "", Vector2(62, y + 3))
		var plus := _button(_stats_root, "＋", Vector2(80, y), func(): allocate(stat))
		var effect := _label(_stats_root, "", Vector2(104, y + 3))
		var skill := _label(_stats_root, "", Vector2(190, y + 3))
		_stat_rows[stat] = [pts, plus, effect, skill]

var _settings_root: Control
var _difficulty_buttons := {}
var _flash_buttons := {}
var _items_root: Control
var _items_box: VBoxContainer

func _build_items_page() -> void:
	_items_root = _page_root()
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(6, 24)
	scroll.size = Vector2(292, 140)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_items_root.add_child(scroll)
	_items_box = VBoxContainer.new()
	_items_box.add_theme_constant_override("separation", 1)
	scroll.add_child(_items_box)

## 持ち物のページの行（テスト用にも使う）：お金、道具、矢、素材の順。
func item_lines() -> Array[String]:
	var inv := run.inventory
	var out: Array[String] = ["お金 %d" % inv.money]
	for id in inv.tools():
		out.append("%s ×%d　%s" % [ItemCatalog.name_of(id), inv.count(id), ItemCatalog.trait_of(id)])
	for k in Arrow.KINDS:
		if inv.arrow_count(k) > 0:
			out.append("%s ×%d" % [Arrow.NAMES[k], inv.arrow_count(k)])
	for id in inv.materials():
		out.append("%s ×%d　（素材）" % [ItemCatalog.name_of(id), inv.count(id)])
	return out

func _refresh_items() -> void:
	for c in _items_box.get_children():
		_items_box.remove_child(c)
		c.queue_free()
	for line in item_lines():
		_label(_items_box, line, Vector2.ZERO)
	if run.inventory.tools().size() > 0:
		var hint := _label(_items_box, "道具は 5 で持ち、ホイールで替えてクリックで使う", Vector2.ZERO)
		hint.modulate.a = 0.7

func _build_settings_page() -> void:
	_settings_root = _page_root()
	_label(_settings_root, "難易度", Vector2(6, 30))
	_difficulty_buttons[false] = _button(_settings_root, "", Vector2(60, 27), func(): set_easy(false))
	_difficulty_buttons[true] = _button(_settings_root, "", Vector2(124, 27), func(): set_easy(true))
	var note := _label(_settings_root, "簡単：敵から受けるダメージだけが半分になる。\nほかのルールは普通と同じ。", Vector2(6, 52))
	note.modulate.a = 0.75
	_label(_settings_root, "画面の光", Vector2(6, 90))
	_flash_buttons[false] = _button(_settings_root, "", Vector2(60, 87), func(): set_soft_flash(false))
	_flash_buttons[true] = _button(_settings_root, "", Vector2(124, 87), func(): set_soft_flash(true))
	var note2 := _label(_settings_root, "弱い：画面が白く光る演出を弱くする。", Vector2(6, 110))
	note2.modulate.a = 0.75

func set_soft_flash(v: bool) -> void:
	settings.soft_flash = v
	refresh()

func set_easy(v: bool) -> void:
	settings.easy_mode = v
	refresh()

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

## 品物 id を装備する。持っていなければ false。
func choose(id: String) -> bool:
	if not run.inventory.equipment.equip(id):
		return false
	stats_changed.emit()  # 防具なら最大いのちが変わる
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
	for k in Arrow.KINDS:
		var kind: Arrow.Kind = k
		var mark := "●" if inv.arrow_kind == kind else "○"
		var text := "%s %s ×%d" % [mark, Arrow.NAMES[kind], inv.arrow_count(kind)]
		if not Arrow.usable(kind, run.stats.skills_in(PlayerStats.Stat.BOW)):
			text += " 要技能"
		var b := _button(_rank_box, text, Vector2.ZERO, func(): choose_arrow(kind))
		b.disabled = not Arrow.usable(kind, run.stats.skills_in(PlayerStats.Stat.BOW))

func allocate(stat: PlayerStats.Stat) -> bool:
	var before := run.stats.skills_in(stat)
	if not run.stats.allocate(stat):
		return false
	var names: Array = PlayerStats.SKILLS.get(stat, [])
	var now := run.stats.skills_in(stat)
	if now > before and now <= names.size():
		skill_learned.emit(names[now - 1])
	stats_changed.emit()
	refresh()
	return true

## 武器の枠に出す名前。品物の名前（ランク2以上は★と数字）。何もなければ種類の名前と －。
static func weapon_label(slot: Equipment.Slot, id: String) -> String:
	if id == "":
		return "%s －" % Equipment.NAMES[slot]
	return ItemCatalog.label(id)

## 今並べている品物（テスト用）。
func listed_items() -> Array:
	return _listed.duplicate()

func refresh() -> void:
	_equip_root.visible = page == Page.EQUIP
	_stats_root.visible = page == Page.STATS
	_settings_root.visible = page == Page.SETTINGS
	_items_root.visible = page == Page.ITEMS
	var pts := run.stats.points
	_page_buttons[Page.STATS].text = "ステータス" + ("（%d）" % pts if pts > 0 else "")
	for p in _page_buttons:
		_page_buttons[p].modulate = Color.WHITE if p == page else Color(1, 1, 1, 0.55)
	match page:
		Page.EQUIP:
			_refresh_equip()
		Page.STATS:
			_refresh_stats()
		Page.ITEMS:
			_refresh_items()
		Page.SETTINGS:
			for easy in _difficulty_buttons:
				var on: bool = settings.easy_mode == easy
				_difficulty_buttons[easy].text = ("● " if on else "○ ") + ("簡単" if easy else "普通")
			for soft in _flash_buttons:
				var on: bool = settings.soft_flash == soft
				_flash_buttons[soft].text = ("● " if on else "○ ") + ("弱い" if soft else "ふつう")

## 主人公の姿に出す物：[手に持つ物, 防具]。鉄球・剣・弓・杖の枠を選んでいるときは、その枠の品物を持たせる。
func portrait_look() -> Array:
	var eq := run.inventory.equipment
	var held := ""
	if selected_slot in [Equipment.Slot.BALL, Equipment.Slot.SWORD, Equipment.Slot.BOW, Equipment.Slot.STAFF]:
		held = eq.current(selected_slot)
	return [held, eq.current(Equipment.Slot.ARMOR)]

func _refresh_equip() -> void:
	var eq := run.inventory.equipment
	var look := portrait_look()
	_portrait.set_model(HeroModel.build(look[0], look[1]))
	for slot in _slot_buttons:
		var b: Button = _slot_buttons[slot]
		b.text = weapon_label(slot, eq.current(slot))
		b.modulate = Color(1.0, 0.9, 0.5) if slot == selected_slot else Color.WHITE
	_detail_title.text = Equipment.NAMES[selected_slot] + ("（武器）" if Equipment.WEAPONS.has(selected_slot) else "")
	for c in _rank_box.get_children():
		_rank_box.remove_child(c)
		c.queue_free()
	_listed = eq.items(selected_slot)
	var in_grave: Array = []
	if run.grave != null:
		for id in run.grave.equipment:
			if ItemCatalog.slot(id) == selected_slot:
				in_grave.append(id)
	if _listed.is_empty() and in_grave.is_empty():
		var l := _label(_rank_box, "まだ持っていない", Vector2.ZERO)
		l.modulate.a = 0.7
	for id in _listed:
		var mark := "●" if id == eq.current(selected_slot) else "○"
		var rank := ItemCatalog.rank(id)
		var text := "%s %s ランク%d\n　つよさ＋%d" % [mark, ItemCatalog.name_of(id), rank, Equipment.rank_attack(rank)]
		if Equipment.ARMOR.has(selected_slot):
			text = "%s %s ランク%d\n　いのち＋%d" % [mark, ItemCatalog.name_of(id), rank, rank * Equipment.HP_PER_ARMOR_RANK + int(ItemCatalog.trait_value(id, "hp", 0))]
		var t := ItemCatalog.trait_of(id)
		if selected_slot == Equipment.Slot.STAFF:
			var names: Array[String] = []
			for sp in ItemCatalog.spells(id):
				names.append(Magic.NAMES[sp])
			t = "・".join(names)
		if t != "":
			text += "\n　" + t
		var item_id: String = id
		_button(_rank_box, text, Vector2.ZERO, func(): choose(item_id))
	for id in in_grave:
		var l := _label(_rank_box, "× %s：墓石の中" % ItemCatalog.label(id), Vector2.ZERO)
		l.modulate.a = 0.7
	if selected_slot == Equipment.Slot.BOW:
		_add_arrow_choices()
	var inv := run.inventory
	_items.text = "お金 %d　道具 %d種\n矢 ×%d　素材 %d種\n（くわしくは「持ち物」）" % [inv.money, inv.tools().size(),
		inv.arrow_count(Arrow.Kind.NORMAL), inv.materials().size()]

func _refresh_stats() -> void:
	var st := run.stats
	_stats_header.text = "Lv%d　経験 %d/%d　ポイント %d　（3ポイントで技能を1つ）" % [st.level, st.exp_in_level(), st.exp_level_span(), st.points]
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
			return "最大いのち %d" % st.max_hp()
		PlayerStats.Stat.ATTACK:
			return "つよさ %d" % st.attack()
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
	return "%sまで%d" % [names[learned], left]

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
