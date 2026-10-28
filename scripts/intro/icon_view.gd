class_name IconView
extends Control
## Symbolraster für den Desktop oder einen Ordner: auswählen (auch mit Rahmen), verschieben,
## auf Ordner oder Papierkorb ziehen, Doppelklick öffnet, Rechtsklick zeigt ein Kontextmenü.

signal opened(key: String)

const CELL := Vector2(92, 84)
const MARGIN := Vector2(8, 8)

enum { M_OPEN = 1, M_RENAME, M_DELETE, M_NEW_FOLDER = 10, M_NEW_TEXT, M_ARRANGE, M_REFRESH }

var fs: DeskFS
var parent_id := "desk"
var system: Array = []        # [{key, title, kind}] feste Symbole (nur Desktop)
var light_text := true
var badges := {}               # key -> Zahl

var entries: Array = []
var selected := {}

var _press_key := ""
var _press_pos := Vector2.ZERO
var _pressing := false
var _dragging := false
var _drag_delta := Vector2.ZERO
var _lasso := false
var _lasso_rect := Rect2()
var _menu: PopupMenu
var _menu_pos := Vector2.ZERO
var _edit: LineEdit
var _edit_id := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_CLICK
	clip_contents = true
	fs.changed.connect(refresh)
	resized.connect(refresh)
	_menu = Win98.popup()
	add_child(_menu)
	_menu.id_pressed.connect(_on_menu)
	refresh()


func is_desk() -> bool:
	return parent_id == "desk"


func refresh() -> void:
	if parent_id != "desk" and not fs.items.has(parent_id):
		return
	entries.clear()
	for s in system:
		entries.append({"key": s["key"], "title": s["title"], "kind": s["kind"], "id": "", "cell": null})
	for it in fs.children(parent_id):
		entries.append({"key": "i" + it["id"], "title": it["name"], "kind": it["type"], "id": it["id"], "cell": null})
	_layout()
	var keys := entries.map(func(e): return e["key"])
	for k in selected.keys():
		if not keys.has(k):
			selected.erase(k)
	queue_redraw()


func _rows() -> int:
	return maxi(1, int((size.y - MARGIN.y) / CELL.y))


func _cols() -> int:
	return maxi(1, int((size.x - MARGIN.x) / CELL.x))


func _cell_at(k: int) -> Vector2i:
	return Vector2i(k / _rows(), k % _rows()) if is_desk() else Vector2i(k % _cols(), k / _cols())


func _layout() -> void:
	var used := {}
	if is_desk():
		for e in entries:
			var p = fs.pos.get(e["key"])
			if p != null:
				var c := Vector2i(int(p[0]), int(p[1]))
				if c.y < _rows() and not used.has(c):
					e["cell"] = c
					used[c] = true
	var k := 0
	for e in entries:
		if e["cell"] != null:
			continue
		var c := _cell_at(k)
		while used.has(c):
			k += 1
			c = _cell_at(k)
		e["cell"] = c
		used[c] = true
	if not is_desk():
		var rows := 0
		for e in entries:
			rows = maxi(rows, _cell(e).y + 1)
		custom_minimum_size.y = rows * CELL.y + MARGIN.y * 2


func _cell(e: Dictionary) -> Vector2i:
	return e["cell"]


func _rect(e: Dictionary) -> Rect2:
	return Rect2(MARGIN + Vector2(e["cell"]) * CELL, CELL)


func _hit_rect(e: Dictionary) -> Rect2:
	var r := _rect(e)
	return Rect2(r.position + Vector2(12, 2), Vector2(CELL.x - 24, CELL.y - 8))


func _entry(key: String) -> Dictionary:
	for e in entries:
		if e["key"] == key:
			return e
	return {}


func _hit(p: Vector2) -> String:
	for i in range(entries.size() - 1, -1, -1):
		if _hit_rect(entries[i]).has_point(p):
			return entries[i]["key"]
	return ""


# ------------------------------------------------------------------ Eingabe

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_left_press(mb)
			else:
				_left_release(mb)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_context(mb.position)
			accept_event()
	elif event is InputEventMouseMotion and _pressing:
		var p := (event as InputEventMouseMotion).position
		if _press_key != "":
			if _dragging or p.distance_to(_press_pos) > 5.0:
				_dragging = true
				_drag_delta = p - _press_pos
		elif _lasso:
			_lasso_rect = Rect2(_press_pos, Vector2.ZERO).expand(p)
			selected.clear()
			for e in entries:
				if _lasso_rect.intersects(_hit_rect(e)):
					selected[e["key"]] = true
		queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_F2:
				if selected.size() == 1:
					start_rename(_entry(selected.keys()[0]).get("id", ""))
			KEY_DELETE:
				_delete_selected()
			KEY_ENTER, KEY_KP_ENTER:
				for k in selected:
					opened.emit(k)
		accept_event()


func _left_press(mb: InputEventMouseButton) -> void:
	grab_focus()
	_commit_rename()
	var k := _hit(mb.position)
	if mb.double_click and k != "":
		opened.emit(k)
		_pressing = false
		return
	_pressing = true
	_press_pos = mb.position
	_dragging = false
	_drag_delta = Vector2.ZERO
	_press_key = k
	if k != "":
		if mb.ctrl_pressed:
			if selected.has(k):
				selected.erase(k)
			else:
				selected[k] = true
		elif not selected.has(k):
			selected = {k: true}
	else:
		_lasso = true
		_lasso_rect = Rect2(mb.position, Vector2.ZERO)
		if not mb.ctrl_pressed:
			selected.clear()
	queue_redraw()


func _left_release(mb: InputEventMouseButton) -> void:
	if not _pressing:
		return
	_pressing = false
	if _dragging:
		var target := _hit(mb.position)
		if target != "" and not selected.has(target) and _is_drop_target(target):
			_drop_on(target)
		elif is_desk():
			_move_selected(_drag_delta)
	elif _press_key != "" and not mb.ctrl_pressed:
		selected = {_press_key: true}
	_dragging = false
	_lasso = false
	_press_key = ""
	queue_redraw()


func _is_drop_target(key: String) -> bool:
	if key == "sys:trash":
		return true
	var e := _entry(key)
	return e.get("kind", "") == "folder" and e.get("id", "") != ""


func _selected_ids() -> Array:
	var ids := []
	for k in selected:
		var e := _entry(k)
		if e.get("id", "") != "":
			ids.append(e["id"])
	return ids


func _drop_on(target: String) -> void:
	var ids := _selected_ids()
	if ids.is_empty():
		Flow.play("blip", -6, 0.7)
		return
	if target == "sys:trash":
		for id in ids:
			fs.delete(id)
		Flow.play("capture", -8, 0.8)
	else:
		var folder: String = _entry(target)["id"]
		for id in ids:
			fs.move(id, folder)
		Flow.play("clack", -8)
	selected.clear()


func _move_selected(delta: Vector2) -> void:
	var occupied := {}
	for e in entries:
		if not selected.has(e["key"]):
			occupied[e["cell"]] = true
	var rows := _rows()
	var cols := maxi(1, int((size.x - MARGIN.x) / CELL.x))
	for e in entries:
		if not selected.has(e["key"]):
			continue
		var want := ((_rect(e).position + delta - MARGIN) / CELL).round()
		var c := Vector2i(clampi(int(want.x), 0, cols - 1), clampi(int(want.y), 0, rows - 1))
		c = _nearest_free(c, occupied, cols, rows)
		occupied[c] = true
		e["cell"] = c
	for e in entries:
		fs.pos[e["key"]] = [_cell(e).x, _cell(e).y]
	fs.save()


func _nearest_free(c: Vector2i, occupied: Dictionary, cols: int, rows: int) -> Vector2i:
	for r in maxi(cols, rows):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var p := c + Vector2i(dx, dy)
				if maxi(absi(dx), absi(dy)) == r and p.x >= 0 and p.y >= 0 and p.x < cols and p.y < rows and not occupied.has(p):
					return p
	return c


func _delete_selected() -> void:
	var ids := _selected_ids()
	if ids.is_empty():
		return
	for id in ids:
		fs.delete(id)
	Flow.play("capture", -8, 0.8)
	selected.clear()


# ------------------------------------------------------------------ Kontextmenü und Umbenennen

func _context(p: Vector2) -> void:
	_commit_rename()
	_menu_pos = p
	var k := _hit(p)
	if k != "" and not selected.has(k):
		selected = {k: true}
	elif k == "":
		selected.clear()
	queue_redraw()
	_menu.clear()
	if k != "":
		_menu.add_item("Öffnen", M_OPEN)
		var custom := _selected_ids().size() > 0
		_menu.add_separator()
		_menu.add_item("Umbenennen", M_RENAME)
		_menu.set_item_disabled(_menu.get_item_index(M_RENAME), not custom or selected.size() != 1)
		_menu.add_item("Löschen", M_DELETE)
		_menu.set_item_disabled(_menu.get_item_index(M_DELETE), not custom)
	else:
		_menu.add_item("Neuer Ordner", M_NEW_FOLDER)
		_menu.add_item("Neues Textdokument", M_NEW_TEXT)
		_menu.add_separator()
		if is_desk():
			_menu.add_item("Symbole anordnen", M_ARRANGE)
		_menu.add_item("Aktualisieren", M_REFRESH)
	_menu.reset_size()
	_menu.popup(Rect2i(Vector2i(get_global_transform_with_canvas() * p), Vector2i.ZERO))


func _on_menu(id: int) -> void:
	match id:
		M_OPEN:
			for k in selected.keys():
				opened.emit(k)
		M_RENAME:
			if selected.size() == 1:
				start_rename(_entry(selected.keys()[0]).get("id", ""))
		M_DELETE:
			_delete_selected()
		M_NEW_FOLDER:
			create_item("folder", _menu_pos)
		M_NEW_TEXT:
			create_item("text", _menu_pos)
		M_ARRANGE:
			for e in entries:
				fs.pos.erase(e["key"])
			fs.save()
		M_REFRESH:
			refresh()


## Legt ein neues Objekt an (auf dem Desktop möglichst an der Mausposition) und startet das Umbenennen.
func create_item(type: String, at := Vector2(-1, -1)) -> void:
	if is_desk():
		for e in entries:
			fs.pos[e["key"]] = [_cell(e).x, _cell(e).y]
	var id := fs.create(type, parent_id)
	if is_desk():
		var occupied := {}
		for e in entries:
			occupied[e["cell"]] = true
		var want := Vector2i(0, 0)
		if at.x >= 0:
			var w := ((at - MARGIN - CELL * 0.5) / CELL).round()
			want = Vector2i(maxi(0, int(w.x)), clampi(int(w.y), 0, _rows() - 1))
		var c := _nearest_free(want, occupied, maxi(1, int((size.x - MARGIN.x) / CELL.x)), _rows())
		fs.pos["i" + id] = [c.x, c.y]
		fs.save()
	refresh()
	selected = {"i" + id: true}
	start_rename(id)


func start_rename(id: String) -> void:
	if id == "" or not fs.items.has(id):
		return
	var e := _entry("i" + id)
	if e.is_empty():
		return
	_commit_rename()
	_edit_id = id
	_edit = LineEdit.new()
	_edit.text = fs.items[id]["name"]
	_edit.add_theme_font_override("font", Flow.font_ui)
	_edit.add_theme_font_size_override("font_size", 12)
	_edit.add_theme_color_override("font_color", Color.BLACK)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.border_color = Color.BLACK
	sb.set_border_width_all(1)
	sb.set_content_margin_all(2)
	_edit.add_theme_stylebox_override("normal", sb)
	_edit.add_theme_stylebox_override("focus", sb)
	var r := _rect(e)
	_edit.position = r.position + Vector2(2, 48)
	_edit.size = Vector2(CELL.x - 4, 22)
	add_child(_edit)
	_edit.grab_focus()
	var base := String(_edit.text).get_basename() if fs.items[id]["type"] == "text" else _edit.text
	_edit.select(0, base.length())
	_edit.text_submitted.connect(func(_t): _commit_rename())
	_edit.focus_exited.connect(_commit_rename)
	_edit.gui_input.connect(func(ev):
		if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
			_cancel_rename())
	queue_redraw()


func _commit_rename() -> void:
	if _edit == null:
		return
	var e := _edit
	var id := _edit_id
	_edit = null
	_edit_id = ""
	if not fs.rename(id, e.text) and e.text.strip_edges() != fs.items.get(id, {}).get("name", ""):
		Flow.play("blip", -6, 0.6)
	e.queue_free()
	refresh()


func _cancel_rename() -> void:
	if _edit:
		_edit.queue_free()
		_edit = null
		_edit_id = ""
		queue_redraw()


# ------------------------------------------------------------------ Zeichnen

func _draw() -> void:
	for e in entries:
		var off := _drag_delta if _dragging and selected.has(e["key"]) else Vector2.ZERO
		_draw_entry(e, off)
	if _dragging:
		var target := _hit(_press_pos + _drag_delta)
		if target != "" and not selected.has(target) and _is_drop_target(target):
			draw_rect(_hit_rect(_entry(target)), Color(1, 1, 1, 0.6), false, 1.0)
	if _lasso and _lasso_rect.size.length() > 2.0:
		draw_rect(_lasso_rect, Color(0, 0, 0.5, 0.18))
		draw_rect(_lasso_rect, Color(1, 1, 1, 0.9) if light_text else Color(0, 0, 0, 0.8), false, 1.0)


func _draw_entry(e: Dictionary, off: Vector2) -> void:
	var r := _rect(e)
	r.position += off
	var c := r.position + Vector2(CELL.x * 0.5, 24)
	var kind: String = e["kind"]
	if kind == "trash" and fs.trashed > 0:
		kind = "trash_full"
	IconArt.draw(self, kind, c)
	var sel := selected.has(e["key"])
	if sel:
		draw_rect(Rect2(c - Vector2(20, 20), Vector2(40, 40)), Color(0, 0, 0.5, 0.35))
	var b: int = badges.get(e["key"], 0)
	if b > 0:
		draw_circle(c + Vector2(19, -17), 9, Color("e00000"))
		var bs := str(b)
		var bw := Flow.font_ui_bold.get_string_size(bs, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(Flow.font_ui_bold, c + Vector2(19 - bw * 0.5, -13), bs, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	if _edit and e["id"] == _edit_id and off == Vector2.ZERO:
		return
	var font := Flow.font_ui
	var w := CELL.x - 8
	var ts := font.get_multiline_string_size(e["title"], HORIZONTAL_ALIGNMENT_CENTER, w, 12, 2)
	var tp := Vector2(r.position.x + 4, r.position.y + 50)
	if sel:
		draw_rect(Rect2(tp.x + (w - ts.x) * 0.5 - 2, tp.y, ts.x + 4, ts.y + 2), Win98.NAVY)
	var col := Color.WHITE if sel or light_text else Color.BLACK
	if light_text and not sel:
		draw_multiline_string(font, tp + Vector2(1, 13), e["title"], HORIZONTAL_ALIGNMENT_CENTER, w, 12, 2, Color(0, 0, 0, 0.6))
	draw_multiline_string(font, tp + Vector2(0, 12), e["title"], HORIZONTAL_ALIGNMENT_CENTER, w, 12, 2, col)
