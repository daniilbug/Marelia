@tool
class_name BuildingInterior
extends Level

signal layout_changed

@export var layouts: BuildingLayoutCatalog:
	set(value):
		if layouts != null and layouts.changed.is_connected(_schedule_rebuild):
			layouts.changed.disconnect(_schedule_rebuild)
		layouts = value
		if layouts != null:
			layouts.changed.connect(_schedule_rebuild)
		_schedule_rebuild()
@export var configuration: BuildingInteriorSettings = BuildingInteriorSettings.new():
	set(value):
		if configuration != value:
			if configuration != null and configuration.changed.is_connected(_schedule_rebuild):
				configuration.changed.disconnect(_schedule_rebuild)
			configuration = value
			if configuration != null:
				configuration.changed.connect(_schedule_rebuild)
		_schedule_rebuild()
@export_tool_button("Randomize interior") var randomize_action: Callable = randomize
@export_tool_button("Randomize furniture") var randomize_furniture_action: Callable = randomize_furniture
@export_storage var selected_placements: Dictionary = {}
@export var has_entrance := true:
	set(value):
		has_entrance = value
		_schedule_rebuild()
@export var has_upstairs := false:
	set(value):
		has_upstairs = value
		_schedule_rebuild()
@export var has_downstairs := false:
	set(value):
		has_downstairs = value
		_schedule_rebuild()

var _pending := false
var _has_built_layout := false
var _applied_placements: Dictionary = {}
var _layout: BuildingLayout
var _layout_synchronizers: Array[MultiplayerSynchronizer] = []
var initial_door_states: Dictionary = {}
var shared_furniture_styles: Dictionary[DecorationVariants, DecorationStyle] = {}:
	set(value):
		if shared_furniture_styles == value:
			return
		shared_furniture_styles = value
		_schedule_rebuild()

func _ready() -> void:
	_layout = get_node_or_null("Layout") as BuildingLayout
	if configuration != null and not configuration.changed.is_connected(_schedule_rebuild):
		configuration.changed.connect(_schedule_rebuild)
	rebuild()
	if not Engine.is_editor_hint() and _layout != null:
		super._ready()

func randomize() -> void:
	if is_inside_tree() and not Engine.is_editor_hint() and not multiplayer.is_server():
		return
	configuration.randomize(layouts)
	randomize_furniture()

func randomize_furniture() -> void:
	if is_inside_tree() and not Engine.is_editor_hint() and not multiplayer.is_server():
		return
	selected_placements.clear()
	_schedule_rebuild()

func _schedule_rebuild() -> void:
	if is_node_ready() and not _pending:
		_pending = true
		rebuild.call_deferred()

## Select a complete authored scene and apply settings to its existing nodes.
func rebuild() -> void:
	_pending = false
	if not is_node_ready() or configuration == null:
		return
	var scene := configuration.get_template_scene(layouts)
	if scene == null:
		if layouts != null or not Engine.is_editor_hint():
			push_error("Assign the selected layout in the building's catalog or Configuration / Layout Scene")
		return
	var path := scene.resource_path
	var replaced := _layout == null or _layout.scene_file_path != path
	var first_build := not _has_built_layout
	var states := initial_door_states if first_build else get_door_states()
	if replaced:
		var instance := scene.instantiate()
		if instance is not BuildingLayout:
			if instance != null:
				instance.free()
			push_error("Layout must use BuildingLayout: %s" % path)
			return
		if _layout != null:
			remove_child(_layout)
			_layout.queue_free()
		_layout = instance as BuildingLayout
		_layout.name = "Layout"
		_prepare_layout_synchronizers()
		add_child(_layout)
		# Keep the chosen PackedScene when the editor saves this interior.
		_layout.owner = self
	_layout.apply_configuration(configuration)
	_layout.configure_access(has_entrance, has_upstairs, has_downstairs)
	_layout.select_placements(selected_placements, shared_furniture_styles)
	if replaced or first_build:
		_layout.apply_door_states(states)
	initial_door_states.clear()
	player_spawn = _layout.get_node("PlayerSpawn")
	_bounds_body = _layout.get_node("LevelBounds")
	_bottom_left_bound = _bounds_body.get_node("BottomLeft")
	_top_right_bound = _bounds_body.get_node("TopRight")
	if replaced:
		layout_changed.emit()
	if not Engine.is_editor_hint() and is_instance_valid(local_player):
		if replaced or first_build or selected_placements != _applied_placements:
			local_player.global_position = player_spawn.global_position
		activate_local_player(local_player)
	_has_built_layout = true
	_applied_placements = selected_placements.duplicate(true)

func _create_bounds_walls() -> void:
	# The selected layout already owns its complete set of bounds colliders.
	pass

func get_doors() -> Array[HouseRoomDoor]:
	if _layout == null:
		return []
	return _layout.get_doors()

func get_door_states() -> Dictionary:
	return _layout.get_door_states() if _layout != null else {}

## A lazy layout's synchronizers can send state after the client has its nodes.
func _prepare_layout_synchronizers() -> void:
	_layout_synchronizers.clear()
	if Engine.is_editor_hint() or get_parent() is not Main:
		return
	for synchronizer: MultiplayerSynchronizer in _layout.find_children("*", "MultiplayerSynchronizer", true, false):
		if synchronizer.public_visibility:
			_layout_synchronizers.append(synchronizer)
			if multiplayer.is_server():
				synchronizer.public_visibility = false

func get_layout_path() -> String:
	return _layout.scene_file_path if _layout != null else ""

func has_layout_synchronizers() -> bool:
	return not _layout_synchronizers.is_empty()

func show_layout_to_peer(peer_id: int) -> void:
	for synchronizer in _layout_synchronizers:
		synchronizer.set_visibility_for(peer_id, true)
