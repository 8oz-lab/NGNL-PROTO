// Anime-Himmel: Verlauf von Blau nach Rosa, Sonnenschein, zweifarbige Wolken, die langsam ziehen
shader_type sky;

uniform vec3 zenith : source_color = vec3(0.22, 0.47, 0.93);
uniform vec3 mid : source_color = vec3(0.5, 0.72, 0.98);
uniform vec3 horizon : source_color = vec3(1.0, 0.86, 0.92);
uniform vec3 ground : source_color = vec3(0.72, 0.78, 0.9);
uniform vec3 cloud_light : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 cloud_shade : source_color = vec3(0.74, 0.74, 0.95);
uniform sampler2D cloud_noise : repeat_enable, filter_linear_mipmap;
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.48;
uniform float cloud_speed = 0.004;

float clouds(vec2 p, vec2 wind) {
	float n = texture(cloud_noise, p * 0.18 + wind).r * 0.6
		+ texture(cloud_noise, p * 0.47 - wind * 1.7).r * 0.3
		+ texture(cloud_noise, p * 1.3 + wind * 2.5).r * 0.1;
	return n;
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col = mix(horizon, mid, smoothstep(0.0, 0.22, h));
	col = mix(col, zenith, smoothstep(0.2, 0.75, h));
	col = mix(col, ground, smoothstep(0.0, -0.08, h));
	// Sonne mit weichem Hof
	float sd = max(dot(d, LIGHT0_DIRECTION), 0.0);
	col += LIGHT0_COLOR * (pow(sd, 900.0) * 6.0 + pow(sd, 12.0) * 0.18);
	// Wolken auf einer gedachten Wolkendecke
	if (h > 0.0) {
		vec2 wind = vec2(TIME * cloud_speed, TIME * cloud_speed * 0.35);
		vec2 p = d.xz / (h + 0.18) * 2.2;
		float n = clouds(p, wind);
		float edge = cloud_cover;
		float a = smoothstep(edge, edge + 0.06, n);
		// Unterseite der Wolken dunkler: weiter unten in der Wolke = Schatten
		float lit = smoothstep(edge + 0.05, edge + 0.16, clouds(p + LIGHT0_DIRECTION.xz * 0.08, wind));
		vec3 cc = mix(cloud_shade, cloud_light, lit);
		cc = mix(cc, horizon, smoothstep(0.35, 0.0, h) * 0.55);
		a *= smoothstep(0.0, 0.12, h);
		col = mix(col, cc, a);
	}
	COLOR = col;
}
