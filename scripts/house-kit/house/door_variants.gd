@tool
class_name HouseDoorVariants
extends Resource

@export var variants: Array[HouseDoorStyle] = []

func choose_style() -> HouseDoorStyle:
	var choices := variants.filter(func(style): return style != null)
	return choices.pick_random().duplicate(true) as HouseDoorStyle if not choices.is_empty() else null
