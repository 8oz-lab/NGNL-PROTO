extends Node3D
## Das Grundstück am Stadtrand von Elkia: Gelände, Parzellen, Hütte, Nachbarschaft, Figuren und Steuerung.

const SORA_SCENE := preload("res://assets/models/characters/sora_neu.glb")
const SHIRO_SCENE := preload("res://assets/models/characters/shiro_neu.glb")
# Ältere Modelle mit Mixamo-Animationen: liefern, was den neuen Modellen fehlt
const SORA_ANIMS := preload("res://assets/models/characters/sora.glb")
const SHIRO_ANIMS := preload("res://assets/models/characters/shiro.glb")
const QUEEN_SCENE := preload("res://assets/models/props/chess_queen.glb")
const GROUND_SHADER := preload("res://assets/shaders/ground.gdshader")

const PARCEL := 6.0          # Kantenlänge einer Parzelle in Metern
const HALF := 9.0            # halbe Breite des Grundstücks (3 × 6 m)
const FENCE := HALF + 0.4
const ROOF_COLORS := [Color("3f5fae"), Color("b8443c"), Color("4a8c5a"), Color("7f56b8"), Color("c77e2c"), Color("2f8fa8")]
## Baum-Modelle (erzeugt mit tools/make_trees.gd): Szene, Höhe ab der die Krone im Wind wiegt, Stammbreite
const TREES := {
	"laubbaum": [preload("res://assets/models/trees/laubbaum.glb"), 2.3, 0.6],
	"laubbaum_gross": [preload("res://assets/models/trees/laubbaum_gross.glb"), 3.0, 0.8],
	"kirschbaum": [preload("res://assets/models/trees/kirschbaum.glb"), 2.0, 0.6],
	"tanne": [preload("res://assets/models/trees/tanne.glb"), 1.2, 0.5],
	"birke": [preload("res://assets/models/trees/birke.glb"), 2.4, 0.4],
	"busch": [preload("res://assets/models/trees/busch.glb"), 0.2, 0.0],
}
## Mischung für den Waldrand: Art und Gewicht
const FOREST_MIX := [["laubbaum", 30], ["laubbaum_gross", 18], ["tanne", 24], ["birke", 16], ["kirschbaum", 12]]

var heroes: Array[Hero] = []
var active := 0
var rig: CameraRig
var hud: Hud
var highlight: Node3D
var current_parcel := ""
var _spot: Dictionary = {}
var _smoke: Array[MeshInstance3D] = []
var _flags: Array[Node3D] = []
var _time := 0.0
var _rng := RandomNumberGenerator.new()

var grass_tex: Texture2D
var cobble_tex: Texture2D
var noise_tex: NoiseTexture2D
var grass: GrassField
var _footprints: Array[Rect2] = []


func _ready() -> void:
	_rng.seed = 1209
	_build_environment()
	_build_textures()
	_build_ground()
	_build_plot()
	_build_hut()
	_build_neighbourhood()
	_build_grass()
	_spawn_heroes()
	# Entwicklerhilfe: `-- --capture=bild.png` speichert nach kurzer Zeit ein Bild und beendet das Spiel
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			var cap := preload("res://scripts/dev_capture.gd").new()
			cap.output = arg.trim_prefix("--capture=")
			add_child(cap)


# ---------------------------------------------------------------- Umgebung

func _build_environment() -> void:
	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.32, 0.6, 0.95)
	sky_mat.sky_horizon_color = Color(1.0, 0.86, 0.92)
	sky_mat.ground_horizon_color = Color(1.0, 0.86, 0.92)
	sky_mat.ground_bottom_color = Color(0.36, 0.5, 0.36)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# Lavendelfarbenes Umgebungslicht: Schatten wirken farbig wie im Anime
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.6, 0.85)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 2.2
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.2
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.9, 0.97)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	sun.light_color = Color(1.0, 0.94, 0.86)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)


func _build_textures() -> void:
	grass_tex = _noise_texture(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.02, [Color("4f8a3c"), Color("6aa84f"), Color("86bd5e")])
	var cell := FastNoiseLite.new()
	cell.noise_type = FastNoiseLite.TYPE_CELLULAR
	cell.frequency = 0.06
	cell.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = cell
	tex.color_ramp = _ramp([Color("6e655a"), Color("a39785"), Color("c4baab")], [0.0, 0.18, 1.0])
	cobble_tex = tex
	# Großflächiges Rauschen für Farbvariation von Boden und Gras
	var macro := FastNoiseLite.new()
	macro.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	macro.frequency = 0.008
	macro.fractal_octaves = 4
	noise_tex = NoiseTexture2D.new()
	noise_tex.width = 512
	noise_tex.height = 512
	noise_tex.seamless = true
	noise_tex.noise = macro


func _noise_texture(kind: int, freq: float, colors: Array) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = kind
	n.frequency = freq
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = n
	tex.color_ramp = _ramp(colors, [0.0, 0.5, 1.0])
	return tex


func _ramp(colors: Array, offsets: Array) -> Gradient:
	var g := Gradient.new()
	g.colors = PackedColorArray(colors)
	g.offsets = PackedFloat32Array(offsets)
	return g


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(240, 240)
	ground.mesh = plane
	var gm := ShaderMaterial.new()
	gm.shader = GROUND_SHADER
	gm.set_shader_parameter("noise_tex", noise_tex)
	gm.set_shader_parameter("plot_half", HALF)
	ground.material_override = gm
	add_child(ground)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	body.add_child(shape)
	add_child(body)

	# Straße, Zugangsweg und Erdwege malt der Boden-Shader (ground.gdshader)


# ---------------------------------------------------------------- Grundstück

func _build_plot() -> void:
	for x in [-3.0, 3.0]:
		for z in [-3.0, 3.0]:
			_box(Vector3(0.12, 0.7, 0.12), Vector3(x, 0.35, z), Color("c99a5b"), 0.012)
			_box(Vector3(0.28, 0.12, 0.02), Vector3(x + 0.16, 0.6, z), Color("ff4fb4"), 0.0)

	# Goldener Rahmen um die Parzelle, auf der man steht
	highlight = Node3D.new()
	var gold := Toon.glow(Color(1.0, 0.83, 0.42), 1.4)
	var e := PARCEL * 0.5 - 0.25
	for spec in [[Vector3(PARCEL - 0.5, 0.04, 0.08), Vector3(0, 0, -e)], [Vector3(PARCEL - 0.5, 0.04, 0.08), Vector3(0, 0, e)], [Vector3(0.08, 0.04, PARCEL - 0.5), Vector3(-e, 0, 0)], [Vector3(0.08, 0.04, PARCEL - 0.5), Vector3(e, 0, 0)]]:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = spec[0]
		bar.mesh = bm
		bar.position = spec[1]
		bar.material_override = gold
		highlight.add_child(bar)
	highlight.position.y = 0.07
	highlight.visible = false
	add_child(highlight)

	# Zaun mit Tor vorne in der Mitte
	_fence(Vector3(-FENCE, 0, -FENCE), Vector3(FENCE, 0, -FENCE))
	_fence(Vector3(-FENCE, 0, -FENCE), Vector3(-FENCE, 0, FENCE))
	_fence(Vector3(FENCE, 0, -FENCE), Vector3(FENCE, 0, FENCE))
	_fence(Vector3(-FENCE, 0, FENCE), Vector3(-1.4, 0, FENCE))
	_fence(Vector3(1.4, 0, FENCE), Vector3(FENCE, 0, FENCE))

	# Schild am Tor
	_box(Vector3(0.14, 1.6, 0.14), Vector3(-2.3, 0.8, FENCE + 0.38), Color("8a5a30"), 0.015)
	_box(Vector3(1.6, 0.66, 0.08), Vector3(-2.3, 1.45, FENCE + 0.5), Color("e0b77c"), 0.015)
	_collider(Vector3(-2.3, 1, FENCE + 0.5), Vector3(0.4, 2, 0.4))
	var label := Label3D.new()
	label.text = "Grundstück\nvon Sora & Shiro"
	label.font_size = 40
	label.pixel_size = 0.004
	label.modulate = Color("3b2412")
	label.outline_size = 0
	label.position = Vector3(-2.3, 1.45, FENCE + 0.56)
	add_child(label)

	# Büsche am Zaun
	for i in 14:
		var side := 1.0 if i % 2 else -1.0
		_tree("busch", Vector3(side * (FENCE + 0.9), 0, -8.0 + (i >> 1) * 2.4), 0.8 + _rng.randf() * 0.35)


func _fence(a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	var n := maxi(1, roundi(length / 1.5))
	for i in n + 1:
		_box(Vector3(0.16, 1.05, 0.16), a.lerp(b, float(i) / n) + Vector3(0, 0.52, 0), Color("8a5a30"), 0.015)
	var mid := (a + b) * 0.5
	var horizontal: bool = absf(b.x - a.x) > absf(b.z - a.z)
	for h in [0.42, 0.82]:
		var size := Vector3(length, 0.09, 0.06) if horizontal else Vector3(0.06, 0.09, length)
		_box(size, mid + Vector3(0, h, 0), Color("b07a46"), 0.012)
	_collider(mid + Vector3(0, 0.6, 0), Vector3(absf(b.x - a.x) + 0.3, 1.2, absf(b.z - a.z) + 0.3))


func _build_hut() -> void:
	var hut := Node3D.new()
	hut.position = Vector3(0, 0, -6.3)
	add_child(hut)
	_box(Vector3(4.2, 2.6, 3.4), Vector3(0, 1.3, 0), Color("f4e6c8"), 0.02, true, hut)
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(4.0, 1.7, 4.8)
	roof.mesh = prism
	roof.rotation_degrees.y = 90
	roof.position = Vector3(0, 3.45, 0)
	roof.material_override = Toon.mat(Color("d2544a"))
	hut.add_child(roof)
	_box(Vector3(0.95, 1.7, 0.1), Vector3(0, 0.85, 1.72), Color("8a5a34"), 0.012, true, hut)
	_box(Vector3(0.1, 0.1, 0.06), Vector3(0.32, 0.85, 1.79), Color("ffd36b"), 0.0, false, hut)
	for wx in [-1.35, 1.35]:
		var win := _box(Vector3(0.8, 0.7, 0.08), Vector3(wx, 1.55, 1.72), Color.WHITE, 0.012, false, hut)
		win.material_override = Toon.glow(Color("9fd8ff"), 0.35)
		_box(Vector3(0.95, 0.08, 0.1), Vector3(wx, 1.17, 1.74), Color("8a5a34"), 0.0, false, hut)
	_box(Vector3(0.5, 1.4, 0.5), Vector3(1.2, 3.9, -0.5), Color("a7988a"), 0.015, true, hut)
	_box(Vector3(1.4, 0.15, 0.6), Vector3(0, 0.075, 2.0), Color("c7bcab"), 0.0, false, hut)
	_collider(Vector3(0, 1.5, -6.3), Vector3(4.4, 3, 3.6))

	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.albedo_color = Color(1, 1, 1, 0.7)
	for i in 6:
		var puff := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.22
		sm.height = 0.44
		puff.mesh = sm
		puff.material_override = smoke_mat.duplicate()
		puff.set_meta("t", float(i) / 6.0)
		add_child(puff)
		_smoke.append(puff)


# ---------------------------------------------------------------- Nachbarschaft

func _build_neighbourhood() -> void:
	for i in 9:
		_house(Vector3(-40 + i * 10 + (_rng.randf() - 0.5) * 2, 0, 24), Vector3(6 + _rng.randf() * 2, 3.4 + _rng.randf() * 1.6, 5), ROOF_COLORS[i % 6], false)
	for x in [-20.0, -32.0, 20.0, 32.0]:
		_house(Vector3(x, 0, 6 + _rng.randf() * 4), Vector3(6, 3.6 + _rng.randf(), 5), ROOF_COLORS[int(x + 40) % 6], true)
	for i in 7:
		_house(Vector3(-30 + i * 10, 0, -22 - _rng.randf() * 3), Vector3(6 + _rng.randf() * 2, 3.6 + _rng.randf() * 1.8, 5), ROOF_COLORS[(i + 2) % 6], true)

	# Rund ums Grundstück: Kirschbäume und Laubbäume im Wechsel
	var near := [Vector2(-13, -12), Vector2(13, -11), Vector2(-14, 4), Vector2(14, 2), Vector2(-12.5, 10), Vector2(12.5, 9.5), Vector2(-6, -13.5), Vector2(7, -13.5)]
	for i in near.size():
		_tree("kirschbaum" if i % 2 == 0 else "laubbaum", Vector3(near[i].x, 0, near[i].y), 0.85 + _rng.randf() * 0.3)
	# Büsche an Häusern und Wegrändern
	for i in 18:
		var bx := -40.0 + _rng.randf() * 80.0
		var bz: float = [19.5, 9.5, -16.0][i % 3] + _rng.randf_range(-0.8, 0.8)
		if absf(bx) < FENCE + 2.0 and bz < 12.0:
			continue
		_tree("busch", Vector3(bx, 0, bz), 0.7 + _rng.randf() * 0.5)
	# Waldrand in der Ferne
	for i in 70:
		var a := _rng.randf() * TAU
		var d := 34.0 + _rng.randf() * 34.0
		var pos := Vector3(cos(a) * d, 0, sin(a) * d)
		if absf(pos.z - 14.5) < 5.0 or (absf(pos.x - 6.0) < 14.0 and pos.z < -60.0):
			continue
		_tree(_pick_forest(), pos, 0.85 + _rng.randf() * 0.45)

	# Steinerne Schachdame als Denkmal an der Straße
	var queen: Node3D = QUEEN_SCENE.instantiate()
	add_child(queen)
	queen.position = Vector3(6.5, 0.4, 19.8)
	queen.scale = Vector3.ONE * 3.2
	Toon.apply_to(queen, 0.004, Color(1.05, 1.0, 0.9))
	_box(Vector3(2.0, 0.4, 2.0), Vector3(6.5, 0.2, 19.8), Color("a7a2b6"), 0.015)
	_collider(Vector3(6.5, 1.5, 19.8), Vector3(2.0, 3.0, 2.0))

	# Die Burg von Elkia in der Ferne
	var castle := Node3D.new()
	castle.position = Vector3(6, 0, -75)
	add_child(castle)
	var stone := Color("e7e0f2")
	_box(Vector3(18, 12, 10), Vector3(0, 6, 0), stone, 0.05, true, castle)
	for t in [Vector3(-10, 20, 0), Vector3(10, 20, 0), Vector3(0, 28, -4)]:
		var tower := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 2.6
		cyl.bottom_radius = 2.9
		cyl.height = t.y
		tower.mesh = cyl
		tower.position = Vector3(t.x, t.y * 0.5, t.z)
		tower.material_override = Toon.mat(stone, null, Vector2.ONE, 0.05)
		castle.add_child(tower)
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 3.4
		cm.height = 6.0
		cone.mesh = cm
		cone.position = Vector3(t.x, t.y + 3.0, t.z)
		cone.material_override = Toon.mat(Color("4a5ab8"), null, Vector2.ONE, 0.05)
		castle.add_child(cone)
		var flag := Node3D.new()
		flag.position = Vector3(t.x, t.y + 6.5, t.z)
		castle.add_child(flag)
		_box(Vector3(0.12, 3.0, 0.12), Vector3(0, 1.0, 0), Color("7a5a3a"), 0.0, false, flag)
		_box(Vector3(2.0, 1.1, 0.05), Vector3(1.0, 1.9, 0), Color("e0405f"), 0.0, false, flag)
		_flags.append(flag)


func _house(pos: Vector3, size: Vector3, roof_color: Color, faces_south: bool) -> void:
	var h := Node3D.new()
	h.position = pos
	h.rotation_degrees.y = 0.0 if faces_south else 180.0
	add_child(h)
	var w := size.x
	var height := size.y
	var d := size.z
	_box(Vector3(w, height, d), Vector3(0, height * 0.5, 0), Color("e9ddc4"), 0.03, true, h)
	var beam := Color("7a4f2a")
	for bx in [-w * 0.5 + 0.1, w * 0.5 - 0.1]:
		_box(Vector3(0.18, height, 0.18), Vector3(bx, height * 0.5, d * 0.5 + 0.02), beam, 0.0, false, h)
	_box(Vector3(w, 0.16, 0.12), Vector3(0, height * 0.55, d * 0.5 + 0.04), beam, 0.0, false, h)
	_box(Vector3(0.9, 1.6, 0.1), Vector3(0, 0.8, d * 0.5 + 0.05), beam, 0.0, false, h)
	for wx in [-w * 0.25 - 0.2, w * 0.25 + 0.2]:
		var win := _box(Vector3(0.7, 0.6, 0.08), Vector3(wx, height * 0.75, d * 0.5 + 0.05), Color.WHITE, 0.0, false, h)
		win.material_override = Toon.glow(Color("9fd8ff"), 0.35)
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(d + 0.8, height * 0.6, w + 0.6)
	roof.mesh = prism
	roof.rotation_degrees.y = 90
	roof.position = Vector3(0, height + height * 0.3, 0)
	roof.material_override = Toon.mat(roof_color, null, Vector2.ONE, 0.03)
	h.add_child(roof)
	_collider(pos + Vector3(0, height * 0.5, 0), Vector3(w + 0.2, height, d + 0.2))


func _tree(kind: String, pos: Vector3, s: float) -> void:
	var spec: Array = TREES[kind]
	var t: Node3D = (spec[0] as PackedScene).instantiate()
	t.position = pos
	t.rotation.y = _rng.randf() * TAU
	t.scale = Vector3.ONE * s
	add_child(t)
	Toon.apply_to(t, 0.02 / s)
	Toon.set_sway(t, 0.01 if kind != "busch" else 0.02, spec[1])
	if spec[2] > 0.0:
		_collider(pos + Vector3(0, 1, 0), Vector3(spec[2] * s, 2, spec[2] * s))


func _pick_forest() -> String:
	var total := 0
	for e in FOREST_MIX:
		total += e[1]
	var r := _rng.randi() % total
	for e in FOREST_MIX:
		r -= e[1]
		if r < 0:
			return e[0]
	return "laubbaum"


# ---------------------------------------------------------------- Gras

func _build_grass() -> void:
	grass = GrassField.new()
	add_child(grass)
	for r in _footprints:
		grass.blocked.append(r.grow(0.15))
	grass.blocked.append(Rect2(-0.9, -4.7, 1.8, 1.0))  # Stufe vor der Hütte
	grass.exclude = func(p: Vector2) -> bool:
		if absf(p.y - 14.5) < 3.25:
			return true
		if absf(p.x) < 1.4 and absf(p.y - 10.75) < 1.5:
			return true
		if absf(p.x) < HALF and absf(p.y) < HALF:
			var dl := minf(minf(absf(p.x - 3.0), absf(p.x + 3.0)), minf(absf(p.y - 3.0), absf(p.y + 3.0)))
			if dl < 0.38:
				return true
		return false
	grass.build(noise_tex)


# ---------------------------------------------------------------- Figuren

func _spawn_heroes() -> void:
	for spec in [["Sora", "Liest Menschen", SORA_SCENE, 1.72, Vector3(0.7, 0, 12.2), SORA_ANIMS], ["Shiro", "Rechnet alles durch", SHIRO_SCENE, 1.42, Vector3(-0.7, 0, 12.6), SHIRO_ANIMS]]:
		var hero := Hero.new()
		hero.display_name = spec[0]
		hero.skill = spec[1]
		hero.model_scene = spec[2]
		hero.height = spec[3]
		hero.anim_sources = [spec[5]]
		hero.position = spec[4]
		add_child(hero)
		hero.model.rotation.y = PI
		heroes.append(hero)

	rig = CameraRig.new()
	add_child(rig)
	for hero in heroes:
		rig.exclude(hero)
	rig.target = heroes[0]
	rig.global_position = heroes[0].global_position + Vector3(0, 1.25, 0)

	hud = Hud.new()
	add_child(hud)
	hud.set_hero(heroes[0])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("swap"):
		active = 1 - active
		rig.target = heroes[active]
		hud.set_hero(heroes[active])
	elif event.is_action_pressed("interact"):
		if hud.is_talking():
			hud.advance()
		elif not _spot.is_empty():
			_interact()


func _physics_process(delta: float) -> void:
	if heroes.size() < 2:
		return
	var lead := heroes[active]
	var other := heroes[1 - active]
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if hud.is_talking():
		input = Vector2.ZERO
	var sprint := Input.is_action_pressed("sprint") and input.length() > 0.1
	var dir := rig.flat_basis() * Vector3(input.x, 0, input.y)
	lead.drive(dir, sprint, delta)
	other.follow(lead, sprint, delta)
	grass.set_players(heroes[0].global_position, heroes[1].global_position)
	_update_parcel(lead.global_position)


func _process(delta: float) -> void:
	_time += delta
	for puff in _smoke:
		var t := fmod(float(puff.get_meta("t")) + delta * 0.18, 1.0)
		puff.set_meta("t", t)
		puff.position = Vector3(1.2 + sin(t * 6.0 + _time) * 0.25, 4.7 + t * 3.0, -6.8 - t * 0.8)
		puff.scale = Vector3.ONE * (0.6 + t * 1.6)
		(puff.material_override as StandardMaterial3D).albedo_color.a = 0.65 * (1.0 - t)
	for flag in _flags:
		flag.rotation.y = sin(_time * 3.0 + flag.global_position.x) * 0.25
	if highlight.visible:
		highlight.scale = Vector3.ONE * (1.0 + sin(_time * 4.0) * 0.01)


func _update_parcel(p: Vector3) -> void:
	current_parcel = ""
	if absf(p.x) < HALF and absf(p.z) < HALF:
		var col := mini(2, int((p.x + HALF) / PARCEL))
		var row := mini(2, int((p.z + HALF) / PARCEL))
		current_parcel = "ABC"[col] + str(row + 1)
		highlight.visible = true
		highlight.position = Vector3(-HALF + PARCEL * (col + 0.5), 0.07, -HALF + PARCEL * (row + 0.5))
	else:
		highlight.visible = false
	hud.show_parcel(current_parcel)

	_spot = {}
	if Vector2(p.x, p.z).distance_to(Vector2(0, -3.8)) < 1.6:
		_spot = {"label": "E · Hütte betreten", "kind": "hut"}
	elif Vector2(p.x, p.z).distance_to(Vector2(-2.3, FENCE + 1.3)) < 1.5:
		_spot = {"label": "E · Schild lesen", "kind": "sign"}
	elif current_parcel != "" and GameState.parcels[current_parcel]["building"] == "":
		var c := highlight.position
		if Vector2(p.x, p.z).distance_to(Vector2(c.x, c.z)) < 1.2:
			_spot = {"label": "E · Parzelle ansehen", "kind": "parcel"}
	hud.show_prompt(_spot.get("label", ""))


func _interact() -> void:
	match _spot["kind"]:
		"hut":
			GameState.save_game()
			hud.say([["Sora", "Unser Zuhause. Klein, aber es gehört uns."], ["Shiro", "…Gespeichert."], ["Sora", "Die Hütte steht auf B1. Die Parzelle setzen wir nie, egal wie verlockend die Wette ist."]])
		"sign":
			hud.say([["Schild", "Grundstück von 「　」. 9 Parzellen. Betreten nur nach Herausforderung."]])
		"parcel":
			hud.say([["Shiro", "%s: leer. Wert %d Münzen." % [current_parcel, GameState.parcel_value(current_parcel)]], ["Sora", "Hier könnte ein Marktstand hin. Oder wir setzen die Parzelle in einer Wette und holen uns zwei dazu."]])


# ---------------------------------------------------------------- Bausteine

func _box(size: Vector3, pos: Vector3, color: Color, outline := 0.02, shadow := true, parent: Node = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = Toon.mat(color, null, Vector2.ONE, outline)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _collider(center: Vector3, size: Vector3) -> void:
	_footprints.append(Rect2(center.x - size.x * 0.5, center.z - size.z * 0.5, size.x, size.z))
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	add_child(body)
