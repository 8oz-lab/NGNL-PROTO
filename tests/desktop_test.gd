extends Node
## Klickt sich durch den Desktop (Dateien anlegen, verschieben, löschen, Fenster) und gibt die Ergebnisse aus.
## Aufruf: godot --path . res://tests/desktop_test.tscn
var f := 0
var d: Control
func click(pos: Vector2, button := MOUSE_BUTTON_LEFT, pressed := true, dbl := false) -> void:
	var e := InputEventMouseButton.new()
	e.position = pos
	e.global_position = pos
	e.button_index = button
	e.pressed = pressed
	e.double_click = dbl
	get_tree().root.push_input(e)
func move(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_tree().root.push_input(e)
func center_of(key: String) -> Vector2:
	var iv: IconView = d.icons
	for e in iv.entries:
		if e["key"] == key:
			return iv.get_global_rect().position + iv._rect(e).position + Vector2(46, 24)
	return Vector2(-1, -1)
func _process(_d) -> void:
	f += 1
	if f == 2:
		d = load("res://scenes/intro/desktop.tscn").instantiate()
		get_tree().root.add_child(d)
	if f == 5:
		var fs: DeskFS = d.fs
		print("start items ", fs.items.size(), " trashed ", fs.trashed)
		# neue Datei anlegen, umbenennen
		d.icons.create_item("text", Vector2(400, 300))
		d.icons._edit.text = "Plan"
		d.icons._commit_rename()
		var id := ""
		for it in fs.items.values():
			if it["name"] == "Plan":
				id = it["id"]
		print("created+renamed: ", id != "", " pos ", fs.pos.get("i" + id))
		# auf den Ordner „Strategien“ ziehen
		var from := center_of("i" + id)
		var to := center_of("i1")
		click(from)
		move(from + Vector2(10, 10))
		move(to)
		click(to, MOUSE_BUTTON_LEFT, false)
		print("moved into folder: ", fs.items[id]["parent"] == "1")
		# Notizen.txt in den Papierkorb
		from = center_of("i2")
		to = center_of("sys:trash")
		click(from)
		move(from + Vector2(10, 10))
		move(to)
		click(to, MOUSE_BUTTON_LEFT, false)
		print("trashed notizen: ", not fs.items.has("2"), " trashed ", fs.trashed)
		# Symbol verschieben
		var pc := center_of("sys:pc")
		click(pc)
		move(pc + Vector2(10, 10))
		move(pc + Vector2(400, 200))
		click(pc + Vector2(400, 200), MOUSE_BUTTON_LEFT, false)
		print("pc pos ", fs.pos.get("sys:pc"))
		# Rahmen ziehen
		click(Vector2(1500, 20))
		move(Vector2(1400, 300))
		move(Vector2(5, 300))
		click(Vector2(5, 300), MOUSE_BUTTON_LEFT, false)
		print("lasso selected ", d.icons.selected.keys())
	if f == 8:
		d._open_key("sys:lol")
	if f == 10:
		var w: W98Window = d.apps["lol"]
		var corner := w.get_global_rect().end - Vector2(4, 4)
		var before := w.size
		click(corner)
		move(corner + Vector2(-200, -100))
		click(corner + Vector2(-200, -100), MOUSE_BUTTON_LEFT, false)
		print("resize ", before, " -> ", w.size)
		var mr := w.get_global_rect().position + w._min_rect().get_center()
		click(mr)
		click(mr, MOUSE_BUTTON_LEFT, false)
		print("minimized: ", not w.visible, " task exists: ", d.tasks.has(w))
		d.tasks[w].pressed.emit()
		print("restored: ", w.visible)
	if f == 12:
		get_tree().quit()
