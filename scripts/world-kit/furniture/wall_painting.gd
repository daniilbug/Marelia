@tool
extends FurniturePiece

@export_group("Design")
@export var style: HouseFurnitureStyle.PaintingDesign = HouseFurnitureStyle.PaintingDesign.COUNTRYSIDE:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style

func set_appearance(profile: HouseFurnitureStyle) -> void:
	style = profile.painting_style
	wood_color = profile.wood_color
