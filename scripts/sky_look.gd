class_name SkyLook
## Gemeinsamer Himmel von Disboard für den Sturz und das Spiel: Sky-Shader, Wolkenrauschen,
## dazu passender Dunst und Umgebungslicht.

const HORIZON := Color(1.0, 0.8, 0.86)
const SKY_SHADER := preload("res://assets/shaders/sky.gdshader")

static var _noise: NoiseTexture2D


static func cloud_noise() -> NoiseTexture2D:
	if _noise == null:
		_noise = NoiseTexture2D.new()
		_noise.seamless = true
		_noise.width = 512
		_noise.height = 512
		var n := FastNoiseLite.new()
		n.frequency = 0.008
		n.fractal_octaves = 5
		_noise.noise = n
	return _noise


## Setzt Himmel, Dunst in Horizontfarbe und Umgebungslicht. fog_density: Dichte des Dunstes.
static func apply(env: Environment, fog_density: float) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SKY_SHADER
	mat.set_shader_parameter("cloud_noise", cloud_noise())
	var sky := Sky.new()
	sky.sky_material = mat
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.64, 0.62, 0.9)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = HORIZON.lerp(Color(0.8, 0.86, 1.0), 0.45)
	env.fog_density = fog_density
	env.fog_sky_affect = 0.0
