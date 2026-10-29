// Höhe der Landschaft unter dem Sturz (Meter), gemeinsam für Gelände und Meer
uniform sampler2D terrain_noise : repeat_enable, filter_linear;

float terrain_height(vec2 w) {
	float n1 = texture(terrain_noise, w * 0.00005).r;
	float n2 = texture(terrain_noise, w * 0.00021 + vec2(0.37, 0.11)).r;
	float n3 = texture(terrain_noise, w * 0.0009 + vec2(0.71, 0.53)).r;
	float land = (n1 - 0.5) * 1400.0;                                        // Kontinente und Meer
	float hills = (n2 - 0.5) * 160.0;
	// Gebirge nur auf großen Landmassen, breit und weich statt spitz
	float ridge = smoothstep(0.57, 0.8, n2);
	float mount = ridge * ridge * 380.0 * smoothstep(0.52, 0.64, n1);
	float h = land + hills + mount + (n3 - 0.5) * 40.0;
	// flache Anhöhe in der Mitte für die Hauptstadt, das Meer öffnet sich erst weiter draußen
	return mix(32.0, h, smoothstep(900.0, 2600.0, length(w)));
}
