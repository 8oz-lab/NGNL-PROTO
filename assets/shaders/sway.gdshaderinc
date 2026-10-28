// Sanftes Wiegen im Wind für Baumkronen (gemeinsam für Toon- und Umriss-Shader)
uniform float sway = 0.0;
uniform float sway_start = 1.0;

vec3 sway_offset(vec3 v, mat4 model) {
	if (sway <= 0.0) {
		return vec3(0.0);
	}
	vec3 wp = model[3].xyz;
	float h = max(v.y - sway_start, 0.0);
	float t = TIME * 1.1 + wp.x * 0.31 + wp.z * 0.23;
	return vec3(sin(t) + 0.4 * sin(t * 2.3 + v.x), 0.0, cos(t * 0.8) * 0.6) * sway * h;
}
