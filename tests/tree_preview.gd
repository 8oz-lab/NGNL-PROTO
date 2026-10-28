extends Node3D
## Zeigt alle Baum-Modelle nebeneinander im Spiel-Look (Toon-Shader, Wind).
## Aufruf: godot --path . res://tests/tree_preview.tscn

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
	for i in TREES.size():
		var t: Node3D = load("res://assets/models/trees/%s.glb" % TREES[i]).instantiate()
		t.position = Vector3(-15 + i * 6.0, 0, 0)
		add_child(t)
		Toon.apply_to(t, 0.02)
		Toon.set_sway(t, 0.015, 1.5)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 5, 21)
	cam.rotation_degrees.x = -6
	cam.fov = 55
	add_child(cam)
