@tool
class_name LevelTransition
extends Interactable

## Interactive passages share validation, allocation and transfer.
@export var connection: LevelConnection
@export var enabled := true
@export var arrival_direction := Vector2.UP
## Platform occupied by this endpoint; empty for ground and indoor passages.
@export var platform: WalkablePlatform

var _pending_players: Dictionary = {}

func interact(player: Player) -> void:
	if multiplayer.is_server():
		_activate(player)
	else:
		_request.rpc_id(1)

@rpc("any_peer", "reliable")
func _request() -> void:
	if not multiplayer.is_server():
		return
	var level := Level.find_level_node(self)
	if level != null:
		_activate(level.get_player(multiplayer.get_remote_sender_id()))

func _can_use(player: Player) -> bool:
	var level := Level.find_level_node(self)
	return enabled and level != null and is_instance_valid(player) \
		and player.level_id == level.level_id and not player.is_sitting \
		and not player.is_world_input_blocked and $Area.overlaps_area(player.interaction_area) \
		and (platform == null or player.get_platform() == platform)

func _activate(player: Player) -> void:
	if not _can_use(player) or _pending_players.has(player.get_instance_id()) or not is_instance_valid(connection):
		return
	var destination := connection.prepare_destination(self)
	if destination == null:
		return
	var player_id := player.get_instance_id()
	_pending_players[player_id] = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	_pending_players.erase(player_id)
	if not is_instance_valid(player) or not is_instance_valid(destination) or not is_instance_valid(connection) \
		or not _can_use(player) or connection.get_destination(self) != destination:
		return
	_transfer(player, destination)

func _transfer(player: Player, target: LevelTransition) -> void:
	var destination := Level.find_level_node(target)
	if destination == null:
		return
	var arrival := target.get_node("Arrival") as Marker2D
	var world := destination.get_parent() as Main
	if world != null:
		world.transfer_player(player, destination, arrival, target.arrival_direction, target.platform)
		return
	if not destination.get_world_bounds().has_point(arrival.global_position):
		return
	var source := Level.find_level_node(self)
	source.deactivate_local_player()
	source.visible = false
	player.platform_path = NodePath()
	player.reparent(destination)
	player.global_position = arrival.global_position
	player.direction = player.velocity.normalized() if not player.velocity.is_zero_approx() else target.arrival_direction
	player.level_id = destination.level_id
	player.platform_path = destination.get_path_to(target.platform) if target.platform != null else NodePath()
	destination.visible = true
	destination.activate_local_player(player)
