@tool
class_name StreetLitterBin
extends StreetProp

enum Style { OPEN, HOODED }

@export_group("Design")
@export var style: Style = Style.OPEN:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
