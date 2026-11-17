@tool
extends FurniturePiece

@export_group("Fire")
@export var burning := true:
	set(value):
		burning = value
		_elapsed = 0.0
		_refresh_appearance()
@export_range(0.0, 4.0, 0.1) var animation_speed := 1.0

var _elapsed := 0.0

func _get_design_index() -> int:
	return 1 if burning else 0

func _process(delta: float) -> void:
	if _view == null or _view.frames <= 1 or _view.fps <= 0.0:
		return
	_elapsed = fmod(_elapsed + delta * animation_speed, _view.frames / _view.fps)
	$Sprite.frame = int(floor(_elapsed * _view.fps + 0.00001)) % _view.frames
