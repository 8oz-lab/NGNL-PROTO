extends Node3D
## Nach dem Schachsieg: Die Kamera zieht aus dem Bildschirm zurück (Ich-Perspektive), der Röhrenmonitor
## flackert, sprüht Funken, das Glas zerspringt und ein Strudel zieht euch langsam in die Welt hinein.

const SCREEN_W := 0.36
const SCREEN_H := 0.27
const SCREEN_Z := 0.231          # Vorderseite des Bildschirms
const SCREEN_CENTER := Vector3(0, 1.0, SCREEN_Z)
const EYE := Vector3(0.06, 1.2, 1.3)

const T_PULL := 0.5      # Rückzug beginnt
const T_SETTLE := 4.2    # Kamera ist am Schreibtischstuhl
const T_SHATTER := 7.2   # Glas zerspringt
const T_PULL_IN := 8.4   # Sog beginnt
const T_END := 15.0

const SCREEN_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D screen_tex : source_color, filter_linear;
uniform float flicker = 0.0;
uniform float brightness = 1.0;
uniform float time_s = 0.0;
uniform vec4 crop = vec4(0.125, 0.0, 0.75, 1.0);
void fragment() {
	vec2 uv = UV - 0.5;
	uv *= 1.0 + dot(uv, uv) * 0.18;
	vec2 suv = crop.xy + (uv + 0.5) * crop.zw;
	// waagerechte Bildstörung beim Flackern
	float band = step(0.93, fract(sin(floor(UV.y * 40.0 + time_s * 25.0) * 91.7) * 4375.5)) * flicker;
	suv.x += band * 0.04;
	vec3 col = texture(screen_tex, suv).rgb;
	col.r = mix(col.r, texture(screen_tex, suv + vec2(0.004 * flicker, 0.0)).r, 0.8);
	col *= 0.86 + 0.14 * sin(UV.y * 900.0);
	float noise = fract(sin(dot(UV * 300.0 + time_s, vec2(12.9898, 78.233))) * 43758.5);
	col = mix(col, vec3(noise), flicker * 0.35);
	float edge = smoothstep(0.5, 0.42, max(abs(uv.x), abs(uv.y)));
	ALBEDO = col * brightness * edge;
}
"""

const VORTEX_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float time_s = 0.0;
uniform float power = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.333, 1.0);
	float r = length(p) + 1e-4;
	float a = atan(p.y, p.x);
	// Schachbrett in Polarkoordinaten: dreht sich und läuft nach innen
	float u = a / 6.2831 * 12.0 + time_s * 0.7;
	float v = log(r) * 3.0 + time_s * 2.2 + a * 0.95;
	float checker = mod(floor(u) + floor(v), 2.0);
	vec3 mint = vec3(0.66, 0.91, 0.84);
	vec3 blue = vec3(0.3, 0.5, 0.84);
	vec3 col = mix(blue, mint, checker);
	col = mix(col, vec3(1.0), smoothstep(0.22, 0.0, r));
	col += vec3(1.0, 0.85, 0.55) * smoothstep(0.08, 0.0, abs(fract(v) - 0.5) - 0.42) * 0.25;
	float fade = smoothstep(0.95, 0.25, r) * 0.85 + 0.15;
	ALBEDO = col * power * fade;
}
"""

var cam: Camera3D
var screen_mat: ShaderMaterial
var vortex_mat: ShaderMaterial
var screen_mesh: MeshInstance3D
var screen_light: OmniLight3D
var lamp: OmniLight3D
var monitor: Node3D
var sparks: Array[CPUParticles3D] = []
var shards: Array = []        # {node, vel, spin}
var floaters: Array = []      # {node, base, phase, speed}
var _t := 0.0
var _shattered := false
var _pulling := false
var _done := false
var _next_zap := 0.0
var _shake := 0.0
var _cam_roll := 0.0


func _ready() -> void:
	_build_environment()
	_build_room()
	_build_desk()
	_build_monitor()
	_build_props()
	cam = Camera3D.new()
	cam.fov = 52.0
	cam.near = 0.01
	add_child(cam)
	cam.current = true
	_place_camera(0.0)
	Flow.loop("hum", -14)
	Flow.flash(Color.WHITE, 0.01, 0.5)


# ------------------------------------------------------------------ Aufbau

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.34, 0.55)
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 1.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# Mondlicht durchs Fenster
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.62, 1.0)
	moon.light_energy = 0.2
	moon.rotation_degrees = Vector3(-35, 60, 0)
	moon.shadow_enabled = true
	add_child(moon)


func _box(size: Vector3, pos: Vector3, color: Color, parent: Node = self, outline := 0.006) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = pos
	mi.material_override = Toon.mat(color, null, Vector2.ONE, outline)
	parent.add_child(mi)
	return mi


func _build_room() -> void:
	_box(Vector3(5, 0.1, 5), Vector3(0, -0.05, 0.6), Color(0.28, 0.22, 0.24), self, 0.0)   # Boden
	_box(Vector3(5, 0.1, 5), Vector3(0, 2.6, 0.6), Color(0.3, 0.3, 0.38), self, 0.0)       # Decke
	_box(Vector3(5, 2.7, 0.1), Vector3(0, 1.3, -0.45), Color(0.36, 0.38, 0.52), self, 0.0) # Wand hinten
	_box(Vector3(0.1, 2.7, 5), Vector3(-1.6, 1.3, 0.6), Color(0.34, 0.35, 0.5), self, 0.0) # Wand links
	_box(Vector3(0.1, 2.7, 5), Vector3(1.9, 1.3, 0.6), Color(0.34, 0.35, 0.5), self, 0.0)  # Wand rechts
	# Fenster mit Jalousie, durch die Mondlicht fällt
	var win := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.8)
	win.mesh = q
	win.position = Vector3(1.0, 1.55, -0.39)
	var wm := StandardMaterial3D.new()
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wm.albedo_color = Color(0.4, 0.5, 0.95)
	win.material_override = wm
	add_child(win)
	for i in 9:
		_box(Vector3(0.94, 0.03, 0.02), Vector3(1.0, 1.2 + i * 0.09, -0.37), Color(0.75, 0.78, 0.9), self, 0.0)
	# Poster an der Wand
	var poster := _box(Vector3(0.5, 0.7, 0.01), Vector3(-0.9, 1.6, -0.39), Color(0.85, 0.35, 0.5), self, 0.0)
	poster.rotation_degrees.z = 2.0
	_box(Vector3(0.38, 0.38, 0.012), Vector3(-0.9, 1.68, -0.385), Color(0.98, 0.9, 0.6), self, 0.0)
	# Regal mit Spielen links
	_box(Vector3(0.35, 1.8, 0.9), Vector3(-1.35, 0.9, 0.2), Color(0.32, 0.24, 0.22))
	for i in 5:
		for k in 7:
			var c := Color.from_hsv(randf(), 0.55, 0.85)
			_box(Vector3(0.12, 0.2, 0.025), Vector3(-1.3, 0.3 + i * 0.34, -0.15 + k * 0.05), c, self, 0.0)


func _build_desk() -> void:
	var wood := Color(0.42, 0.3, 0.26)
	_box(Vector3(1.6, 0.05, 0.75), Vector3(0, 0.74, 0.08), wood)
	for x in [-0.76, 0.76]:
		for z in [-0.26, 0.42]:
			_box(Vector3(0.05, 0.72, 0.05), Vector3(x, 0.36, z), wood.darkened(0.2))
	# PC-Gehäuse unter dem Tisch mit blinkender LED
	_box(Vector3(0.2, 0.45, 0.45), Vector3(0.55, 0.23, 0.1), Color(0.78, 0.77, 0.72))
	var led := _box(Vector3(0.012, 0.012, 0.005), Vector3(0.6, 0.38, 0.33), Color(0.2, 1, 0.3), self, 0.0)
	led.material_override = Toon.glow(Color(0.2, 1, 0.3), 3.0)


func _build_monitor() -> void:
	monitor = Node3D.new()
	add_child(monitor)
	var beige := Color(0.62, 0.6, 0.55)
	# Rahmen vorne aus vier Teilen, damit hinter dem Glas Platz für den Strudel bleibt
	var bw := (0.48 - SCREEN_W) * 0.5
	var bh := (0.4 - SCREEN_H) * 0.5
	_box(Vector3(0.48, bh, 0.06), Vector3(0, 1.0 + SCREEN_H * 0.5 + bh * 0.5, 0.2), beige, monitor)
	_box(Vector3(0.48, bh, 0.06), Vector3(0, 1.0 - SCREEN_H * 0.5 - bh * 0.5, 0.2), beige, monitor)
	_box(Vector3(bw, SCREEN_H, 0.06), Vector3(-SCREEN_W * 0.5 - bw * 0.5, 1.0, 0.2), beige, monitor)
	_box(Vector3(bw, SCREEN_H, 0.06), Vector3(SCREEN_W * 0.5 + bw * 0.5, 1.0, 0.2), beige, monitor)
	_box(Vector3(0.44, 0.36, 0.3), Vector3(0, 1.0, 0.02), beige.darkened(0.05), monitor)
	_box(Vector3(0.32, 0.26, 0.14), Vector3(0, 1.0, -0.17), beige.darkened(0.12), monitor)
	_box(Vector3(0.28, 0.03, 0.24), Vector3(0, 0.78, 0.03), beige.darkened(0.1), monitor)  # Fuß
	_box(Vector3(0.1, 0.05, 0.1), Vector3(0, 0.81, 0.03), beige.darkened(0.15), monitor)
	var power := _box(Vector3(0.018, 0.018, 0.006), Vector3(0.19, 0.83, 0.231), Color(0.3, 1, 0.4), monitor, 0.0)
	power.material_override = Toon.glow(Color(0.3, 1, 0.4), 3.0)
	# Strudel hinter dem Glas (erst nach dem Zerspringen sichtbar)
	var vortex := MeshInstance3D.new()
	var vq := QuadMesh.new()
	vq.size = Vector2(SCREEN_W, SCREEN_H)
	vortex.mesh = vq
	vortex.position = SCREEN_CENTER + Vector3(0, 0, -0.03)
	vortex_mat = ShaderMaterial.new()
	vortex_mat.shader = _shader(VORTEX_SHADER)
	vortex.material_override = vortex_mat
	monitor.add_child(vortex)
	# Bildschirm mit dem letzten Bild vom Desktop
	var tex: Texture2D
	if Flow.screen_capture:
		tex = ImageTexture.create_from_image(Flow.screen_capture)
	else:
		tex = _fallback_texture()
	screen_mat = ShaderMaterial.new()
	screen_mat.shader = _shader(SCREEN_SHADER)
	screen_mat.set_shader_parameter("screen_tex", tex)
	screen_mesh = MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(SCREEN_W, SCREEN_H)
	screen_mesh.mesh = sq
	screen_mesh.position = SCREEN_CENTER
	screen_mesh.material_override = screen_mat
	monitor.add_child(screen_mesh)
	# Licht des Bildschirms
	screen_light = OmniLight3D.new()
	screen_light.position = SCREEN_CENTER + Vector3(0, 0.05, 0.55)
	screen_light.light_color = Color(0.6, 0.85, 1.0)
	screen_light.light_energy = 0.7
	screen_light.omni_range = 4.0
	screen_light.shadow_enabled = true
	monitor.add_child(screen_light)
	lamp = OmniLight3D.new()
	lamp.position = Vector3(-0.6, 1.5, 0.5)
	lamp.light_color = Color(1.0, 0.75, 0.5)
	lamp.light_energy = 0.3
	lamp.omni_range = 3.0
	add_child(lamp)
	# Funkenquellen an den Seiten des Monitors
	for p in [Vector3(-0.23, 1.12, 0.2), Vector3(0.23, 0.92, 0.2), Vector3(0.1, 1.2, 0.1), Vector3(-0.15, 0.84, 0.2)]:
		var s := _spark_emitter()
		s.position = p
		monitor.add_child(s)
		sparks.append(s)


func _build_props() -> void:
	# Tastatur, Maus, Dosen, Spielehüllen, Notizzettel: alles hebt später ab
	var kb := Node3D.new()
	kb.position = Vector3(0, 0.78, 0.33)
	add_child(kb)
	_box(Vector3(0.44, 0.025, 0.15), Vector3.ZERO, Color(0.85, 0.83, 0.76), kb)
	for r in 4:
		for c in 13:
			_box(Vector3(0.026, 0.012, 0.026), Vector3(-0.19 + c * 0.0317, 0.017, -0.05 + r * 0.033), Color(0.93, 0.92, 0.86), kb, 0.0)
	_float(kb, 0.6)
	var mouse := _box(Vector3(0.06, 0.03, 0.1), Vector3(0.32, 0.78, 0.33), Color(0.86, 0.85, 0.78))
	_float(mouse, 1.0)
	for spec in [[Vector3(-0.42, 0.83, 0.2), Color(0.2, 0.75, 0.95)], [Vector3(-0.5, 0.83, 0.32), Color(0.95, 0.4, 0.5)], [Vector3(0.48, 0.83, -0.05), Color(0.6, 0.95, 0.4)]]:
		var can := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.032
		cyl.bottom_radius = 0.032
		cyl.height = 0.12
		can.mesh = cyl
		can.position = spec[0]
		can.material_override = Toon.mat(spec[1], null, Vector2.ONE, 0.004)
		add_child(can)
		_float(can, randf_range(0.5, 1.3))
	for i in 4:
		var case := _box(Vector3(0.14, 0.015, 0.19), Vector3(-0.55 + randf_range(-0.05, 0.05), 0.775 + i * 0.016, -0.12), Color.from_hsv(randf(), 0.6, 0.85))
		case.rotation.y = randf_range(-0.3, 0.3)
		_float(case, randf_range(0.6, 1.2))
	for i in 6:
		var paper := _box(Vector3(0.1, 0.002, 0.1), Vector3(randf_range(-0.6, 0.6), 0.768, randf_range(0.2, 0.42)), Color(1, 0.95, 0.6), self, 0.0)
		paper.rotation.y = randf()
		_float(paper, randf_range(1.0, 1.8))
	# Gamecontroller-artige Klötze und Kabel
	for i in 2:
		var pad := _box(Vector3(0.14, 0.03, 0.08), Vector3(0.3 + i * 0.16, 0.78, 0.12), Color(0.2, 0.2, 0.25))
		_float(pad, randf_range(0.7, 1.1))


func _float(n: Node3D, speed: float) -> void:
	floaters.append({"node": n, "base": n.position, "phase": randf() * TAU, "speed": speed, "lift": 0.0})


func _spark_emitter() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = 22
	p.lifetime = 0.7
	p.explosiveness = 0.9
	p.direction = Vector3(0, 0.6, 1)
	p.spread = 70.0
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 2.2
	p.gravity = Vector3(0, -6, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var m := QuadMesh.new()
	m.size = Vector2(0.004, 0.018)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.3)
	mat.emission_energy_multiplier = 4.0
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.material = mat
	p.mesh = m
	return p


func _shader(code: String) -> Shader:
	var s := Shader.new()
	s.code = code
	return s


func _fallback_texture() -> Texture2D:
	var img := Image.create(1600, 900, false, Image.FORMAT_RGB8)
	img.fill(Win98.TEAL)
	img.fill_rect(Rect2i(420, 20, 760, 560), Win98.FACE)
	for r in 8:
		for f in 8:
			img.fill_rect(Rect2i(440 + f * 60, 70 + r * 60, 60, 60), ChessBoard.DARK if (r + f) % 2 else ChessBoard.LIGHT)
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ Ablauf

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode in [KEY_ESCAPE, KEY_F8]:
		_finish()


func _process(delta: float) -> void:
	_t += delta
	screen_mat.set_shader_parameter("time_s", _t)
	vortex_mat.set_shader_parameter("time_s", _t)
	_place_camera(delta)
	_update_screen()
	_update_shards(delta)
	_update_floaters(delta)
	if _t > T_SHATTER and not _shattered:
		_shatter()
	if _t > T_PULL_IN and not _pulling:
		_pulling = true
		Flow.loop("wind", -6)
		Flow.play("whoosh", -4, 0.7)
	if _t > T_END:
		_finish()


func _place_camera(delta: float) -> void:
	# Start: Bildschirm füllt das Bild. Dann zurück zum Stuhl, dann langsam wieder hinein.
	var start := SCREEN_CENTER + Vector3(0, 0, 0.215)
	var pos: Vector3
	if _t < T_PULL:
		pos = start
	elif _t < T_SETTLE:
		var k := ease((_t - T_PULL) / (T_SETTLE - T_PULL), 0.35)
		pos = start.lerp(EYE, k)
	elif _t < T_PULL_IN:
		pos = EYE
	else:
		var k := clampf((_t - T_PULL_IN) / (T_END - T_PULL_IN), 0.0, 1.0)
		k = k * k * k
		pos = EYE.lerp(SCREEN_CENTER + Vector3(0, 0, 0.02), k)
		cam.fov = lerpf(52.0, 85.0, k)
		_cam_roll = sin(_t * 0.9) * 0.08 * k + k * 0.6
	# Atmen und Zittern der Hand, ab dem Zerspringen starkes Beben
	var breathe := Vector3(sin(_t * 0.9) * 0.004, sin(_t * 1.3) * 0.006, 0) * clampf(_t - T_PULL, 0.0, 1.0)
	_shake = maxf(0.0, _shake - delta * 1.8)
	var quake := 0.0
	if _t > T_SETTLE:
		quake = clampf((_t - T_SETTLE) / (T_SHATTER - T_SETTLE), 0.0, 1.0) * 0.004
	if _t > T_SHATTER:
		quake = 0.006
	var q := quake + _shake * 0.03
	var jitter := Vector3(randf_range(-q, q), randf_range(-q, q), 0)
	cam.position = pos + breathe + jitter
	cam.look_at(SCREEN_CENTER + jitter * 0.5, Vector3.UP)
	cam.rotate_object_local(Vector3.FORWARD, _cam_roll)


func _update_screen() -> void:
	var flick := 0.0
	var bright := 1.0
	if _t > T_SETTLE - 1.5 and not _shattered:
		var tension := clampf((_t - (T_SETTLE - 1.5)) / (T_SHATTER - T_SETTLE + 1.5), 0.0, 1.0)
		flick = tension * (0.4 + 0.6 * float(randf() < 0.25))
		bright = 1.0 - float(randf() < tension * 0.25) * 0.85
		screen_light.light_energy = 0.7 * bright + randf() * tension * 0.4
		lamp.light_energy = 0.3 * (0.2 if randf() < tension * 0.2 else 1.0)
		if _t > _next_zap:
			_next_zap = _t + randf_range(0.25, 1.1) * (1.4 - tension)
			Flow.play("zap", -10 + tension * 6, randf_range(0.8, 1.3))
			var s: CPUParticles3D = sparks.pick_random()
			s.restart()
			s.emitting = true
			_shake = maxf(_shake, 0.25 * tension)
			monitor.position = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 0.004 * tension
	screen_mat.set_shader_parameter("flicker", flick)
	screen_mat.set_shader_parameter("brightness", bright)
	if _shattered:
		var p := clampf((_t - T_SHATTER) / 1.2, 0.0, 1.0)
		vortex_mat.set_shader_parameter("power", p * (0.8 + clampf(_t - T_PULL_IN, 0.0, 6.0) * 0.06))
		screen_light.light_energy = 0.9 + sin(_t * 9.0) * 0.25 + p * 0.5
		screen_light.light_color = Color(0.55, 0.95, 0.9).lerp(Color(1, 1, 1), clampf(_t - T_PULL_IN, 0.0, 6.0) / 6.0)
		lamp.light_energy = 0.0 if randf() < 0.3 else 0.2


## Das Glas zerspringt in Scherben, die mit dem Bild darauf auf die Kamera zufliegen.
func _shatter() -> void:
	_shattered = true
	Flow.play("shatter", 0)
	Flow.play("crack", -4, 0.8)
	Flow.flash(Color(0.8, 1, 1), 0.04, 0.35)
	Flow.stop_loop("hum", 0.3)
	_shake = 1.0
	screen_mesh.visible = false
	for s in sparks:
		s.amount = 40
		s.restart()
		s.emitting = true
	var cols := 7
	var rows := 5
	var pts := []
	for r in rows + 1:
		var row := []
		for c in cols + 1:
			var u := float(c) / cols
			var v := float(r) / rows
			if c > 0 and c < cols:
				u += randf_range(-0.4, 0.4) / cols
			if r > 0 and r < rows:
				v += randf_range(-0.4, 0.4) / rows
			row.append(Vector2(u, v))
		pts.append(row)
	for r in rows:
		for c in cols:
			var a: Vector2 = pts[r][c]
			var b: Vector2 = pts[r][c + 1]
			var d: Vector2 = pts[r + 1][c]
			var e: Vector2 = pts[r + 1][c + 1]
			if randf() < 0.5:
				_make_shard([a, b, e])
				_make_shard([a, e, d])
			else:
				_make_shard([a, b, d])
				_make_shard([b, e, d])


func _make_shard(uvs: Array) -> void:
	var center: Vector2 = (uvs[0] + uvs[1] + uvs[2]) / 3.0
	var verts := PackedVector3Array()
	var tex := PackedVector2Array()
	for uv in uvs:
		var local: Vector2 = uv - center
		verts.append(Vector3(local.x * SCREEN_W, -local.y * SCREEN_H, 0))
		tex.append(uv)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = tex
	arr[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = screen_mat
	mi.position = SCREEN_CENTER + Vector3((center.x - 0.5) * SCREEN_W, -(center.y - 0.5) * SCREEN_H, 0.002)
	add_child(mi)
	var out := Vector3((center.x - 0.5) * 2.0, -(center.y - 0.5) * 2.0, 0)
	var vel := out * randf_range(0.4, 1.4) + Vector3(0, randf_range(0.0, 0.6), randf_range(1.4, 3.2))
	shards.append({"node": mi, "vel": vel, "spin": Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9))})


func _update_shards(delta: float) -> void:
	for s in shards:
		var n: MeshInstance3D = s["node"]
		if not n.visible:
			continue
		s["vel"] += Vector3(0, -3.5, 0) * delta
		n.position += s["vel"] * delta
		n.rotation += s["spin"] * delta
		if n.position.y < 0.0 or n.position.z > 2.5:
			n.visible = false


func _update_floaters(delta: float) -> void:
	if _t < T_SHATTER - 0.8:
		return
	var suck := clampf((_t - T_PULL_IN) / (T_END - T_PULL_IN - 1.0), 0.0, 1.0)
	for f in floaters:
		var n: Node3D = f["node"]
		f["lift"] = minf(1.0, f["lift"] + delta * 0.5 * f["speed"])
		var hover: Vector3 = f["base"] + Vector3(0, 0.12 * f["lift"] + sin(_t * 2.0 + f["phase"]) * 0.02 * f["lift"], 0)
		var k := clampf(suck * f["speed"], 0.0, 1.0)
		k = k * k
		n.position = hover.lerp(SCREEN_CENTER + Vector3(0, 0, -0.05), k)
		n.rotation += Vector3(0.4, 0.9, 0.3) * delta * f["lift"] * (1.0 + k * 6.0) * f["speed"]
		n.scale = Vector3.ONE * maxf(0.01, 1.0 - k * 0.9)


func _finish() -> void:
	if _done:
		return
	_done = true
	Flow.stop_loop("hum", 0.2)
	Flow.play("whoosh", 0, 1.2)
	Flow.goto("fall", Color.WHITE, 0.5, 1.2)
