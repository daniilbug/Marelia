class_name Level
extends Node2D

signal world_time_ready(clock: WorldTime)

const PLAYER_SCENE := preload("res://scenes/core/player.tscn")
const WORLD_TIME_SCENE := preload("res://scenes/core/world_time.tscn")
const BOUNDS_WALL_THICKNESS := 16.0

@export var level_id := ""
## A lazily loaded level receives the existing player from its entrance.
@export var auto_spawn_standalone_player := true

static func find_level_node(node: Node2D) -> Level:
	var current: Node = node
	while current.get_parent() != null:
		var parent := current.get_parent()
		if parent is not Level:
			current = parent
		else:
			return parent
	return null

@export var player_spawn: Node2D
## Allows a complete reusable layout scene to own the level's bounds.
@export var bounds_path := NodePath("LevelBounds")
## Camera placement in the player's local pixels, reset on each level change.
@export var camera_position_offset := Vector2.ZERO

@onready var _bounds_body: StaticBody2D = get_node_or_null(bounds_path)
@onready var _bottom_left_bound: Marker2D = _bounds_body.get_node("BottomLeft") if _bounds_body != null else null
@onready var _top_right_bound: Marker2D = _bounds_body.get_node("TopRight") if _bounds_body != null else null

var local_player: Player = null
var world_time: WorldTime
var _has_players := false

func _ready() -> void:
	if world_time == null:
		if get_parent() is Main:
			world_time = get_parent().get_node("WorldTime") as WorldTime
		else:
			world_time = WORLD_TIME_SCENE.instantiate() as WorldTime
			add_child(world_time)
	world_time_ready.emit(world_time)
	_create_bounds_walls()
	if get_parent() is not Main and multiplayer.is_server() and auto_spawn_standalone_player:
		_spawn_standalone_player()
	for child in get_children():
		if child is Room:
			child.init_room()

func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	var occupied := get_players().any(func(player: Player):
		return player.level_id == level_id and not player.is_queued_for_deletion())
	if _has_players and not occupied:
		cleanup()
	_has_players = occupied

## Server hook called once when the last player leaves, including disconnects.
func cleanup() -> void:
	pass

func _spawn_standalone_player() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	player.name = str(multiplayer.get_unique_id())
	player.level_id = level_id
	player.player_name = Player.local_setup.get("name", "Player")
	player.randomize_appearance()
	player.initialize_wardrobe()
	_prepare_player_spawn(player)
	add_child(player)
	var spawn_point := player_spawn if player_spawn != null else get_node_or_null("PlayerSpawn") as Node2D
	if spawn_point != null:
		player.global_position = spawn_point.global_position
	activate_local_player(player)

func _prepare_player_spawn(_player: Player) -> void:
	pass

func _cleanup_player(peer_id: int) -> void:
	for seat in find_children("*", "Seat", true, false):
		if seat.occupant_name == str(peer_id):
			seat.vacate()
	for child in get_children():
		if child is Draggable and (child as Draggable).holder_peer_id == peer_id:
			child.holder_peer_id = 0

func get_player(peer_id: int) -> Player:
	if peer_id < 0:
		return get_node_or_null(str(peer_id)) as Player
	var main := get_parent() as Main
	return main.get_player(peer_id) if main != null else get_node_or_null(str(peer_id)) as Player

func get_players() -> Array[Player]:
	var main := get_parent() as Main
	if main != null:
		return main.get_players()
	var players: Array[Player] = []
	for child in get_children():
		if child is Player and not child is NPC:
			players.append(child)
	return players

## Owns the local level context and camera limits; Main selects the active level.
func activate_local_player(player: Player) -> void:
	if local_player != null and local_player != player:
		deactivate_local_player()
	local_player = player
	var main := get_parent() as Main
	if main != null:
		for level in main.get_levels():
			if level == self:
				player.remove_collision_exception_with(level._bounds_body)
			else:
				player.add_collision_exception_with(level._bounds_body)
	var bounds := get_world_bounds()
	player.camera.position = camera_position_offset
	player.camera.limit_left = floori(bounds.position.x)
	player.camera.limit_top = floori(bounds.position.y)
	player.camera.limit_right = ceili(bounds.end.x)
	player.camera.limit_bottom = ceili(bounds.end.y)
	player.camera.reset_smoothing()

func deactivate_local_player() -> void:
	if local_player == null:
		return
	local_player = null

func get_world_bounds() -> Rect2:
	var a := _bottom_left_bound.global_position
	var b := _top_right_bound.global_position
	var top_left := Vector2(minf(a.x, b.x), minf(a.y, b.y))
	var bottom_right := Vector2(maxf(a.x, b.x), maxf(a.y, b.y))
	return Rect2(top_left, bottom_right - top_left)

func _create_bounds_walls() -> void:
	var a := _bottom_left_bound.position
	var b := _top_right_bound.position
	var left := minf(a.x, b.x)
	var right := maxf(a.x, b.x)
	var top := minf(a.y, b.y)
	var bottom := maxf(a.y, b.y)
	var thickness := BOUNDS_WALL_THICKNESS
	if right <= left or bottom <= top:
		push_error("Level bounds must have a positive width and height")
		return
	_create_bounds_wall("Top", Vector2((left + right) / 2.0, top - thickness / 2.0), Vector2(right - left + thickness * 2.0, thickness))
	_create_bounds_wall("Bottom", Vector2((left + right) / 2.0, bottom + thickness / 2.0), Vector2(right - left + thickness * 2.0, thickness))
	_create_bounds_wall("Left", Vector2(left - thickness / 2.0, (top + bottom) / 2.0), Vector2(thickness, bottom - top))
	_create_bounds_wall("Right", Vector2(right + thickness / 2.0, (top + bottom) / 2.0), Vector2(thickness, bottom - top))

func _create_bounds_wall(wall_name: String, wall_position: Vector2, size: Vector2) -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	var wall := _bounds_body.get_node_or_null(NodePath(wall_name)) as CollisionShape2D
	if wall == null:
		wall = CollisionShape2D.new()
		wall.name = wall_name
		_bounds_body.add_child(wall)
	wall.position = wall_position
	wall.shape = rectangle

## Each level selects an independent route before the server spawns its NPC.
func create_npc_route() -> NPCRoute:
	return null

func get_save_data() -> Dictionary:
	return SaveGraph.capture(self)

func prepare_save_restore(data: Dictionary) -> void:
	SaveGraph.prepare_restore(self, data)

func apply_save_data(data: Dictionary) -> void:
	SaveGraph.restore(self, data)

func can_restore_save_data(data: Dictionary) -> bool:
	return SaveGraph.can_restore(self, data)
