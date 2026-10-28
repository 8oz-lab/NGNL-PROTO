// Grashalme im Wind: Farbverlauf von der Wurzel zur Spitze, biegen sich vor den Figuren weg.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec4 root_color : source_color = vec4(0.3, 0.52, 0.24, 1.0);
uniform vec4 tip_color : source_color = vec4(0.66, 0.8, 0.38, 1.0);
uniform float wind_strength = 0.14;
uniform vec3 player_a = vec3(1000.0);
uniform vec3 player_b = vec3(1000.0);

varying float h;
varying float macro;

vec3 push_from(vec3 world, vec3 p, float hh) {
	vec3 d = world - p;
	d.y = 0.0;
	float dist = length(d);
	float f = (1.0 - smoothstep(0.15, 0.75, dist)) * hh;
	return normalize(d + vec3(0.0001, 0.0, 0.0)) * f * 0.35 - vec3(0.0, f * 0.18, 0.0);
}

void vertex() {
	h = UV.y;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float gust = texture(noise_tex, world.xz * 0.025 + vec2(TIME * 0.06, TIME * 0.03)).r;
	float hh = h * h;
	float sway = (sin(TIME * 1.8 + world.x * 0.5 + world.z * 0.35) * 0.35 + gust - 0.35) * wind_strength * hh * 3.0;
	vec3 offset = vec3(sway, 0.0, sway * 0.45);
	offset += push_from(world, player_a, hh);
	offset += push_from(world, player_b, hh);
	VERTEX += inverse(mat3(MODEL_MATRIX)) * offset;
	// Normalen nach oben: die Wiese wird wie der Boden beleuchtet, nicht wie flache Blätter
	NORMAL = inverse(mat3(MODEL_MATRIX)) * vec3(0.0, 1.0, 0.0);
	macro = texture(noise_tex, world.xz * 0.011).r;
}

void fragment() {
	vec3 c = mix(root_color.rgb, tip_color.rgb, smoothstep(0.0, 1.0, h));
	c *= 0.86 + macro * 0.28;
	c *= COLOR.rgb;
	ALBEDO = c;
	ROUGHNESS = 1.0;
	BACKLIGHT = vec3(0.25, 0.3, 0.12) * h;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-0.02, 0.04, ndl) * 0.55 + smoothstep(0.45, 0.5, ndl) * 0.45;
	float shadow = smoothstep(0.3, 0.5, ATTENUATION);
	DIFFUSE_LIGHT += LIGHT_COLOR * band * shadow / PI;
}
