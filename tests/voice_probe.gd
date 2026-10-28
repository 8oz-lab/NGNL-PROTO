extends Node
## Gibt während des Sturzes aus, welche Zeile läuft und ob die Stimme spielt (Entwicklerhilfe).
var _last := -2

func _process(_d: float) -> void:
	var s := get_tree().current_scene
	if s == null or not ("line" in s):
		return
	if s.line != _last:
		_last = s.line
		print("%5.1f s  Zeile %d  Stimme spielt: %s  Untertitel-Tempo %.1f Zeichen/s" % [Time.get_ticks_msec() / 1000.0, s.line, s._voice.playing, s._speed])
