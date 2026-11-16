@tool
extends FurniturePiece

enum Direction { DOWN, UP, LEFT, RIGHT }

@export_group("Facing")
@export var direction: Direction = Direction.DOWN:
	set(value):
		direction = value
		_refresh_appearance()

func _get_direction_index() -> int:
	return direction
