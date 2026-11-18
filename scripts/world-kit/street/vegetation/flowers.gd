@tool
class_name StreetFlowers
extends StreetProp

enum Style { DAISIES, POPPIES, SUNFLOWER }

@export_group("Design")
@export var style: Style = Style.DAISIES:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
