@tool
class_name UninhabitableHouseStyle
extends HouseFacadeStyle

const DAMAGE_FIELDS := ["style", "wall_variant", "roof_variant", "left_window_variant", "right_window_variant", "wall_texture_offset", "roof_texture_offset", "mirror_left_window", "mirror_right_window"]

@export_group("Damage")
@export var style := 0
@export var wall_variant := -1
@export var roof_variant := -1
@export var left_window_variant := -1
@export var right_window_variant := -1
@export var wall_texture_offset := Vector2.ZERO
@export var roof_texture_offset := Vector2.ZERO
@export var mirror_left_window := false
@export var mirror_right_window := true

func to_data() -> Dictionary:
	var data := super.to_data()
	data.merge(SaveGraph.get_fields(self, DAMAGE_FIELDS))
	return data
