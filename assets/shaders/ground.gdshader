// Gemalter Boden: Wiese mit großflächiger Farbvariation, Erdwege und Pflaster,
// weich ineinander übergehend. Alles in Weltkoordinaten, daher keine sichtbaren Kacheln.
shader_type spatial;
render_mode specular_disabled;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec4 grass_dark : source_color = vec4(0.25, 0.47, 0.21, 1.0);
uniform vec4 grass_mid : source_color = vec4(0.38, 0.6, 0.27, 1.0);
uniform vec4 grass_light : source_color = vec4(0.56, 0.72, 0.34, 1.0);
uniform vec4 dirt_light : source_color = vec4(0.66, 0.5, 0.33, 1.0);
uniform vec4 dirt_dark : source_color = vec4(0.47, 0.34, 0.22, 1.0);
uniform vec4 stone_light : source_color = vec4(0.82, 0.78, 0.72, 1.0);
uniform vec4 stone_dark : source_color = vec4(0.6, 0.57, 0.53, 1.0);
uniform vec4 grout : source_color = vec4(0.34, 0.31, 0.29, 1.0);
// Lage der Wege (passend zu world.gd)
uniform float road_z = 14.5;
uniform float road_half = 3.0;
uniform float plot_half = 9.0;

varying vec3 wpos;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

// Voronoi: x = Abstand zur Zellmitte, y = Abstand zur nächsten Kante, z = Zufallswert der Zelle
vec3 voronoi(vec2 x) {
	vec2 n = floor(x);
	vec2 f = fract(x);
	float f1 = 8.0;
	float f2 = 8.0;
	vec2 id = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash2(n + g) * 0.7 + 0.15;
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < f1) { f2 = f1; f1 = d; id = n + g; }
			else if (d < f2) { f2 = d; }
		}
	}
	return vec3(sqrt(f1), sqrt(f2) - sqrt(f1), hash2(id).x);
}

float nz(vec2 p) { return texture(noise_tex, p).r; }

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float macro = nz(p * 0.011);
	float mid = nz(p * 0.055 + 3.1);
	float fine = nz(p * 0.4 + 7.7);
	float wobble = nz(p * 0.45 + 1.3) - 0.5;

	// Wiese
	vec3 grass = mix(grass_dark.rgb, grass_mid.rgb, smoothstep(0.25, 0.62, macro));
	grass = mix(grass, grass_light.rgb, smoothstep(0.55, 0.85, mid) * 0.55);
	grass *= 0.93 + fine * 0.14;
	// Parzellen leicht im Schachbrett abgesetzt
	float in_plot = step(abs(p.x), plot_half) * step(abs(p.y), plot_half);
	float checker = mod(floor((p.x + plot_half) / 6.0) + floor((p.y + plot_half) / 6.0), 2.0);
	grass *= mix(vec3(1.0), vec3(1.05, 1.07, 0.97), in_plot * checker);

	// Erdwege zwischen den Parzellen, mit ausgefransten Rändern
	float dl = min(min(abs(p.x - 3.0), abs(p.x + 3.0)), min(abs(p.y - 3.0), abs(p.y + 3.0)));
	float dirt = in_plot * (1.0 - smoothstep(0.14, 0.32, dl + wobble * 0.22));
	vec3 dcol = mix(dirt_dark.rgb, dirt_light.rgb, smoothstep(0.25, 0.75, fine));
	dcol *= 0.9 + step(0.86, nz(p * 2.3)) * 0.25; // kleine Kiesel

	// Pflaster: Straße und Zugangsweg
	float road = 1.0 - smoothstep(road_half - 0.35, road_half, abs(p.y - road_z) + wobble * 0.25);
	float path = (1.0 - smoothstep(1.0, 1.25, abs(p.x) + wobble * 0.15)) * (1.0 - smoothstep(1.15, 1.4, abs(p.y - 10.75) + wobble * 0.1));
	float stone = max(road, path);
	vec3 v = voronoi(p * vec2(3.2, 3.8));
	float joint = smoothstep(0.03, 0.1, v.y);
	vec3 scol = mix(stone_dark.rgb, stone_light.rgb, v.z * 0.75 + 0.1) * (0.94 + fine * 0.1);
	scol *= 0.86 + 0.22 * smoothstep(0.45, 0.0, v.x); // gewölbte Steine: Mitte heller
	scol = mix(grout.rgb, scol, joint);

	vec3 col = mix(grass, dcol, dirt);
	col = mix(col, scol, stone);
	// Abgetretener, dunklerer Rand ums Pflaster
	col *= 1.0 - stone * (1.0 - stone) * 0.6;
	ALBEDO = col;
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-0.02, 0.04, ndl) * 0.55 + smoothstep(0.45, 0.5, ndl) * 0.45;
	float shadow = smoothstep(0.3, 0.5, ATTENUATION);
	DIFFUSE_LIGHT += LIGHT_COLOR * band * shadow / PI;
}
