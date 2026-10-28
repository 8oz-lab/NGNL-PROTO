class_name Hud
extends CanvasLayer
## Anzeige: Münzen und Parzellen, aktive Figur, Parzellen-Info, Aktions-Hinweis und Dialog.

signal dialog_closed

const PANEL := Color(0.06, 0.05, 0.16, 0.82)
const GOLD := Color(1.0, 0.83, 0.42)
const CYAN := Color(0.25, 0.89, 1.0)
const MUTE := Color(0.73, 0.69, 0.87)

var coins_label: Label
var parcels_label: Label
var who_label: Label
var skill_label: Label
var parcel_box: PanelContainer
var parcel_tag: Label
var parcel_name: Label
var parcel_sub: Label
var prompt: PanelContainer
var prompt_label: Label
var dialog: PanelContainer
var dialog_name: Label
var dialog_text: Label
var title_box: VBoxContainer

var _lines: Array = []
var _line := 0


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Oben links: Münzen und Parzellen
	var wallet := _panel(root)
	wallet.position = Vector2(20, 18)
	var wrow := HBoxContainer.new()
	wrow.add_theme_constant_override("separation", 26)
	wallet.add_child(wrow)
	coins_label = _stat(wrow, "MÜNZEN", GOLD)
	parcels_label = _stat(wrow, "PARZELLEN", CYAN)

	# Oben rechts: aktive Figur
	var who := _panel(root)
	var wcol := VBoxContainer.new()
	who.add_child(wcol)
	who_label = _label(wcol, "Sora", 22, GOLD)
	skill_label = _label(wcol, "", 14, MUTE)
	_label(wcol, "Q  wechseln", 12, MUTE)
	who.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	who.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	# Unten mittig: Parzelle
	parcel_box = _panel(root)
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 14)
	parcel_box.add_child(prow)
	parcel_tag = _label(prow, "B1", 30, GOLD)
	var pcol := VBoxContainer.new()
	prow.add_child(pcol)
	parcel_name = _label(pcol, "", 16, Color.WHITE)
	parcel_sub = _label(pcol, "", 13, MUTE)
	_pin_bottom(parcel_box, 24)
	parcel_box.visible = false

	# Aktions-Hinweis
	prompt = _panel(root, GOLD)
	prompt_label = _label(prompt, "", 16, Color.WHITE)
	_pin_bottom(prompt, 118)
	prompt.visible = false

	# Dialog
	dialog = _panel(root, Color(1.0, 0.31, 0.71, 0.7))
	dialog.custom_minimum_size = Vector2(680, 0)
	var dcol := VBoxContainer.new()
	dcol.add_theme_constant_override("separation", 6)
	dialog.add_child(dcol)
	dialog_name = _label(dcol, "", 20, GOLD)
	dialog_text = _label(dcol, "", 18, Color.WHITE)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.custom_minimum_size = Vector2(640, 0)
	_label(dcol, "E  weiter", 12, MUTE).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pin_bottom(dialog, 24)
	dialog.visible = false

	# Titel beim Start
	title_box = VBoxContainer.new()
	title_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 140)
	title_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title_box)
	for spec in [["ELKIA · STADTRAND", 14, Color.WHITE], ["Euer Grundstück", 56, Color.WHITE], ["9 Parzellen, eine Hütte, 100 Münzen", 18, Color.WHITE]]:
		var l := _label(title_box, spec[0], spec[1], spec[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_shadow_color", Color(0.1, 0.0, 0.25, 0.6))
		l.add_theme_constant_override("shadow_offset_y", 3)
	var tw := create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(title_box, "modulate:a", 0.0, 1.2)

	# Steuerungshilfe
	var help := _label(root, "WASD laufen · Shift sprinten · Leertaste springen · Maus ziehen: Kamera · Mausrad: Zoom · Q wechseln · E interagieren · F1 Tutorial", 13, MUTE)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	help.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN

	GameState.changed.connect(refresh)
	refresh()


func refresh() -> void:
	coins_label.text = str(GameState.coins)
	parcels_label.text = str(GameState.owned_count())


func set_hero(hero: Hero) -> void:
	who_label.text = hero.display_name
	skill_label.text = hero.skill


func show_parcel(id: String) -> void:
	if id == "" or dialog.visible:
		parcel_box.visible = false
		return
	var p: Dictionary = GameState.parcels[id]
	parcel_box.visible = true
	parcel_tag.text = id
	if p["building"] != "":
		parcel_name.text = "Bebaut: " + p["building"]
		parcel_sub.text = "Startparzelle · kann nie gesetzt werden"
	else:
		parcel_name.text = "Leere Parzelle"
		parcel_sub.text = "Wert %d Münzen · als Einsatz verwendbar" % GameState.parcel_value(id)


func show_prompt(text: String) -> void:
	prompt.visible = text != "" and not dialog.visible
	prompt_label.text = text


func say(lines: Array) -> void:
	_lines = lines
	_line = 0
	_show_line()


func is_talking() -> bool:
	return dialog.visible


func advance() -> void:
	_line += 1
	if _line < _lines.size():
		_show_line()
	else:
		dialog.visible = false
		dialog_closed.emit()


func _show_line() -> void:
	dialog.visible = true
	prompt.visible = false
	parcel_box.visible = false
	dialog_name.text = _lines[_line][0]
	dialog_text.text = _lines[_line][1]


## Unten mittig anheften; wächst nach oben und zu beiden Seiten.
func _pin_bottom(c: Control, margin: int) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, margin)
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _panel(parent: Control, border := Color(1, 1, 1, 0.16)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(1)
	sb.border_color = border
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _label(parent: Node, text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _stat(parent: Node, caption: String, color: Color) -> Label:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	parent.add_child(col)
	_label(col, caption, 11, MUTE)
	return _label(col, "0", 26, color)
