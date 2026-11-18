@tool
class_name StreetBush
extends StreetProp

enum Style { OLEANDER, LAVENDER, ROSEMARY, HYDRANGEA }

@export_group("Design")
@export var style: Style = Style.OLEANDER:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
