@tool
extends FurniturePiece

enum Style { PANEL_DOORS, THREE_DRAWERS }

@export_group("Design")
@export var style: Style = Style.PANEL_DOORS:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
