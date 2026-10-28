class_name W98Button
extends Control
## Knopf im Win98-Stil: erhaben, beim Drücken eingelassen.

signal pressed

var text := "":
	set(v):
		text = v
		queue_redraw()
var font_size := 13
var bold := false
## Dauerhaft eingedrückt (z. B. aktiver Eintrag in der Taskleiste)
var sunken := false:
	set(v):
		if v != sunken:
			sunken = v
			queue_redraw()
## Text linksbündig statt mittig
var align_left := false
var _down := false
var _hover := false


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func(): _hover = true; queue_redraw())
	mouse_exited.connect(func(): _hover = false; _down = false; queue_redraw())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _get_minimum_size() -> Vector2:
	var f := Flow.font_ui_bold if bold else Flow.font_ui
	return Vector2(f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 24, 26)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_down = true
		elif _down:
			_down = false
			pressed.emit()
		queue_redraw()
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		pressed.emit()
		accept_event()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var down := _down or sunken
	Win98.bevel(self, r, not down, Color("d8d8d8") if sunken else Win98.FACE)
	var f := Flow.font_ui_bold if bold or sunken else Flow.font_ui
	var off := Vector2(1, 1) if down else Vector2.ZERO
	var ts := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var x := 8.0 if align_left else (size.x - ts.x) * 0.5
	var pos := Vector2(x, (size.y + f.get_ascent(font_size) - f.get_descent(font_size)) * 0.5) + off
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 4, font_size, Color.BLACK)
	if has_focus():
		var fr := r.grow(-4)
		for i in range(int(fr.position.x), int(fr.end.x), 2):
			draw_rect(Rect2(i, fr.position.y, 1, 1), Color.BLACK)
			draw_rect(Rect2(i, fr.end.y - 1, 1, 1), Color.BLACK)
