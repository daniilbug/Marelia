@tool
extends FurniturePiece

enum Style { CHALKBOARD, PAPER, ENAMEL }

@export_group("Design")
@export var style: Style = Style.CHALKBOARD:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style
