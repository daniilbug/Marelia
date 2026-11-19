@tool
class_name BeachLifebuoyStand
extends StreetProp

enum Style { POST, FRAME }

@export_group("Design")
@export var style: Style = Style.POST:
	set(value):
		style = value
		_refresh_appearance()

@export_group("Material colors")
@export_color_no_alpha var stand_color: Color:
	get:
		return body_color
	set(value):
		body_color = value
@export_color_no_alpha var lifebuoy_color: Color:
	get:
		return support_color
	set(value):
		support_color = value

func set_appearance(design: Style, stand: Color, lifebuoy: Color) -> void:
	style = design
	stand_color = stand
	lifebuoy_color = lifebuoy

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	if property.name in ["body_color", "support_color"]:
		property.usage = PROPERTY_USAGE_NONE

func _get_design_index() -> int:
	return style
