extends Node
## Spielstand: Münzen und Parzellen. Läuft als Autoload "GameState".

signal changed

const SAVE_PATH := "user://save.json"
const START_COINS := 100
const PARCEL_VALUE := 50

var coins: int = START_COINS
## Parzellen-ID → Zustand. "owner" ist "player" oder der Name eines Gegners, "building" ist leer oder ein Gebäude.
var parcels: Dictionary = {}


func _ready() -> void:
	_setup_input()
	_reset_parcels()
	load_game()


func _reset_parcels() -> void:
	parcels.clear()
	for row in 3:
		for col in 3:
			var id := "ABC"[col] + str(row + 1)
			parcels[id] = {"owner": "player", "building": "Hütte" if id == "B1" else ""}


func owned_count() -> int:
	var n := 0
	for p in parcels.values():
		if p["owner"] == "player":
			n += 1
	return n


func parcel_value(id: String) -> int:
	return 0 if parcels[id]["building"] == "Hütte" else PARCEL_VALUE


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"coins": coins, "parcels": parcels}))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		coins = int(data.get("coins", START_COINS))
		if data.get("parcels") is Dictionary:
			for id in data["parcels"]:
				if parcels.has(id):
					parcels[id] = data["parcels"][id]
	changed.emit()


## Tastenbelegung im Code, damit sie nicht in project.godot gepflegt werden muss.
func _setup_input() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT],
		"swap": [KEY_Q, KEY_TAB],
		"interact": [KEY_E, KEY_ENTER, KEY_SPACE],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
