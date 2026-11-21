@tool
class_name HouseFurnitureVariants
extends DecorationVariants

@export var variants: Array[HouseFurnitureStyle] = []
@export var rug_variants: Array[HouseFurnitureStyle.RugDesign] = []
@export var painting_variants: Array[HouseFurnitureStyle.PaintingDesign] = []
@export var wall_decoration_variants: Array[HouseFurnitureStyle.WallDecoration] = []

func choose_style() -> HouseFurnitureStyle:
	var choices := variants.filter(func(style): return style != null)
	if choices.is_empty():
		return null
	var style := choices.pick_random().duplicate(true) as HouseFurnitureStyle
	if not rug_variants.is_empty():
		style.rug_style = rug_variants.pick_random()
	if not painting_variants.is_empty():
		style.painting_style = painting_variants.pick_random()
	if not wall_decoration_variants.is_empty():
		style.wall_decoration = wall_decoration_variants.pick_random()
	return style
