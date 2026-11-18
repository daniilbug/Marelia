class_name Main
extends Node2D


const PLAYER_SCENE := preload("res://scenes/core/player.tscn")

@export var auto_spawn_players := true

@export var spawn_level: Level
signal load_failed(message: String)
@onready var world_time: WorldTime = $WorldTime
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var world_save: WorldSave = $WorldSave

var _levels: Dictionary = {}
var local_player: Player

func _ready() -> void:
	_register_levels()
	if spawn_level == null or not _levels.has(spawn_level.level_id):
		load_failed.emit("Укажите начальный Level мира.")
		return
	player_spawner.spawned.connect(_on_player_spawned)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if multiplayer.is_server() and auto_spawn_players:
		multiplayer.peer_connected.connect(_on_peer_connected)
		var saved := SaveManager.take_pending_snapshot()
		if not saved.is_empty():
			for factory in get_tree().get_nodes_in_group("level_factories"):
				if is_ancestor_of(factory):
					factory.prepare_levels_for_restore(saved.levels)
			if not world_save.can_restore(saved):
				load_failed.emit("Сохранение не соответствует текущему игровому миру.")
				return
		_spawn_player(multiplayer.get_unique_id(), saved.get("player", {}))
		_init_local_player(get_player(multiplayer.get_unique_id()))
		var setup := Player.local_setup if saved.is_empty() else {"name": saved.player.player_name}
		_register_player_setup(multiplayer.get_unique_id(), setup)
		if not saved.is_empty():
			world_save.restore_world(saved)
	elif not multiplayer.is_server():
		# Request factories only after this peer has instantiated the outside scene.
		_request_dynamic_levels.rpc_id(1)

func _register_levels() -> void:
	for child in get_children():
		if child is not Level:
			continue
		var level := child as Level
		register_level(level)

## Supports private levels created on first use, without changing the startup scene.
func register_level(level: Level) -> bool:
	if level.get_parent() != null and level.get_parent() != self:
		push_error("Register a direct child level or an unattached level")
		return false
	if level.level_id.is_empty() or (_levels.has(level.level_id) and _levels[level.level_id] != level):
		push_error("Levels need unique, nonempty IDs: %s" % level.name)
		return false
	_levels[level.level_id] = level
	if level.get_parent() == null:
		add_child(level)
	for player in get_players():
		player._refresh_platform()
	level.visible = level == spawn_level if local_player == null else level.level_id == local_player.level_id
	if local_player != null:
		get_player_level(int(local_player.name)).activate_local_player(local_player)
	return true

func get_level(level_id: String) -> Level:
	return _levels.get(level_id) as Level

func get_levels() -> Array[Level]:
	var levels: Array[Level] = []
	levels.assign(_levels.values())
	return levels

func get_player(peer_id: int) -> Player:
	return get_node_or_null(str(peer_id)) as Player

func get_players() -> Array[Player]:
	var players: Array[Player] = []
	for child in get_children():
		if child is Player and not child is NPC:
			players.append(child)
	return players

func _on_peer_connected(peer_id: int) -> void:
	_spawn_player(peer_id)

@rpc("any_peer", "reliable")
func _request_dynamic_levels() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	for factory in get_tree().get_nodes_in_group("level_factories"):
		if is_ancestor_of(factory):
			factory.sync_to_peer(peer_id)

func _spawn_player(peer_id: int, saved: Dictionary = {}) -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	player.name = str(peer_id)
	if saved.is_empty():
		player.level_id = spawn_level.level_id
		player.randomize_appearance()
		spawn_level._prepare_player_spawn(player)
	else:
		player.apply_save_data(saved)
	player.initialize_wardrobe()
	var level := get_level(player.level_id)
	var spawn_position := spawn_level.player_spawn.global_position if saved.is_empty() else level.to_global(saved.position)
	if not saved.is_empty() and not level.get_world_bounds().has_point(spawn_position):
		spawn_position = level.player_spawn.global_position
		player.platform_path = NodePath()
	player.position = to_local(spawn_position)
	add_child(player)
	_watch_player_level(player)

func _on_player_spawned(node: Node) -> void:
	if node is Player:
		_watch_player_level(node)
	# A late join can receive held items before their player has spawned.
	for level in get_levels():
		for item in level.get_children():
			if item is Draggable and item.holder_peer_id == int(str(node.name)):
				item._sync_hands(0)
	if node is Player and int(node.name) == multiplayer.get_unique_id() and local_player == null:
		var player := node as Player
		_init_local_player(player)
		if not multiplayer.is_server():
			_request_player_setup.rpc_id(1, Player.local_setup)

func _init_local_player(player: Player) -> void:
	if player == null or local_player != null:
		return
	local_player = player
	_activate_local_level(player.level_id)

func _watch_player_level(player: Player) -> void:
	player.level_changed.connect(_on_player_level_changed.bind(player))
	_refresh_player_visibility()

func _on_player_level_changed(player: Player) -> void:
	if player == local_player:
		_activate_local_level(player.level_id)
	_refresh_player_visibility()

func _refresh_player_visibility() -> void:
	if local_player == null:
		return
	for player in get_players():
		player.visible = player.level_id == local_player.level_id

## Called by an entrance after the server validates the source level and reach.
func transfer_player(player: Player, destination: Level, spawn: Marker2D, facing: Vector2, platform: WalkablePlatform = null) -> bool:
	if not multiplayer.is_server() or player == null or destination == null or spawn == null:
		return false
	if get_level(destination.level_id) != destination or Level.find_level_node(spawn) != destination:
		return false
	if not destination.get_world_bounds().has_point(spawn.global_position):
		return false
	if platform != null and Level.find_level_node(platform) != destination:
		return false
	var arrival := _find_transfer_position(player, destination, spawn, platform)
	if not arrival.is_finite():
		return false
	var platform_path := destination.get_path_to(platform) if platform != null else NodePath()
	_apply_level_transfer.rpc(int(str(player.name)), destination.level_id, to_local(arrival), facing, platform_path)
	return player.level_id == destination.level_id

func _find_transfer_position(player: Player, destination: Level, spawn: Marker2D, platform: WalkablePlatform = null) -> Vector2:
	var shape := player.get_node("Shape") as CollisionShape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	var previous_platform := player.get_platform()
	query.collision_mask = previous_platform.get_ground_collision_mask(player) if previous_platform != null else player.collision_mask
	var excluded: Array[RID] = [player.get_rid()]
	if platform != null:
		query.collision_mask = (query.collision_mask & ~1) | WalkablePlatform.COLLISION_LAYER
		for body in platform.ignored_bodies:
			if is_instance_valid(body):
				excluded.append(body.get_rid())
	query.exclude = excluded
	query.transform = shape.global_transform
	var shape_offset := shape.global_position - player.global_position
	var origin := destination.to_local(spawn.global_position)
	var offsets := [Vector2.ZERO, Vector2(-16, 0), Vector2(16, 0), Vector2(-32, 0), Vector2(32, 0), Vector2(0, -16), Vector2(0, 16)]
	if platform != null:
		offsets = [Vector2.ZERO, Vector2(-8, 0), Vector2(8, 0), Vector2(0, 8), Vector2(-8, 8), Vector2(8, 8)]
	for offset in offsets:
		var arrival := destination.to_global(origin + offset)
		if not destination.get_world_bounds().has_point(arrival):
			continue
		if platform != null and not platform.walkable_rect.grow(-6).has_point(platform.to_local(arrival)):
			continue
		query.transform.origin = arrival + shape_offset
		if get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			return arrival
	return Vector2.INF

@rpc("authority", "call_local", "reliable")
func _apply_level_transfer(peer_id: int, destination_id: String, spawn_position: Vector2, facing: Vector2, platform_path := NodePath()) -> void:
	var player := get_player(peer_id)
	if player == null or not _levels.has(destination_id):
		return
	player.platform_path = NodePath()
	player.position = spawn_position
	player.direction = player.velocity.normalized() if not player.velocity.is_zero_approx() else facing
	player.level_id = destination_id
	player.platform_path = platform_path
	if player == local_player:
		# Also reset after the RPC if level_id replication arrived before it.
		_activate_local_level(destination_id)
	_refresh_player_visibility()

func _register_player_setup(peer_id: int, setup: Dictionary) -> void:
	var desired: Variant = setup.get("name", "Player")
	if desired is not String:
		return
	var final_setup := {"name": desired.strip_edges().substr(0, 64)}
	if final_setup.name.is_empty():
		final_setup.name = "Player"
	var player := get_player(peer_id)
	if player != null:
		player.rpc_apply_player_setup.rpc(final_setup)

@rpc("any_peer", "reliable")
func _request_player_setup(setup: Dictionary) -> void:
	if multiplayer.is_server():
		_register_player_setup(multiplayer.get_remote_sender_id(), setup)

func get_player_level(peer_id: int) -> Level:
	var player := get_player(peer_id)
	return _levels.get(player.level_id) as Level if player != null else null

func _activate_local_level(level_id: String) -> void:
	if not _levels.has(level_id):
		return
	var current := _levels[level_id] as Level
	for level: Level in _levels.values():
		level.visible = level == current
		if level != current:
			level.deactivate_local_player()
	current.activate_local_player(local_player)
	_refresh_player_visibility()

func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		for level: Level in _levels.values():
			level._cleanup_player(peer_id)
		var player := get_player(peer_id)
		if player != null:
			player.queue_free()
