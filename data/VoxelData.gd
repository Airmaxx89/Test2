extends Node
class_name VoxelData
## Static block/voxel definitions for the world generator and chunk mesher.
## All block art is original pixel art (see tools/generate_textures.py).

const ATLAS_COLS := 8
const ATLAS_ROWS := 2

enum Block {
	AIR = 0,
	GRASS = 1,
	DIRT = 2,
	STONE = 3,
	SAND = 4,
	WATER = 5,
	WOOD = 6,
	LEAVES = 7,
	SNOW = 8,
	PATH = 9,
	PLANKS = 10,
	ORE = 11,
	DARK_STONE = 12,
	ROOF = 13,
	FACHWERK = 14,
}

# Atlas tile index order produced by generate_textures.py
const TILE_GRASS_TOP := 0
const TILE_GRASS_SIDE := 1
const TILE_DIRT := 2
const TILE_STONE := 3
const TILE_SAND := 4
const TILE_WATER := 5
const TILE_WOOD_SIDE := 6
const TILE_WOOD_TOP := 7
const TILE_LEAVES := 8
const TILE_SNOW := 9
const TILE_PATH := 10
const TILE_PLANKS := 11
const TILE_ORE := 12
const TILE_DARK_STONE := 13
const TILE_ROOF := 14
const TILE_FACHWERK := 15

## face order: top, bottom, side
static func get_tiles(block: int) -> Vector3i:
	match block:
		Block.GRASS:
			return Vector3i(TILE_GRASS_TOP, TILE_DIRT, TILE_GRASS_SIDE)
		Block.DIRT:
			return Vector3i(TILE_DIRT, TILE_DIRT, TILE_DIRT)
		Block.STONE:
			return Vector3i(TILE_STONE, TILE_STONE, TILE_STONE)
		Block.SAND:
			return Vector3i(TILE_SAND, TILE_SAND, TILE_SAND)
		Block.WATER:
			return Vector3i(TILE_WATER, TILE_WATER, TILE_WATER)
		Block.WOOD:
			return Vector3i(TILE_WOOD_TOP, TILE_WOOD_TOP, TILE_WOOD_SIDE)
		Block.LEAVES:
			return Vector3i(TILE_LEAVES, TILE_LEAVES, TILE_LEAVES)
		Block.SNOW:
			return Vector3i(TILE_SNOW, TILE_SNOW, TILE_SNOW)
		Block.PATH:
			return Vector3i(TILE_PATH, TILE_PATH, TILE_PATH)
		Block.PLANKS:
			return Vector3i(TILE_PLANKS, TILE_PLANKS, TILE_PLANKS)
		Block.ORE:
			return Vector3i(TILE_ORE, TILE_ORE, TILE_ORE)
		Block.DARK_STONE:
			return Vector3i(TILE_DARK_STONE, TILE_DARK_STONE, TILE_DARK_STONE)
		Block.ROOF:
			return Vector3i(TILE_ROOF, TILE_ROOF, TILE_ROOF)
		Block.FACHWERK:
			return Vector3i(TILE_FACHWERK, TILE_FACHWERK, TILE_FACHWERK)
		_:
			return Vector3i(-1, -1, -1)

static func is_solid(block: int) -> bool:
	return block != Block.AIR and block != Block.WATER

static func is_opaque(block: int) -> bool:
	return block != Block.AIR and block != Block.WATER and block != Block.LEAVES
