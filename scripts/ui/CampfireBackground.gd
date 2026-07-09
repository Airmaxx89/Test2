extends SubViewportContainer
class_name CampfireBackground
## A small, self-contained looping 3D scene (campfire, embers, smoke, a
## couple of villagers, a slowly orbiting camera) rendered into a
## SubViewport and stretched to fill its parent Control. Used as a living
## background behind the start menu and character creation screens instead
## of a flat gradient. Everything here is built from primitive meshes and
## particles - no external assets.

var _viewport: SubViewport
var _orbit_pivot: Node3D
var _fire_light: OmniLight3D
var _flicker_time: float = 0.0


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_viewport = SubViewport.new()
	_viewport.size = Vector2i(640, 360)
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	_build_environment()
	_build_camera()
	_build_ground()
	_build_campfire()
	_build_particles()
	_build_figures()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.11, 0.16)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.04, 0.07)
	env.fog_density = 0.035
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.25

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_viewport.add_child(world_env)

	var stars := DirectionalLight3D.new()
	stars.light_color = Color(0.5, 0.55, 0.7)
	stars.light_energy = 0.15
	stars.rotation_degrees = Vector3(-60, 20, 0)
	stars.shadow_enabled = false
	_viewport.add_child(stars)


func _build_camera() -> void:
	_orbit_pivot = Node3D.new()
	_viewport.add_child(_orbit_pivot)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.7, 4.4)
	camera.current = true
	_orbit_pivot.add_child(camera)
	camera.look_at(Vector3(0, 0.5, 0), Vector3.UP)


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 6.0
	mesh.bottom_radius = 6.5
	mesh.height = 0.2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.14, 0.07)
	mat.roughness = 1.0
	mesh.material = mat
	ground.mesh = mesh
	ground.position = Vector3(0, -0.1, 0)
	_viewport.add_child(ground)

	var dirt := MeshInstance3D.new()
	var dirt_mesh := CylinderMesh.new()
	dirt_mesh.top_radius = 1.15
	dirt_mesh.bottom_radius = 1.2
	dirt_mesh.height = 0.05
	var dirt_mat := StandardMaterial3D.new()
	dirt_mat.albedo_color = Color(0.22, 0.16, 0.11)
	dirt_mesh.material = dirt_mat
	dirt.mesh = dirt_mesh
	dirt.position = Vector3(0, 0.001, 0)
	_viewport.add_child(dirt)


func _build_campfire() -> void:
	for i in range(4):
		var log_mi := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.06
		mesh.bottom_radius = 0.07
		mesh.height = 1.0
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.24, 0.15, 0.08)
		mesh.material = mat
		log_mi.mesh = mesh
		log_mi.rotation_degrees = Vector3(90, i * 45, 0)
		log_mi.position = Vector3(0, 0.09, 0)
		_viewport.add_child(log_mi)

	var embers := MeshInstance3D.new()
	var embers_mesh := SphereMesh.new()
	embers_mesh.radius = 0.18
	embers_mesh.height = 0.26
	var embers_mat := StandardMaterial3D.new()
	embers_mat.albedo_color = Color(1.0, 0.4, 0.05)
	embers_mat.emission_enabled = true
	embers_mat.emission = Color(1.0, 0.45, 0.05)
	embers_mat.emission_energy_multiplier = 3.0
	embers_mesh.material = embers_mat
	embers.mesh = embers_mesh
	embers.position = Vector3(0, 0.18, 0)
	_viewport.add_child(embers)

	for i in range(8):
		var angle := i * TAU / 8.0
		var stone := MeshInstance3D.new()
		var stone_mesh := SphereMesh.new()
		stone_mesh.radius = 0.15
		stone_mesh.height = 0.22
		var stone_mat := StandardMaterial3D.new()
		stone_mat.albedo_color = Color(0.4, 0.4, 0.43)
		stone_mesh.material = stone_mat
		stone.mesh = stone_mesh
		stone.position = Vector3(cos(angle) * 0.8, 0.05, sin(angle) * 0.8)
		_viewport.add_child(stone)

	_fire_light = OmniLight3D.new()
	_fire_light.light_color = Color(1.0, 0.55, 0.2)
	_fire_light.omni_range = 7.0
	_fire_light.light_energy = 2.0
	_fire_light.position = Vector3(0, 0.4, 0)
	_viewport.add_child(_fire_light)


func _build_particles() -> void:
	var fire := CPUParticles3D.new()
	fire.amount = 28
	fire.lifetime = 1.0
	fire.position = Vector3(0, 0.22, 0)
	fire.direction = Vector3(0, 1, 0)
	fire.spread = 18.0
	fire.initial_velocity_min = 0.7
	fire.initial_velocity_max = 1.3
	fire.gravity = Vector3(0, 0.9, 0)
	fire.scale_amount_min = 0.12
	fire.scale_amount_max = 0.26
	var fire_ramp := Gradient.new()
	fire_ramp.set_color(0, Color(1.0, 0.85, 0.3, 1.0))
	fire_ramp.add_point(0.5, Color(1.0, 0.4, 0.05, 0.85))
	fire_ramp.set_color(1, Color(0.3, 0.05, 0.02, 0.0))
	fire.color_ramp = fire_ramp
	var fire_quad := QuadMesh.new()
	fire_quad.size = Vector2(0.35, 0.35)
	var fire_mat := StandardMaterial3D.new()
	fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire_mat.vertex_color_use_as_albedo = true
	fire_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fire_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fire_quad.material = fire_mat
	fire.mesh = fire_quad
	_viewport.add_child(fire)

	var smoke := CPUParticles3D.new()
	smoke.amount = 12
	smoke.lifetime = 2.6
	smoke.position = Vector3(0, 0.5, 0)
	smoke.direction = Vector3(0, 1, 0)
	smoke.spread = 12.0
	smoke.initial_velocity_min = 0.3
	smoke.initial_velocity_max = 0.6
	smoke.gravity = Vector3(0, 0.25, 0)
	smoke.scale_amount_min = 0.3
	smoke.scale_amount_max = 0.6
	var smoke_ramp := Gradient.new()
	smoke_ramp.set_color(0, Color(0.5, 0.5, 0.5, 0.3))
	smoke_ramp.set_color(1, Color(0.5, 0.5, 0.5, 0.0))
	smoke.color_ramp = smoke_ramp
	var smoke_quad := QuadMesh.new()
	smoke_quad.size = Vector2(0.6, 0.6)
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.vertex_color_use_as_albedo = true
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smoke_quad.material = smoke_mat
	smoke.mesh = smoke_quad
	_viewport.add_child(smoke)


func _build_figures() -> void:
	var positions := [Vector3(1.3, 0, 0.7), Vector3(-1.5, 0, -0.4)]
	for pos in positions:
		var figure := CharacterModel.build(Color(0.6, 0.5, 0.42), Color(0.28, 0.24, 0.32))
		figure.position = pos
		_viewport.add_child(figure)
		figure.look_at(Vector3(0, pos.y, 0), Vector3.UP)


func _process(delta: float) -> void:
	_flicker_time += delta
	if _fire_light:
		_fire_light.light_energy = 1.8 + sin(_flicker_time * 9.0) * 0.25 + sin(_flicker_time * 23.0) * 0.15
	if _orbit_pivot:
		_orbit_pivot.rotation.y += delta * 0.05
