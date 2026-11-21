@tool
@abstract
class_name DecorationStyle
extends Resource

func _init() -> void:
	resource_local_to_scene = true

@abstract func apply_to(piece: StaticBody2D) -> void
