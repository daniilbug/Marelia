@tool
extends "res://scripts/home-kit/directional_furniture.gd"

enum Style { WOOD_FRAME, UPHOLSTERED_ARMS, CARVED_BACK }

@export_group("Design")
@export var style: Style = Style.WOOD_FRAME:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
