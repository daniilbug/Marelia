@tool
class_name StreetUtilityCover
extends StreetProp

enum Style { RECTANGULAR_DRAIN }

@export_group("Design")
@export var style: Style = Style.RECTANGULAR_DRAIN:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
