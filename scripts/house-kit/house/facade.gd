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
@export var interior_settings: HouseInteriorSettings = HouseInteriorSettings.new():
	set(value):
		interior_settings = value if value != null else HouseInteriorSettings.new()
		if is_instance_valid(_interior):
			_interior.configuration = interior_settings
@export_tool_button("Randomize exterior") var randomize_exterior_action: Callable = randomize
@export_tool_button("Randomize interior") var randomize_interior_action: Callable = randomize_interior

var _pending := false
var _geometry := Vector3.ZERO
var _interior: HouseInterior

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		set_multiplayer_authority(1, true)
		add_to_group("saveable")
		add_to_group("level_factories")

func _ready() -> void:
	_refresh()
	$Entrance.arrival_direction = Vector2.DOWN
	if not Engine.is_editor_hint():
		$Entrance.opening_requested.connect(_open_interior)

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
			door_style = selected.style
			door_color = selected.color
	if is_inside_tree() and not Engine.is_editor_hint() and multiplayer.is_server():
		_apply_appearance.rpc(get_appearance())

func randomize_interior() -> void:
	if is_inside_tree() and not Engine.is_editor_hint() and not multiplayer.is_server():
		return
	if is_instance_valid(_interior):
		_interior.randomize()
		_sync_interior_configuration.call_deferred()
	else:
		interior_settings.randomize()

func _sync_interior_configuration() -> void:
	if not is_instance_valid(_interior):
		return
	_apply_interior_configuration.rpc(interior_settings.to_data(), _interior.selected_placements)

func randomize_furniture() -> void:
	if is_inside_tree() and not Engine.is_editor_hint() and not multiplayer.is_server():
		return
	if is_instance_valid(_interior):
		_interior.randomize_furniture()
		_sync_interior_configuration.call_deferred()

func get_appearance() -> Dictionary:
	return SaveGraph.get_fields(self, _appearance_fields)

@rpc("authority", "reliable")
func _apply_appearance(data: Dictionary) -> void:
	SaveGraph.apply_fields(self, _appearance_fields, data)

@rpc("authority", "reliable")
func _apply_interior_configuration(data: Dictionary, placements: Dictionary) -> void:
	interior_settings.apply_data(data)
	if is_instance_valid(_interior):
		_interior.selected_placements = placements.duplicate(true)
		_interior.configuration = interior_settings

func _schedule_refresh() -> void:
	if is_node_ready() and not _pending:
		_pending = true
		_refresh.call_deferred()

func _refresh() -> void:
	_pending = false
	if not is_node_ready():
		return
	var wall := $Visuals/Wall as Sprite2D
	var material := HouseArt.apply(wall, ["facade_plaster", "facade_fieldstone"][facade_style], {"plaster_color": facade_color, "stone_color": facade_color}, true)
	wall.position = Vector2(-house_width / 2.0, -wall_height)
	wall.region_enabled = true
	wall.region_rect = Rect2(0, 0, house_width, wall_height)
	HouseArt.set_parameter(material, &"opening_a", Vector4(house_width / 2.0 - 12, wall_height - 28, 24, 28))
	var roof := $Visuals/Roof as Sprite2D
	HouseArt.apply(roof, ["roof_tiles", "roof_coppi"][roof_style], {"roof_color": roof_color}, true)
	roof.position = Vector2(-house_width / 2.0 - 6, -wall_height - house_depth)
	roof.region_enabled = true
	roof.region_rect = Rect2(0, 0, house_width + 12, house_depth)
	var plinth := $Visuals/Plinth as Sprite2D
	material = HouseArt.apply(plinth, "plinth_stone", {"stone_color": plinth_color}, true)
	plinth.position = Vector2(-house_width / 2.0, -8)
	plinth.region_enabled = true
	plinth.region_rect = Rect2(0, 0, house_width, 8)
	HouseArt.set_parameter(material, &"opening_a", Vector4(house_width / 2.0 - 12, 0, 24, 8))
	for index in 2:
		var window := get_node("Visuals/" + ["LeftWindow", "RightWindow"][index]) as Sprite2D
		HouseArt.apply(window, ["window_louvered", "window_panelled", "window_arched"][window_style] + ("_closed" if shutters_closed else "_open"), {"wood_color": frame_color, "paint_color": shutter_color})
		window.position = Vector2(house_width * [-0.28, 0.28][index] - window.texture.get_width() / 2.0, -wall_height + 5)
	$Entrance.style = door_style
	$Entrance.color = door_color
	var dimensions := Vector3(house_width, house_depth, wall_height)
	if dimensions != _geometry:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(house_width, house_depth)
		$Collision.shape = shape
		$Collision.position = Vector2(0, -house_depth / 2.0)
		var zone := RectangleShape2D.new()
		zone.resource_local_to_scene = true
		zone.size = Vector2(house_width + 12, wall_height)
		$TransparencyArea.shape = zone
		$TransparencyArea.position = Vector2(0, -house_depth - wall_height / 2.0)
		_geometry = dimensions

func get_interior() -> HouseInterior:
	return _interior

func get_interior_id() -> String:
	var source := Level.find_level_node(self)
	var key := house_id if not house_id.is_empty() else source.level_id + "_" + str(source.get_path_to(self)).replace("/", "_")
	return "house_" + key + "_floor_0"

func _open_interior(_player: Player) -> void:
	if Level.find_level_node(self) == null:
		return
	if not is_instance_valid(_interior):
		_create_interior(interior_settings.to_data(), {})
		if is_instance_valid(_interior):
			_create_interior.rpc(interior_settings.to_data(), _interior.selected_placements, _interior.position)

@rpc("authority", "reliable")
func _create_interior(data: Dictionary, placements: Dictionary, location := Vector2.INF, door_states: Dictionary = {}) -> void:
	if is_instance_valid(_interior):
		return
	var source := Level.find_level_node(self)
	if source == null or interior_scene == null:
		return
	var parent := source.get_parent()
	var world := parent as Main
	interior_settings.apply_data(data)
	var instance := interior_scene.instantiate()
	var interior := instance as HouseInterior
	if interior == null:
		instance.free()
		push_error("Interior scene must inherit HouseInterior")
		return
	interior.configuration = interior_settings
	interior.scale = Vector2.ONE if world != null else source.scale
	interior.auto_spawn_standalone_player = false
	interior.world_time = source.world_time
	interior.selected_placements = placements.duplicate(true)
	interior.initial_door_states = door_states.duplicate()
	interior.level_id = get_interior_id()
	interior.name = interior.level_id
	var right := 0.0
	for existing in parent.get_children():
		if existing is Level:
			var edge: Vector2 = existing.get_world_bounds().end
			right = maxf(right, parent.to_local(edge).x if parent is Node2D else edge.x)
	# The server sends its exact allocation: peers may have created houses in a
	# different order before joining, while player positions are world-relative.
	interior.position = location if location.is_finite() else Vector2(right + 1024, 0)
	if world != null:
		if not world.register_level(interior):
			interior.free()
			return
	else:
		interior.visible = false
		parent.add_child(interior)
	_interior = interior
	($Entrance as HousePortal).pair_with(interior.get_entry_portal())

func sync_to_peer(peer_id: int) -> void:
	_apply_appearance.rpc_id(peer_id, get_appearance())
	if is_instance_valid(_interior):
		_create_interior.rpc_id(peer_id, interior_settings.to_data(), _interior.selected_placements, _interior.position, _interior.get_door_states())

func get_save_data() -> Dictionary:
	return {"appearance": get_appearance(), "interior": interior_settings.to_data(), "created": is_instance_valid(_interior), "placements": _interior.selected_placements.duplicate(true) if is_instance_valid(_interior) else {}}

func apply_save_data(data: Dictionary) -> void:
	_apply_appearance(data.appearance)
	if interior_settings.to_data() != data.interior:
		interior_settings.apply_data(data.interior)

func prepare_levels_for_restore(levels: Dictionary) -> void:
	var source := Level.find_level_node(self)
	var path := source.get_path_to(self)
	var state: Dictionary = levels.get(source.level_id, {}).get("objects", {}).get(path, {})
	if state.is_empty():
		return
	apply_save_data(state)
	if state.created:
		_create_interior(state.interior, state.placements)
