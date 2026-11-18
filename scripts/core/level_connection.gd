@tool
class_name LevelConnection
extends Node

## An explicit, bidirectional link. Paths are relative to their Level roots.
## Factories can create the destination when level_requested is emitted.
signal level_requested(level_id: String)

@export var first_level_id := ""
@export var first_transition := NodePath()
@export var second_level_id := ""
@export var second_transition := NodePath()

var first: LevelTransition
var second: LevelTransition
var _world: Node

func _ready() -> void:
	_bind_authored_levels.call_deferred()

func _bind_authored_levels() -> void:
	if is_instance_valid(_world):
		return
	var ancestor := get_parent()
	while ancestor != null:
		for child in ancestor.get_children():
			if child is Level and child.level_id in [first_level_id, second_level_id]:
				bind_levels(ancestor)
				return
		ancestor = ancestor.get_parent()

func _get_configuration_warnings() -> PackedStringArray:
	if first_level_id.is_empty() or second_level_id.is_empty() or first_transition.is_empty() or second_transition.is_empty():
		return ["Assign both Level IDs and both transition paths relative to those Levels."]
	return []

func bind_levels(world: Node) -> void:
	_world = world
	first = _resolve(first_level_id, first_transition)
	second = _resolve(second_level_id, second_transition)
	for endpoint in [first, second]:
		if is_instance_valid(endpoint):
			endpoint.connection = self

func _resolve(id: String, path: NodePath) -> LevelTransition:
	if not is_instance_valid(_world) or path.is_empty():
		return null
	for child in _world.get_children():
		if child is Level and child.level_id == id:
			return child.get_node_or_null(path) as LevelTransition
	return null

func get_destination(source: LevelTransition) -> LevelTransition:
	if source == first:
		return second if is_instance_valid(second) else null
	if source == second:
		return first if is_instance_valid(first) else null
	return null

func prepare_destination(source: LevelTransition) -> LevelTransition:
	var id := second_level_id if source == first else first_level_id if source == second else ""
	if id.is_empty():
		return null
	if get_destination(source) == null:
		level_requested.emit(id)
		bind_levels(_world)
	return get_destination(source)
