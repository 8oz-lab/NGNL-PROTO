// Anime-Toon-Shading: drei harte Lichtstufen, farbige Schatten, leichter Randglanz
shader_type spatial;
render_mode specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_texture = false;
uniform vec2 uv_scale = vec2(1.0);
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.1;
uniform bool use_vertex_color = false;
#include "res://assets/shaders/sway.gdshaderinc"

void vertex() {
	VERTEX += sway_offset(VERTEX, MODEL_MATRIX);
}

void fragment() {
	vec4 c = albedo;
	if (use_texture) {
		c *= texture(albedo_texture, UV * uv_scale);
	}
	if (use_vertex_color) {
		c.rgb *= COLOR.rgb;
	}
	ALBEDO = c.rgb;
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	EMISSION = emission_color.rgb + c.rgb * rim * rim_strength;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-0.02, 0.04, ndl) * 0.55 + smoothstep(0.45, 0.5, ndl) * 0.45;
	float shadow = smoothstep(0.3, 0.5, ATTENUATION);
	DIFFUSE_LIGHT += LIGHT_COLOR * band * shadow / PI;
}
