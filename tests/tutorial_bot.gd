extends Node
## Spielt das Steuerungs-Training automatisch durch und gibt aus, welche Schritte geschafft wurden.
## Aufruf: godot --path . -- --start=world --tutorial --probe=res://tests/tutorial_bot.gd

var _last_key := ""
var _wait := 0.0
var _coins0 := -1
var _ring := 0


func _process(delta: float) -> void:
	var world := get_tree().current_scene
	if world == null or not ("tutorial" in world):
		return
	if _coins0 < 0:
		_coins0 = GameState.coins
	var tut: Tutorial = world.tutorial
	if tut == null:
		if _last_key != "":
			print("ENDE: Training beendet, Münzen %d → %d, gespeichert: %s" % [_coins0, GameState.coins, GameState.tutorial_done])
			get_tree().quit()
		return
	if tut._key != _last_key:
		print("%6.1f s  Schritt: %s" % [Time.get_ticks_msec() / 1000.0, tut._key])
		_last_key = tut._key
		_wait = 0.0
		_ring = 0
	_wait += delta
	if _wait < 0.6 or tut._done_t >= 0.0:
		return
	var hero: Hero = world.heroes[world.active]
	match tut._key:
		"kamera":
			world.rig.yaw += 0.08
		"zoom":
			world.rig.distance = 4.0 if _wait < 1.2 else 12.0
		"laufen":
			hero.global_position = Tutorial.WAYPOINT_A + Vector3(0, 0.1, 0)
		"springen":
			if hero.global_position.x > -2.0:
				hero.global_position = Vector3(-3, 0.2, Tutorial.ROAD_Z)
			elif int(_wait * 2.0) % 2 == 0 and hero.is_on_floor():
				_press("jump")
			if hero.jumps - tut._jumps0 >= 2:
				hero.global_position = Tutorial.HURDLE_GOAL + Vector3(0, 0.2, 0)
		"sammeln":
			for p in tut._pieces:
				if p.visible:
					hero.global_position = p.global_position * Vector3(1, 0, 1) + Vector3(0, 0.2, 0)
					break
		"sprinten":
			if _ring < Tutorial.RINGS.size():
				hero.global_position = Vector3(Tutorial.RINGS[_ring], 0.2, Tutorial.ROAD_Z)
				_ring += 1
		"wechseln":
			if _ring == 0:
				_press("swap")
				_ring = 1
		"zweite_figur":
			hero.global_position = Tutorial.WAYPOINT_B + Vector3(0, 0.2, 0)
			if OS.get_cmdline_user_args().has("--debug"):
				print("aktiv %s, Start %s, Abstand %.2f" % [hero.display_name, tut._start_hero.display_name, Tutorial._flat(hero.global_position, Tutorial.WAYPOINT_B)])
		"truhe":
			hero.global_position = Tutorial.CHEST_POS + Vector3(0, 0.2, 1.2)
			if _wait > 1.0:
				_press("interact")


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
