@tool
extends "res://scripts/home-kit/directional_furniture.gd"

enum Style { LADDER_BACK, PADDED_SLATS, CARVED_BACK }

@export_group("Design")
@export var style: Style = Style.LADDER_BACK:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
