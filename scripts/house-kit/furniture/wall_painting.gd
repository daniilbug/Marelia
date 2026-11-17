@tool
extends FurniturePiece

@export_group("Design")
@export var style: HouseFurnitureStyle.PaintingDesign = HouseFurnitureStyle.PaintingDesign.COUNTRYSIDE:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style

func apply_group_style(group_style: HouseFurnitureStyle) -> void:
	style = group_style.painting_style
	wood_color = group_style.wood_color
