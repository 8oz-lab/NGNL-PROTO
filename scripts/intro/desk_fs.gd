class_name DeskFS
extends RefCounted
## Kleines Dateisystem für den Desktop: eigene Ordner und Textdokumente, Symbolpositionen, Papierkorb.
## Wird in user://desktop.json gespeichert.

signal changed

const PATH := "user://desktop.json"

var items := {}      # id -> {id, type ("folder"/"text"), parent ("desk" oder Ordner-id), name, content}
var pos := {}        # Symbolschlüssel auf dem Desktop -> [spalte, zeile]
var next_id := 1
var trashed := 0


func _init() -> void:
	load_data()


func load_data() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	items = data.get("items", {})
	pos = data.get("pos", {})
	next_id = int(data.get("next", 1))
	trashed = int(data.get("trashed", 0))


## silent: nur speichern, ohne die Ansichten neu aufzubauen (z. B. beim Tippen im Editor)
func save(silent := false) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"items": items, "pos": pos, "next": next_id, "trashed": trashed}))
	if not silent:
		changed.emit()


func children(parent: String) -> Array:
	var list := items.values().filter(func(i): return i["parent"] == parent)
	list.sort_custom(func(a, b):
		if a["type"] != b["type"]:
			return a["type"] == "folder"
		return String(a["name"]).naturalnocasecmp_to(b["name"]) < 0)
	return list


func create(type: String, parent: String) -> String:
	var id := str(next_id)
	next_id += 1
	var base := "Neuer Ordner" if type == "folder" else "Neues Textdokument"
	items[id] = {"id": id, "type": type, "parent": parent, "content": "", "name": unique_name(parent, base, "" if type == "folder" else ".txt")}
	save()
	return id


func unique_name(parent: String, base: String, ext: String, except := "") -> String:
	var taken := {}
	for i in items.values():
		if i["parent"] == parent and i["id"] != except:
			taken[String(i["name"]).to_lower()] = true
	var n := base + ext
	var k := 2
	while taken.has(n.to_lower()):
		n = "%s (%d)%s" % [base, k, ext]
		k += 1
	return n


## Gibt false zurück, wenn der Name ungültig oder schon vergeben ist.
func rename(id: String, name: String) -> bool:
	name = name.strip_edges()
	if name == "" or not items.has(id) or name.contains("/") or name.contains("\\"):
		return false
	var it: Dictionary = items[id]
	if unique_name(it["parent"], name, "", id) != name:
		return false
	it["name"] = name
	save()
	return true


func delete(id: String) -> void:
	if not items.has(id):
		return
	for c in children(id):
		delete(c["id"])
	items.erase(id)
	pos.erase("i" + id)
	trashed += 1
	save()


## Verschiebt ein Objekt in einen Ordner (nicht in sich selbst oder einen eigenen Unterordner).
func move(id: String, parent: String) -> bool:
	if not items.has(id) or id == parent:
		return false
	var p := parent
	while items.has(p):
		if p == id:
			return false
		p = items[p]["parent"]
	var it: Dictionary = items[id]
	it["parent"] = parent
	it["name"] = unique_name(parent, String(it["name"]).get_basename() if it["type"] == "text" else it["name"], ".txt" if it["type"] == "text" else "", id)
	pos.erase("i" + id)
	save()
	return true


func path_of(id: String) -> String:
	var parts := []
	var cur := id
	while items.has(cur):
		parts.push_front(items[cur]["name"])
		cur = items[cur]["parent"]
	return "C:\\Desktop\\" + "\\".join(parts)
