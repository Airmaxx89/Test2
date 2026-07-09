extends Node3D
class_name World
## Owns procedural terrain generation, chunk streaming, NPC placement and
## mob spawning for the Eichenmark starting region. Terrain is generated
## purely from a height function + a sparse override dictionary (trees,
## houses, fortress walls) - no per-block data needs to be stored for the
## empty procedural terrain itself, only for player-visible landmarks.

const CHUNK_SIZE := 16
const WORLD_HEIGHT := 48
const LOAD_RADIUS := 3
const IMMEDIATE_RADIUS := 1
const CHUNKS_PER_FRAME := 2
const WATER_LEVEL := 27

var noise: FastNoiseLite
var overrides: Dictionary = {} # Vector3i -> Block id
var chunks: Dictionary = {} # Vector2i -> Chunk
var atlas_material: StandardMaterial3D
var water_material: StandardMaterial3D

var spawner_state: Dictionary = {} # spawner id -> {"alive": Array, "timer": float}

var player: Node3D = null

var _chunk_timer: float = 0.0
var _pending_chunks: Array = []

signal player_spawned(player: Node3D)


func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.seed = 1337
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	_build_atlas_material()
	_build_sun()
	_generate_overrides()
	_spawn_npcs()
	_init_spawners()
	_spawn_player()
	# Build the ground right under/around the player synchronously so they
	# never fall through the world; the rest of the view distance streams
	# in over the next few frames instead of freezing on one big frame.
	_load_chunks_immediate(player.global_position)
	update_chunks(player.global_position)


func _build_atlas_material() -> void:
	var tex := load("res://assets/textures/atlas.png")

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	mat.vertex_color_use_as_albedo = true
	atlas_material = mat

	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_texture = tex
	water_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.65)
	water_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	water_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	water_mat.roughness = 0.05
	water_mat.metallic = 0.1
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.vertex_color_use_as_albedo = true
	water_material = water_mat


## A fixed, world-space sun. This must NOT be parented to the player - the
## player rotates constantly to face different directions, and a light
## parented to a rotating node would visibly swing the sun/shadows around
## with the camera instead of keeping a stable world direction.
func _build_sun() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = float(LOAD_RADIUS * CHUNK_SIZE)
	add_child(sun)


func _spawn_player() -> void:
	var p := preload("res://scripts/entities/Player.gd").new()
	add_child(p)
	player = p
	if GameManager.character_created and GameManager.world_position.length() > 0.1:
		p.global_position = GameManager.world_position
	else:
		p.global_position = Vector3(0, get_height(0, 0) + 2, 0)
	player_spawned.emit(p)


func _spawn_npcs() -> void:
	var npc_script := preload("res://scripts/entities/NPC.gd")
	for def in ZoneData.NPCS:
		var npc = npc_script.new()
		add_child(npc)
		npc.setup(def["id"], def["name"])
		npc.global_position = Vector3(def["x"], get_spawn_height(def["x"], def["z"]), def["z"])


func _init_spawners() -> void:
	for def in ZoneData.SPAWNERS:
		spawner_state[def["id"]] = {"alive": [], "timer": 1.0}


# ---------------------------------------------------------------------------
# Terrain
# ---------------------------------------------------------------------------

func get_zone(x: int) -> String:
	return ZoneData.get_zone(x)


func get_biome(x: int) -> String:
	return ZoneData.get_biome(x)


## Ground level to stand on, raised above the water surface in swampy spots
## so NPCs/mobs don't spawn waist-deep (or fully submerged) in water.
func get_spawn_height(x: int, z: int) -> int:
	return max(get_height(x, z), WATER_LEVEL) + 1


func get_height(x: int, z: int) -> int:
	var biome := ZoneData.get_biome(x)
	if biome == "meadow" and absi(x) < 26:
		return 32
	if biome == "ruins":
		return 34
	var n := noise.get_noise_2d(float(x), float(z))
	var h: int
	match biome:
		"meadow":
			h = 32 + int(n * 4.0)
		"forest":
			h = 33 + int(n * 5.0)
		"hills":
			h = 36 + int(n * 10.0)
		"swamp":
			h = 25 + int(n * 2.0)
		_:
			h = 32
	return clampi(h, 10, 45)


func get_surface_block(x: int) -> int:
	match ZoneData.get_biome(x):
		"meadow", "forest":
			return VoxelData.Block.GRASS
		"hills":
			return VoxelData.Block.GRASS
		"swamp":
			return VoxelData.Block.DIRT
		"ruins":
			return VoxelData.Block.DARK_STONE
		_:
			return VoxelData.Block.GRASS


func get_block(x: int, y: int, z: int) -> int:
	return get_block_in_column(x, y, z, get_height(x, z), ZoneData.get_biome(x))


## Faster path for chunk meshing: caller already knows the column's height
## and biome, so this skips re-sampling noise for every single y-level.
func get_block_in_column(x: int, y: int, z: int, h: int, biome: String) -> int:
	var key := Vector3i(x, y, z)
	if overrides.has(key):
		return overrides[key]
	if y > h:
		if biome == "swamp" and y <= WATER_LEVEL:
			return VoxelData.Block.WATER
		return VoxelData.Block.AIR
	if y == h:
		return get_surface_block(x)
	var dirt_depth := 1 if biome == "hills" else 3
	if y > h - dirt_depth:
		return VoxelData.Block.DARK_STONE if biome == "ruins" else VoxelData.Block.DIRT
	return VoxelData.Block.DARK_STONE if biome == "ruins" else VoxelData.Block.STONE


# ---------------------------------------------------------------------------
# Overrides: trees, village houses, fortress walls, road
# ---------------------------------------------------------------------------

func _hash01(x: int, z: int) -> float:
	var n: int = (x * 374761393 + z * 668265263)
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xFFFFFFF) / float(0xFFFFFFF)


func _generate_overrides() -> void:
	_generate_trees()
	_build_house(Vector3i(-24, 32, -18), 8, 6, 4)
	_build_house(Vector3i(8, 32, -18), 8, 6, 4)
	_build_house(Vector3i(-8, 32, 6), 12, 8, 5)
	_build_fortress()
	_build_road()


func _generate_trees() -> void:
	for gx in range(-64, 168, 5):
		for gz in range(ZoneData.Z_RANGE.x, ZoneData.Z_RANGE.y, 5):
			var biome := ZoneData.get_biome(gx)
			if biome != "meadow" and biome != "forest":
				continue
			var jitter_x: int = int(_hash01(gx, gz) * 4.0) - 2
			var jitter_z: int = int(_hash01(gx + 1, gz + 1) * 4.0) - 2
			var tx: int = gx + jitter_x
			var tz: int = gz + jitter_z
			if biome == "meadow" and absi(tx) < 30:
				continue # keep the village square clear
			var density: float = 0.85 if biome == "meadow" else 0.55
			if _hash01(tx, tz) > density:
				continue
			_plant_tree(tx, tz)


func _plant_tree(tx: int, tz: int) -> void:
	var h := get_height(tx, tz)
	var trunk_height: int = 4 + int(_hash01(tx, tz) * 3.0)
	for i in range(trunk_height):
		overrides[Vector3i(tx, h + 1 + i, tz)] = VoxelData.Block.WOOD
	var top := h + 1 + trunk_height
	for dx in range(-2, 3):
		for dy in range(-1, 2):
			for dz in range(-2, 3):
				if absi(dx) == 2 and absi(dz) == 2:
					continue
				var pos := Vector3i(tx + dx, top + dy, tz + dz)
				if overrides.get(pos, VoxelData.Block.AIR) != VoxelData.Block.WOOD:
					overrides[pos] = VoxelData.Block.LEAVES


func _build_house(origin: Vector3i, w: int, d: int, wall_h: int) -> void:
	for x in range(origin.x, origin.x + w):
		for z in range(origin.z, origin.z + d):
			var is_perimeter: bool = (x == origin.x or x == origin.x + w - 1 or z == origin.z or z == origin.z + d - 1)
			if is_perimeter:
				for y in range(origin.y + 1, origin.y + 1 + wall_h):
					overrides[Vector3i(x, y, z)] = VoxelData.Block.FACHWERK
	for x in range(origin.x - 1, origin.x + w + 1):
		for z in range(origin.z - 1, origin.z + d + 1):
			overrides[Vector3i(x, origin.y + 1 + wall_h, z)] = VoxelData.Block.ROOF
	var door_x := origin.x + int(w / 2)
	overrides[Vector3i(door_x, origin.y + 1, origin.z)] = VoxelData.Block.AIR
	overrides[Vector3i(door_x, origin.y + 2, origin.z)] = VoxelData.Block.AIR


func _build_fortress() -> void:
	var x0 := 428
	var x1 := 468
	var z0 := -40
	var z1 := 40
	var base_h := 34
	var wall_h := 8
	for x in range(x0, x1):
		for z in range(z0, z1):
			var is_perimeter: bool = (x == x0 or x == x1 - 1 or z == z0 or z == z1 - 1)
			if is_perimeter:
				for y in range(base_h + 1, base_h + 1 + wall_h):
					overrides[Vector3i(x, y, z)] = VoxelData.Block.DARK_STONE
	for z in range(-3, 4):
		for y in range(base_h + 1, base_h + 6):
			overrides[Vector3i(x0, y, z)] = VoxelData.Block.AIR
	for cx in [x0, x1 - 1]:
		for cz in [z0, z1 - 1]:
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					for y in range(base_h + 1, base_h + 1 + wall_h + 3):
						overrides[Vector3i(cx + dx, y, cz + dz)] = VoxelData.Block.DARK_STONE


func _build_road() -> void:
	for x in range(-45, 468):
		for z in range(-2, 3):
			var h := get_height(x, z)
			overrides[Vector3i(x, h, z)] = VoxelData.Block.PATH


# ---------------------------------------------------------------------------
# Chunk streaming
# ---------------------------------------------------------------------------

func _get_chunk_coord(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / CHUNK_SIZE)), int(floor(pos.z / CHUNK_SIZE)))


func _load_chunks_immediate(center_pos: Vector3) -> void:
	var center_chunk := _get_chunk_coord(center_pos)
	for dx in range(-IMMEDIATE_RADIUS, IMMEDIATE_RADIUS + 1):
		for dz in range(-IMMEDIATE_RADIUS, IMMEDIATE_RADIUS + 1):
			var c := Vector2i(center_chunk.x + dx, center_chunk.y + dz)
			if not chunks.has(c):
				_load_chunk(c)


func update_chunks(center_pos: Vector3) -> void:
	var center_chunk := _get_chunk_coord(center_pos)
	var needed: Dictionary = {}
	for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dz in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var c := Vector2i(center_chunk.x + dx, center_chunk.y + dz)
			needed[c] = true
			if not chunks.has(c) and not _pending_chunks.has(c):
				_pending_chunks.append(c)
	for c in chunks.keys():
		if not needed.has(c):
			_unload_chunk(c)
	_pending_chunks = _pending_chunks.filter(func(c): return needed.has(c))


func _process_chunk_queue() -> void:
	for i in range(CHUNKS_PER_FRAME):
		if _pending_chunks.is_empty():
			break
		var c: Vector2i = _pending_chunks.pop_front()
		if not chunks.has(c):
			_load_chunk(c)


func _load_chunk(c: Vector2i) -> void:
	var chunk_script := preload("res://scripts/world/Chunk.gd")
	var chunk = chunk_script.new()
	add_child(chunk)
	chunk.build(c.x, c.y, self)
	chunks[c] = chunk


func _unload_chunk(c: Vector2i) -> void:
	chunks[c].queue_free()
	chunks.erase(c)


# ---------------------------------------------------------------------------
# Mob spawning
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if player == null:
		return
	_chunk_timer -= delta
	if _chunk_timer <= 0.0:
		_chunk_timer = 0.5
		update_chunks(player.global_position)
	_process_chunk_queue()
	_update_spawners(delta)


func _update_spawners(delta: float) -> void:
	var mob_script := preload("res://scripts/entities/Mob.gd")
	for def in ZoneData.SPAWNERS:
		var st: Dictionary = spawner_state[def["id"]]
		st["alive"] = st["alive"].filter(func(m): return is_instance_valid(m))
		if st["alive"].size() >= def["max_alive"]:
			continue
		var center := Vector3(def["x"], 0, def["z"])
		var flat_player := Vector3(player.global_position.x, 0, player.global_position.z)
		if flat_player.distance_to(center) > LOAD_RADIUS * CHUNK_SIZE * 1.5:
			continue
		st["timer"] -= delta
		if st["timer"] <= 0.0:
			_spawn_mob(def, st, mob_script)
			st["timer"] = def["respawn"]


func _spawn_mob(def: Dictionary, st: Dictionary, mob_script: Script) -> void:
	var angle := randf() * TAU
	var r := randf() * def["radius"]
	var mx := int(def["x"] + cos(angle) * r)
	var mz := int(def["z"] + sin(angle) * r)
	var my := get_spawn_height(mx, mz)
	var mob = mob_script.new()
	add_child(mob)
	var mob_data: Dictionary = MobData.get_mob(def["mob"])
	var level_range: Vector2i = mob_data["level_range"]
	var mob_level: int = level_range.x if level_range.x == level_range.y else randi_range(level_range.x, level_range.y)
	mob.setup(def["mob"], mob_level, self)
	mob.global_position = Vector3(mx, my, mz)
	st["alive"].append(mob)
