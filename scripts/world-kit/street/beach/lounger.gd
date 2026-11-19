@tool
class_name BeachLounger
extends StreetProp

enum Style { STRIPED, PLAIN }

@export_group("Design")
@export var style: Style = Style.STRIPED:
	set(value):
		style = value
		_refresh_appearance()

func set_appearance(design: Style, fabric: Color, frame: Color) -> void:
	style = design
	body_color = fabric
	support_color = frame

func _get_design_index() -> int:
	return style
