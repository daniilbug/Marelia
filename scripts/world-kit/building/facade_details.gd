@tool
class_name BuildingFacadeDetails
extends Node2D

@export var tint_targets: Array[StreetProp] = []
@export var window_targets: Array[Sprite2D] = []

var _authored_colors: Dictionary[StreetProp, Color] = {}

func apply_appearance(profile: HouseFacadeStyle, color: Color) -> void:
	for window in window_targets:
		if is_instance_valid(window):
			HouseArt.apply_window(window, profile)
			window.centered = true
	for prop in tint_targets:
		if not is_instance_valid(prop):
			continue
		if not _authored_colors.has(prop):
			_authored_colors[prop] = prop.body_color
		prop.body_color = color if color.a > 0.0 else _authored_colors[prop]
