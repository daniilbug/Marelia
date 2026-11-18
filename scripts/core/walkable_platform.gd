@tool
class_name WalkablePlatform
extends Node2D

## Raised outdoor platforms share their Level with the street. Only their
## occupants collide with the railings and ignore the building underneath.
const COLLISION_LAYER := 32
@export var ignored_bodies: Array[PhysicsBody2D] = []
@export var standing_z_index := 2
@export var walkable_rect := Rect2(-20, 0, 40, 32)
var _previous: Dictionary = {}

func attach_player(player: Player) -> void:
	_previous[player.get_instance_id()] = {"mask": player.collision_mask, "layer": player.collision_layer, "z": player.z_index}
	for body in ignored_bodies:
		if is_instance_valid(body):
			player.add_collision_exception_with(body)
	player.collision_mask = (player.collision_mask & ~1) | COLLISION_LAYER
	player.collision_layer = COLLISION_LAYER
	player.z_index = standing_z_index

func detach_player(player: Player) -> void:
	for body in ignored_bodies:
		if is_instance_valid(body):
			player.remove_collision_exception_with(body)
	var previous: Dictionary = _previous.get(player.get_instance_id(), {"mask": 9, "layer": 1, "z": 0})
	player.collision_mask = previous.mask
	player.collision_layer = previous.layer
	player.z_index = previous.z
	_previous.erase(player.get_instance_id())

func get_ground_collision_mask(player: Player) -> int:
	return _previous.get(player.get_instance_id(), {"mask": 9}).mask
