class_name ItemTip
extends ColorRect
## 品物にカーソルを合わせたときに出す、詳しい説明の箱（2026-11-25 夜の設計 2章）。
## 持ち物のページ・装備のページ・お店の画面で使う。show_item(id, 数) で出し、hide_tip() で消す。

const PAD := Vector2(4, 3)
const MAX_W := 170.0

var _title: Label
var _body: Label
## 今出している品物の id（テスト用）
var item_id := ""
## 装備のレベルの制限を見るのに使う（なければ制限を出さない）
var stats: PlayerStats

func _init() -> void:
	color = Color(0.03, 0.04, 0.06, 0.96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	_title = UiText.label()
	_title.position = PAD
	add_child(_title)
	_body = UiText.label()
	_body.position = PAD + Vector2(0, 12)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size.x = MAX_W - PAD.x * 2
	_body.modulate = Color(0.85, 0.9, 1.0)
	add_child(_body)
	hide()

## 箱に出す文：[1行目, 本文]。
func texts(id: String, count := 0) -> Array:
	var head := ItemCatalog.label(id)
	if ItemCatalog.exists(id):
		head += "　ランク%d" % ItemCatalog.rank(id)
		head += "　%s" % Equipment.NAMES[ItemCatalog.slot(id)]
	elif count > 1:
		head += " ×%d" % count
	var body := ItemCatalog.describe(id)
	if ItemCatalog.exists(id):
		var r := ItemCatalog.rank(id)
		var base := "つよさ＋%d" % Equipment.rank_attack(r)
		if ItemCatalog.slot(id) == Equipment.Slot.ARMOR:
			base = "いのち＋%d" % (r * Equipment.HP_PER_ARMOR_RANK + int(ItemCatalog.trait_value(id, "hp", 0)))
		body = base + "\n" + body
		if stats != null and ItemCatalog.required_level(id) > stats.level:
			body += "\n（今は Lv%d。まだ装備できない）" % stats.level
	return [head, body]

## 品物の説明を、画面の点 at のそばに出す（画面からはみ出さないようにずらす）。
func show_item(id: String, count := 0, at := Vector2.ZERO) -> void:
	item_id = id
	var t := texts(id, count)
	_title.text = t[0]
	_title.modulate = ItemIcons.rank_color(id).lightened(0.45) if ItemCatalog.exists(id) else Color.WHITE
	_body.text = t[1]
	_body.size = Vector2.ZERO
	_title.size = Vector2.ZERO
	var w := maxf(_title.get_minimum_size().x, minf(MAX_W - PAD.x * 2, _body.get_minimum_size().x)) + PAD.x * 2
	_body.size.x = w - PAD.x * 2
	var h := 12.0 + _body.get_minimum_size().y + PAD.y * 2
	size = Vector2(w, h)
	var p := at + Vector2(10, 8)
	if p.x + w > 318.0:
		p.x = at.x - w - 6.0
	if p.y + h > 178.0:
		p.y = 178.0 - h
	position = p - (get_parent().global_position if get_parent() is Control else Vector2.ZERO)
	show()

func hide_tip() -> void:
	item_id = ""
	hide()

## カーソルを合わせると tip に説明が出る、アイコンの箱（20×20）。count が1より大きければ右下に数。
static func make_slot(id: String, count: int, tip: ItemTip, on_press := Callable(), dim := false) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(20, 20)
	b.focus_mode = Control.FOCUS_NONE
	b.icon = ItemIcons.texture(id)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var frame := ItemIcons.rank_color(id)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.12, 0.14, 0.19) if st != "hover" else Color(0.22, 0.26, 0.34)
		box.border_color = frame if st != "hover" else frame.lightened(0.4)
		box.set_border_width_all(1)
		box.set_content_margin_all(1)
		b.add_theme_stylebox_override(st, box)
	if dim:
		b.modulate = Color(1, 1, 1, 0.4)
	if count > 1:
		var l := UiText.label()
		l.text = str(count) if count < 1000 else "999+"
		l.position = Vector2(0, 10)
		l.size = Vector2(20, 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(l)
	if tip != null:
		b.mouse_entered.connect(func(): tip.show_item(id, count, b.global_position + Vector2(b.size.x, 0)))
		b.mouse_exited.connect(tip.hide_tip)
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b
