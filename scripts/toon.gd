class_name Toon
## Materialien im Anime-Toon-Look, mit Umrisslinie als zweitem Durchgang.

const TOON_SHADER := preload("res://assets/shaders/toon.gdshader")
const OUTLINE_SHADER := preload("res://assets/shaders/outline.gdshader")


static func mat(color: Color, texture: Texture2D = null, uv_scale := Vector2.ONE, outline := 0.02) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON_SHADER
	m.set_shader_parameter("albedo", color)
	if texture:
		m.set_shader_parameter("albedo_texture", texture)
		m.set_shader_parameter("use_texture", true)
		m.set_shader_parameter("uv_scale", uv_scale)
	if outline > 0.0:
		m.next_pass = outline_mat(outline)
	return m


static func outline_mat(thickness: float, color := Color(0.12, 0.08, 0.22)) -> ShaderMaterial:
	var o := ShaderMaterial.new()
	o.shader = OUTLINE_SHADER
	o.set_shader_parameter("thickness", thickness)
	o.set_shader_parameter("outline_color", color)
	return o


static func glow(color: Color, strength := 0.6) -> ShaderMaterial:
	var m := mat(color, null, Vector2.ONE, 0.0)
	m.set_shader_parameter("emission_color", color * strength)
	return m


## Ersetzt alle Materialien eines importierten Modells durch Toon-Materialien (Texturen bleiben).
static func apply_to(node: Node, outline := 0.008, tint := Color.WHITE) -> void:
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mi as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for i in mesh_instance.mesh.get_surface_count():
			var src := mesh_instance.get_active_material(i)
			var tex: Texture2D = null
			var col := tint
			if src is BaseMaterial3D:
				tex = (src as BaseMaterial3D).albedo_texture
				if tex == null:
					col = (src as BaseMaterial3D).albedo_color * tint
			mesh_instance.set_surface_override_material(i, mat(col, tex, Vector2.ONE, outline))
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
