extends Node3D
## Zeigt Modelle nebeneinander im Spiel-Look (Toon-Shader, Wind).
## Aufruf: godot --path . res://tests/tree_preview.tscn  (Bäume)
##         godot --path . res://tests/tree_preview.tscn -- --folder=houses  (Häuser, Breite 8 m)

const TREES := ["busch", "birke", "laubbaum", "kirschbaum", "laubbaum_gross", "tanne"]


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.72, 1.0)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 2.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -35, 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 30)
	ground.mesh = plane
	ground.material_override = Toon.mat(Color(0.5, 0.72, 0.42), null, Vector2.ONE, 0.0)
	add_child(ground)
	var folder := "trees"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--folder="):
			folder = arg.trim_prefix("--folder=")
	var cam := Camera3D.new()
	cam.position = Vector3(0, 5, 21)
	if folder == "trees":
		for i in TREES.size():
			var t: Node3D = load("res://assets/models/trees/%s.glb" % TREES[i]).instantiate()
			t.position = Vector3(-15 + i * 6.0, 0, 0)
			add_child(t)
			Toon.apply_to(t, 0.02)
			Toon.set_sway(t, 0.015, 1.5)
	else:
		var files := Array(DirAccess.get_files_at("res://assets/models/%s/" % folder)).filter(func(f): return f.get_extension() == "glb")
		files.sort()
		for i in files.size():
			_place(load("res://assets/models/%s/%s" % [folder, files[i]]), Vector3((i - (files.size() - 1) * 0.5) * 10.0, 0, 0), 8.0)
		cam.position = Vector3(0, 7, 13 + files.size() * 3.5)
	cam.rotation_degrees.x = -6
	cam.fov = 55
	add_child(cam)


## Skaliert ein Modell auf eine Breite und stellt es auf den Boden (wie die Häuser im Spiel).
func _place(scene: PackedScene, pos: Vector3, width: float) -> void:
	var holder := Node3D.new()
	holder.position = pos
	add_child(holder)
	var m: Node3D = scene.instantiate()
	holder.add_child(m)
	var box := AABB()
	var first := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (holder.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var k := width / maxf(box.size.x, box.size.z)
	m.scale *= k
	m.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * k
	Toon.apply_to(m, 0.015 / k)
