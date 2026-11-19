@tool
class_name PlacementGroup
extends Node2D

## Catalog resource that provides choose_style().
@export var style_variants: Resource

@export var selected_variant: StringName = &"":
	set(value):
		if selected_variant == value:
			return
		selected_variant = value
		if is_node_ready():
			apply_selection()

func _ready() -> void:
	apply_selection()

func apply_selection() -> void:
	for point in get_points():
		var active := point.name == selected_variant
		point.visible = active
		point.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func get_points() -> Array[Marker2D]:
	var points: Array[Marker2D] = []
	for child in get_children():
		if child is Marker2D:
			points.append(child)
	return points

func get_instances() -> Array[Node]:
	var instances: Array[Node] = []
	for point in get_points():
		instances.append_array(point.get_children())
	return instances

func choose_variant() -> void:
	var points := get_points()
	if not points.is_empty():
		selected_variant = points.pick_random().name

func get_selected_point() -> Marker2D:
	return get_node_or_null(NodePath(selected_variant)) as Marker2D if not selected_variant.is_empty() else null

func choose_style() -> void:
	if style_variants != null and style_variants.has_method(&"choose_style"):
		apply_style(style_variants.choose_style() as Resource)

func apply_style(profile: Resource) -> void:
	if profile == null:
		return
	for instance in get_instances():
		if instance.has_method(&"apply_placement_style"):
			instance.apply_placement_style(profile)
