extends Node
# Drückt zu bestimmten Zeiten die Leertaste und speichert Bilder davor/danach.
var t := 0.0
var events := []
var out := ""

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--plan="):
			for e in a.trim_prefix("--plan=").split(","):
				events.append(e)
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")

func _process(d: float) -> void:
	t += d
	while events.size() > 0 and float(events[0].substr(1)) <= t:
		var e: String = events.pop_front()
		if e[0] == "s":
			var img := get_viewport().get_texture().get_image()
			img.save_png(out + "_%05.1f.png" % t)
			print("Bild bei %.1f" % t)
		elif e[0] == "k":
			var ev := InputEventKey.new()
			ev.keycode = KEY_SPACE
			ev.physical_keycode = KEY_SPACE
			ev.pressed = true
			Input.parse_input_event(ev)
			var up := ev.duplicate()
			up.pressed = false
			Input.parse_input_event(up)
			print("Leertaste bei %.1f" % t)
		elif e[0] == "q":
			get_tree().quit()
