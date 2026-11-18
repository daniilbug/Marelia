@tool
class_name StreetPostBox
extends StreetProp

enum Style { RECTANGULAR, ARCHED }

@export_group("Design")
@export var style: Style = Style.RECTANGULAR:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
