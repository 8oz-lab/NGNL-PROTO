extends SceneTree
## Baut die Baum-Modelle im Toon-Stil und speichert sie als GLB in assets/models/trees/.
## Stamm und Krone sind getrennte Flächen mit Farbe pro Punkt (oben hell, unten dunkel).
## Aufruf: godot --path . --script res://tools/make_trees.gd  (mit Grafik, nicht --headless)

const OUT := "res://assets/models/trees/"

var noise := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()
var _frames := 0


func _process(_d: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	noise.frequency = 0.9
	noise.fractal_octaves = 3
	_save("laubbaum", _laubbaum(1.0, Color(0.56, 0.8, 0.42), Color(0.22, 0.47, 0.31), 11))
	_save("laubbaum_gross", _laubbaum(1.35, Color(0.6, 0.82, 0.4), Color(0.26, 0.48, 0.28), 23))
	_save("kirschbaum", _kirschbaum())
	_save("tanne", _tanne())
	_save("birke", _birke())
	_save("busch", _busch())
	return true


func _save(name: String, parts: Array) -> void:
	var root := Node3D.new()
	root.name = name
	get_root().add_child(root)
	var mesh := ArrayMesh.new()
	for p in parts:
		var st: SurfaceTool = p[1]
		st.commit(mesh)
		var m := StandardMaterial3D.new()
		m.resource_name = p[0]
		m.vertex_color_use_as_albedo = true
		m.roughness = 1.0
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	root.add_child(mi)
	mi.owner = root
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	doc.append_from_scene(root, state)
	var err := doc.write_to_filesystem(state, ProjectSettings.globalize_path(OUT + name + ".glb"))
	var tris := 0
	for i in mesh.get_surface_count():
		tris += mesh.surface_get_array_index_len(i) / 3 if mesh.surface_get_format(i) & Mesh.ARRAY_FORMAT_INDEX else mesh.surface_get_array_len(i) / 3
	print("%-14s %s  %d Dreiecke  Höhe %.1f m" % [name, "ok" if err == OK else "Fehler %d" % err, tris, mesh.get_aabb().end.y])
	root.queue_free()


func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


# ------------------------------------------------------------------ Grundformen

## Kegelstumpf von a nach b (Stamm, Ast), Farbe pro Punkt über die Funktion col(höhe 0–1, winkel).
func _limb(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float, segs: int, col: Callable) -> void:
	var axis := (b - a).normalized()
	var side := axis.cross(Vector3.FORWARD if absf(axis.y) > 0.9 else Vector3.UP).normalized()
	side = axis.cross(Vector3.RIGHT).normalized() if side.length() < 0.5 else side
	var up := side.cross(axis).normalized()
	var rings := 4
	for r in rings:
		for s in segs:
			var quad := []
			for k in [[r, s], [r + 1, s], [r + 1, s + 1], [r, s + 1]]:
				var t: float = float(k[0]) / rings
				var ang: float = TAU * k[1] / segs
				var dir := side * cos(ang) + up * sin(ang)
				var rad := lerpf(r0, r1, t) * (1.0 + noise.get_noise_3dv(a * 3.0 + dir + Vector3(0, t * 4.0, 0)) * 0.12)
				quad.append([a.lerp(b, t) + dir * rad, dir, col.call(t, ang)])
			for idx in [0, 2, 1, 0, 3, 2]:
				st.set_color(quad[idx][2])
				st.set_normal(quad[idx][1])
				st.add_vertex(quad[idx][0])


## Weiche, leicht unregelmäßige Laubwolke. Normalen zeigen von der Mitte weg (weiches Anime-Licht).
func _clump(st: SurfaceTool, c: Vector3, r: Vector3, top: Color, bottom: Color, bumps := 0.22) -> void:
	var rings := 9
	var segs := 14
	var tint := rng.randf_range(-0.04, 0.04)
	var pts := []
	for i in rings + 1:
		var row := []
		var phi := PI * i / rings
		for j in segs + 1:
			var th := TAU * j / segs
			var dir := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			var n := noise.get_noise_3dv(dir * 1.7 + c * 0.7)
			var p := c + dir * r * (1.0 + n * bumps)
			if dir.y < -0.3:
				p.y = lerpf(p.y, c.y - r.y * 0.45, 0.5)   # flachere Unterseite
			var k := clampf(dir.y * 0.5 + 0.5 + n * 0.25, 0.0, 1.0)
			var col := bottom.lerp(top, smoothstep(0.15, 0.95, k))
			col = Color(col.r + tint, col.g + tint * 0.5, col.b, 1.0)
			row.append([p, (dir + Vector3(0, 0.25, 0)).normalized(), col])
		pts.append(row)
	for i in rings:
		for j in segs:
			var q := [pts[i][j], pts[i + 1][j], pts[i + 1][j + 1], pts[i][j + 1]]
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(q[idx][2])
				st.set_normal(q[idx][1])
				st.add_vertex(q[idx][0])


## Gezackter Kegel für Tannen.
func _cone(st: SurfaceTool, y0: float, h: float, radius: float, top: Color, bottom: Color) -> void:
	var segs := 16
	var tip := Vector3(0, y0 + h, 0)
	for s in segs:
		var a0 := TAU * s / segs
		var a1 := TAU * (s + 1) / segs
		var r0 := radius * (1.0 if s % 2 == 0 else 0.78)
		var r1 := radius * (1.0 if (s + 1) % 2 == 0 else 0.78)
		var p0 := Vector3(cos(a0) * r0, y0 - (0.25 if s % 2 == 0 else 0.0), sin(a0) * r0)
		var p1 := Vector3(cos(a1) * r1, y0 - (0.25 if (s + 1) % 2 == 0 else 0.0), sin(a1) * r1)
		var n0 := Vector3(cos(a0), radius / h, sin(a0)).normalized()
		var n1 := Vector3(cos(a1), radius / h, sin(a1)).normalized()
		for v in [[tip, (n0 + n1).normalized(), top], [p0, n0, bottom], [p1, n1, bottom]]:
			st.set_color(v[2])
			st.set_normal(v[1])
			st.add_vertex(v[0])
		# Unterseite
		for v in [[Vector3(0, y0 + 0.1, 0), Vector3.DOWN, bottom.darkened(0.3)], [p1, Vector3.DOWN, bottom.darkened(0.3)], [p0, Vector3.DOWN, bottom.darkened(0.3)]]:
			st.set_color(v[2])
			st.set_normal(v[1])
			st.add_vertex(v[0])


func _bark(base: Color) -> Callable:
	return func(t: float, _a: float) -> Color: return base.lerp(base.lightened(0.18), t)


# ------------------------------------------------------------------ Bäume

func _laubbaum(s: float, top: Color, bottom: Color, seed_value: int) -> Array:
	rng.seed = seed_value
	noise.seed = seed_value
	var trunk := _st()
	var leaves := _st()
	var bark := _bark(Color(0.45, 0.3, 0.22))
	_limb(trunk, Vector3.ZERO, Vector3(0.05, 2.7, 0) * s, 0.3 * s, 0.17 * s, 9, bark)
	var clumps := [
		[Vector3(0, 3.7, 0), Vector3(1.75, 1.35, 1.75)],
		[Vector3(1.15, 3.1, 0.35), Vector3(1.15, 0.95, 1.1)],
		[Vector3(-1.05, 3.2, -0.45), Vector3(1.2, 1.0, 1.15)],
		[Vector3(-0.35, 3.35, 1.05), Vector3(1.05, 0.9, 1.0)],
		[Vector3(0.45, 3.4, -1.05), Vector3(1.0, 0.85, 1.0)],
		[Vector3(0.15, 4.6, -0.1), Vector3(1.15, 0.95, 1.15)],
	]
	for c in clumps:
		var cc: Vector3 = c[0] * s
		_limb(trunk, Vector3(0, 2.3, 0) * s, cc * Vector3(0.75, 0.92, 0.75), 0.11 * s, 0.05 * s, 6, bark)
		_clump(leaves, cc, c[1] * s, top, bottom)
	return [["Stamm", trunk], ["Krone", leaves]]


func _kirschbaum() -> Array:
	rng.seed = 5
	noise.seed = 5
	var trunk := _st()
	var leaves := _st()
	var bark := _bark(Color(0.36, 0.22, 0.2))
	# leicht gebogener Stamm mit weit ausladenden Ästen
	_limb(trunk, Vector3.ZERO, Vector3(0.25, 1.4, 0.1), 0.3, 0.22, 9, bark)
	_limb(trunk, Vector3(0.25, 1.4, 0.1), Vector3(0.05, 2.4, -0.05), 0.22, 0.16, 9, bark)
	var top := Color(1.0, 0.76, 0.87)
	var bottom := Color(0.84, 0.42, 0.64)
	var clumps := [
		[Vector3(0, 3.2, 0), Vector3(1.6, 0.95, 1.6)],
		[Vector3(1.7, 2.75, 0.4), Vector3(1.2, 0.75, 1.1)],
		[Vector3(-1.6, 2.85, -0.3), Vector3(1.25, 0.8, 1.15)],
		[Vector3(0.3, 2.8, 1.55), Vector3(1.1, 0.7, 1.05)],
		[Vector3(-0.4, 2.9, -1.5), Vector3(1.15, 0.75, 1.1)],
		[Vector3(0.4, 3.85, 0.2), Vector3(1.05, 0.7, 1.0)],
		[Vector3(-1.0, 3.5, 0.9), Vector3(0.9, 0.6, 0.9)],
	]
	for c in clumps:
		_limb(trunk, Vector3(0.05, 2.2, 0), c[0] * Vector3(0.85, 0.95, 0.85), 0.12, 0.05, 6, bark)
		_clump(leaves, c[0], c[1], top, bottom, 0.28)
	return [["Stamm", trunk], ["Bluete", leaves]]


func _tanne() -> Array:
	rng.seed = 7
	noise.seed = 7
	var trunk := _st()
	var needles := _st()
	_limb(trunk, Vector3.ZERO, Vector3(0, 2.0, 0), 0.26, 0.2, 8, _bark(Color(0.4, 0.27, 0.2)))
	var top := Color(0.36, 0.62, 0.5)
	var bottom := Color(0.12, 0.3, 0.3)
	var tiers := [[1.1, 2.6, 2.3], [2.5, 2.3, 1.9], [3.8, 2.0, 1.5], [5.0, 1.8, 1.1], [6.1, 1.6, 0.7]]
	for t in tiers:
		_cone(needles, t[0], t[1], t[2], top, bottom)
	return [["Stamm", trunk], ["Nadeln", needles]]


func _birke() -> Array:
	rng.seed = 13
	noise.seed = 13
	var trunk := _st()
	var leaves := _st()
	# weißer Stamm mit dunklen Flecken
	var bark := func(t: float, a: float) -> Color:
		var n := noise.get_noise_2d(a * 3.0, t * 14.0)
		return Color(0.2, 0.19, 0.22) if n > 0.12 else Color(0.93, 0.92, 0.88)
	_limb(trunk, Vector3.ZERO, Vector3(0.1, 3.6, 0), 0.17, 0.1, 10, bark)
	_limb(trunk, Vector3(0.05, 2.0, 0), Vector3(0.7, 3.4, 0.2), 0.08, 0.05, 6, bark)
	var top := Color(0.78, 0.9, 0.5)
	var bottom := Color(0.4, 0.62, 0.32)
	var clumps := [
		[Vector3(0.1, 4.6, 0), Vector3(0.95, 1.5, 0.95)],
		[Vector3(0.7, 3.9, 0.25), Vector3(0.75, 1.1, 0.7)],
		[Vector3(-0.5, 4.0, -0.2), Vector3(0.7, 1.15, 0.7)],
		[Vector3(0.0, 5.6, 0.1), Vector3(0.6, 0.9, 0.6)],
	]
	for c in clumps:
		_clump(leaves, c[0], c[1], top, bottom, 0.2)
	return [["Stamm", trunk], ["Krone", leaves]]


func _busch() -> Array:
	rng.seed = 17
	noise.seed = 17
	var leaves := _st()
	var top := Color(0.5, 0.76, 0.4)
	var bottom := Color(0.2, 0.42, 0.28)
	for c in [[Vector3(0, 0.55, 0), Vector3(0.75, 0.6, 0.75)], [Vector3(0.6, 0.45, 0.2), Vector3(0.55, 0.45, 0.5)], [Vector3(-0.55, 0.45, -0.15), Vector3(0.55, 0.45, 0.55)], [Vector3(0.1, 0.42, 0.6), Vector3(0.5, 0.4, 0.45)]]:
		_clump(leaves, c[0], c[1], top, bottom, 0.25)
	return [["Busch", leaves]]
