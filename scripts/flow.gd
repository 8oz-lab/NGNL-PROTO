extends CanvasLayer
## Autoload "Flow": Szenenwechsel mit Blende, Klänge und gemeinsame Schriften.

const SCENES := {
	"desktop": "res://scenes/intro/desktop.tscn",
	"break": "res://scenes/intro/break_sequence.tscn",
	"fall": "res://scenes/intro/fall_sequence.tscn",
	"world": "res://scenes/main.tscn",
}

## Bild vom Bildschirm im Moment des Schachsiegs (für den zerbrechenden Monitor)
var screen_capture: Image

var _fade: ColorRect
var _players: Array[AudioStreamPlayer] = []
var _loops := {}
var _sounds := {}

var _shot_path := ""
var _shot_times: Array = []
var _shot_t := 0.0

var font_ui: FontFile
var font_ui_bold: FontFile
var font_display: FontFile
var font_pixel: FontFile


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(1, 1, 1, 0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_load_fonts()
	_dev_args()


## Wechselt die Szene mit einer Blende in der angegebenen Farbe.
func goto(key: String, color := Color.BLACK, out_time := 0.4, in_time := 0.5) -> void:
	_fade.color = Color(color, _fade.color.a)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, out_time)
	await tw.finished
	get_tree().change_scene_to_file(SCENES[key])
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, in_time)


func flash(color := Color.WHITE, up := 0.15, down := 0.6) -> void:
	_fade.color = Color(color, 0.0)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, up)
	tw.tween_property(_fade, "color:a", 0.0, down)


func play(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	var stream := _stream(name)
	if stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return


func loop(name: String, volume_db := 0.0) -> void:
	if _loops.has(name):
		return
	var src := _stream(name)
	if src == null:
		return
	var stream := src.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = stream.data.size() / 2
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = -40.0
	add_child(p)
	p.play()
	create_tween().tween_property(p, "volume_db", volume_db, 0.8)
	p.set_meta("base_db", volume_db)
	_loops[name] = p


## Senkt eine Schleife vorübergehend ab (offset in dB relativ zur ursprünglichen Lautstärke, 0 = normal).
func duck(name: String, offset: float, time := 0.4) -> void:
	if not _loops.has(name):
		return
	var p: AudioStreamPlayer = _loops[name]
	var target: float = p.get_meta("base_db", p.volume_db) + offset
	if p.get_meta("duck", 0.0) == offset:
		return
	p.set_meta("duck", offset)
	create_tween().tween_property(p, "volume_db", target, time)


func stop_loop(name: String, time := 0.8) -> void:
	if not _loops.has(name):
		return
	var p: AudioStreamPlayer = _loops[name]
	_loops.erase(name)
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -40.0, time)
	tw.tween_callback(p.queue_free)


func _stream(name: String) -> AudioStreamWAV:
	if not _sounds.has(name):
		var path := "res://assets/audio/%s.wav" % name
		_sounds[name] = load(path) if ResourceLoader.exists(path) else null
	return _sounds[name]


func _load_fonts() -> void:
	var jp: FontFile = load("res://assets/fonts/mplus-rounded-japanese-400.woff2")
	var ext: FontFile = load("res://assets/fonts/mplus-rounded-latinext-400.woff2")
	var sym: FontFile = load("res://assets/fonts/noto-symbols2.woff2")
	font_ui = load("res://assets/fonts/mplus-rounded-latin-400.woff2")
	font_ui.fallbacks = [ext, jp, sym]
	font_ui_bold = load("res://assets/fonts/mplus-rounded-latin-800.woff2")
	font_ui_bold.fallbacks = [ext, jp, sym]
	font_display = load("res://assets/fonts/cinzel-700.woff2")
	font_display.fallbacks = [font_ui]
	font_pixel = load("res://assets/fonts/dotgothic16-latin.woff2")
	font_pixel.fallbacks = [load("res://assets/fonts/dotgothic16-japanese.woff2")]


## Entwicklerhilfe: `-- --start=fall --shots=bild.png --at=2,5,9` springt in eine Szene,
## speichert zu den angegebenen Sekunden Bilder und beendet danach das Spiel.
func _dev_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--start="):
			var key := arg.trim_prefix("--start=")
			get_tree().change_scene_to_file.call_deferred(SCENES[key])
		elif arg.begins_with("--probe="):
			# Hängt ein Prüfskript an (z. B. res://tests/voice_probe.gd), das während des Spiels mitliest
			var probe := Node.new()
			probe.set_script(load(arg.trim_prefix("--probe=")))
			add_child(probe)
		elif arg.begins_with("--shots="):
			_shot_path = arg.trim_prefix("--shots=")
		elif arg.begins_with("--at="):
			_shot_times = Array(arg.trim_prefix("--at=").split(",")).map(func(x): return float(x))
	if _shot_path != "" and _shot_times.is_empty():
		_shot_times = [3.0]
	set_process(_shot_path != "")


func _process(delta: float) -> void:
	_shot_t += delta
	if not _shot_times.is_empty() and _shot_t >= _shot_times[0]:
		_shot_times.pop_front()
		var img := get_viewport().get_texture().get_image()
		img.save_png(_shot_path.replace(".png", "_%04.1f.png" % _shot_t))
		if _shot_times.is_empty():
			get_tree().quit()
