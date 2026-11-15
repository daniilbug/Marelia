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
			if not world_save.can_restore(saved):
				load_failed.emit("Сохранение не соответствует текущему игровому миру.")
				return
		_spawn_player(multiplayer.get_unique_id(), saved.get("player", {}))
		_init_local_player(get_player(multiplayer.get_unique_id()))
		var setup := Player.local_setup if saved.is_empty() else {"name": saved.player.player_name}
		_register_player_setup(multiplayer.get_unique_id(), setup)
		if not saved.is_empty():
			world_save.restore_world(saved)

func _register_levels() -> void:
	for child in get_children():
		if child is not Level:
			continue
		var level := child as Level
		if level.level_id.is_empty() or _levels.has(level.level_id):
			push_error("Levels need unique, nonempty IDs: %s" % child.name)
			continue
		_levels[level.level_id] = level

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
	player.position = to_local(spawn_position)
	add_child(player)

func _on_player_spawned(node: Node) -> void:
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
		if level != current:
			level.deactivate_local_player()
	current.activate_local_player(local_player)

func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		for level: Level in _levels.values():
			level._cleanup_player(peer_id)
		var player := get_player(peer_id)
		if player != null:
			player.queue_free()
