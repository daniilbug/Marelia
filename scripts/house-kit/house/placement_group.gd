@tool
class_name HousePlacementGroup
extends Node2D

@export var style_variants: HouseFurnitureVariants
@export var selected_variant: StringName = &"LeftWall":
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

func get_points() -> Array[HousePlacementPoint]:
	var points: Array[HousePlacementPoint] = []
	for child in get_children():
		if child is HousePlacementPoint:
			points.append(child)
	return points

func choose_variant() -> void:
	var points := get_points()
	if not points.is_empty():
		selected_variant = points.pick_random().name

func get_selected_point() -> HousePlacementPoint:
	return get_node_or_null(NodePath(selected_variant)) as HousePlacementPoint if not selected_variant.is_empty() else null

func choose_style() -> void:
	if style_variants != null:
		var style := style_variants.choose_style()
		if style != null:
			_apply_style(style)

func apply_style_data(data: Dictionary) -> void:
	if data.is_empty() or data == get_style_data():
		return
	var style := HouseFurnitureStyle.new()
	style.apply_data(data)
	_apply_style(style)

func get_style_data() -> Dictionary:
	var point := get_selected_point()
	if point != null:
		for child in point.get_children():
			if child is HouseFurnitureGroup and child.style != null:
				return child.style.to_data()
	return {}

func _apply_style(style: HouseFurnitureStyle) -> void:
	for point in get_points():
		for child in point.get_children():
			if child is HouseFurnitureGroup:
				child.style = style
