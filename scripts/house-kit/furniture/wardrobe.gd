@tool
extends FurniturePiece

enum Style { RUSTIC, SHAPED_CORNICE, BOTTOM_DRAWER }

@export_group("Design")
@export var style: Style = Style.RUSTIC:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
