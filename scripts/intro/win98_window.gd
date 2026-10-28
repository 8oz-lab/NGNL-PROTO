class_name W98Window
extends Control
## Fenster im Win98-Stil: Titelleiste mit Farbverlauf, verschiebbar, mit Schließen-Knopf.

signal closed

const TITLE_H := 24

var title := "":
	set(v):
		title = v
		queue_redraw()
var icon_color := Color("ffd36b")
var closable := true
var active := true:
	set(v):
		active = v
		queue_redraw()
## Bereich für den Inhalt (unterhalb der Titelleiste)
var content: MarginContainer

var _drag := false
var _drag_offset := Vector2.ZERO


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
			if mb.position.y < TITLE_H + 4:
				_drag = true
				_drag_offset = mb.position
		else:
			_drag = false
	elif event is InputEventMouseMotion and _drag:
		var parent_size := get_parent_area_size()
		position = (position + (event as InputEventMouseMotion).position - _drag_offset).clamp(Vector2(-size.x + 80, 0), parent_size - Vector2(80, 60))


func _close_rect() -> Rect2:
	return Rect2(size.x - 24, 6, 18, 16)


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
	draw_string(Flow.font_ui_bold, Vector2(32, 21), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 70, 13, Color.WHITE if active else Color("dcdcdc"))
	if closable:
		var cr := _close_rect()
		Win98.bevel(self, cr, true)
		draw_line(cr.position + Vector2(5, 4), cr.end - Vector2(5, 4), Color.BLACK, 2.0)
		draw_line(Vector2(cr.end.x - 5, cr.position.y + 4), Vector2(cr.position.x + 5, cr.end.y - 4), Color.BLACK, 2.0)
