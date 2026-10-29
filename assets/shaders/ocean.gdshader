// Meer: türkis an den Küsten, tiefblau draußen, Schaum am Ufer, Glitzern im Sonnenlicht
shader_type spatial;
render_mode diffuse_toon, specular_toon;
#include "res://assets/shaders/terrain_height.gdshaderinc"

varying vec2 vw;

void vertex() {
	vw = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float depth = -terrain_height(vw);
	vec3 shallow = vec3(0.32, 0.86, 0.88);
	vec3 deep = vec3(0.07, 0.3, 0.72);
	vec3 col = mix(shallow, deep, smoothstep(0.0, 180.0, depth));
	float waves = texture(terrain_noise, vw * 0.01 + vec2(TIME * 0.004, 0.0)).r;
	col = mix(col, vec3(1.0), smoothstep(14.0, 0.0, depth) * smoothstep(0.35, 0.6, waves) * 0.8);
	float sparkle = smoothstep(0.72, 0.78, texture(terrain_noise, vw * 0.05 - vec2(0.0, TIME * 0.01)).r);
	ALBEDO = col;
	EMISSION = vec3(1.0, 0.95, 0.85) * sparkle * 0.25;
	ROUGHNESS = 0.25;
	SPECULAR = 0.6;
}
