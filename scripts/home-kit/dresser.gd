@tool
extends FurniturePiece

enum Style { THREE_DRAWERS, SPLIT_TOP_DRAWERS, TWO_DEEP_DRAWERS }

@export_group("Design")
@export var style: Style = Style.THREE_DRAWERS:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
