@tool
class_name StreetBollard
extends StreetProp

enum Style { CLASSIC }

@export_group("Design")
@export var style: Style = Style.CLASSIC:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
