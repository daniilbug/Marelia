@tool
extends FurniturePiece

@export_group("Design")
@export var style: HouseFurnitureStyle.RugDesign = HouseFurnitureStyle.RugDesign.GEOMETRIC:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style

func set_appearance(profile: HouseFurnitureStyle) -> void:
	style = profile.rug_style
	fabric_color = profile.fabric_color
	paint_color = profile.pattern_color
