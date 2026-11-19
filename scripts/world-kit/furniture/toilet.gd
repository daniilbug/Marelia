@tool
extends "res://scripts/world-kit/furniture/directional_furniture.gd"

enum Style { CLASSIC, COMPACT }

@export_group("Design")
@export var style: Style = Style.CLASSIC:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
