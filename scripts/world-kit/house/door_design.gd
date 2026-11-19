@tool
class_name HouseDoorDesign
extends Resource

const SINGLE_OPENING := Vector2(16, 28)
const DOUBLE_OPENING := Vector2(24, 28)
const ATLAS_SIZE := Vector2(56, 34)

@export var single_leaf := false
## Both states use the same 56 × 34 canvas and the door scene's ground anchor.
@export var closed_sprite: Texture2D
@export var closed_materials: Texture2D
@export var open_sprite: Texture2D
@export var open_materials: Texture2D

func is_complete() -> bool:
	return closed_sprite != null and closed_sprite.get_size() == ATLAS_SIZE \
		and (not single_leaf or open_sprite != null) \
		and (open_sprite == null or open_sprite.get_size() == ATLAS_SIZE) \
		and (closed_materials == null or closed_materials.get_size() == ATLAS_SIZE) \
		and (open_materials == null or open_materials.get_size() == ATLAS_SIZE)

func get_opening_size() -> Vector2:
	return SINGLE_OPENING if single_leaf else DOUBLE_OPENING
