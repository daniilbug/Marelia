@tool
class_name Door
extends Interactable

signal state_changed(is_open: bool)

## The concrete object assigns its passage colliders and observes state_changed
## to update its own appearance. The core only owns state and reach validation.
@export var blockers: Array[CollisionShape2D] = []
@export var is_open := false:
	set(value):
		if is_open == value:
			return
		is_open = value
		if is_node_ready():
			_apply_state()

func _enter_tree() -> void:
	set_multiplayer_authority(1, true)
	add_to_group("saveable")

func _ready() -> void:
	_apply_state()

func interact(player: Player) -> void:
	if multiplayer.is_server():
		_toggle_for(player)
	else:
		_request_toggle.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_toggle() -> void:
	if multiplayer.is_server():
		var level := Level.find_level_node(self)
		_toggle_for(level.get_player(multiplayer.get_remote_sender_id()))

func _toggle_for(player: Player) -> void:
	var level := Level.find_level_node(self)
	if player != null and player.level_id == level.level_id and $Area.overlaps_area(player.interaction_area):
		is_open = not is_open

func _apply_state() -> void:
	for blocker in blockers:
		if is_instance_valid(blocker):
			blocker.set_deferred("disabled", is_open)
	state_changed.emit(is_open)

func get_save_data() -> Dictionary:
	return {"is_open": is_open}

func apply_save_data(data: Dictionary) -> void:
	SaveGraph.apply_fields(self, ["is_open"], data)
