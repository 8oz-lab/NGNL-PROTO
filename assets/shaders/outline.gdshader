// Umrisslinie per vergrößerter Rückseite (Inverted Hull)
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0.12, 0.08, 0.22, 1.0);
uniform float thickness = 0.02;
#include "res://assets/shaders/sway.gdshaderinc"

void vertex() {
	VERTEX += sway_offset(VERTEX, MODEL_MATRIX) + NORMAL * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
