@tool
class_name UninhabitableHouseDesign
extends Resource

@export_group("Wall")
@export var wall_albedo: Texture2D
@export var wall_materials: Texture2D
@export_group("Roof")
@export var roof_albedo: Texture2D
@export var roof_materials: Texture2D
@export_group("Window")
@export var window_albedo: Texture2D
@export var window_materials: Texture2D
@export_group("Door")
@export var door_albedo: Texture2D
@export var door_materials: Texture2D

func apply_part(sprite: Sprite2D, part: String) -> void:
	var texture := get(part + "_albedo") as Texture2D
	var mask := get(part + "_materials") as Texture2D
	if texture == null or mask == null:
		return
	sprite.texture = texture
	HouseArt.set_parameter(sprite.material as ShaderMaterial, &"material_mask", mask)

func is_complete() -> bool:
	for part in ["wall", "roof", "window", "door"]:
		var texture := get(part + "_albedo") as Texture2D
		var mask := get(part + "_materials") as Texture2D
		if texture == null or mask == null or texture.get_size() != mask.get_size():
			return false
	return true
