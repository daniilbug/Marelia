@tool
class_name HouseDoorVariants
extends Resource

@export var variants: Array[HouseDoorStyle] = []

func choose_style(seed_value: int, family := -1, single_only := false) -> HouseDoorStyle:
	var choices := variants.filter(func(style: HouseDoorStyle) -> bool:
		return style != null and (family == -1 or style.style == family) \
			and (not single_only or style.get_design().single_leaf)
	)
	return choices[posmod(seed_value, choices.size())] if not choices.is_empty() else null

static func choose_design(catalogues: Array[HouseDoorVariants], seed_value: int, family: HouseDoorStyle.Style, single_only := false) -> HouseDoorDesign:
	for catalogue in catalogues:
		if catalogue != null:
			var choice := catalogue.choose_style(seed_value, family, single_only)
			if choice != null:
				return choice.get_design()
	return null
