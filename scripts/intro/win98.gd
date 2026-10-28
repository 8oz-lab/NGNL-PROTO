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
