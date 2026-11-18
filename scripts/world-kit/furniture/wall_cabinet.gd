@tool
extends FurniturePiece

enum Style { PANEL_DOORS, GLAZED_EMPTY, GLAZED_WITH_DISHES }

@export_group("Design")
@export var style: Style = Style.PANEL_DOORS:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
