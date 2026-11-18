@tool
class_name StreetFireHydrant
extends StreetProp

enum Style { CLASSIC }

@export_group("Design")
@export var style: Style = Style.CLASSIC:
	set(value):
		style = value
		_refresh_appearance()

@export_group("Material colors")
@export_color_no_alpha var caps_color: Color:
	get:
		return support_color
	set(value):
		support_color = value

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	if property.name == "support_color":
		property.usage = PROPERTY_USAGE_NONE

func _get_design_index() -> int:
	return style
