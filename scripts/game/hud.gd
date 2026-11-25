class_name Hud
extends Control
## 遊んでいる間の画面の表示（2026-11-25 夜の設計 1章）。
## 左上：いのちのバー（赤）とマナのバー（青）と数、細い経験値のバー、レベル・お金・薬の残り・墓石のあるエリア。
## 下の真ん中：手に持つ物の5つの箱（アイコンと番号。持っていない武器は暗い）。選んでいる物の名前は箱の上。
## 杖を持つと、使える魔法を小さな箱で並べ、待ち時間の間は箱が暗くなって残り秒を出す（マナが足りなければ赤い印）。

const BAR_POS := Vector2(15, 3)
const BAR_W := 72.0
const BAR_H := 5.0
const SLOT := 20.0
const SLOT_GAP := 3.0
const HOTBAR_Y := 157.0
const SPELL := 14.0

const HP_COLOR := Color("e04a4a")
const MANA_COLOR := Color("3a8ae8")
const EXP_COLOR := Color("e8c84a")
const BAR_BG := Color(0.08, 0.06, 0.08, 0.85)
const SLOT_BG := Color(0.07, 0.08, 0.11, 0.8)

## 魔法の箱の色
const SPELL_COLORS := {
	Magic.Spell.NULL_BOLT: Color("d8d8e8"),
	Magic.Spell.FIREBALL: Color("ff7a2a"),
	Magic.Spell.FIRE_PILLAR: Color("ff4a1a"),
	Magic.Spell.FIRE_RAIN: Color("ffb03a"),
	Magic.Spell.ICE_SHARD: Color("8ad8ff"),
	Magic.Spell.THUNDER: Color("fff04a"),
	Magic.Spell.HEAL: Color("7aff9a"),
}

var field: Node

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(320, 180)

func _process(_delta: float) -> void:
	queue_redraw()

func _font() -> Font:
	return UiText.SMALL_FONT

func _text(pos: Vector2, text: String, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f := _font()
	draw_string_outline(f, pos, text, align, width, 10, 2, UiText.OUTLINE_COLOR)
	draw_string(f, pos, text, align, width, 10, color)

func _bar(pos: Vector2, w: float, h: float, rate: float, color: Color) -> void:
	draw_rect(Rect2(pos - Vector2.ONE, Vector2(w + 2, h + 2)), UiText.OUTLINE_COLOR)
	draw_rect(Rect2(pos, Vector2(w, h)), BAR_BG)
	if rate > 0.0:
		draw_rect(Rect2(pos, Vector2(maxf(1.0, w * clampf(rate, 0.0, 1.0)), h)), color)
		draw_rect(Rect2(pos, Vector2(maxf(1.0, w * clampf(rate, 0.0, 1.0)), 1)), color.lightened(0.35))

func _draw() -> void:
	if field == null or field.player == null:
		return
	_draw_status()
	_draw_hotbar()

func _draw_status() -> void:
	var p: Player = field.player
	var run: RunState = field.run
	var mana: Mana = field.mana
	# いのち
	_heart(Vector2(4, 2))
	_bar(BAR_POS, BAR_W, BAR_H, float(p.hp) / maxf(1.0, p.max_hp), HP_COLOR)
	_text(BAR_POS + Vector2(BAR_W + 4, 7), "%d/%d" % [p.hp, p.max_hp])
	# マナ
	_drop(Vector2(4, 11))
	_bar(BAR_POS + Vector2(0, 9), BAR_W, BAR_H, mana.value / maxf(1.0, mana.max_value), MANA_COLOR)
	_text(BAR_POS + Vector2(BAR_W + 4, 16), "%d/%d" % [floori(mana.value), mana.max_value])
	# 経験値とレベル・お金
	var st := run.stats
	_bar(BAR_POS + Vector2(0, 18), BAR_W, 2, float(st.exp_in_level()) / maxf(1.0, st.exp_level_span()), EXP_COLOR)
	var line := "Lv%d　%dG" % [st.level, run.inventory.money]
	if st.points > 0:
		line += "　ポイント%d" % st.points
	_text(Vector2(4, 32), line)
	var extra: Array[String] = []
	var buffs: Buffs = field.buffs
	for k in buffs.active():
		extra.append("%s%d" % [{"atk": "力", "def": "守", "speed": "速"}[k], ceili(buffs.remaining(k))])
	if run.grave != null:
		extra.append("墓石：%s" % field.world.area(run.grave.area_id).title)
	if not extra.is_empty():
		_text(Vector2(4, 42), "　".join(extra), Color("d8e0f0"))

func _heart(at: Vector2) -> void:
	for r in [Rect2(1, 1, 2, 2), Rect2(5, 1, 2, 2), Rect2(0, 2, 8, 3), Rect2(1, 5, 6, 1), Rect2(2, 6, 4, 1), Rect2(3, 7, 2, 1)]:
		draw_rect(Rect2(at + r.position, r.size), HP_COLOR)

func _drop(at: Vector2) -> void:
	for r in [Rect2(3, 0, 2, 2), Rect2(2, 2, 4, 2), Rect2(1, 4, 6, 3), Rect2(2, 7, 4, 1)]:
		draw_rect(Rect2(at + r.position, r.size), MANA_COLOR)

## 手に持つ物の箱の左上の位置（i は0始まり）
static func slot_pos(i: int) -> Vector2:
	var total := 5 * SLOT + 4 * SLOT_GAP
	return Vector2((320.0 - total) * 0.5 + i * (SLOT + SLOT_GAP), HOTBAR_Y)

func _draw_hotbar() -> void:
	var hb: Hotbar = field.hotbar
	for i in Hotbar.SLOTS.size():
		var item: Hotbar.Item = Hotbar.SLOTS[i]
		var info: Dictionary = field.hotbar_slot(item)
		var at := slot_pos(i)
		var sel: bool = item == hb.selected
		var id: String = info.get("id", "")
		var frame := Color("f0e0a0") if sel else (ItemIcons.rank_color(id) if id != "" else Color("3a3f4a"))
		draw_rect(Rect2(at - Vector2.ONE, Vector2(SLOT + 2, SLOT + 2)), UiText.OUTLINE_COLOR)
		draw_rect(Rect2(at, Vector2(SLOT, SLOT)), Color(0.18, 0.2, 0.26, 0.92) if sel else SLOT_BG)
		draw_rect(Rect2(at, Vector2(SLOT, SLOT)), frame, false, 1.0)
		if sel:
			draw_rect(Rect2(at + Vector2.ONE, Vector2(SLOT - 2, SLOT - 2)), frame.darkened(0.3), false, 1.0)
		if id != "":
			draw_texture(ItemIcons.texture(id), at + Vector2(2, 2), Color.WHITE if info.get("ok", true) else Color(1, 1, 1, 0.35))
		_text(at + Vector2(1, 8), str(i + 1), Color("c8d0e0") if not sel else Color.WHITE)
		if info.has("count"):
			_text(at + Vector2(0, SLOT + 1), str(info["count"]), Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, SLOT)
	# 選んでいる物の名前（箱の上）
	var cur: Dictionary = field.hotbar_slot(hb.selected)
	var name_y := HOTBAR_Y - 3.0
	if hb.selected == Hotbar.Item.STAFF:
		name_y = _draw_spells() - 3.0
	_text(Vector2(0, name_y), cur.get("name", ""), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 320)

## 杖の魔法の箱を並べ、いちばん上の y を返す。
func _draw_spells() -> float:
	var list: Array = field.usable_spells()
	if list.is_empty():
		return HOTBAR_Y
	var magic: Magic = field.magic
	var cur: int = field.current_spell()
	var total := list.size() * SPELL + (list.size() - 1) * 3.0
	var x0 := (320.0 - total) * 0.5
	var y := HOTBAR_Y - SPELL - 5.0
	for i in list.size():
		var sp: int = list[i]
		var at := Vector2(x0 + i * (SPELL + 3.0), y)
		var sel := sp == cur
		draw_rect(Rect2(at - Vector2.ONE, Vector2(SPELL + 2, SPELL + 2)), UiText.OUTLINE_COLOR)
		draw_rect(Rect2(at, Vector2(SPELL, SPELL)), SLOT_BG)
		var c: Color = SPELL_COLORS.get(sp, Color.WHITE)
		draw_circle(at + Vector2(SPELL, SPELL) * 0.5, SPELL * 0.3, c)
		draw_circle(at + Vector2(SPELL, SPELL) * 0.5 - Vector2(1, 1), SPELL * 0.12, c.lightened(0.5))
		var left := magic.remaining(sp)
		if left > 0.0:
			var rate := left / float(Magic.COOLDOWN[sp])
			draw_rect(Rect2(at, Vector2(SPELL, SPELL * rate)), Color(0, 0, 0, 0.7))
			_text(at + Vector2(0, 11), str(ceili(left)), Color("ffe080"), HORIZONTAL_ALIGNMENT_CENTER, SPELL)
		elif field.mana.value < Magic.cost_of(sp, field.spell_cost_mult()):
			draw_rect(Rect2(at + Vector2(SPELL - 4, SPELL - 4), Vector2(3, 3)), Color("ff4a4a"))
		draw_rect(Rect2(at, Vector2(SPELL, SPELL)), Color("f0e0a0") if sel else Color("4a5060"), false, 1.0)
	return y
