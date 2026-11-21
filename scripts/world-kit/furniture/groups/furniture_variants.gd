@tool
class_name HouseFurnitureVariants
extends DecorationVariants

@export var variants: Array[HouseFurnitureStyle] = []
@export var rug_variants: Array[HouseFurnitureStyle.RugDesign] = []
@export var painting_variants: Array[HouseFurnitureStyle.PaintingDesign] = []
@export var wall_decoration_variants: Array[HouseFurnitureStyle.WallDecoration] = []

func choose_style(rng: RandomNumberGenerator = null) -> HouseFurnitureStyle:
	var choices := variants.filter(func(style): return style != null)
	if choices.is_empty():
		return null
	var style := _pick(choices, rng).duplicate(true) as HouseFurnitureStyle
	if not rug_variants.is_empty():
		style.rug_style = _pick(rug_variants, rng)
	if not painting_variants.is_empty():
		style.painting_style = _pick(painting_variants, rng)
	if not wall_decoration_variants.is_empty():
		style.wall_decoration = _pick(wall_decoration_variants, rng)
	return style

func _pick(choices: Array, rng: RandomNumberGenerator) -> Variant:
	return choices[rng.randi_range(0, choices.size() - 1)] if rng != null else choices.pick_random()
