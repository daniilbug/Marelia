@tool
class_name HousePortal
extends Interactable

signal opening_requested(player: Player)

@export var style: HouseDoorStyle.Style = HouseDoorStyle.Style.PLANK:
	set(value):
		if style == value:
			return
		style = value
		_refresh_art()
		if is_instance_valid(target_door):
			target_door.style = value
@export_color_no_alpha var color := Color("ae7d46"):
	set(value):
		if color == value:
			return
		color = value
		_refresh_art()
		if is_instance_valid(target_door):
			target_door.color = value

## Bound automatically after the house creates its private interior.
var target_door: HousePortal
var arrival_direction := Vector2.UP
var _busy := false

func _ready() -> void:
	_refresh_art()

func _refresh_art() -> void:
	if is_node_ready():
		HouseArt.apply($Sprite, HouseArt.DOORS[style] + "_closed", {"wood_color": color, "paint_color": color})

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
	return level != null and is_instance_valid(player) and player.level_id == level.level_id and not player.is_sitting and not player.is_world_input_blocked and $Area.overlaps_area(player.interaction_area)

func _activate(player: Player) -> void:
	if _busy or not _can_use(player):
		return
	_busy = true
	if not is_instance_valid(target_door):
		opening_requested.emit(player)
		if not is_instance_valid(target_door):
			_busy = false
			return
	transfer(player)

func transfer(player: Player) -> void:
	# Newly created walls and blockers must enter the physics space first.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_busy = false
	if not is_instance_valid(target_door) or not _can_use(player):
		return
	var destination := Level.find_level_node(target_door)
	var world := destination.get_parent() as Main if destination else null
	if world != null:
		world.transfer_player(player, destination, target_door.get_node("Arrival"), target_door.arrival_direction)
	elif destination != null:
		var source := Level.find_level_node(self)
		var arrival: Vector2 = target_door.get_node("Arrival").global_position
		if not destination.get_world_bounds().has_point(arrival):
			return
		source.deactivate_local_player()
		source.visible = false
		player.reparent(destination)
		player.global_position = arrival
		player.velocity = Vector2.ZERO
		player.direction = target_door.arrival_direction
		player.level_id = destination.level_id
		destination.visible = true
		destination.activate_local_player(player)

func pair_with(other: HousePortal) -> void:
	target_door = other
	other.target_door = self
	other.style = style
	other.color = color
