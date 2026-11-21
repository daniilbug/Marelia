@tool
class_name BuildingDefinition
extends Resource

@export var layouts: BuildingLayoutCatalog
@export var default_floor: BuildingInteriorSettings
@export var entrance_variants: HouseDoorVariants:
	set(value):
		entrance_variants = value
		emit_changed()
@export var facade_styles: HouseFacadeVariants
## Stable keys identify decoration scenes in saves and network state.
@export var facade_details: Dictionary[StringName, PackedScene] = {}:
	set(value):
		facade_details = value
		emit_changed()
@export var facade_detail_colors: Array[Color] = []:
	set(value):
		facade_detail_colors = value
		emit_changed()
@export var exterior_objects: PackedScene:
	set(value):
		exterior_objects = value
		emit_changed()
## These variant sets use one building-wide style in every layout and exterior group.
@export var shared_furniture_variants: Array[HouseFurnitureVariants] = []:
	set(value):
		shared_furniture_variants = value
		emit_changed()
@export var facade_windows := true:
	set(value):
		facade_windows = value
		emit_changed()
@export_range(40.0, 96.0, 1.0) var minimum_wall_height := 40.0:
	set(value):
		minimum_wall_height = value
		emit_changed()
@export var requires_bathroom := false:
	set(value):
		requires_bathroom = value
		emit_changed()
## Keep this prefix stable once buildings using this definition have been saved.
@export var level_id_prefix := "building"
