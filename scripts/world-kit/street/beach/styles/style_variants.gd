@tool
class_name BeachStyleVariants
extends Resource

@export var variants: Array[BeachDecorationStyle] = []

func choose_style() -> BeachDecorationStyle:
	var choices := variants.filter(func(style): return style != null)
	if choices.is_empty():
		return null
	return choices.pick_random().duplicate(true) as BeachDecorationStyle
