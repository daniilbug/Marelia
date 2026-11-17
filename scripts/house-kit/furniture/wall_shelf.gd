@tool
extends FurniturePiece

enum Style { EMPTY, WITH_DISHES }

@export_group("Design")
@export var style: Style = Style.EMPTY:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
