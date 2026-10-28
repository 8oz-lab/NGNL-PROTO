class_name Win98
## Bausteine im Stil eines alten Windows: abgeschrägte Rahmen, Fenster, Knöpfe.

const FACE := Color("c0c0c0")
const HI := Color("ffffff")
const LIGHT := Color("dfdfdf")
const SHADE := Color("808080")
const DARK := Color("0a0a0a")
const NAVY := Color("000080")
const BLUE := Color("1084d0")
const TEAL := Color("008080")


## Zeichnet einen erhabenen (raised) oder eingelassenen Rahmen.
static func bevel(ci: CanvasItem, r: Rect2, raised := true, fill := FACE) -> void:
	ci.draw_rect(r, fill)
	var tl := HI if raised else SHADE
	var br := DARK if raised else HI
	var tl2 := LIGHT if raised else DARK
	var br2 := SHADE if raised else LIGHT
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.end.x - 1
	var y1 := r.end.y - 1
	ci.draw_line(Vector2(x0, y0), Vector2(x1, y0), tl)
	ci.draw_line(Vector2(x0, y0), Vector2(x0, y1), tl)
	ci.draw_line(Vector2(x0, y1), Vector2(x1, y1), br)
	ci.draw_line(Vector2(x1, y0), Vector2(x1, y1), br)
	ci.draw_line(Vector2(x0 + 1, y0 + 1), Vector2(x1 - 1, y0 + 1), tl2)
	ci.draw_line(Vector2(x0 + 1, y0 + 1), Vector2(x0 + 1, y1 - 1), tl2)
	ci.draw_line(Vector2(x0 + 1, y1 - 1), Vector2(x1 - 1, y1 - 1), br2)
	ci.draw_line(Vector2(x1 - 1, y0 + 1), Vector2(x1 - 1, y1 - 1), br2)


static func label(text: String, size := 13, color := Color.BLACK, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Flow.font_ui_bold if bold else Flow.font_ui)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, min_width := 80) -> W98Button:
	var b := W98Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 26)
	return b


## Kontextmenü im Win98-Stil.
static func popup() -> PopupMenu:
	var p := PopupMenu.new()
	var panel := StyleBoxFlat.new()
	panel.bg_color = FACE
	panel.border_color = DARK
	panel.set_border_width_all(1)
	panel.border_width_left = 2
	panel.border_width_top = 2
	panel.border_color = SHADE
	panel.set_content_margin_all(3)
	var hover := StyleBoxFlat.new()
	hover.bg_color = NAVY
	p.add_theme_stylebox_override("panel", panel)
	p.add_theme_stylebox_override("hover", hover)
	var sep := StyleBoxLine.new()
	sep.color = SHADE
	sep.thickness = 1
	p.add_theme_stylebox_override("separator", sep)
	p.add_theme_font_override("font", Flow.font_ui)
	p.add_theme_font_size_override("font_size", 13)
	p.add_theme_color_override("font_color", Color.BLACK)
	p.add_theme_color_override("font_hover_color", Color.WHITE)
	p.add_theme_color_override("font_disabled_color", SHADE)
	p.add_theme_constant_override("v_separation", 8)
	p.add_theme_constant_override("item_start_padding", 14)
	p.add_theme_constant_override("item_end_padding", 24)
	return p


## Weißes, eingelassenes Feld (z. B. für Listen und Texte).
static func sunken_box(fill := Color.WHITE) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = SHADE
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.set_content_margin_all(6)
	return s
