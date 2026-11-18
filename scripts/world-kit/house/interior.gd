@tool
class_name HouseInterior
extends Level

signal connections_changed

@export var layouts: HouseLayoutCatalog:
	set(value):
		if layouts != null and layouts.changed.is_connected(_schedule_rebuild):
			layouts.changed.disconnect(_schedule_rebuild)
		layouts = value
		if layouts != null:
			layouts.changed.connect(_schedule_rebuild)
		_schedule_rebuild()
@export var configuration: HouseInteriorSettings = HouseInteriorSettings.new():
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
var _layout_signature := ""
var _applied_placements: Dictionary = {}
var _layout: HouseLayout
var initial_door_states: Dictionary = {}

func _ready() -> void:
	_layout = $Layout
	if not configuration.changed.is_connected(_schedule_rebuild):
		configuration.changed.connect(_schedule_rebuild)
	rebuild()
	if not Engine.is_editor_hint():
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
		push_error("Assign the selected layout in the house scene's Layouts catalog or Configuration / Layout Scene")
		return
	var path := scene.resource_path
	var replaced := _layout.scene_file_path != path
	var states := initial_door_states if _layout_signature.is_empty() else get_door_states()
	if replaced:
		var instance := scene.instantiate()
		if instance is not HouseLayout:
			if instance != null:
				instance.free()
			push_error("House layout must inherit HouseLayout: %s" % path)
			return
		remove_child(_layout)
		_layout.queue_free()
		_layout = instance as HouseLayout
		_layout.name = "Layout"
		add_child(_layout)
		# Keep the chosen PackedScene when the editor saves this interior.
		_layout.owner = self
	_layout.apply_configuration(configuration)
	_layout.configure_access(has_entrance, has_upstairs, has_downstairs)
	_layout.select_placements(selected_placements)
	if replaced or _layout_signature.is_empty():
		_layout.apply_door_states(states)
	initial_door_states.clear()
	player_spawn = _layout.get_node("PlayerSpawn")
	_bounds_body = _layout.get_node("LevelBounds")
	_bottom_left_bound = _bounds_body.get_node("BottomLeft")
	_top_right_bound = _bounds_body.get_node("TopRight")
	if replaced:
		connections_changed.emit()
	var signature := "%s:%s" % [path, configuration.interior_size]
	if not Engine.is_editor_hint() and is_instance_valid(local_player):
		if signature != _layout_signature or selected_placements != _applied_placements:
			local_player.global_position = player_spawn.global_position
		activate_local_player(local_player)
	_layout_signature = signature
	_applied_placements = selected_placements.duplicate(true)

func _create_bounds_walls() -> void:
	# The selected layout already owns its complete set of bounds colliders.
	pass

func get_entry_portal() -> HousePortal:
	return _layout.get_node("Exit") as HousePortal

func get_door_states() -> Dictionary:
	return _layout.get_door_states()
