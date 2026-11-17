@tool
class_name HouseFacadeVariants
extends Resource

@export var variants: Array[HouseFacadeStyle] = []

func choose_style() -> HouseFacadeStyle:
	var choices := variants.filter(func(style): return style != null)
	return choices.pick_random().duplicate(true) as HouseFacadeStyle if not choices.is_empty() else null
