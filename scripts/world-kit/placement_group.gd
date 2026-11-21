@tool
class_name PlacementGroup
extends Node2D

@export var style_variants: DecorationVariants

@export var selected_variant: StringName = &"":
	set(value):
		if selected_variant == value:
			return
		selected_variant = value
		if is_node_ready():
			apply_selection()

@export_tool_button("Randomize placement") var randomize_action: Callable = randomize

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

func randomize() -> void:
	choose_variant()
	choose_style()

func choose_variant() -> void:
	var points := get_points()
	if not points.is_empty():
		selected_variant = points.pick_random().name

func get_selected_point() -> Marker2D:
	return get_node_or_null(NodePath(selected_variant)) as Marker2D if not selected_variant.is_empty() else null

func choose_style() -> void:
	if style_variants != null:
		apply_style(style_variants.choose_style())

func apply_style(profile: DecorationStyle) -> void:
	if profile == null:
		return
	for instance in get_instances():
		if instance is DecorationGroup:
			instance.apply_placement_style(profile)
		elif instance is StaticBody2D:
			profile.apply_to(instance)
