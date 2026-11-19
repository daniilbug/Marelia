@tool
class_name HouseDoorStyle
extends Resource

enum Style { PLANK, PANEL, GLAZED }

const DOUBLE_DESIGNS: Array[HouseDoorDesign] = [
	preload("res://assets/world-kit/house/door-designs/double_plank.tres"),
	preload("res://assets/world-kit/house/door-designs/double_panel.tres"),
	preload("res://assets/world-kit/house/door-designs/double_glazed.tres"),
]
const SINGLE_DESIGNS: Array[HouseDoorDesign] = [
	preload("res://assets/world-kit/house/door-designs/single_plank.tres"),
	preload("res://assets/world-kit/house/door-designs/single_panel.tres"),
	preload("res://assets/world-kit/house/door-designs/single_glazed.tres"),
]

## The family also selects the damaged door art on houses awaiting restoration.
@export var style: Style = Style.PLANK
@export_color_no_alpha var color := Color("ae7d46")
@export var design: HouseDoorDesign

func get_design() -> HouseDoorDesign:
	return design if design != null and design.is_complete() else DOUBLE_DESIGNS[style]

func apply_art(sprite: Sprite2D, opened := false) -> void:
	var art := get_design()
	var colors := {"wood_color": color, "paint_color": color}
	if opened:
		HouseArt.apply_textures(sprite, art.open_sprite, art.open_materials, colors)
	else:
		HouseArt.apply_textures(sprite, art.closed_sprite, art.closed_materials, colors)

static func create(family: Style, tint: Color, art: HouseDoorDesign = null) -> HouseDoorStyle:
	var profile := HouseDoorStyle.new()
	profile.style = family
	profile.color = tint
	profile.design = art
	return profile
