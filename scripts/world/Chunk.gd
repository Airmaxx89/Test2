extends StaticBody3D
class_name Chunk
## Builds one CHUNK_SIZE x CHUNK_SIZE column of terrain mesh + collision by
## sampling World.get_block. Only faces adjacent to air/water/leaves are
## emitted, so memory use stays proportional to visible surface, not volume.
## Opaque terrain and water are built as two separate mesh surfaces/materials
## so water can be transparent. Each vertex also gets a baked ambient-
## occlusion darkening factor (corner-neighbor based), which is what makes
## the blocky terrain read as lit/shaded rather than flat-shaded slabs.

const AO_LUT := [1.0, 0.82, 0.65, 0.5]

var chunk_pos: Vector2i


func build(cx: int, cz: int, world: World) -> void:
	chunk_pos = Vector2i(cx, cz)
	position = Vector3(cx * World.CHUNK_SIZE, 0, cz * World.CHUNK_SIZE)

	var st_opaque := SurfaceTool.new()
	st_opaque.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_water := SurfaceTool.new()
	st_water.begin(Mesh.PRIMITIVE_TRIANGLES)
	var opaque_blocks := 0
	var water_blocks := 0

	for lx in range(World.CHUNK_SIZE):
		for lz in range(World.CHUNK_SIZE):
			var wx := cx * World.CHUNK_SIZE + lx
			var wz := cz * World.CHUNK_SIZE + lz
			var h := world.get_height(wx, wz)
			var biome := world.get_biome(wx)
			# No override ever carves below the surface (trees/houses/walls/
			# roads only ever add blocks at or above ground level), so any
			# block well below this column's own height AND all 4 neighbors'
			# heights is guaranteed fully buried - skip it without even
			# touching the override dictionary.
			var min_neighbor_h: int = h
			min_neighbor_h = min(min_neighbor_h, world.get_height(wx + 1, wz))
			min_neighbor_h = min(min_neighbor_h, world.get_height(wx - 1, wz))
			min_neighbor_h = min(min_neighbor_h, world.get_height(wx, wz + 1))
			min_neighbor_h = min(min_neighbor_h, world.get_height(wx, wz - 1))
			var safe_below := min_neighbor_h - 2
			for y in range(World.WORLD_HEIGHT):
				if y < safe_below:
					continue
				var block: int = world.get_block_in_column(wx, y, wz, h, biome)
				if block == VoxelData.Block.AIR:
					continue
				if block == VoxelData.Block.WATER:
					water_blocks += 1
					_add_block(st_water, world, wx, y, wz, lx, y, lz, block)
				else:
					opaque_blocks += 1
					_add_block(st_opaque, world, wx, y, wz, lx, y, lz, block)

	var mesh: ArrayMesh = null

	if opaque_blocks > 0:
		st_opaque.index()
		mesh = st_opaque.commit()
		mesh.surface_set_material(0, world.atlas_material)
		var shape: Shape3D = mesh.create_trimesh_shape()
		var cs := CollisionShape3D.new()
		cs.shape = shape
		add_child(cs)

	if water_blocks > 0:
		st_water.index()
		mesh = st_water.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, world.water_material)

	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)


func _add_block(st: SurfaceTool, world: World, wx: int, wy: int, wz: int, lx: int, ly: int, lz: int, block: int) -> void:
	var tiles: Vector3i = VoxelData.get_tiles(block)
	var top_tile := tiles.x
	var bottom_tile := tiles.y
	var side_tile := tiles.z

	# +Y top
	if _face_visible(world, block, wx, wy + 1, wz):
		var layer := Vector3i(wx, wy + 1, wz)
		var ao := [
			_ao_for_offsets(world, layer, 0, 0, 2, 0),
			_ao_for_offsets(world, layer, 0, 0, 2, 1),
			_ao_for_offsets(world, layer, 0, 1, 2, 1),
			_ao_for_offsets(world, layer, 0, 1, 2, 0),
		]
		_add_quad(st, [
			Vector3(lx, ly + 1, lz), Vector3(lx, ly + 1, lz + 1),
			Vector3(lx + 1, ly + 1, lz + 1), Vector3(lx + 1, ly + 1, lz),
		], Vector3(0, 1, 0), top_tile, ao)
	# -Y bottom
	if _face_visible(world, block, wx, wy - 1, wz):
		var layer := Vector3i(wx, wy - 1, wz)
		var ao := [
			_ao_for_offsets(world, layer, 0, 0, 2, 1),
			_ao_for_offsets(world, layer, 0, 0, 2, 0),
			_ao_for_offsets(world, layer, 0, 1, 2, 0),
			_ao_for_offsets(world, layer, 0, 1, 2, 1),
		]
		_add_quad(st, [
			Vector3(lx, ly, lz + 1), Vector3(lx, ly, lz),
			Vector3(lx + 1, ly, lz), Vector3(lx + 1, ly, lz + 1),
		], Vector3(0, -1, 0), bottom_tile, ao)
	# +Z front
	if _face_visible(world, block, wx, wy, wz + 1):
		var layer := Vector3i(wx, wy, wz + 1)
		var ao := [
			_ao_for_offsets(world, layer, 0, 0, 1, 0),
			_ao_for_offsets(world, layer, 0, 1, 1, 0),
			_ao_for_offsets(world, layer, 0, 1, 1, 1),
			_ao_for_offsets(world, layer, 0, 0, 1, 1),
		]
		_add_quad(st, [
			Vector3(lx, ly, lz + 1), Vector3(lx + 1, ly, lz + 1),
			Vector3(lx + 1, ly + 1, lz + 1), Vector3(lx, ly + 1, lz + 1),
		], Vector3(0, 0, 1), side_tile, ao)
	# -Z back
	if _face_visible(world, block, wx, wy, wz - 1):
		var layer := Vector3i(wx, wy, wz - 1)
		var ao := [
			_ao_for_offsets(world, layer, 0, 1, 1, 0),
			_ao_for_offsets(world, layer, 0, 0, 1, 0),
			_ao_for_offsets(world, layer, 0, 0, 1, 1),
			_ao_for_offsets(world, layer, 0, 1, 1, 1),
		]
		_add_quad(st, [
			Vector3(lx + 1, ly, lz), Vector3(lx, ly, lz),
			Vector3(lx, ly + 1, lz), Vector3(lx + 1, ly + 1, lz),
		], Vector3(0, 0, -1), side_tile, ao)
	# +X right
	if _face_visible(world, block, wx + 1, wy, wz):
		var layer := Vector3i(wx + 1, wy, wz)
		var ao := [
			_ao_for_offsets(world, layer, 2, 1, 1, 0),
			_ao_for_offsets(world, layer, 2, 0, 1, 0),
			_ao_for_offsets(world, layer, 2, 0, 1, 1),
			_ao_for_offsets(world, layer, 2, 1, 1, 1),
		]
		_add_quad(st, [
			Vector3(lx + 1, ly, lz + 1), Vector3(lx + 1, ly, lz),
			Vector3(lx + 1, ly + 1, lz), Vector3(lx + 1, ly + 1, lz + 1),
		], Vector3(1, 0, 0), side_tile, ao)
	# -X left
	if _face_visible(world, block, wx - 1, wy, wz):
		var layer := Vector3i(wx - 1, wy, wz)
		var ao := [
			_ao_for_offsets(world, layer, 2, 0, 1, 0),
			_ao_for_offsets(world, layer, 2, 1, 1, 0),
			_ao_for_offsets(world, layer, 2, 1, 1, 1),
			_ao_for_offsets(world, layer, 2, 0, 1, 1),
		]
		_add_quad(st, [
			Vector3(lx, ly, lz), Vector3(lx, ly, lz + 1),
			Vector3(lx, ly + 1, lz + 1), Vector3(lx, ly + 1, lz),
		], Vector3(-1, 0, 0), side_tile, ao)


func _face_visible(world: World, current: int, nx: int, ny: int, nz: int) -> bool:
	if ny < 0 or ny >= World.WORLD_HEIGHT:
		return false
	var neighbor: int = world.get_block(nx, ny, nz)
	if neighbor == VoxelData.Block.AIR:
		return true
	if current == VoxelData.Block.WATER and neighbor == VoxelData.Block.WATER:
		return false
	return not VoxelData.is_opaque(neighbor)


## Ambient occlusion for one face-corner. `layer` is the block position one
## step out along the face normal (where the face plane sits). `axis1`/
## `axis2` (0=x, 1=y, 2=z) are the two tangent axes of the face; `off1`/
## `off2` (0 or 1) say which of the four corners this is, matching the same
## 0/1 convention used for that corner's vertex position.
func _ao_for_offsets(world: World, layer: Vector3i, axis1: int, off1: int, axis2: int, off2: int) -> float:
	var sign1 := -1 if off1 == 0 else 1
	var sign2 := -1 if off2 == 0 else 1
	var t1 := Vector3i.ZERO
	var t2 := Vector3i.ZERO
	match axis1:
		0: t1.x = sign1
		1: t1.y = sign1
		2: t1.z = sign1
	match axis2:
		0: t2.x = sign2
		1: t2.y = sign2
		2: t2.z = sign2

	var side1 := VoxelData.is_opaque(world.get_block(layer.x + t1.x, layer.y + t1.y, layer.z + t1.z))
	var side2 := VoxelData.is_opaque(world.get_block(layer.x + t2.x, layer.y + t2.y, layer.z + t2.z))
	if side1 and side2:
		return AO_LUT[3]
	var corner := VoxelData.is_opaque(world.get_block(layer.x + t1.x + t2.x, layer.y + t1.y + t2.y, layer.z + t1.z + t2.z))
	return AO_LUT[int(side1) + int(side2) + int(corner)]


func _add_quad(st: SurfaceTool, corners: Array, normal: Vector3, tile_index: int, ao: Array) -> void:
	var tile_w := 1.0 / float(VoxelData.ATLAS_COLS)
	var tile_h := 1.0 / float(VoxelData.ATLAS_ROWS)
	var col := tile_index % VoxelData.ATLAS_COLS
	var row := int(tile_index / VoxelData.ATLAS_COLS)
	var u0 := col * tile_w
	var v0 := row * tile_h
	var u1 := u0 + tile_w
	var v1 := v0 + tile_h
	var uvs := [Vector2(u0, v1), Vector2(u1, v1), Vector2(u1, v0), Vector2(u0, v0)]

	var order := [0, 1, 2, 0, 2, 3]
	for i in order:
		var shade: float = ao[i]
		st.set_color(Color(shade, shade, shade, 1.0))
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(corners[i])
