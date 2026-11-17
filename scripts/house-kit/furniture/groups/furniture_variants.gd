@tool
class_name HouseFurnitureVariants
extends Resource

@export var variants: Array[HouseFurnitureStyle] = []

func choose_style() -> HouseFurnitureStyle:
	var choices := variants.filter(func(style): return style != null)
	return choices.pick_random().duplicate(true) as HouseFurnitureStyle if not choices.is_empty() else null
