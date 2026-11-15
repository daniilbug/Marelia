class_name Draggable
extends Node2D

@onready var sprite: Sprite2D = $Sprite
@onready var _level: Level = Level.find_level_node(self)

@export var holder_peer_id := 0:
	set(value):
		var previous := holder_peer_id
		holder_peer_id = value
		if is_node_ready():
			_sync_hands(previous)

## Relative to the spawning Level; empty while held or initially on the floor.
@export var dock_path: NodePath

func _enter_tree() -> void:
	add_to_group("saveable")
	set_multiplayer_authority(1, true)

func _ready() -> void:
	_sync_hands(0)

func _sync_hands(previous: int) -> void:
	var old_holder := _level.get_player(previous)
	if old_holder != null and old_holder._hands_item == self:
		old_holder._hands_item = null
	var holder := _level.get_player(holder_peer_id)
	if holder != null:
		holder.take_spawned_item(self)

func _process(_delta: float) -> void:
	if not multiplayer.is_server() or holder_peer_id == 0:
		return
	var holder := _level.get_player(holder_peer_id)
	if holder == null:
		holder_peer_id = 0
		return
	var hands_pos := holder.hands.global_position
	if holder.direction.y < 0:
		global_position = hands_pos
		sprite.position = Vector2.ZERO
	else:
		global_position = Vector2(hands_pos.x, holder.global_position.y + 5.0)
		sprite.position = to_local(hands_pos)

func can_pickup(player: Player) -> bool:
	return is_instance_valid(player) and holder_peer_id == 0 and player.level_id == _level.level_id

func pickup(player: Player) -> void:
	if multiplayer.is_server():
		_local_pickup(int(player.name))
	else:
		_remote_pickup.rpc_id(1)

func drop(player: Player, place: DropPlace) -> void:
	if multiplayer.is_server():
		_local_drop(int(player.name), _level.get_path_to(place))
	else:
		_remote_drop.rpc_id(1, _level.get_path_to(place))

@rpc("any_peer", "reliable")
func _remote_pickup() -> void:
	if multiplayer.is_server():
		_local_pickup(multiplayer.get_remote_sender_id())

@rpc("any_peer", "reliable")
func _remote_drop(place_path: NodePath) -> void:
	if multiplayer.is_server():
		_local_drop(multiplayer.get_remote_sender_id(), place_path)

func _local_pickup(player_id: int) -> bool:
	var player := _level.get_player(player_id)
	if not can_pickup(player) or player.is_sitting or not $Area.overlaps_area(player.interaction_area):
		return false
	for item in _level.get_children():
		if item is Draggable and item != self and item.holder_peer_id == player_id:
			return false
	dock_path = NodePath()
	sprite.position = Vector2.ZERO
	holder_peer_id = player_id
	return true

func _local_drop(player_id: int, place_path: NodePath) -> bool:
	if not SaveGraph.safe_path(place_path) or holder_peer_id != player_id:
		return false
	var player := _level.get_player(player_id)
	var place := _level.get_node_or_null(place_path) as DropPlace
	if player == null or place == null or not place.can_accept(self) or not place.get_node("Area").overlaps_area(player.interaction_area):
		return false
	var visual_pos := place.shape.global_position
	var anchor := place.get_parent() as Node2D
	global_position = Vector2(visual_pos.x, maxf(visual_pos.y, anchor.global_position.y + 5.0))
	sprite.position = to_local(visual_pos)
	dock_path = place_path
	holder_peer_id = 0
	return true

func get_save_schema() -> Dictionary:
	return {"dock_path": NodePath()}

func get_save_data() -> Dictionary:
	if holder_peer_id < 0:
		return {}
	var data := {
		"scene": scene_file_path, "name": str(name), "path": _level.get_path_to(self),
		"position": position, "sprite_position": sprite.position, "holder_peer_id": holder_peer_id,
		"fields": SaveGraph.get_fields(self, get_save_schema().keys()),
	}
	# Guests are session-scoped, as in Drunkards. Their items remain in the world.
	if holder_peer_id > 1:
		data.holder_peer_id = 0
		data.position = _level.player_spawn.position
		data.sprite_position = Vector2.ZERO
	return data

func apply_save_data(data: Dictionary) -> void:
	position = data.position
	sprite.position = data.sprite_position
	SaveGraph.apply_fields(self, get_save_schema().keys(), data.fields)
	holder_peer_id = data.holder_peer_id

func can_restore_save_data(fields: Dictionary, saved_level: Node2D) -> bool:
	return SaveGraph.matches(fields, get_save_schema()) and (fields.dock_path.is_empty() or
		(SaveGraph.safe_path(fields.dock_path) and saved_level.get_node_or_null(fields.dock_path) is DropPlace))
