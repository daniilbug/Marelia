@tool
extends FurniturePiece

enum Style { OLIVE, LEMON }

@export var style: Style = Style.OLIVE:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
