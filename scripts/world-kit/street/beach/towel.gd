@tool
class_name BeachTowel
extends StreetProp

enum Style { STRIPED, BORDERED }

@export_group("Design")
@export var style: Style = Style.STRIPED:
	set(value):
		style = value
		_refresh_appearance()

@export_group("Material colors")
@export_color_no_alpha var fabric_color: Color:
	get:
		return body_color
	set(value):
		body_color = value
@export_color_no_alpha var trim_color: Color:
	get:
		return support_color
	set(value):
		support_color = value

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	if property.name in ["body_color", "support_color"]:
		property.usage = PROPERTY_USAGE_NONE

func _get_design_index() -> int:
	return style

func apply_placement_style(profile: Resource) -> void:
	if profile is BeachTowelStyle:
		style = profile.style
		fabric_color = profile.fabric_color
		trim_color = profile.trim_color
