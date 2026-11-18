@tool
class_name HouseFacade
extends StaticBody2D

static var _appearance_fields := HouseFacadeStyle.FIELDS + ["door_style", "door_color", "house_width", "house_depth", "wall_height"]

@export_group("Exterior")
@export var style_variants: HouseFacadeVariants
@export var door_variants: HouseDoorVariants
@export var facade_style: HouseFacadeStyle.Facade = HouseFacadeStyle.Facade.PLASTER:
	set(value):
		facade_style = value
		_schedule_refresh()
@export var roof_style: HouseFacadeStyle.Roof = HouseFacadeStyle.Roof.TILES:
	set(value):
		roof_style = value
		_schedule_refresh()
@export var door_style: HouseDoorStyle.Style = HouseDoorStyle.Style.PLANK:
	set(value):
		door_style = value
		_schedule_refresh()
@export var window_style: HouseFacadeStyle.WindowStyle = HouseFacadeStyle.WindowStyle.LOUVERED:
	set(value):
		window_style = value
		_schedule_refresh()
@export var shutters_closed := false:
	set(value):
		shutters_closed = value
		_schedule_refresh()
@export_range(144, 512, 8) var house_width := 176.0:
	set(value):
		house_width = maxf(144, value)
		_schedule_refresh()
@export_range(48, 256, 8) var house_depth := 80.0:
	set(value):
		house_depth = maxf(48, value)
		_schedule_refresh()
@export_range(40, 96, 8) var wall_height := 48.0:
	set(value):
		wall_height = maxf(40, value)
		_schedule_refresh()
@export_group("Colors")
@export_color_no_alpha var facade_color := Color("dec59a"):
	set(value):
		facade_color = value
		_schedule_refresh()
@export_color_no_alpha var roof_color := Color("b8764e"):
	set(value):
		roof_color = value
		_schedule_refresh()
@export_color_no_alpha var door_color := Color("ae7d46"):
	set(value):
		door_color = value
		_schedule_refresh()
@export_color_no_alpha var shutter_color := Color("647f60"):
	set(value):
		shutter_color = value
		_schedule_refresh()
@export_color_no_alpha var frame_color := Color("ae7d46"):
	set(value):
		frame_color = value
		_schedule_refresh()
@export_color_no_alpha var plinth_color := Color("b4aa8a"):
	set(value):
		plinth_color = value
		_schedule_refresh()
@export_group("Interior")
## Optional stable identifier; an empty value uses this facade's scene path.
@export var house_id := ""
@export var interior_scene: PackedScene
## Shared layout catalog; assign it in the facade scene like style variants.
@export var layouts: HouseLayoutCatalog
## Each entry is an independently authored above-ground floor, starting at zero.
@export var floors: Array[HouseInteriorSettings] = [HouseInteriorSettings.new()]:
	set(value):
		floors = value
		if floors.is_empty():
			floors.append(HouseInteriorSettings.new())
		for index in floors.size():
			if floors[index] == null:
				floors[index] = HouseInteriorSettings.new()
		_schedule_refresh()
@export var basement_enabled := false:
	set(value):
		basement_enabled = value
		notify_property_list_changed()
		_schedule_refresh()
@export var basement_settings: HouseInteriorSettings = HouseInteriorSettings.create_cellar():
	set(value):
		basement_settings = value if value != null else HouseInteriorSettings.create_cellar()
@export_tool_button("Randomize exterior") var randomize_exterior_action: Callable = randomize
@export_tool_button("Randomize interior") var randomize_interior_action: Callable = randomize_interior

const FLOOR_SCENE := preload("res://scenes/world-kit/house/facade_floor.tscn")
const BALCONY_SCENE := preload("res://scenes/world-kit/house/balcony.tscn")

var _pending := false
var _interiors: Dictionary = {}

func _validate_property(property: Dictionary) -> void:
	if property.name == "basement_settings" and not basement_enabled:
		property.usage &= ~PROPERTY_USAGE_EDITOR

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		set_multiplayer_authority(1, true)
		add_to_group("saveable")
		add_to_group("level_factories")

func _ready() -> void:
	_refresh()

func _all_indices() -> Array[int]:
	var indices: Array[int] = []
	if basement_enabled:
		indices.append(-1)
	for index in floors.size():
		indices.append(index)
	return indices

func get_floor_settings(index: int) -> HouseInteriorSettings:
	return basement_settings if index == -1 else floors[index]

func randomize() -> void:
	if is_inside_tree() and not Engine.is_editor_hint() and not multiplayer.is_server():
		return
	if style_variants != null:
		var selected := style_variants.choose_style()
		if selected != null:
			_apply_appearance(selected.to_data())
	if door_variants != null:
		var selected := door_variants.choose_style()
		if selected != null:
			_apply_door_style(selected)
	if is_inside_tree() and not Engine.is_editor_hint() and multiplayer.is_server():
		_apply_appearance.rpc(get_appearance())

func _apply_door_style(selected: HouseDoorStyle) -> void:
	door_style = selected.style
	door_color = selected.color

func randomize_interior() -> void:
	if is_inside_tree() and not Engine.is_editor_hint() and not multiplayer.is_server():
		return
	for index in _all_indices():
		if is_instance_valid(get_interior(index)):
			get_interior(index).randomize()
		else:
			get_floor_settings(index).randomize(layouts)
	_sync_interior_configuration.call_deferred()

func randomize_furniture() -> void:
	if is_inside_tree() and not Engine.is_editor_hint() and not multiplayer.is_server():
		return
	for interior: HouseInterior in _interiors.values():
		interior.randomize_furniture()
	_sync_interior_configuration.call_deferred()

func _get_appearance_fields() -> Array:
	return _appearance_fields

func get_appearance() -> Dictionary:
	return SaveGraph.get_fields(self, _get_appearance_fields())

@rpc("authority", "reliable")
func _apply_appearance(data: Dictionary) -> void:
	SaveGraph.apply_fields(self, _get_appearance_fields(), data)

func _configuration_data() -> Dictionary:
	var data := {"floors": [], "basement_enabled": basement_enabled, "basement": basement_settings.to_data()}
	for settings in floors:
		data.floors.append(settings.to_data())
	return data

func _placements_data() -> Dictionary:
	var data := {}
	for index: int in _interiors:
		data[index] = get_interior(index).selected_placements.duplicate(true)
	return data

func _sync_interior_configuration() -> void:
	if is_inside_tree() and not Engine.is_editor_hint() and multiplayer.is_server():
		_apply_interior_configuration.rpc(_configuration_data(), _placements_data())

@rpc("authority", "reliable")
func _apply_interior_configuration(data: Dictionary, placements: Dictionary) -> void:
	_apply_configuration(data)
	for index: int in _interiors:
		var interior := get_interior(index)
		interior.selected_placements = placements.get(index, {}).duplicate(true)
		interior.configuration = get_floor_settings(index)

func _apply_configuration(data: Dictionary) -> void:
	# Restore into existing Resources so editor-authored randomization sets survive.
	while floors.size() < data.floors.size():
		floors.append(HouseInteriorSettings.new())
	floors.resize(data.floors.size())
	for index in floors.size():
		floors[index].apply_data(data.floors[index])
	basement_enabled = data.basement_enabled
	basement_settings.apply_data(data.basement)
	_schedule_refresh()

func _schedule_refresh() -> void:
	if is_node_ready() and not _pending:
		_pending = true
		_refresh.call_deferred()

func _refresh() -> void:
	_pending = false
	if not is_node_ready():
		return
	for settings in floors:
		if not settings.changed.is_connected(_schedule_refresh):
			settings.changed.connect(_schedule_refresh)
	var sections := $Visuals/Floors
	while sections.get_child_count() > floors.size():
		var child := sections.get_child(sections.get_child_count() - 1)
		sections.remove_child(child)
		child.queue_free()
	while sections.get_child_count() < floors.size():
		var child := FLOOR_SCENE.instantiate()
		child.name = "Floor%d" % sections.get_child_count()
		sections.add_child(child)
		if Engine.is_editor_hint():
			child.owner = get_tree().edited_scene_root if get_tree().edited_scene_root != null else self
	for index in floors.size():
		(sections.get_child(index) as HouseFacadeFloor).apply_style(self, index)
	_refresh_balconies()
	var total_height := wall_height * floors.size()
	var roof := $Visuals/Roof as Sprite2D
	HouseArt.apply(roof, ["roof_tiles", "roof_coppi", "roof_coppi_aged"][roof_style], {"roof_color": roof_color}, true)
	roof.position = Vector2(-house_width / 2.0 - 6, -total_height - house_depth)
	roof.region_enabled = true
	roof.region_rect = Rect2(0, 0, house_width + 12, house_depth)
	var plinth := $Visuals/Plinth as Sprite2D
	var material := HouseArt.apply(plinth, "plinth_stone", {"stone_color": plinth_color}, true)
	plinth.position = Vector2(-house_width / 2.0, -8)
	plinth.region_enabled = true
	plinth.region_rect = Rect2(0, 0, house_width, 8)
	HouseArt.set_parameter(material, &"opening_a", Vector4(house_width / 2.0 - 12, 0, 24, 8 + $Entrance.position.y))
	$Entrance.style = door_style
	$Entrance.color = door_color
	$Entrance/Step.stone_color = plinth_color
	$Collision.shape.size = Vector2(house_width, house_depth)
	$Collision.position = Vector2(0, -house_depth / 2.0)
	$TransparencyArea.shape.size = Vector2(house_width + 12, total_height)
	$TransparencyArea.position = Vector2(0, -house_depth - total_height / 2.0)
	_build_connections()

func get_interior(index := 0) -> HouseInterior:
	return _interiors.get(index) as HouseInterior

func get_interior_id(index := 0) -> String:
	var source := Level.find_level_node(self)
	var key := house_id
	if key.is_empty():
		key = source.level_id + "_" + str(source.get_path_to(self)).replace("/", "_") if source != null else str(name)
	return "house_" + key + "_floor_" + ("basement" if index == -1 else str(index))

func _build_connections() -> void:
	for link in $Connections.get_children():
		$Connections.remove_child(link)
		link.queue_free()
	var source := Level.find_level_node(self)
	if source == null:
		return
	_add_connection("Entrance", source.level_id, source.get_path_to($Entrance), get_interior_id(), NodePath("Layout/Exit"))
	for index in floors.size() - 1:
		_add_connection("Floor%dTo%d" % [index, index + 1], get_interior_id(index), NodePath("Layout/Transitions/StairsUp"), get_interior_id(index + 1), NodePath("Layout/Transitions/StairsDown"))
	if basement_enabled:
		_add_connection("BasementToGround", get_interior_id(-1), NodePath("Layout/Transitions/StairsUp"), get_interior_id(), NodePath("Layout/Transitions/StairsDown"))
	for index in range(1, floors.size()):
		if floors[index].balcony and has_node("Balconies/Floor%d/Door" % index):
			var door := get_node("Balconies/Floor%d/Door" % index)
			_add_connection("Balcony%d" % index, source.level_id, source.get_path_to(door), get_interior_id(index), NodePath("Layout/Exit"))
	_bind_connections()

func _refresh_balconies() -> void:
	var platforms: Array[WalkablePlatform] = []
	for child in $Balconies.get_children():
		var index := int(str(child.name).trim_prefix("Floor"))
		if index >= floors.size() or not floors[index].balcony:
			$Balconies.remove_child(child)
			child.queue_free()
	for index in range(1, floors.size()):
		if not floors[index].balcony:
			continue
		var platform := $Balconies.get_node_or_null("Floor%d" % index) as HouseBalcony
		if platform == null:
			platform = BALCONY_SCENE.instantiate() as HouseBalcony
			platform.name = "Floor%d" % index
			$Balconies.add_child(platform)
			if Engine.is_editor_hint():
				platform.owner = get_tree().edited_scene_root if get_tree().edited_scene_root != null else self
		platform.position = Vector2(0, -wall_height * index)
		platform.ignored_bodies.assign([self])
		platform.configure(floors[index].door_style, floors[index].door_color, plinth_color)
		platforms.append(platform)
	$TransparencyArea.excluded_platforms = platforms
	if not Engine.is_editor_hint():
		var source := Level.find_level_node(self)
		if source != null:
			for player in source.get_players():
				if player.level_id == source.level_id:
					player._refresh_platform()

func _add_connection(link_name: String, first_id: String, first_path: NodePath, second_id: String, second_path: NodePath) -> void:
	var link := LevelConnection.new()
	link.name = link_name
	link.first_level_id = first_id
	link.first_transition = first_path
	link.second_level_id = second_id
	link.second_transition = second_path
	$Connections.add_child(link)
	link.owner = self if Engine.is_editor_hint() else null
	link.level_requested.connect(_ensure_level)

func _bind_connections() -> void:
	var source := Level.find_level_node(self)
	if source == null:
		return
	for link: LevelConnection in $Connections.get_children():
		link.bind_levels(source.get_parent())
	_refresh_interior_art()

func _refresh_interior_art() -> void:
	var entry := get_interior()
	if is_instance_valid(entry):
		entry.get_entry_portal().style = door_style
		entry.get_entry_portal().color = door_color

func _ensure_level(id: String) -> void:
	if not multiplayer.is_server():
		return
	for index in _all_indices():
		if get_interior_id(index) != id or is_instance_valid(get_interior(index)):
			continue
		_create_floor(index, _configuration_data(), {})
		var interior := get_interior(index)
		if interior != null:
			_create_floor.rpc(index, _configuration_data(), interior.selected_placements, interior.position)

@rpc("authority", "reliable")
func _create_floor(index: int, configuration: Dictionary, placements: Dictionary, location := Vector2.INF, door_states: Dictionary = {}) -> void:
	if is_instance_valid(get_interior(index)):
		return
	var source := Level.find_level_node(self)
	if source == null or interior_scene == null:
		return
	if not multiplayer.is_server():
		_apply_configuration(configuration)
	if index not in _all_indices():
		return
	var parent := source.get_parent()
	var world := parent as Main
	var instance := interior_scene.instantiate()
	var interior := instance as HouseInterior
	if interior == null:
		instance.free()
		push_error("Interior scene must inherit HouseInterior")
		return
	interior.configuration = get_floor_settings(index)
	interior.layouts = layouts
	interior.has_entrance = index == 0 or (index > 0 and interior.configuration.balcony)
	interior.has_upstairs = index < floors.size() - 1
	interior.has_downstairs = index > 0 or (index == 0 and basement_enabled)
	interior.scale = Vector2.ONE if world != null else source.scale
	interior.auto_spawn_standalone_player = false
	interior.world_time = source.world_time
	interior.selected_placements = placements.duplicate(true)
	interior.initial_door_states = door_states.duplicate()
	interior.level_id = get_interior_id(index)
	interior.name = interior.level_id
	interior.connections_changed.connect(_bind_connections, CONNECT_DEFERRED)
	var right := 0.0
	for existing in parent.get_children():
		if existing is Level:
			var edge: Vector2 = existing.get_world_bounds().end
			right = maxf(right, parent.to_local(edge).x if parent is Node2D else edge.x)
	interior.position = location if location.is_finite() else Vector2(right + 1024, 0)
	if world != null:
		if not world.register_level(interior):
			interior.free()
			return
	else:
		interior.visible = false
		parent.add_child(interior)
	_interiors[index] = interior
	_bind_connections()

func sync_to_peer(peer_id: int) -> void:
	_apply_appearance.rpc_id(peer_id, get_appearance())
	_apply_interior_configuration.rpc_id(peer_id, _configuration_data(), _placements_data())
	for index: int in _interiors:
		var interior := get_interior(index)
		_create_floor.rpc_id(peer_id, index, _configuration_data(), interior.selected_placements, interior.position, interior.get_door_states())

func get_save_data() -> Dictionary:
	return {"appearance": get_appearance(), "configuration": _configuration_data(), "created_floors": _interiors.keys(), "floor_placements": _placements_data()}

func can_restore_save_data(data: Dictionary) -> bool:
	if not data.has("appearance") or not SaveGraph.matches(data.appearance, get_appearance()):
		return false
	if data.has("configuration"):
		var settings: Variant = data.configuration
		if not SaveGraph.matches(settings, {"floors": [], "basement_enabled": false, "basement": {}}) \
			or settings.floors.is_empty() or not HouseInteriorSettings.is_valid_data(settings.basement) \
			or data.get("created_floors") is not Array or data.get("floor_placements") is not Dictionary:
			return false
		for floor_data in settings.floors:
			if not HouseInteriorSettings.is_valid_data(floor_data):
				return false
		var seen := {}
		for index in data.created_floors:
			if index is not int or index < (-1 if settings.basement_enabled else 0) or index >= settings.floors.size() or seen.has(index):
				return false
			if data.floor_placements.get(index, {}) is not Dictionary:
				return false
			seen[index] = true
		return true
	return HouseInteriorSettings.is_valid_data(data.get("interior")) and data.get("created") is bool and data.get("placements") is Dictionary

func apply_save_data(data: Dictionary) -> void:
	_apply_appearance(data.appearance)
	if data.has("configuration"):
		_apply_configuration(data.configuration)
	else:
		floors.resize(1)
		floors[0].kind = HouseInteriorSettings.Kind.WITH_KITCHEN
		floors[0].apply_data(data.interior)
		basement_enabled = false

func prepare_levels_for_restore(levels: Dictionary) -> void:
	var source := Level.find_level_node(self)
	var path := source.get_path_to(self)
	var state: Dictionary = levels.get(source.level_id, {}).get("objects", {}).get(path, {})
	if state.is_empty() or not can_restore_save_data(state):
		return
	apply_save_data(state)
	if state.has("created_floors"):
		for index: int in state.created_floors:
			_create_floor(index, _configuration_data(), state.floor_placements.get(index, {}))
	elif state.created:
		_create_floor(0, _configuration_data(), state.placements)
