// Himmel von Disboard: kräftiges Blau oben, warmes Pfirsich-Rosa am Horizont, große Haufenwolken,
// feine Federwolken in der Höhe und ein zarter Sternenschleier im Zenit (wie im Anime auch am Tag)
shader_type sky;

uniform vec3 zenith : source_color = vec3(0.09, 0.27, 0.84);
uniform vec3 mid : source_color = vec3(0.32, 0.6, 1.0);
uniform vec3 horizon : source_color = vec3(1.0, 0.76, 0.84);
uniform vec3 glow_band : source_color = vec3(1.0, 0.86, 0.68);
uniform vec3 ground : source_color = vec3(0.62, 0.7, 0.92);
uniform vec3 cloud_light : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 cloud_shade : source_color = vec3(0.72, 0.7, 0.96);
uniform vec3 cloud_warm : source_color = vec3(1.0, 0.82, 0.8);
uniform sampler2D cloud_noise : repeat_enable, filter_linear_mipmap;
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.47;
uniform float cloud_speed = 0.004;
uniform float stars = 0.22;

float fbm(vec2 p, vec2 wind) {
	return texture(cloud_noise, p * 0.18 + wind).r * 0.6
		+ texture(cloud_noise, p * 0.47 - wind * 1.7).r * 0.3
		+ texture(cloud_noise, p * 1.3 + wind * 2.5).r * 0.1;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	// Farbverlauf mit warmem Band knapp über dem Horizont
	vec3 col = mix(horizon, mid, smoothstep(0.0, 0.25, h));
	col = mix(col, zenith, smoothstep(0.22, 0.8, h));
	col = mix(col, glow_band, exp(-abs(h - 0.035) * 28.0) * 0.55);
	col = mix(col, ground, smoothstep(0.0, -0.1, h));
	// Sternenschleier und Milchstraßen-Band im Zenit
	if (h > 0.25 && stars > 0.0) {
		vec2 sp = d.xz / (h + 0.05) * 90.0;
		vec2 cell = floor(sp);
		float st = step(0.985, hash(cell)) * smoothstep(0.5, 0.0, length(fract(sp) - 0.5));
		float band = texture(cloud_noise, d.xz * 0.6 + vec2(0.3, 0.1)).r;
		float milky = smoothstep(0.55, 0.8, band) * exp(-pow(d.x + d.z * 0.4, 2.0) * 6.0);
		float k = smoothstep(0.25, 0.85, h) * stars;
		col += (vec3(1.0) * st + vec3(0.75, 0.6, 1.0) * milky * 0.35) * k;
	}
	// Sonne mit weichem Hof
	float sd = max(dot(d, LIGHT0_DIRECTION), 0.0);
	col += LIGHT0_COLOR * (pow(sd, 900.0) * 6.0 + pow(sd, 10.0) * 0.22 + pow(sd, 3.0) * 0.06);
	if (h > 0.0) {
		vec2 wind = vec2(TIME * cloud_speed, TIME * cloud_speed * 0.35);
		// Federwolken: langgezogene, zarte Streifen hoch oben
		vec2 cp = d.xz / (h + 0.05) * vec2(0.6, 3.5);
		float ci = smoothstep(0.58, 0.8, texture(cloud_noise, cp * 0.25 + wind * 0.5).r);
		col = mix(col, cloud_light, ci * 0.35 * smoothstep(0.15, 0.5, h));
		// Haufenwolken: groß und zweifarbig, zum Horizont hin dichter und wärmer
		vec2 p = d.xz / (h + 0.12) * 2.0;
		float n = fbm(p, wind);
		float edge = cloud_cover - smoothstep(0.35, 0.0, h) * 0.06;
		float a = smoothstep(edge, edge + 0.05, n);
		float lit = smoothstep(edge + 0.04, edge + 0.15, fbm(p + LIGHT0_DIRECTION.xz * 0.08, wind));
		vec3 cc = mix(cloud_shade, cloud_light, lit);
		cc = mix(cc, cloud_warm, smoothstep(0.3, 0.0, h) * 0.6 + pow(sd, 6.0) * 0.4);
		a *= smoothstep(0.0, 0.08, h);
		col = mix(col, cc, a);
	}
	COLOR = col;
}
