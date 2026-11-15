class_name NPCRoute
extends RefCounted

var npc: NPC
var spawn_position: Vector2

func _init(start_position: Vector2) -> void:
	spawn_position = start_position

func start(actor: NPC) -> void:
	npc = actor

## Routes own destinations, transitions and lifecycle decisions.
func update(_delta: float) -> bool:
	return true

func is_navigating() -> bool:
	return false

func move_direct(_delta: float) -> bool:
	return false

func cleanup() -> void:
	pass
