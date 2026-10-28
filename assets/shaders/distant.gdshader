// Ferne Kulisse (riesige Schachfiguren am Horizont): flache Farbe, die nach oben in den Himmel verblasst,
// heller Rand zur Sonne, kein Nebel
shader_type spatial;
render_mode unshaded, fog_disabled, cull_back;

uniform vec3 base_color : source_color = vec3(0.78, 0.8, 0.95);
uniform vec3 haze : source_color = vec3(1.0, 0.88, 0.94);
uniform float height = 200.0;
varying float vh;

void vertex() {
	vh = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 c = mix(haze, base_color, smoothstep(0.0, height * 0.6, vh));
	ALBEDO = c + rim * 0.12;
}
