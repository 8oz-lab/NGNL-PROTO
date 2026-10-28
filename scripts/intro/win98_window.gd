class_name W98Window
extends Control
## Fenster im Win98-Stil: Titelleiste mit Farbverlauf, verschiebbar, in der Größe ziehbar,
## mit Knöpfen zum Minimieren und Schließen.

signal closed
signal minimized

const TITLE_H := 24
const GRIP := 14.0
const EDGE := 6.0

var title := "":
	set(v):
		if v != title:
			title = v
			queue_redraw()
var icon_color := Color("ffd36b")
var closable := true
var minimizable := true
var resizable := true
var min_size := Vector2(260, 160)
var active := true:
	set(v):
		if v != active:
			active = v
			queue_redraw()
## Bereich für den Inhalt (unterhalb der Titelleiste)
var content: MarginContainer

var _mode := ""          # "", "move", "r", "b", "rb"
var _grab := Vector2.ZERO
var _start_size := Vector2.ZERO


func _init() -> void:
	content = MarginContainer.new()
	for side in ["left", "right", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 4)
	content.add_theme_constant_override("margin_top", TITLE_H + 6)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			move_to_front()
			if closable and _close_rect().has_point(mb.position):
				Flow.play("blip", -6)
				closed.emit()
				return
			if minimizable and _min_rect().has_point(mb.position):
				Flow.play("blip", -8)
				minimized.emit()
				return
			_mode = _edge_at(mb.position)
			if _mode == "" and mb.position.y < TITLE_H + 4:
				_mode = "move"
			_grab = mb.position
			_start_size = size
		else:
			_mode = ""
		accept_event()
	elif event is InputEventMouseMotion:
		var p := (event as InputEventMouseMotion).position
		match _mode:
			"move":
				var parent_size := get_parent_area_size()
				position = (position + p - _grab).clamp(Vector2(-size.x + 80, 0), parent_size - Vector2(80, 60))
			"r", "b", "rb":
				var limit := get_parent_area_size() - position
				var s := _start_size + p - _grab
				if _mode == "r":
					s.y = size.y
				elif _mode == "b":
					s.x = size.x
				size = s.clamp(min_size, limit.max(min_size))
			_:
				var e := _edge_at(p)
				mouse_default_cursor_shape = {"r": Control.CURSOR_HSIZE, "b": Control.CURSOR_VSIZE, "rb": Control.CURSOR_FDIAGSIZE}.get(e, Control.CURSOR_ARROW)


func _edge_at(p: Vector2) -> String:
	if not resizable:
		return ""
	if p.x > size.x - GRIP and p.y > size.y - GRIP:
		return "rb"
	if p.x > size.x - EDGE:
		return "r"
	if p.y > size.y - EDGE:
		return "b"
	return ""


func _close_rect() -> Rect2:
	return Rect2(size.x - 24, 7, 18, 16)


func _min_rect() -> Rect2:
	return Rect2(size.x - (44 if closable else 24), 7, 18, 16)


func _draw() -> void:
	Win98.bevel(self, Rect2(Vector2.ZERO, size), true)
	var tr := Rect2(4, 4, size.x - 8, TITLE_H)
	var c0 := Win98.NAVY if active else Win98.SHADE
	var c1 := Win98.BLUE if active else Color("b5b5b5")
	var steps := 24
	for i in steps:
		var x := tr.position.x + tr.size.x * i / steps
		draw_rect(Rect2(x, tr.position.y, tr.size.x / steps + 1, tr.size.y), c0.lerp(c1, float(i) / (steps - 1)))
	draw_rect(Rect2(10, 9, 14, 14), icon_color)
	draw_rect(Rect2(10, 9, 14, 14), Color.BLACK, false, 1.0)
	draw_string(Flow.font_ui_bold, Vector2(32, 21), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 90, 13, Color.WHITE if active else Color("dcdcdc"))
	if closable:
		var cr := _close_rect()
		Win98.bevel(self, cr, true)
		draw_line(cr.position + Vector2(5, 4), cr.end - Vector2(5, 4), Color.BLACK, 2.0)
		draw_line(Vector2(cr.end.x - 5, cr.position.y + 4), Vector2(cr.position.x + 5, cr.end.y - 4), Color.BLACK, 2.0)
	if minimizable:
		var mr := _min_rect()
		Win98.bevel(self, mr, true)
		draw_rect(Rect2(mr.position.x + 5, mr.end.y - 5, 7, 2), Color.BLACK)
	if resizable:
		for i in 3:
			var o := 4.0 + i * 4.0
			draw_line(Vector2(size.x - o, size.y - 3), Vector2(size.x - 3, size.y - o), Win98.HI, 1.0)
			draw_line(Vector2(size.x - o + 1, size.y - 3), Vector2(size.x - 3, size.y - o + 1), Win98.SHADE, 1.0)
