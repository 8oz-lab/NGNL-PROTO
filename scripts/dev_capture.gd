extends Node
## Entwicklerhilfe für automatische Tests: läuft ein Stück, speichert Bilder und beendet das Spiel.
## Aufruf: godot --path . -- --capture=shot.png [--walk]

var output := "capture.png"
var _t := 0.0
var _shots := 0


func _process(delta: float) -> void:
	_t += delta
	var walk := OS.get_cmdline_user_args().has("--walk")
	if walk and _t > 2.0 and _t < 5.0:
		Input.action_press("move_forward")
	elif walk and _t >= 5.0:
		Input.action_release("move_forward")
	var times := [2.0, 4.0, 6.5] if walk else [3.0]
	if _shots < times.size() and _t > times[_shots]:
		var img := get_viewport().get_texture().get_image()
		img.save_png(output.replace(".png", "_%d.png" % _shots))
		_shots += 1
		if _shots == times.size():
			get_tree().quit()
