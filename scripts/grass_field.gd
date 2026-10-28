class_name GrassField
extends Node3D
## Verteilt Grashalme als MultiMesh in Kacheln (für schnelles Ausblenden außerhalb des Bildes).
## Ausgespart werden Wege, Pflaster und alles, was in `blocked` steht (Grundflächen von Gebäuden, Zäunen, Bäumen).

const GRASS_SHADER := preload("res://assets/shaders/grass.gdshader")

@export var area := Rect2(-46, -34, 92, 72)
@export var density := 26.0        # Halme pro Quadratmeter
@export var chunk := 12.0          # Kantenlänge einer Kachel

var material: ShaderMaterial
## Rechtecke (x, z, Breite, Tiefe), auf denen kein Gras wächst.
var blocked: Array[Rect2] = []
## Zusätzliche Regel: Funktion (Vector2) -> bool, true = kein Gras.
var exclude: Callable


func build(noise: Texture2D) -> void:
	material = ShaderMaterial.new()
	material.shader = GRASS_SHADER
	material.set_shader_parameter("noise_tex", noise)
	var blade := _blade_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var cx := area.position.x
	while cx < area.end.x:
		var cz := area.position.y
		while cz < area.end.y:
			_build_chunk(Rect2(cx, cz, chunk, chunk), blade, rng)
			cz += chunk
		cx += chunk


func set_players(a: Vector3, b: Vector3) -> void:
	if material:
		material.set_shader_parameter("player_a", a)
		material.set_shader_parameter("player_b", b)


func _build_chunk(r: Rect2, blade: Mesh, rng: RandomNumberGenerator) -> void:
	var xforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var count := int(r.get_area() * density)
	# Nur die Sperrflächen prüfen, die diese Kachel berühren
	var local: Array[Rect2] = []
	for rect in blocked:
		if rect.intersects(r):
			local.append(rect)
	for i in count:
		var p := Vector2(r.position.x + rng.randf() * r.size.x, r.position.y + rng.randf() * r.size.y)
		if _is_blocked(p, local):
			continue
		var height := rng.randf_range(0.16, 0.38)
		var b := Basis(Vector3.UP, rng.randf() * TAU)
		b = b.rotated(b.x, rng.randf_range(-0.18, 0.18))
		b = b.scaled(Vector3(rng.randf_range(0.8, 1.3), height, 1.0))
		xforms.append(Transform3D(b, Vector3(p.x, 0.0, p.y)))
		var tint := rng.randf_range(0.88, 1.1)
		colors.append(Color(tint, tint * rng.randf_range(0.97, 1.04), tint * 0.95))
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = blade
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 70.0
	mmi.visibility_range_end_margin = 8.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(mmi)


func _is_blocked(p: Vector2, rects: Array[Rect2]) -> bool:
	if exclude.is_valid() and exclude.call(p):
		return true
	for rect in rects:
		if rect.has_point(p):
			return true
	return false


## Ein Halm: schmal, spitz zulaufend, leicht gebogen. Höhe 1, wird pro Halm skaliert.
func _blade_mesh() -> ArrayMesh:
	var w := 0.05
	var levels := [[0.0, w], [0.35, w * 0.85], [0.7, w * 0.5], [1.0, 0.0]]
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	for lv in levels:
		var y: float = lv[0]
		var half: float = lv[1]
		var bend := y * y * 0.12
		verts.append(Vector3(-half, y, bend))
		verts.append(Vector3(half, y, bend))
		uvs.append(Vector2(0.0, y))
		uvs.append(Vector2(1.0, y))
	var idx := PackedInt32Array()
	for i in 3:
		var a := i * 2
		idx.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var normals := PackedVector3Array()
	for v in verts:
		normals.append(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-0.3, 0, -0.3), Vector3(0.6, 1.2, 0.6))
	return mesh
