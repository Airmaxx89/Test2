extends StaticBody3D
class_name Chunk
## Builds one CHUNK_SIZE x CHUNK_SIZE column of terrain mesh + collision by
## sampling World.get_block. Only faces adjacent to air/water/leaves are
## emitted, so memory use stays proportional to visible surface, not volume.

var chunk_pos: Vector2i


func build(cx: int, cz: int, world: World) -> void:
	chunk_pos = Vector2i(cx, cz)
	position = Vector3(cx * World.CHUNK_SIZE, 0, cz * World.CHUNK_SIZE)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

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
				_add_block(st, world, wx, y, wz, lx, y, lz, block)

	st.index()
	var mesh := st.commit()
	if mesh.get_surface_count() == 0:
		return
	mesh.surface_set_material(0, world.atlas_material)

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)

	var shape: Shape3D = mesh.create_trimesh_shape()
	var cs := CollisionShape3D.new()
	cs.shape = shape
	add_child(cs)


func _add_block(st: SurfaceTool, world: World, wx: int, wy: int, wz: int, lx: int, ly: int, lz: int, block: int) -> void:
	var tiles: Vector3i = VoxelData.get_tiles(block)
	var top_tile := tiles.x
	var bottom_tile := tiles.y
	var side_tile := tiles.z

	# +Y top
	if _face_visible(world, block, wx, wy + 1, wz):
		_add_quad(st, [
			Vector3(lx, ly + 1, lz), Vector3(lx, ly + 1, lz + 1),
			Vector3(lx + 1, ly + 1, lz + 1), Vector3(lx + 1, ly + 1, lz),
		], Vector3(0, 1, 0), top_tile)
	# -Y bottom
	if _face_visible(world, block, wx, wy - 1, wz):
		_add_quad(st, [
			Vector3(lx, ly, lz + 1), Vector3(lx, ly, lz),
			Vector3(lx + 1, ly, lz), Vector3(lx + 1, ly, lz + 1),
		], Vector3(0, -1, 0), bottom_tile)
	# +Z front
	if _face_visible(world, block, wx, wy, wz + 1):
		_add_quad(st, [
			Vector3(lx, ly, lz + 1), Vector3(lx + 1, ly, lz + 1),
			Vector3(lx + 1, ly + 1, lz + 1), Vector3(lx, ly + 1, lz + 1),
		], Vector3(0, 0, 1), side_tile)
	# -Z back
	if _face_visible(world, block, wx, wy, wz - 1):
		_add_quad(st, [
			Vector3(lx + 1, ly, lz), Vector3(lx, ly, lz),
			Vector3(lx, ly + 1, lz), Vector3(lx + 1, ly + 1, lz),
		], Vector3(0, 0, -1), side_tile)
	# +X right
	if _face_visible(world, block, wx + 1, wy, wz):
		_add_quad(st, [
			Vector3(lx + 1, ly, lz + 1), Vector3(lx + 1, ly, lz),
			Vector3(lx + 1, ly + 1, lz), Vector3(lx + 1, ly + 1, lz + 1),
		], Vector3(1, 0, 0), side_tile)
	# -X left
	if _face_visible(world, block, wx - 1, wy, wz):
		_add_quad(st, [
			Vector3(lx, ly, lz), Vector3(lx, ly, lz + 1),
			Vector3(lx, ly + 1, lz + 1), Vector3(lx, ly + 1, lz),
		], Vector3(-1, 0, 0), side_tile)


func _face_visible(world: World, current: int, nx: int, ny: int, nz: int) -> bool:
	if ny < 0 or ny >= World.WORLD_HEIGHT:
		return false
	var neighbor: int = world.get_block(nx, ny, nz)
	if neighbor == VoxelData.Block.AIR:
		return true
	if current == VoxelData.Block.WATER and neighbor == VoxelData.Block.WATER:
		return false
	return not VoxelData.is_opaque(neighbor)


func _add_quad(st: SurfaceTool, corners: Array, normal: Vector3, tile_index: int) -> void:
	var tile_w := 1.0 / float(VoxelData.ATLAS_COLS)
	var tile_h := 1.0 / float(VoxelData.ATLAS_ROWS)
	var col := tile_index % VoxelData.ATLAS_COLS
	var row := int(tile_index / VoxelData.ATLAS_COLS)
	var u0 := col * tile_w
	var v0 := row * tile_h
	var u1 := u0 + tile_w
	var v1 := v0 + tile_h
	var uvs := [Vector2(u0, v1), Vector2(u1, v1), Vector2(u1, v0), Vector2(u0, v0)]

	st.set_normal(normal)
	st.set_uv(uvs[0])
	st.add_vertex(corners[0])
	st.set_normal(normal)
	st.set_uv(uvs[1])
	st.add_vertex(corners[1])
	st.set_normal(normal)
	st.set_uv(uvs[2])
	st.add_vertex(corners[2])

	st.set_normal(normal)
	st.set_uv(uvs[0])
	st.add_vertex(corners[0])
	st.set_normal(normal)
	st.set_uv(uvs[2])
	st.add_vertex(corners[2])
	st.set_normal(normal)
	st.set_uv(uvs[3])
	st.add_vertex(corners[3])
