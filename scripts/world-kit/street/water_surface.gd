@tool
class_name WaterSurface
extends Area2D

const SWIM_COLLISION_LAYER := 1 << 6

@export var size := Vector2(128, 96):
	set(value):
		size = value.round().max(Vector2.ONE)
		if is_node_ready():
			_update_size()

@export_group("Movement")
@export_range(0, 200, 1, "or_greater", "suffix:%") var speed_percent := 100

@export_group("Audio")
## Played by characters swimming through this water.
@export var swim_stroke_sound: AudioStream

@onready var _surface: ColorRect = $Surface
@onready var _collision: CollisionShape2D = $Collision

func _ready() -> void:
	_update_size()

func get_speed_multiplier() -> float:
	return maxi(speed_percent, 0) / 100.0

func _update_size() -> void:
	_surface.size = size
	_collision.position = size / 2.0
	(_collision.shape as RectangleShape2D).size = size
