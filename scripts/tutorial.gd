class_name Tutorial
extends Node
## Tetos Steuerungs-Training nach der Landung: Kamera, Zoom, Laufen, Springen, Sammeln, Sprinten,
## Figur wechseln, Interagieren. Jede Aufgabe zeigt die passenden Tasten, die beim Drücken aufleuchten.
## F1 überspringt das Training (und startet es später erneut).

signal finished

## Schritt, deutscher Text, japanischer Text (gesprochen, erzeugt mit tools/make_teto_voice.py)
const LINES := [
	["intro", "Ihr seid gelandet! Bevor ihr Elkia erobert, zeige ich euch kurz, wie ihr euch bewegt.",
		"着いたね！エルキアを攻略する前に、動き方を教えてあげる。"],
	["kamera", "Schaut euch um: Haltet eine Maustaste gedrückt und zieht die Maus.",
		"まずは周りを見てみて。マウスのボタンを押したまま動かすんだ。"],
	["zoom", "Mit dem Mausrad holt ihr die Kamera näher heran oder weiter weg. Probiert beides!",
		"マウスホイールでカメラを近づけたり、遠ざけたりできるよ。両方やってみて！"],
	["laufen", "Mit W, A, S und D lauft ihr. Geht zum leuchtenden Wegstein auf eurem Grundstück.",
		"W、A、S、Dで歩けるよ。土地の光る石まで行ってみて。"],
	["springen", "Mit der Leertaste springt ihr. Auf der Straße stehen Hürden. Springt drüber bis zum Licht!",
		"スペースキーでジャンプできるよ。道のハードルを跳び越えて、光のところまで行って！"],
	["sammeln", "Auf dem Grundstück liegen fünf goldene Schachfiguren. Sammelt sie alle ein!",
		"土地に金色の駒が五つ落ちてるよ。全部集めて！"],
	["sprinten", "Haltet Shift, um zu sprinten. Lauft durch alle Ringe an der Straße, bevor die Zeit abläuft!",
		"シフトを押しながら走ってみて。時間内に道の輪を全部くぐるんだ！"],
	["zu_langsam", "Zu langsam! Die Ringe sind wieder da. Noch einmal, und diesmal mit Shift!",
		"遅い遅い！もう一回、今度はシフトでね！"],
	["wechseln", "Ihr seid zu zweit. Drückt Q, um zwischen Sora und Shiro zu wechseln.",
		"君たちは二人で一人。Qでソラとシロを切り替えられるよ。"],
	["zweite_figur", "Gut so! Jetzt lauft mit der anderen Figur zum zweiten Wegstein.",
		"いいね！じゃあ、もう一人で二つ目の石まで行ってみて。"],
	["truhe", "Zum Schluss: Geht zur Schatztruhe und drückt E, um sie zu öffnen.",
		"最後に、宝箱の前でEを押して開けてみて。"],
	["fertig", "Perfekt! Ihr beherrscht die Steuerung. Die fünfzig Münzen aus der Truhe gehören euch. Viel Spaß in Disboard!",
		"完璧！もう操作はばっちりだね。宝箱のコイン五十枚は君たちのものだよ。ディスボードを楽しんで！"],
]
const VOICE_PATH := "res://assets/audio/teto/tutorial_%02d.ogg"
const STEPS := ["intro", "kamera", "zoom", "laufen", "springen", "sammeln", "sprinten", "wechseln", "zweite_figur", "truhe", "fertig"]
const TASKS := {
	"kamera": ["Umsehen", [["Maustaste halten + ziehen", ""]]],
	"zoom": ["Zoomen", [["Mausrad", ""]]],
	"laufen": ["Zum Wegstein laufen", [["W", "move_forward"], ["A", "move_left"], ["S", "move_back"], ["D", "move_right"]]],
	"springen": ["Über die Hürden springen", [["Leertaste", "jump"], ["W", "move_forward"], ["A", "move_left"], ["S", "move_back"], ["D", "move_right"]]],
	"sammeln": ["Goldene Figuren sammeln", [["W", "move_forward"], ["A", "move_left"], ["S", "move_back"], ["D", "move_right"]]],
	"sprinten": ["Durch alle Ringe sprinten", [["Shift", "sprint"], ["W", "move_forward"], ["A", "move_left"], ["S", "move_back"], ["D", "move_right"]]],
	"wechseln": ["Figur wechseln", [["Q", "swap"]]],
	"zweite_figur": ["Mit der anderen Figur zum Wegstein", [["W", "move_forward"], ["A", "move_left"], ["S", "move_back"], ["D", "move_right"]]],
	"truhe": ["Schatztruhe öffnen", [["E", "interact"]]],
}
const GOLD := Color(1.0, 0.78, 0.3)
const WAYPOINT_A := Vector3(0, 0, 1.5)
const WAYPOINT_B := Vector3(-6, 0, -0.5)
const HURDLES := [-5.0, -10.0, -15.0]
const HURDLE_GOAL := Vector3(-19, 0, 14.5)
const PIECES := [Vector3(-6, 0, -6), Vector3(6, 0, -6), Vector3(-6, 0, 5), Vector3(6, 0, 5), Vector3(0.5, 0, 6.5)]
const RINGS := [8.0, 15.0, 22.0, 29.0, 36.0]
const RING_TIME := 6.0
const CHEST_POS := Vector3(5.5, 0, -4.5)
const REWARD := 50
const ROAD_Z := 14.5

var world: Node3D
var step := -1
var _key := ""
var _voice: AudioStreamPlayer
var _t := 0.0
var _done_t := -1.0
var _yaw0 := 0.0
var _turned := 0.0
var _zoom_min := 99.0
var _zoom_max := 0.0
var _jumps0 := 0
var _start_hero: Node3D
var _ring_next := 0
var _ring_timer := -1.0
var _chest_open := false

var _markers: Array[Node3D] = []
var _pieces: Array[Node3D] = []
var _rings: Array[Node3D] = []
var _hurdles: Array[Node3D] = []
var _chest: Node3D
var _beam: Node3D

var ui: CanvasLayer
var card: PanelContainer
var step_label: Label
var teto_label: Label
var task_label: Label
var keys_row: HBoxContainer
var progress: Label
var _caps := {}   # Aktion -> Tastenfeld


func _ready() -> void:
	_voice = AudioStreamPlayer.new()
	add_child(_voice)
	_build_ui()
	_build_props()
	# Entwicklerhilfe: `--tutorial-step=sprinten` beginnt direkt bei einem Schritt
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tutorial-step="):
			step = STEPS.find(arg.trim_prefix("--tutorial-step=")) - 1
	_next()


# ------------------------------------------------------------------ Ablauf

func _next() -> void:
	step += 1
	if step >= STEPS.size():
		_finish()
		return
	_key = STEPS[step]
	_t = 0.0
	_done_t = -1.0
	_say(_key)
	var task: Array = TASKS.get(_key, ["", []])
	task_label.text = task[0]
	task_label.visible = task[0] != ""
	_set_keys(task[1])
	progress.text = ""
	step_label.text = "Schritt %d / %d" % [step, STEPS.size() - 2] if step > 0 and _key != "fertig" else ""
	var hero := _hero()
	match _key:
		"kamera":
			_yaw0 = world.rig.yaw
			_turned = 0.0
		"zoom":
			_zoom_min = world.rig.distance
			_zoom_max = world.rig.distance
		"laufen":
			_beam_at(WAYPOINT_A)
		"springen":
			_jumps0 = hero.jumps
			for h in _hurdles:
				h.visible = true
			_beam_at(HURDLE_GOAL)
		"sammeln":
			for p in _pieces:
				p.visible = true
		"sprinten":
			_reset_rings()
		"wechseln":
			_start_hero = hero
		"zweite_figur":
			_beam_at(WAYPOINT_B)
		"truhe":
			_chest.visible = true
			_beam_at(CHEST_POS)
		"fertig":
			Flow.play("mate", -4)
			_beam.visible = false
			GameState.coins += REWARD
			GameState.tutorial_done = true
			GameState.save_game()
			GameState.changed.emit()
			card.get_theme_stylebox("panel").border_color = GOLD


func _process(delta: float) -> void:
	_t += delta
	_animate(delta)
	_highlight_keys()
	if _done_t >= 0.0:
		_done_t += delta
		if _done_t > 1.1 and not _voice.playing:
			_next()
		return
	var hero := _hero()
	var p: Vector3 = hero.global_position
	match _key:
		"intro":
			if _t > 1.0 and not _voice.playing:
				_complete()
		"kamera":
			_turned += absf(angle_difference(_yaw0, world.rig.yaw))
			_yaw0 = world.rig.yaw
			progress.text = "%d %%" % mini(100, int(_turned / 1.6 * 100.0))
			if _turned > 1.6:
				_complete()
		"zoom":
			_zoom_min = minf(_zoom_min, world.rig.distance)
			_zoom_max = maxf(_zoom_max, world.rig.distance)
			var near: bool = _zoom_min < 6.0
			var far: bool = _zoom_max > 10.0
			progress.text = "Näher %s   ·   Weiter weg %s" % ["✓" if near else "–", "✓" if far else "–"]
			if near and far:
				_complete()
		"laufen":
			progress.text = "Noch %.0f m" % _flat(p, WAYPOINT_A)
			if _flat(p, WAYPOINT_A) < 1.5:
				_complete()
		"springen":
			var jumps: int = hero.jumps - _jumps0
			progress.text = "Sprünge: %d" % jumps
			if p.x < HURDLE_GOAL.x + 1.5 and absf(p.z - HURDLE_GOAL.z) < 4.0 and jumps >= 2:
				for h in _hurdles:
					h.visible = false
				_complete()
		"sammeln":
			var left := 0
			for piece in _pieces:
				if not piece.visible:
					continue
				if _flat(p, piece.global_position) < 1.3:
					piece.visible = false
					_sparkle(piece.global_position + Vector3(0, 0.6, 0))
					Flow.play("blip", -4, 1.6)
				else:
					left += 1
			progress.text = "%d / %d gesammelt" % [PIECES.size() - left, PIECES.size()]
			if left == 0:
				_complete()
		"sprinten":
			_update_rings(p, delta)
		"wechseln":
			if hero != _start_hero:
				_complete()
		"zweite_figur":
			if hero == _start_hero:
				progress.text = "Erst mit Q zu %s wechseln" % _other_name()
			else:
				progress.text = "Noch %.0f m mit %s" % [_flat(p, WAYPOINT_B), (hero as Hero).display_name]
			if hero != _start_hero and _flat(p, WAYPOINT_B) < 1.5:
				_complete()
		"truhe":
			progress.text = "Noch %.0f m" % maxf(0.0, _flat(p, CHEST_POS) - 1.8) if not _chest_open else ""
		"fertig":
			if _t > 1.0 and not _voice.playing:
				_finish()


func _complete() -> void:
	if _done_t >= 0.0:
		return
	_done_t = 0.0
	progress.text = "Geschafft!"
	Flow.play("check", -6, 1.3)
	_beam.visible = false
	var tw := create_tween()
	tw.tween_property(card, "scale", Vector2.ONE * 1.04, 0.1)
	tw.tween_property(card, "scale", Vector2.ONE, 0.2)


func skip() -> void:
	GameState.tutorial_done = true
	GameState.save_game()
	_finish()


func _finish() -> void:
	_voice.stop()
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func():
		finished.emit()
		queue_free())


func _other_name() -> String:
	for h in world.heroes:
		if h != _start_hero:
			return h.display_name
	return ""


func _hero() -> Node3D:
	return world.heroes[world.active]


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _say(key: String) -> void:
	for i in LINES.size():
		if LINES[i][0] == key:
			teto_label.text = LINES[i][1]
			var path := VOICE_PATH % i
			if ResourceLoader.exists(path):
				_voice.stream = load(path)
				_voice.play()
			return


# ------------------------------------------------------------------ Truhe (über die Interaktion der Welt)

## Text für den Hinweis unten, wenn die Figur an der Truhe steht (sonst leer).
func spot_label(p: Vector3) -> String:
	if _key == "truhe" and not _chest_open and _flat(p, CHEST_POS) < 1.9:
		return "E · Truhe öffnen"
	return ""


func interact() -> void:
	if _key != "truhe" or _chest_open:
		return
	_chest_open = true
	Flow.play("capture", -2, 0.8)
	Flow.play("welcome", -8, 1.2)
	_sparkle(CHEST_POS + Vector3(0, 1.0, 0), 60)
	var tw := create_tween()
	tw.tween_property(_chest, "scale", Vector3(1.15, 0.85, 1.15), 0.1)
	tw.tween_property(_chest, "scale", Vector3(0.95, 1.12, 0.95), 0.12)
	tw.tween_property(_chest, "scale", Vector3.ONE, 0.2)
	progress.text = "+%d Münzen" % REWARD
	_complete()


# ------------------------------------------------------------------ Ringe

func _reset_rings() -> void:
	_ring_next = 0
	_ring_timer = -1.0
	for r in _rings:
		r.visible = true
		r.set_meta("hit", false)
	_beam_at(Vector3(RINGS[0], 0, ROAD_Z))


func _update_rings(p: Vector3, delta: float) -> void:
	if _ring_next < _rings.size():
		var r: Node3D = _rings[_ring_next]
		if absf(p.x - r.position.x) < 1.0 and absf(p.z - r.position.z) < 2.0:
			r.visible = false
			_sparkle(r.position, 20)
			Flow.play("blip", -6, 1.0 + _ring_next * 0.15)
			_ring_next += 1
			if _ring_next == 1:
				_ring_timer = RING_TIME
				_beam.visible = false
			if _ring_next == _rings.size():
				_complete()
				return
	if _ring_timer >= 0.0:
		_ring_timer -= delta
		progress.text = "Ring %d / %d   ·   %.1f s" % [_ring_next, _rings.size(), maxf(0.0, _ring_timer)]
		if _ring_timer <= 0.0:
			Flow.play("blip", -4, 0.5)
			_say("zu_langsam")
			_reset_rings()
	else:
		progress.text = "Ring 0 / %d   ·   Die Zeit läuft ab dem ersten Ring" % _rings.size()


# ------------------------------------------------------------------ Objekte in der Welt

func _build_props() -> void:
	# Lichtsäule, die das aktuelle Ziel markiert
	_beam = Node3D.new()
	world.add_child(_beam)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 0.9
	cyl.height = 14.0
	var beam := MeshInstance3D.new()
	beam.mesh = cyl
	beam.position.y = 7.0
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.albedo_color = Color(0.4, 0.85, 1.0, 0.35)
	bm.albedo_texture = _fade_texture()
	beam.material_override = bm
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam.add_child(beam)
	_beam.visible = false
	# Wegsteine
	for pos in [WAYPOINT_A, WAYPOINT_B]:
		var stone := _model("res://assets/models/tutorial/wegstein.glb", 1.4, Color.WHITE)
		stone.position = pos
		_markers.append(stone)
	# Hürden quer über die Straße
	for x in HURDLES:
		var h := Node3D.new()
		h.position = Vector3(x, 0, ROAD_Z)
		world.add_child(h)
		for z in [-2.6, 2.6]:
			world._box(Vector3(0.18, 0.75, 0.18), Vector3(0, 0.37, z), Color("8a5a3c"), 0.015, true, h)
		world._box(Vector3(0.14, 0.18, 5.4), Vector3(0, 0.62, 0), Color("e04a5f"), 0.015, true, h)
		world._box(Vector3(0.14, 0.18, 5.4), Vector3(0, 0.28, 0), Color("f4f0e8"), 0.015, true, h)
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.3, 0.7, 6.0)
		shape.shape = box
		shape.position.y = 0.35
		body.add_child(shape)
		h.add_child(body)
		h.visible = false
		_hurdles.append(h)
	# Goldene Schachfiguren
	var scenes := ["res://assets/models/props/chess_queen.glb", "res://assets/models/props/chess_knight.glb", "res://assets/models/props/chess_bishop.glb"]
	for i in PIECES.size():
		var piece := _model(scenes[i % scenes.size()], 1.2, GOLD)
		piece.position = PIECES[i] + Vector3(0, 0.3, 0)
		for mi in piece.find_children("*", "MeshInstance3D", true, false):
			for k in (mi as MeshInstance3D).get_surface_override_material_count():
				var m := (mi as MeshInstance3D).get_surface_override_material(k) as ShaderMaterial
				if m:
					m.set_shader_parameter("emission_color", Color(1.0, 0.7, 0.2) * 0.45)
		piece.visible = false
		_pieces.append(piece)
	# Ringe an der Straße
	for x in RINGS:
		var ring := Node3D.new()
		ring.position = Vector3(x, 1.4, ROAD_Z)
		world.add_child(ring)
		var tm := TorusMesh.new()
		tm.inner_radius = 1.25
		tm.outer_radius = 1.45
		var mi := MeshInstance3D.new()
		mi.mesh = tm
		mi.rotation.z = PI * 0.5
		mi.material_override = Toon.glow(Color(1.0, 0.75, 0.3), 1.4)
		ring.add_child(mi)
		ring.visible = false
		_rings.append(ring)
	# Schatztruhe
	_chest = _model("res://assets/models/tutorial/schatztruhe.glb", 1.1, Color.WHITE)
	_chest.position = CHEST_POS
	_chest.visible = false


## Lädt ein Modell (oder eine einfache Ersatzform), skaliert es auf eine Höhe und gibt ihm Toon-Look.
func _model(path: String, height: float, tint: Color) -> Node3D:
	var holder := Node3D.new()
	world.add_child(holder)
	if not ResourceLoader.exists(path):
		world._box(Vector3(height, height, height) * 0.7, Vector3(0, height * 0.35, 0), tint, 0.02, true, holder)
		return holder
	var m: Node3D = load(path).instantiate()
	holder.add_child(m)
	var box := AABB()
	var first := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (holder.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var k := height / maxf(box.size.y, 0.01)
	m.scale *= k
	m.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * k
	Toon.apply_to(m, 0.012 / k, tint)
	return holder


func _beam_at(pos: Vector3) -> void:
	_beam.position = Vector3(pos.x, 0, pos.z)
	_beam.visible = true


func _animate(_delta: float) -> void:
	for i in _pieces.size():
		var p := _pieces[i]
		p.rotation.y = _t * 1.6 + i
		p.position.y = 0.3 + sin(_t * 2.5 + i) * 0.15
	for i in _markers.size():
		_markers[i].rotation.y = _t * 0.4
	for r in _rings:
		r.scale = Vector3.ONE * (1.0 + sin(_t * 4.0) * 0.04)
	if _beam.visible:
		_beam.scale = Vector3(1.0 + sin(_t * 3.0) * 0.08, 1.0, 1.0 + sin(_t * 3.0) * 0.08)


func _sparkle(pos: Vector3, amount := 30) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.9
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	p.gravity = Vector3(0, -6, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(1.0, 0.86, 0.4)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.75, 0.3)
	m.emission_energy_multiplier = 2.0
	q.material = m
	p.mesh = q
	p.position = pos
	world.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


func _fade_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 1))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	return t


# ------------------------------------------------------------------ Anzeige

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	card = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.24, 0.82)
	sb.border_color = Color(0.55, 0.85, 1.0, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0.3, 0.2, 0.8, 0.35)
	sb.shadow_size = 14
	card.add_theme_stylebox_override("panel", sb)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	card.offset_left = -390
	card.offset_right = 390
	card.offset_top = 18
	card.pivot_offset = Vector2(390, 60)
	ui.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	head.add_child(_label("テト  ·  Tetos Steuerungs-Training", 15, GOLD, Flow.font_ui_bold))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	step_label = _label("", 13, Color(0.75, 0.8, 1.0))
	head.add_child(step_label)
	teto_label = _label("", 18, Color.WHITE)
	teto_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teto_label.custom_minimum_size.x = 730
	v.add_child(teto_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	task_label = _label("", 15, Color(0.55, 0.9, 1.0), Flow.font_ui_bold)
	row.add_child(task_label)
	keys_row = HBoxContainer.new()
	keys_row.add_theme_constant_override("separation", 5)
	row.add_child(keys_row)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp2)
	progress = _label("", 15, GOLD, Flow.font_ui_bold)
	row.add_child(progress)
	var hint := _label("F1: Training überspringen", 11, Color(1, 1, 1, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(hint)
	card.modulate.a = 0.0
	create_tween().tween_property(card, "modulate:a", 1.0, 0.5)


func _label(text: String, size: int, color: Color, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else Flow.font_ui)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _set_keys(keys: Array) -> void:
	for c in keys_row.get_children():
		c.queue_free()
	_caps.clear()
	for k in keys:
		var cap := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.93, 0.93, 1.0)
		sb.border_color = Color(0.55, 0.55, 0.75)
		sb.border_width_bottom = 4
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		cap.add_theme_stylebox_override("panel", sb)
		cap.add_child(_label(k[0], 14, Color(0.12, 0.1, 0.3), Flow.font_ui_bold))
		keys_row.add_child(cap)
		if k[1] != "":
			_caps[k[1]] = sb


## Gedrückte Tasten leuchten golden auf.
func _highlight_keys() -> void:
	for action in _caps:
		var sb: StyleBoxFlat = _caps[action]
		var down := Input.is_action_pressed(action)
		sb.bg_color = GOLD if down else Color(0.93, 0.93, 1.0)
		sb.border_width_bottom = 1 if down else 4
