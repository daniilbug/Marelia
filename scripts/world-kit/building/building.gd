@tool
class_name Building
extends StaticBody2D

static var _appearance_fields := HouseFacadeStyle.FIELDS + ["door_style", "door_color", "house_width", "house_depth", "wall_height", "door_seed", "facade_detail_id", "facade_detail_color"]

@export var definition: BuildingDefinition:
	set(value):
		if definition == value:
			return
		if definition != null:
			definition.changed.disconnect(_on_definition_changed)
		definition = value
		if definition != null:
			definition.changed.connect(_on_definition_changed)
		_reset_default_floor()
		_on_definition_changed()

@export_group("Exterior")
@export var style_variants: HouseFacadeVariants
@export var facade_detail_id := "":
	set(value):
		facade_detail_id = value
		_schedule_refresh()
## Transparent uses the decoration's authored color.
@export var facade_detail_color := Color.TRANSPARENT:
	set(value):
		facade_detail_color = value
		_schedule_refresh()
@export var facade_style: HouseFacadeStyle.Facade = HouseFacadeStyle.Facade.PLASTER:
	set(value):
		facade_style = value
		_schedule_refresh()
@export var roof_style: HouseFacadeStyle.Roof = HouseFacadeStyle.Roof.TILES:
	set(value):
		roof_style = value
		_schedule_refresh()
## The common door style for the facade and every interior floor.
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
## The common door color for the facade and every interior floor.
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
@export var building_id := ""
@export_storage var house_id := "":
	set(value):
		house_id = value
		if building_id.is_empty():
			building_id = value
## Optional per-building overrides. An empty array uses the definition's default floor.
@export var floors: Array[BuildingInteriorSettings] = []:
	set(value):
		floors = value
		for index in floors.size():
			if floors[index] == null:
				floors[index] = _new_default_floor()
		_schedule_refresh()
@export var basement_enabled := false:
	set(value):
		basement_enabled = value
		notify_property_list_changed()
		_schedule_refresh()
@export var basement_settings: BuildingInteriorSettings = BuildingInteriorSettings.create_cellar():
	set(value):
		basement_settings = value if value != null else BuildingInteriorSettings.create_cellar()
@export_tool_button("Randomize exterior") var randomize_exterior_action: Callable = randomize
@export_tool_button("Randomize interior") var randomize_interior_action: Callable = randomize_interior
@export_storage var door_seed := -1:
	set(value):
		door_seed = value
		_schedule_refresh()

const INTERIOR_SCENE := preload("res://scenes/world-kit/building/interior.tscn")
const FLOOR_SCENE := preload("res://scenes/world-kit/house/facade_floor.tscn")
const BALCONY_SCENE := preload("res://scenes/world-kit/house/balcony.tscn")

var _pending := false
var _interiors: Dictionary = {}
var _default_floors: Array[BuildingInteriorSettings] = [BuildingInteriorSettings.new()]
var _facade_details: Node2D
var _exterior_objects: Node2D

var layouts: BuildingLayoutCatalog:
	get:
		return definition.layouts if definition != null else null

func _new_default_floor() -> BuildingInteriorSettings:
	if definition != null and definition.default_floor != null:
		return definition.default_floor.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL) as BuildingInteriorSettings
	return BuildingInteriorSettings.new()

func _reset_default_floor() -> void:
	_default_floors.assign([_new_default_floor()])

func _active_floors() -> Array[BuildingInteriorSettings]:
	return _default_floors if floors.is_empty() else floors

func _on_definition_changed() -> void:
	notify_property_list_changed()
	_schedule_refresh()

func _validate_property(property: Dictionary) -> void:
	if property.name == "facade_detail_color" and (definition == null or definition.facade_detail_colors.is_empty()):
		property.usage &= ~PROPERTY_USAGE_EDITOR
	if property.name == "facade_detail_id":
		if definition == null or definition.facade_details.size() < 2:
			property.usage &= ~PROPERTY_USAGE_EDITOR
		else:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ",".join(definition.facade_details.keys())
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
	for index in _active_floors().size():
		indices.append(index)
	return indices

func get_floor_settings(index: int) -> BuildingInteriorSettings:
	return basement_settings if index == -1 else _active_floors()[index]

func randomize() -> void:
	if is_inside_tree() and not Engine.is_editor_hint() and not multiplayer.is_server():
		return
	var variants := style_variants
	if variants == null and definition != null:
		variants = definition.facade_styles
	if variants != null:
		var selected := variants.choose_style()
		if selected != null:
			_apply_appearance(selected.to_data())
	if definition != null:
		if definition.facade_details.size() > 1:
			facade_detail_id = str(definition.facade_details.keys().pick_random())
		if not definition.facade_detail_colors.is_empty():
			facade_detail_color = definition.facade_detail_colors.pick_random()
	_randomize_doors()
	if is_inside_tree() and not Engine.is_editor_hint() and multiplayer.is_server():
		_apply_appearance.rpc(get_appearance())

func _randomize_doors() -> void:
	door_seed = randi()
	var variants := definition.entrance_variants if definition != null else null
	var selected := variants.choose_style(door_seed) if variants != null else ($Entrance as HousePortal).choose_style(door_seed)
	if selected != null:
		door_style = selected.style
		door_color = selected.color

func _get_door_profile() -> HouseDoorStyle:
	return HouseDoorStyle.create(door_style, door_color)

func _portal_variant_seed(index: int) -> int:
	return hash([door_seed, index]) if door_seed >= 0 else -1

func randomize_interior() -> void:
	if is_inside_tree() and not Engine.is_editor_hint() and not multiplayer.is_server():
		return
	if Engine.is_editor_hint() and floors.is_empty():
		floors = _active_floors().duplicate()
	_ensure_bathroom()
	for index in _all_indices():
		if is_instance_valid(get_interior(index)):
			get_interior(index).randomize()
		else:
			get_floor_settings(index).randomize(layouts)
	_sync_interior_configuration.call_deferred()

func randomize_furniture() -> void:
	if is_inside_tree() and not Engine.is_editor_hint() and not multiplayer.is_server():
		return
	for interior: BuildingInterior in _interiors.values():
		interior.randomize_furniture()
	_sync_interior_configuration.call_deferred()

func _get_appearance_fields() -> Array:
	return _appearance_fields

func _selected_facade_detail() -> StringName:
	if definition == null or definition.facade_details.is_empty():
		return &""
	var id := StringName(facade_detail_id)
	return id if definition.facade_details.has(id) else definition.facade_details.keys()[0]

func get_appearance() -> Dictionary:
	var data := SaveGraph.get_fields(self, _get_appearance_fields())
	data.facade_detail_id = str(_selected_facade_detail())
	return data

@rpc("authority", "reliable")
func _apply_appearance(data: Dictionary) -> void:
	if not data.has("door_seed"):
		door_seed = -1
	SaveGraph.apply_fields(self, _get_appearance_fields(), data)

func _configuration_data() -> Dictionary:
	var data := {"floors": [], "basement_enabled": basement_enabled, "basement": basement_settings.to_data()}
	for settings in _active_floors():
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
	var settings := _active_floors()
	while settings.size() < data.floors.size():
		settings.append(_new_default_floor())
	settings.resize(data.floors.size())
	for index in settings.size():
		settings[index].apply_data(data.floors[index])
	basement_enabled = data.basement_enabled
	basement_settings.apply_data(data.basement)
	_ensure_bathroom()
	_schedule_refresh()

## A required bathroom must be on an above-ground floor.
func _ensure_bathroom() -> void:
	if definition == null or not definition.requires_bathroom:
		return
	if is_inside_tree() and not Engine.is_editor_hint() and not multiplayer.is_server():
		return
	basement_settings.bathroom_enabled = false
	if _has_bathroom():
		return
	for settings in _active_floors():
		if settings.can_enable_bathroom(layouts):
			settings.bathroom_enabled = true
			return

func _has_bathroom() -> bool:
	for settings in _active_floors():
		if settings.has_bathroom(layouts):
			return true
	return false

func _get_configuration_warnings() -> PackedStringArray:
	if definition == null or definition.layouts == null:
		return PackedStringArray(["Assign a building definition with a layout catalog."])
	if not definition.requires_bathroom or _has_bathroom():
		return PackedStringArray()
	return PackedStringArray(["This building needs a room with the Bathroom ID on an above-ground floor. Choose or author a layout that includes it."])

func _schedule_refresh() -> void:
	if is_node_ready() and not _pending:
		_pending = true
		_refresh.call_deferred()

func _refresh() -> void:
	_pending = false
	if not is_node_ready():
		return
	_ensure_bathroom()
	update_configuration_warnings()
	for settings in _active_floors():
		if not settings.changed.is_connected(_schedule_refresh):
			settings.changed.connect(_schedule_refresh)
	var entrance := $Entrance as HousePortal
	var facade_height := maxf(wall_height, definition.minimum_wall_height) if definition != null else wall_height
	var portals := _refresh_balconies(facade_height)
	portals[0] = entrance
	var door_profile := _get_door_profile()
	for index in portals:
		var variants := get_floor_settings(index).balcony_door_variants if index > 0 else (definition.entrance_variants if definition != null else null)
		portals[index].set_appearance(door_profile, _portal_variant_seed(index), variants)
	var facade_profile := _get_facade_profile()
	_refresh_facade_floors(portals, facade_height, facade_profile)
	var detail_scene: PackedScene = definition.facade_details.get(_selected_facade_detail()) if definition != null else null
	_facade_details = _set_decoration_scene($Visuals/FacadeDetails, _facade_details, detail_scene)
	if _facade_details is BuildingFacadeDetails:
		_facade_details.apply_appearance(facade_profile, facade_detail_color)
	_exterior_objects = _set_decoration_scene($ExteriorObjects, _exterior_objects, definition.exterior_objects if definition != null else null)
	if _exterior_objects != null and _exterior_objects.has_method("set_appearance_seed"):
		_exterior_objects.set_appearance_seed(hash([_building_key(), door_seed, "exterior_objects"]))
	var shared_furniture_styles := _get_shared_furniture_styles()
	_apply_exterior_furniture_styles(shared_furniture_styles)
	var total_height := facade_height * _active_floors().size()
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
	HouseArt.set_parameter(material, &"opening_a", entrance.get_opening_rect(Vector2(house_width / 2.0, 8) + entrance.position))
	$Entrance/Step.stone_color = plinth_color
	$Collision.shape.size = Vector2(house_width, house_depth)
	$Collision.position = Vector2(0, -house_depth / 2.0)
	$TransparencyArea.shape.size = Vector2(house_width + 12, total_height)
	$TransparencyArea.position = Vector2(0, -house_depth - total_height / 2.0)
	for interior: BuildingInterior in _interiors.values():
		_apply_interior_door_style(interior, door_profile)
		interior.shared_furniture_styles = shared_furniture_styles
	_build_connections()

func _get_shared_furniture_styles() -> Dictionary[DecorationVariants, DecorationStyle]:
	var styles: Dictionary[DecorationVariants, DecorationStyle] = {}
	if definition == null or definition.shared_furniture_variants.is_empty():
		return styles
	var building_key := _building_key()
	var rng := RandomNumberGenerator.new()
	for variants in definition.shared_furniture_variants:
		if variants == null:
			continue
		rng.seed = hash([building_key, door_seed, variants.resource_path, "shared_furniture"])
		var style := variants.choose_style(rng)
		if style != null:
			styles[variants] = style
	return styles

func _apply_exterior_furniture_styles(styles: Dictionary[DecorationVariants, DecorationStyle]) -> void:
	if _exterior_objects == null or styles.is_empty():
		return
	for node in [_exterior_objects] + _exterior_objects.find_children("*", "", true, false):
		if node is DecorationGroup and node.style_variants != null:
			node.apply_placement_style(styles.get(node.style_variants))

func _set_decoration_scene(anchor: Node2D, current: Node2D, scene: PackedScene) -> Node2D:
	if current != null and scene != null and current.scene_file_path == scene.resource_path:
		return current
	if current != null:
		anchor.remove_child(current)
		current.queue_free()
	if scene == null:
		return null
	var instance := scene.instantiate()
	if instance is Node2D:
		anchor.add_child(instance)
		return instance
	instance.free()
	return null

func _get_facade_profile() -> HouseFacadeStyle:
	var profile := HouseFacadeStyle.new()
	profile.facade_style = facade_style
	profile.facade_color = facade_color
	profile.window_style = window_style
	profile.shutters_closed = shutters_closed
	profile.frame_color = frame_color
	profile.shutter_color = shutter_color
	return profile

func _refresh_facade_floors(portals: Dictionary[int, HousePortal], facade_height: float, profile: HouseFacadeStyle) -> void:
	var sections := $Visuals/Floors
	var floor_count := _active_floors().size()
	while sections.get_child_count() > floor_count:
		var child := sections.get_child(sections.get_child_count() - 1)
		sections.remove_child(child)
		child.queue_free()
	while sections.get_child_count() < floor_count:
		var child := FLOOR_SCENE.instantiate()
		child.name = "Floor%d" % sections.get_child_count()
		sections.add_child(child)
		if Engine.is_editor_hint():
			child.owner = get_tree().edited_scene_root if get_tree().edited_scene_root != null else self
	var floor_size := Vector2(house_width, facade_height)
	var opening_origin := Vector2(house_width / 2.0, facade_height)
	for index in floor_count:
		var floor_node := sections.get_child(index) as HouseFacadeFloor
		var portal := portals.get(index) as HousePortal
		var opening := portal.get_opening_rect(opening_origin + portal.position) if portal != null else Vector4.ZERO
		floor_node.position = Vector2(0, -facade_height * index)
		floor_node.set_appearance(profile, floor_size, opening, definition == null or definition.facade_windows)

func get_interior(index := 0) -> BuildingInterior:
	return _interiors.get(index) as BuildingInterior

func _building_key() -> String:
	if not building_id.is_empty():
		return building_id
	var source := Level.find_level_node(self)
	return source.level_id + "_" + str(source.get_path_to(self)).replace("/", "_") if source != null else str(name)

func get_interior_id(index := 0) -> String:
	var prefix := definition.level_id_prefix if definition != null else "building"
	return prefix + "_" + _building_key() + "_floor_" + ("basement" if index == -1 else str(index))

func _build_connections() -> void:
	for link in $Connections.get_children():
		$Connections.remove_child(link)
		link.queue_free()
	var source := Level.find_level_node(self)
	if source == null:
		return
	_add_connection("Entrance", source.level_id, source.get_path_to($Entrance), get_interior_id(), NodePath("Layout/Exit"))
	for index in _active_floors().size() - 1:
		_add_connection("Floor%dTo%d" % [index, index + 1], get_interior_id(index), NodePath("Layout/Transitions/StairsUp"), get_interior_id(index + 1), NodePath("Layout/Transitions/StairsDown"))
	if basement_enabled:
		_add_connection("BasementToGround", get_interior_id(-1), NodePath("Layout/Transitions/StairsUp"), get_interior_id(), NodePath("Layout/Transitions/StairsDown"))
	for index in range(1, _active_floors().size()):
		if get_floor_settings(index).balcony and has_node("Balconies/Floor%d/Door" % index):
			var door := get_node("Balconies/Floor%d/Door" % index)
			_add_connection("Balcony%d" % index, source.level_id, source.get_path_to(door), get_interior_id(index), NodePath("Layout/Exit"))
	_bind_connections()

func _refresh_balconies(facade_height: float) -> Dictionary[int, HousePortal]:
	var platforms: Array[WalkablePlatform] = []
	var portals: Dictionary[int, HousePortal] = {}
	for child in $Balconies.get_children():
		var index := int(str(child.name).trim_prefix("Floor"))
		if index >= _active_floors().size() or not get_floor_settings(index).balcony:
			$Balconies.remove_child(child)
			child.queue_free()
	for index in range(1, _active_floors().size()):
		if not get_floor_settings(index).balcony:
			continue
		var platform := $Balconies.get_node_or_null("Floor%d" % index) as HouseBalcony
		if platform == null:
			platform = BALCONY_SCENE.instantiate() as HouseBalcony
			platform.name = "Floor%d" % index
			$Balconies.add_child(platform)
			if Engine.is_editor_hint():
				platform.owner = get_tree().edited_scene_root if get_tree().edited_scene_root != null else self
		platform.position = Vector2(0, -facade_height * index)
		platform.ignored_bodies.assign([self])
		portals[index] = platform.configure(plinth_color)
		platforms.append(platform)
	$TransparencyArea.excluded_platforms = platforms
	if not Engine.is_editor_hint():
		var source := Level.find_level_node(self)
		if source != null:
			for player in source.get_players():
				if player.level_id == source.level_id:
					player._refresh_platform()
	return portals

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
		if link.first is HousePortal and link.second is HousePortal:
			link.second.set_appearance(link.first.style)

func _apply_interior_door_style(interior: BuildingInterior, profile: HouseDoorStyle) -> void:
	var seed_value := maxi(door_seed, 0)
	for door in interior.get_doors():
		door.set_appearance(profile, seed_value)

func _on_interior_layout_changed(interior: BuildingInterior, index: int) -> void:
	_apply_interior_door_style(interior, _get_door_profile())
	_bind_connections()
	if not Engine.is_editor_hint() and not multiplayer.is_server() and interior.has_layout_synchronizers():
		_confirm_interior_layout.rpc_id(1, index, interior.get_layout_path())

@rpc("any_peer", "reliable")
func _confirm_interior_layout(index: int, layout_path: String) -> void:
	if not multiplayer.is_server():
		return
	var interior := get_interior(index)
	if interior != null and interior.get_layout_path() == layout_path:
		interior.show_layout_to_peer(multiplayer.get_remote_sender_id())

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
	if source == null or layouts == null:
		return
	if not multiplayer.is_server():
		_apply_configuration(configuration)
	if index not in _all_indices():
		return
	var parent := source.get_parent()
	var world := parent as Main
	var interior := INTERIOR_SCENE.instantiate() as BuildingInterior
	interior.configuration = get_floor_settings(index)
	interior.layouts = layouts
	interior.has_entrance = index == 0 or (index > 0 and interior.configuration.balcony)
	interior.has_upstairs = index < _active_floors().size() - 1
	interior.has_downstairs = index > 0 or (index == 0 and basement_enabled)
	interior.scale = Vector2.ONE if world != null else source.scale
	interior.auto_spawn_standalone_player = false
	interior.world_time = source.world_time
	interior.selected_placements = placements.duplicate(true)
	interior.shared_furniture_styles = _get_shared_furniture_styles()
	interior.initial_door_states = door_states.duplicate()
	interior.level_id = get_interior_id(index)
	interior.name = interior.level_id
	if location.is_finite():
		interior.position = location
	else:
		var right := 0.0
		for existing in parent.get_children():
			if existing is Level:
				var edge: Vector2 = existing.get_world_bounds().end
				right = maxf(right, parent.to_local(edge).x if parent is Node2D else edge.x)
		interior.position = Vector2(right + 1024, 0)
	if world != null:
		if not world.register_level(interior):
			interior.free()
			return
	else:
		interior.visible = false
		parent.add_child(interior)
	_interiors[index] = interior
	interior.layout_changed.connect(_on_interior_layout_changed.bind(interior, index), CONNECT_DEFERRED)
	_on_interior_layout_changed(interior, index)

func sync_to_peer(peer_id: int) -> void:
	var configuration := _configuration_data()
	_apply_appearance.rpc_id(peer_id, get_appearance())
	_apply_interior_configuration.rpc_id(peer_id, configuration, _placements_data())
	for index: int in _interiors:
		var interior := get_interior(index)
		_create_floor.rpc_id(peer_id, index, configuration, interior.selected_placements, interior.position, interior.get_door_states())

func get_save_data() -> Dictionary:
	return {"appearance": get_appearance(), "configuration": _configuration_data(), "created_floors": _interiors.keys(), "floor_placements": _placements_data()}

func can_restore_save_data(data: Dictionary) -> bool:
	if data.get("appearance") is not Dictionary:
		return false
	var schema := get_appearance()
	schema.door_style = Vector2i(HouseDoorStyle.Style.PLANK, HouseDoorStyle.Style.GLAZED)
	if not data.appearance.has("door_seed"):
		schema.erase("door_seed")
	if not data.appearance.has("facade_detail_color"):
		schema.erase("facade_detail_color")
	if not data.appearance.has("facade_detail_id"):
		schema.erase("facade_detail_id")
	elif data.appearance.facade_detail_id is not String:
		return false
	elif not data.appearance.facade_detail_id.is_empty():
		if definition == null or not definition.facade_details.has(StringName(data.appearance.facade_detail_id)):
			return false
	if not SaveGraph.matches(data.appearance, schema):
		return false
	if data.has("configuration"):
		var settings: Variant = data.configuration
		if not SaveGraph.matches(settings, {"floors": [], "basement_enabled": false, "basement": {}}) \
			or settings.floors.is_empty() or not BuildingInteriorSettings.is_valid_data(settings.basement) \
			or data.get("created_floors") is not Array or data.get("floor_placements") is not Dictionary:
			return false
		for floor_data in settings.floors:
			if not BuildingInteriorSettings.is_valid_data(floor_data):
				return false
			if floor_data.has("layout_id") and (layouts == null or not layouts.scenes.has(StringName(floor_data.layout_id))):
				return false
		var seen := {}
		for index in data.created_floors:
			if index is not int or index < (-1 if settings.basement_enabled else 0) or index >= settings.floors.size() or seen.has(index):
				return false
			if data.floor_placements.get(index, {}) is not Dictionary:
				return false
			seen[index] = true
		return true
	return BuildingInteriorSettings.is_valid_data(data.get("interior")) and data.get("created") is bool and data.get("placements") is Dictionary

func apply_save_data(data: Dictionary) -> void:
	_apply_appearance(data.appearance)
	if data.has("configuration"):
		_apply_configuration(data.configuration)
	else:
		var settings := _active_floors()
		settings.resize(1)
		settings[0].kind = BuildingInteriorSettings.Kind.WITH_KITCHEN
		settings[0].apply_data(data.interior)
		basement_enabled = false
		_ensure_bathroom()

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
