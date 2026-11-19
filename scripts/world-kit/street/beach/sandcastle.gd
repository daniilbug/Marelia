@tool
class_name BeachSandcastle
extends StreetProp

enum Style { TURRETS, BUCKET_TOWER, GATE }

@export_group("Design")
@export var style: Style = Style.TURRETS:
	set(value):
		style = value
		_refresh_appearance()

func _get_design_index() -> int:
	return style

func set_appearance(design: Style) -> void:
	style = design

func apply_placement_style(profile: Resource) -> void:
	if profile is BeachSandcastleStyle:
		set_appearance(profile.style)
