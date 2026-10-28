extends Node3D
## Sturz durch den Himmel von Disboard. Teto erklärt die Zehn Gebote, unten wartet die Insel.

const LINES := [
	["", "Willkommen! Ich bin Teto, der Gott dieser Welt. Und ihr fallt gerade mitten hinein.",
		"ようこそ！ぼくはテト、この世界の神さまだよ。君たちは今、真っ逆さまに落ちてるところ。"],
	["", "Keine Sorge, landen werdet ihr schon. Aber vorher müsst ihr die Regeln kennen. Hört gut zu!",
		"心配しないで、ちゃんと着地できるから。でもその前に、ルールを覚えてもらうよ。よく聞いてね！"],
	["I", "Erstens: Töten, Krieg und Raub sind in dieser Welt verboten.",
		"一つ、この世界におけるあらゆる殺傷、戦争、略奪を禁ずる。"],
	["II", "Zweitens: Jeder Streit wird durch ein Spiel entschieden.",
		"二つ、争いは全てゲームによる勝敗で解決するものとする。"],
	["III", "Drittens: Beide Seiten setzen etwas ein, das sie gegenseitig als gleichwertig anerkennen.",
		"三つ、ゲームには相互が対等と判断したものを賭けて行われる。"],
	["IV", "Viertens: Solange Regel drei gilt, darf alles gesetzt und jedes Spiel gespielt werden.",
		"四つ、三に反しない限り、ゲーム内容、賭けるものは一切を問わない。"],
	["V", "Fünftens: Wer herausgefordert wird, bestimmt die Regeln.",
		"五つ、ゲーム内容は、挑まれた方が決定権を有する。"],
	["VI", "Sechstens: Was nach diesen Regeln gewettet wurde, muss eingelöst werden.",
		"六つ、盟約に誓って行われた賭けは、絶対遵守される。"],
	["VII", "Siebtens: Streit zwischen Gruppen trägt ein bevollmächtigter Vertreter aus.",
		"七つ、集団における争いは、全権代理者をたてるものとする。"],
	["VIII", "Achtens: Wer beim Schummeln erwischt wird, hat verloren. Wer nicht erwischt wird … na ja.",
		"八つ、ゲーム中の不正発覚は、敗北と見なす。"],
	["IX", "Neuntens: In meinem Namen gelten diese Regeln für immer.",
		"九つ、以上をもって神の名のもと絶対不変のルールとする。"],
	["X", "Und zehntens, die wichtigste: Lasst uns alle gemeinsam Spaß haben!",
		"十、みんな仲良くプレイしましょう！"],
	["", "Das war’s. Ich freue mich darauf, euch irgendwann am Spielbrett wiederzusehen. Willkommen in Disboard!",
		"それじゃ、いつかゲーム盤の上でまた会おうね。ディスボードへようこそ！"],
]

const VOICES := ["babble", "jp", "off"]
const VOICE_NAMES := {"babble": "Brabbeln", "jp": "Japanisch (Sprachausgabe)", "off": "Aus"}
const CHARS_PER_SEC := 34.0
const ALT_START := 2600.0
const ALT_TALK_END := 700.0
const DIVE_TIME := 6.5

const CLOUD_SHADER := """
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;
uniform sampler2D noise_tex;
uniform float seed = 0.0;
uniform float fade = 1.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec2 c = UV - 0.5;
	float r = length(c * vec2(1.0, 1.5)) * 2.0;
	float n = texture(noise_tex, UV * 0.7 + seed).r * 0.65 + texture(noise_tex, UV * 1.7 - seed).r * 0.35;
	float a = smoothstep(0.42, 0.6, n * (1.25 - r));
	vec3 lit = vec3(1.0, 0.99, 0.97);
	vec3 shade = vec3(0.72, 0.74, 0.95);
	ALBEDO = mix(lit, shade, smoothstep(0.3, 0.9, UV.y) * 0.8 + (1.0 - n) * 0.2);
	ALPHA = a * fade;
}
"""

const SEA_SHADER := """
shader_type spatial;
render_mode diffuse_toon, specular_disabled;
uniform sampler2D noise_tex : repeat_enable;
varying float h;
void vertex() {
	vec2 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	h = texture(noise_tex, w * 0.00035).r * 0.7 + texture(noise_tex, w * 0.0013).r * 0.3;
	VERTEX.y += h * 140.0;
}
void fragment() {
	ALBEDO = mix(vec3(0.52, 0.58, 0.9), vec3(1.0, 0.98, 0.96), smoothstep(0.38, 0.72, h));
	ROUGHNESS = 1.0;
}
"""

var cam: Camera3D
var env: Environment
var noise: NoiseTexture2D
var clouds: Array = []
var buddies: Array = []     # kleine Schachfiguren, die mit euch fallen
var island: Node3D
var island_top := Vector3(0, 120, 0)

var line := -1
var typed := 0.0
var hold := 0.0
var voice := "babble"
var _jp_voice := ""
var _last_char := 0
var _t := 0.0
var _dive := -1.0
var _done := false
var _yaw := 0.0

var ui: CanvasLayer
var panel: PanelContainer
var text_label: Label
var jp_label: Label
var numeral: Label
var hint: Label
var orb: Control


func _ready() -> void:
	noise = NoiseTexture2D.new()
	noise.seamless = true
	noise.width = 256
	noise.height = 256
	var fn := FastNoiseLite.new()
	fn.frequency = 0.012
	fn.fractal_octaves = 4
	noise.noise = fn
	_build_environment()
	_build_sea()
	_build_landmarks()
	_build_island()
	_build_clouds()
	_build_buddies()
	cam = Camera3D.new()
	cam.fov = 68.0
	cam.far = 12000.0
	add_child(cam)
	cam.current = true
	_build_speed_lines()
	_build_ui()
	for v in DisplayServer.tts_get_voices_for_language("ja"):
		_jp_voice = v
		break
	Flow.loop("wind", -6)
	_place_camera(0.0)
	get_tree().create_timer(1.6).timeout.connect(_next_line)


# ------------------------------------------------------------------ Welt

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.16, 0.36, 0.9)
	sky_mat.sky_horizon_color = Color(0.78, 0.86, 1.0)
	sky_mat.sky_curve = 0.12
	sky_mat.ground_bottom_color = Color(0.55, 0.6, 0.92)
	sky_mat.ground_horizon_color = Color(0.82, 0.86, 1.0)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.74, 1.0)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 2.2
	env.fog_enabled = true
	env.fog_light_color = Color(0.78, 0.84, 1.0)
	env.fog_density = 0.000045
	env.fog_aerial_perspective = 0.35
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_hdr_threshold = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_energy = 1.0
	sun.rotation_degrees = Vector3(-42, -35, 0)
	add_child(sun)


func _build_sea() -> void:
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40000, 40000)
	plane.subdivide_width = 220
	plane.subdivide_depth = 220
	mi.mesh = plane
	var m := ShaderMaterial.new()
	var s := Shader.new()
	s.code = SEA_SHADER
	m.shader = s
	m.set_shader_parameter("noise_tex", noise)
	mi.material_override = m
	mi.position.y = -60
	add_child(mi)


## Riesige Schachfiguren am Horizont, wie im Anime.
func _build_landmarks() -> void:
	var specs := [
		["res://assets/models/props/chess_queen.glb", Vector3(-1900, 0, -2500), 1500.0, Color(0.92, 0.96, 1.0)],
		["res://assets/models/props/chess_knight.glb", Vector3(2300, 0, -1900), 1100.0, Color(0.55, 0.7, 1.0)],
		["res://assets/models/props/chess_bishop.glb", Vector3(600, 0, -3300), 1250.0, Color(0.8, 0.75, 1.0)],
		["res://assets/models/props/chess_queen.glb", Vector3(3000, 0, 1300), 900.0, Color(0.66, 0.92, 0.84)],
		["res://assets/models/props/chess_knight.glb", Vector3(-2900, 0, 1100), 1000.0, Color(0.95, 0.85, 1.0)],
	]
	for s in specs:
		var piece := _fit(load(s[0]).instantiate(), s[2])
		Toon.apply_to(piece, 0.0, s[3])
		piece.position = s[1]
		piece.rotation.y = randf() * TAU
		add_child(piece)


## Skaliert ein Modell auf eine Höhe und stellt es mit der Unterkante auf y = 0.
func _fit(node: Node3D, height: float) -> Node3D:
	var holder := Node3D.new()
	holder.add_child(node)
	var box := _aabb(node)
	var k := height / maxf(box.size.y, 0.001)
	node.scale = Vector3.ONE * k
	node.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * k
	return holder


func _aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var t := node.global_transform.affine_inverse() * m.global_transform if node.is_inside_tree() else _rel(node, m)
		var b := t * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _rel(root: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur and cur != root:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t


func _build_island() -> void:
	var scene: PackedScene = load("res://assets/models/props/island.glb")
	var model: Node3D = scene.instantiate()
	var box := _aabb(model)
	var k := 520.0 / maxf(box.size.x, box.size.z)
	island = Node3D.new()
	model.scale = Vector3.ONE * k
	model.position = -box.get_center() * k
	island.add_child(model)
	Toon.apply_to(model, 0.0)
	island.position = Vector3(0, box.size.y * k * 0.5 - 20.0, 0)
	add_child(island)
	island_top = Vector3(0, island.position.y + box.size.y * k * 0.5, 0)


func _build_clouds() -> void:
	var s := Shader.new()
	s.code = CLOUD_SHADER
	for i in 70:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		var w := randf_range(90, 260)
		q.size = Vector2(w, w * 0.6)
		mi.mesh = q
		var m := ShaderMaterial.new()
		m.shader = s
		m.set_shader_parameter("noise_tex", noise)
		m.set_shader_parameter("seed", randf())
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		clouds.append(mi)
	for c in clouds:
		_respawn_cloud(c, true)


func _respawn_cloud(c: MeshInstance3D, anywhere := false) -> void:
	var base := cam.position if cam else Vector3(0, ALT_START, 0)
	var ang := randf() * TAU
	var dist := randf_range(60, 700)
	var dy := randf_range(-900, 200) if anywhere else randf_range(-1100, -700)
	c.position = Vector3(base.x + cos(ang) * dist, base.y + dy, base.z + sin(ang) * dist)


func _build_buddies() -> void:
	var paths := ["res://assets/models/props/chess_knight.glb", "res://assets/models/props/chess_bishop.glb", "res://assets/models/props/chess_queen.glb", "res://assets/models/props/chess_knight.glb"]
	var tints := [Color(0.66, 0.91, 0.84), Color(0.4, 0.55, 0.95), Color(1, 1, 1), Color(0.85, 0.75, 1.0)]
	for i in paths.size():
		var piece := _fit(load(paths[i]).instantiate(), randf_range(4.0, 7.0))
		Toon.apply_to(piece, 0.012, tints[i])
		add_child(piece)
		var ang := i * TAU / paths.size() + 0.4
		buddies.append({"node": piece, "offset": Vector3(cos(ang) * randf_range(20, 30), randf_range(-24, -10), sin(ang) * randf_range(20, 30)), "spin": Vector3(randf_range(-0.5, 0.5), randf_range(-0.8, 0.8), randf_range(-0.5, 0.5))})


func _build_speed_lines() -> void:
	var p := CPUParticles3D.new()
	p.amount = 90
	p.lifetime = 0.6
	p.local_coords = true
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(18, 2, 18)
	p.position = Vector3(0, -30, 0)
	p.direction = Vector3.UP
	p.spread = 0.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 90
	p.initial_velocity_max = 140
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 5.0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.35)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	q.material = m
	p.mesh = q
	cam.add_child(p)
	# Partikel sollen senkrecht in der Welt laufen, nicht mit der Kamera kippen
	p.top_level = true
	speed_lines = p


var speed_lines: CPUParticles3D


# ------------------------------------------------------------------ Teto

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	numeral = Label.new()
	numeral.add_theme_font_override("font", Flow.font_display)
	numeral.add_theme_font_size_override("font_size", 150)
	numeral.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62))
	numeral.add_theme_color_override("font_outline_color", Color(0.24, 0.2, 0.5, 0.9))
	numeral.add_theme_constant_override("outline_size", 18)
	numeral.add_theme_color_override("font_shadow_color", Color(1.0, 0.75, 0.3, 0.6))
	numeral.add_theme_constant_override("shadow_offset_y", 0)
	numeral.add_theme_constant_override("shadow_outline_size", 40)
	numeral.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numeral.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	numeral.offset_left = -400
	numeral.offset_right = 400
	numeral.offset_top = 90
	numeral.offset_bottom = 300
	numeral.modulate.a = 0.0
	ui.add_child(numeral)

	panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.24, 0.78)
	sb.border_color = Color(1.0, 0.85, 0.5, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 20
	sb.content_margin_bottom = 18
	sb.shadow_color = Color(0.4, 0.3, 0.9, 0.35)
	sb.shadow_size = 18
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -560
	panel.offset_right = 560
	panel.offset_top = -230
	panel.offset_bottom = -40
	panel.modulate.a = 0.0
	ui.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	orb = TetoOrb.new()
	orb.custom_minimum_size = Vector2(34, 34)
	head.add_child(orb)
	var name_label := Label.new()
	name_label.text = "テト  ·  Teto"
	name_label.add_theme_font_override("font", Flow.font_ui_bold)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.5))
	head.add_child(name_label)
	text_label = Label.new()
	text_label.add_theme_font_override("font", Flow.font_ui)
	text_label.add_theme_font_size_override("font_size", 27)
	text_label.add_theme_color_override("font_color", Color.WHITE)
	text_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.25))
	text_label.add_theme_constant_override("outline_size", 4)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(1040, 76)
	text_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	v.add_child(text_label)
	jp_label = Label.new()
	jp_label.add_theme_font_override("font", Flow.font_ui)
	jp_label.add_theme_font_size_override("font_size", 17)
	jp_label.add_theme_color_override("font_color", Color(0.78, 0.8, 1.0, 0.85))
	jp_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(jp_label)

	hint = Label.new()
	hint.add_theme_font_override("font", Flow.font_ui)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	hint.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.3, 0.8))
	hint.add_theme_constant_override("outline_size", 4)
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hint.offset_left = -520
	hint.offset_right = -20
	hint.offset_top = 16
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(hint)
	_update_hint()


func _update_hint() -> void:
	var vname: String = VOICE_NAMES[voice]
	if voice == "jp" and _jp_voice == "":
		vname += " – keine japanische Stimme installiert"
	hint.text = "Klick / Leertaste: weiter   ·   V: Stimme (%s)   ·   Esc: überspringen" % vname


func _next_line() -> void:
	_tts_stop()
	line += 1
	if line >= LINES.size():
		_start_dive()
		return
	var l: Array = LINES[line]
	text_label.text = l[1]
	text_label.visible_characters = 0
	jp_label.text = l[2]
	typed = 0.0
	_last_char = 0
	hold = 0.0
	if panel.modulate.a < 1.0:
		create_tween().tween_property(panel, "modulate:a", 1.0, 0.5)
	if l[0] != "":
		numeral.text = l[0]
		numeral.modulate.a = 0.0
		numeral.scale = Vector2.ONE
		numeral.pivot_offset = Vector2(400, 105)
		var tw := create_tween().set_parallel()
		tw.tween_property(numeral, "modulate:a", 1.0, 0.4)
		tw.tween_property(numeral, "scale", Vector2.ONE * 1.08, 3.0)
		Flow.play("blip", -6, 0.6 + line * 0.05)
	else:
		create_tween().tween_property(numeral, "modulate:a", 0.0, 0.4)
	if voice == "jp" and _jp_voice != "":
		DisplayServer.tts_speak(l[2], _jp_voice, 80, 1.35, 1.05)


func _tts_stop() -> void:
	if _jp_voice != "":
		DisplayServer.tts_stop()


func _start_dive() -> void:
	_dive = 0.0
	create_tween().tween_property(panel, "modulate:a", 0.0, 0.6)
	create_tween().tween_property(numeral, "modulate:a", 0.0, 0.4)
	create_tween().tween_property(hint, "modulate:a", 0.0, 0.6)
	Flow.play("whoosh", -2, 0.8)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_V:
				voice = VOICES[(VOICES.find(voice) + 1) % VOICES.size()]
				if voice != "jp":
					_tts_stop()
				_update_hint()
			KEY_SPACE, KEY_ENTER:
				_advance()
			KEY_ESCAPE, KEY_F8:
				_finish()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _advance() -> void:
	if line < 0 or line >= LINES.size() or _dive >= 0.0:
		return
	var total: int = LINES[line][1].length()
	if typed < total:
		typed = total
	else:
		_next_line()


func _process(delta: float) -> void:
	_t += delta
	if line >= 0 and line < LINES.size():
		var total: int = LINES[line][1].length()
		if typed < total:
			typed = minf(total, typed + delta * CHARS_PER_SEC)
			var n := int(typed)
			text_label.visible_characters = n
			if voice == "babble" and n - _last_char >= 3:
				var ch: String = LINES[line][1][n - 1]
				if ch != " ":
					Flow.play("babble", -9, randf_range(1.25, 1.7))
				_last_char = n
		else:
			hold += delta
			if hold > 2.2 + total * 0.022:
				_next_line()
	(orb as TetoOrb).talking = line >= 0 and line < LINES.size() and typed < LINES[line][1].length()
	if _dive >= 0.0:
		_dive += delta
		if _dive > DIVE_TIME:
			_finish()
	_place_camera(delta)
	_update_clouds()
	_update_buddies(delta)


## Höhe hängt vom Fortschritt des Gesprächs ab, am Ende folgt der Sturzflug auf die Insel.
func _progress() -> float:
	if line < 0:
		return 0.0
	if line >= LINES.size():
		return 1.0
	var total: float = LINES[line][1].length()
	var within := clampf(typed / total * 0.6 + hold / 6.0, 0.0, 1.0)
	return clampf((line + within) / LINES.size(), 0.0, 1.0)


var _prog_smooth := 0.0


func _place_camera(delta: float) -> void:
	_prog_smooth = lerpf(_prog_smooth, _progress(), clampf(delta * 0.8, 0.0, 1.0))
	_yaw += delta * 0.05
	var alt := lerpf(ALT_START, ALT_TALK_END, _prog_smooth) - _t * 2.0
	var radius := lerpf(420.0, 240.0, _prog_smooth)
	var pitch := deg_to_rad(-27.0)
	if _dive >= 0.0:
		var k := clampf(_dive / DIVE_TIME, 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)
		alt = lerpf(ALT_TALK_END - _t * 2.0, island_top.y + 25.0, e)
		radius = lerpf(240.0, 30.0, e)
		pitch = deg_to_rad(lerpf(-27.0, -68.0, e))
		cam.fov = lerpf(68.0, 80.0, e)
	var pos := Vector3(cos(_yaw) * radius, alt, sin(_yaw) * radius)
	# Blick Richtung Inselmitte, sanftes Taumeln im Wind
	var to := (island_top - pos)
	var heading := atan2(-to.x, -to.z)
	cam.position = pos + Vector3(sin(_t * 1.7), sin(_t * 2.3) * 0.5, cos(_t * 1.3)) * 0.6
	cam.rotation = Vector3(pitch + sin(_t * 0.8) * 0.03, heading, sin(_t * 0.6) * 0.06)
	if speed_lines:
		speed_lines.global_position = cam.global_position + Vector3(0, -35, 0)


func _update_clouds() -> void:
	for c in clouds:
		var mi := c as MeshInstance3D
		var dy := mi.position.y - cam.position.y
		if dy > 260.0:
			_respawn_cloud(mi)
		# Wolken direkt vor der Linse ausblenden
		var d := mi.position.distance_to(cam.position)
		(mi.material_override as ShaderMaterial).set_shader_parameter("fade", clampf((d - 40.0) / 120.0, 0.0, 1.0))


func _update_buddies(delta: float) -> void:
	for b in buddies:
		var n: Node3D = b["node"]
		var target: Vector3 = cam.position + Vector3(b["offset"]).rotated(Vector3.UP, cam.rotation.y)
		n.position = n.position.lerp(target, clampf(delta * 2.0, 0.0, 1.0)) if n.position != Vector3.ZERO else target
		n.rotation += b["spin"] * delta
		n.visible = _dive < 2.0


func _finish() -> void:
	if _done:
		return
	_done = true
	_tts_stop()
	Flow.stop_loop("wind", 1.0)
	Flow.goto("world", Color.WHITE, 0.6, 1.4)


## Kleines leuchtendes Abzeichen neben Tetos Namen, pulsiert beim Sprechen.
class TetoOrb extends Control:
	var talking := false
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta * (9.0 if talking else 2.0)
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := 11.0 + sin(_t) * (2.5 if talking else 1.0)
		draw_circle(c, r + 6.0, Color(1.0, 0.8, 0.4, 0.25))
		draw_circle(c, r, Color(1.0, 0.9, 0.6))
		var star := PackedVector2Array()
		for i in 10:
			var a := -PI / 2 + i * PI / 5
			var rr := r * (0.85 if i % 2 == 0 else 0.38)
			star.append(c + Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(star, Color(0.35, 0.3, 0.8))
