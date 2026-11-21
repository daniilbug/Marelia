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

func randomize() -> void:
	super.randomize()
	if designs.is_empty():
		return
	var design := designs[clampi(_get_design_index(), 0, designs.size() - 1)]
	if design == null:
		return
	var choices: Array[Direction] = []
	for index in mini(design.views.size(), Direction.size()):
		var view := design.views[index]
		if view != null and view.albedo != null:
			choices.append(index as Direction)
	if not choices.is_empty():
		direction = choices.pick_random()
