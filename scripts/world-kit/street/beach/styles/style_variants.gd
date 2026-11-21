@tool
class_name BeachStyleVariants
extends DecorationVariants

@export var variants: Array[DecorationStyle] = []

func choose_style() -> DecorationStyle:
	var choices := variants.filter(func(style): return style != null)
	if choices.is_empty():
		return null
	return choices.pick_random().duplicate(true) as DecorationStyle
