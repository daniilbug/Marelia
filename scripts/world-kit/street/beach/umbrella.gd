@tool
class_name BeachUmbrella
extends StreetProp

enum Style { STRIPED, SOLID }

@export_group("Design")
@export var style: Style = Style.STRIPED:
	set(value):
		style = value
		_update_palette()

@export_group("Material colors")
@export_color_no_alpha var primary_color: Color:
	get:
		return body_color
	set(value):
		body_color = value
@export_color_no_alpha var secondary_color: Color:
	get:
		return support_color
	set(value):
		support_color = value

func set_appearance(design: Style, primary: Color, secondary: Color) -> void:
	style = design
	primary_color = primary
	secondary_color = secondary

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	if property.name in ["body_color", "support_color"]:
		property.usage = PROPERTY_USAGE_NONE

func _update_palette() -> void:
	super._update_palette()
	if _palette != null and style == Style.SOLID:
		_palette.set_shader_parameter("support_color", primary_color)
