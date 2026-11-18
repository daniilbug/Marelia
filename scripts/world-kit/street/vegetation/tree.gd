@tool
class_name StreetTree
extends StreetProp

enum Style { OLIVE, CYPRESS, LEMON, ORANGE }

@export_group("Design")
@export var style: Style = Style.OLIVE:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
