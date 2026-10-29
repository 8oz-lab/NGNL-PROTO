// Landschaft von Disboard aus der Luft: Strand, Wiesen, Wälder, Fels und Schnee, weiches Toon-Licht
shader_type spatial;
render_mode diffuse_toon, specular_disabled;
#include "res://assets/shaders/terrain_height.gdshaderinc"

varying float vh;
varying float vslope;
varying vec2 vw;

void vertex() {
	vw = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	float h = terrain_height(vw);
	float e = 45.0;
	float hx = terrain_height(vw + vec2(e, 0.0));
	float hz = terrain_height(vw + vec2(0.0, e));
	VERTEX.y = h;
	NORMAL = normalize(vec3(h - hx, e, h - hz));
	vh = h;
	vslope = 1.0 - NORMAL.y;
}

void fragment() {
	float patch = texture(terrain_noise, vw * 0.004).r;
	float fine = texture(terrain_noise, vw * 0.03).r;
	vec3 sand = vec3(0.97, 0.89, 0.66);
	vec3 meadow = mix(vec3(0.46, 0.78, 0.36), vec3(0.62, 0.86, 0.4), smoothstep(0.4, 0.65, patch));
	vec3 field = vec3(0.86, 0.82, 0.45);
	vec3 forest = vec3(0.16, 0.42, 0.3);
	vec3 rock = vec3(0.56, 0.54, 0.58);
	vec3 snow = vec3(0.97, 0.97, 1.0);
	vec3 col = sand;
	col = mix(col, meadow, smoothstep(6.0, 18.0, vh));
	col = mix(col, field, step(0.66, patch) * smoothstep(18.0, 30.0, vh) * (1.0 - smoothstep(120.0, 160.0, vh)) * 0.8);
	col = mix(col, forest, smoothstep(0.52, 0.6, fine * 0.4 + patch * 0.6) * smoothstep(40.0, 90.0, vh));
	col = mix(col, rock, max(smoothstep(300.0, 420.0, vh), smoothstep(0.4, 0.65, vslope)));
	col = mix(col, snow, smoothstep(470.0, 560.0, vh) * (1.0 - smoothstep(0.55, 0.75, vslope)));
	ALBEDO = col * (0.92 + fine * 0.16);
	ROUGHNESS = 1.0;
}
