@tool
class_name HousePlacementGroup
extends Node2D

@export_storage var selected_variant: StringName

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
