@tool
class_name HouseRoomVariants
extends Resource

@export var variants: Array[HouseRoomStyle] = []

func choose_style() -> HouseRoomStyle:
	var choices := variants.filter(func(style): return style != null)
	# Each house edits its own copy; the preset resource stays unchanged.
	return choices.pick_random().duplicate(true) as HouseRoomStyle if not choices.is_empty() else null
