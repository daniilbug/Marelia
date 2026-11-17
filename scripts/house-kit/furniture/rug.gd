@tool
extends FurniturePiece

@export_group("Design")
@export var style: HouseFurnitureStyle.RugDesign = HouseFurnitureStyle.RugDesign.GEOMETRIC:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style

func apply_group_style(group_style: HouseFurnitureStyle) -> void:
	style = group_style.rug_style
	fabric_color = group_style.fabric_color
	paint_color = group_style.pattern_color
