@tool
class_name HousePlacementPoint
extends Node2D

enum Facing { UP, DOWN, LEFT, RIGHT }
@export var facing: Facing = Facing.DOWN:
	set(value):
		facing = value
		queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		var direction: Vector2 = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT][facing]
		draw_circle(Vector2.ZERO, 2, Color("79b7a4"))
		draw_line(Vector2.ZERO, direction * 10, Color("79b7a4"), 1)
