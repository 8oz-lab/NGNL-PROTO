// Umrisslinie per vergrößerter Rückseite (Inverted Hull)
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0.12, 0.08, 0.22, 1.0);
uniform float thickness = 0.02;

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
