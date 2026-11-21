@tool
class_name BuildingInteriorSettings
extends Resource

enum RoomCount { TWO = 2, THREE = 3, FOUR = 4 }
enum Layout { A, B, C }
enum Kind { WITH_KITCHEN, WITHOUT_KITCHEN, CELLAR }
const BATHROOM_STYLE := preload("res://assets/world-kit/house/room-variants/bathroom_checker.tres")

const ROOM_PROPERTIES := {
	&"LivingRoom": "living", &"Kitchen": "kitchen",
	&"Bedroom": "bedroom", &"SecondBedroom": "second_bedroom",
}
const FIELDS := ["room_count", "layout", "kind", "balcony", "bathroom_enabled"]

## Residential layout settings apply when the floor has no named layout choices.
@export var kind: Kind = Kind.WITH_KITCHEN:
	set(value):
		kind = value
		if kind == Kind.CELLAR:
			bathroom_enabled = false
		notify_property_list_changed()
		emit_changed()
## A service room in addition to the selected number of main rooms.
@export var bathroom_enabled := false:
	set(value):
		value = value and kind != Kind.CELLAR
		if bathroom_enabled == value:
			return
		bathroom_enabled = value
		emit_changed()
@export var balcony := false:
	set(value):
		balcony = value
		notify_property_list_changed()
		emit_changed()
## Optional authored layout. Empty uses the scene-assigned Layouts catalog.
@export var layout_scene: PackedScene:
	set(value):
		layout_scene = value
		notify_property_list_changed()
		emit_changed()
## Stable keys from the building definition's layout catalog.
@export var layout_choices: Array[String] = []:
	set(value):
		layout_choices = value
		notify_property_list_changed()
		emit_changed()
@export var layout_id := "":
	set(value):
		layout_id = value
		emit_changed()
@export var additional_rooms: Dictionary[StringName, HouseRoomStyle] = {}:
	set(value):
		additional_rooms = value
		emit_changed()

@export var room_count: RoomCount = RoomCount.THREE:
	set(value):
		if room_count == value:
			return
		room_count = value
		notify_property_list_changed()
		emit_changed()
@export var layout: Layout = Layout.A:
	set(value):
		if layout == value:
			return
		layout = value
		emit_changed()
@export var layout_variants: Array[Layout] = [Layout.A, Layout.B, Layout.C]
## An empty override uses the balcony door's own catalogue.
@export var balcony_door_variants: HouseDoorVariants:
	set(value):
		balcony_door_variants = value
		emit_changed()
@export var living: HouseRoomStyle = HouseRoomStyle.new():
	set(value):
		if living == value:
			return
		living = value
		emit_changed()
@export var kitchen: HouseRoomStyle = HouseRoomStyle.new():
	set(value):
		if kitchen == value:
			return
		kitchen = value
		emit_changed()
@export var bedroom: HouseRoomStyle = HouseRoomStyle.new():
	set(value):
		if bedroom == value:
			return
		bedroom = value
		emit_changed()
@export var second_bedroom: HouseRoomStyle = HouseRoomStyle.new():
	set(value):
		if second_bedroom == value:
			return
		second_bedroom = value
		emit_changed()

func _init() -> void:
	resource_local_to_scene = true

func _validate_property(property: Dictionary) -> void:
	if not balcony and property.name == "balcony_door_variants":
		property.usage &= ~PROPERTY_USAGE_EDITOR
	if property.name == "layout_id":
		if layout_choices.is_empty() or layout_scene != null:
			property.usage &= ~PROPERTY_USAGE_EDITOR
		else:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ",".join(layout_choices)
	if layout_scene != null or not layout_choices.is_empty():
		if property.name in ["kind", "room_count", "layout", "layout_variants", "bathroom_enabled"]:
			property.usage &= ~PROPERTY_USAGE_EDITOR
	elif kind == Kind.CELLAR and property.name in ["room_count", "layout", "layout_variants", "kitchen", "bedroom", "second_bedroom", "bathroom_enabled"]:
		property.usage &= ~PROPERTY_USAGE_EDITOR
	elif (property.name == "kitchen" and kind == Kind.WITHOUT_KITCHEN) or (property.name == "second_bedroom" and room_count < RoomCount.FOUR):
		property.usage &= ~PROPERTY_USAGE_EDITOR

func get_style(room_id: StringName) -> HouseRoomStyle:
	if room_id == &"Bathroom" and additional_rooms.get(room_id) == null:
		additional_rooms[room_id] = BATHROOM_STYLE.duplicate()
	var extra: HouseRoomStyle = additional_rooms.get(room_id)
	if extra != null:
		return extra
	return get(ROOM_PROPERTIES.get(room_id, "living")) as HouseRoomStyle

func get_template_scene(catalog: BuildingLayoutCatalog) -> PackedScene:
	if layout_scene != null:
		return layout_scene
	if catalog == null:
		return null
	if not layout_choices.is_empty():
		var selected := layout_id if not layout_id.is_empty() else layout_choices[0]
		return catalog.scenes.get(StringName(selected)) as PackedScene
	if kind == Kind.CELLAR:
		return catalog.scenes.get(&"cellar") as PackedScene
	return catalog.scenes.get(_layout_key(bathroom_enabled)) as PackedScene

func can_enable_bathroom(catalog: BuildingLayoutCatalog) -> bool:
	return layout_scene == null and layout_choices.is_empty() and kind != Kind.CELLAR and catalog != null \
		and catalog.scenes.get(_layout_key(true)) != null

func _layout_key(with_bathroom: bool) -> StringName:
	var key := "%d_%s" % [room_count, ["a", "b", "c"][layout]]
	if kind == Kind.WITH_KITCHEN:
		key += "_kitchen"
	if with_bathroom:
		key += "_bathroom"
	return StringName(key)

func has_bathroom(catalog: BuildingLayoutCatalog) -> bool:
	var scene := get_template_scene(catalog)
	if scene == null:
		return false
	if layout_scene == null and layout_choices.is_empty():
		return bathroom_enabled
	# Authored layouts define their rooms independently of the residential selectors.
	var instance := scene.instantiate()
	var found := instance is BuildingLayout and (instance as BuildingLayout).get_rooms().any(func(room: HouseRoom): return room.room_id == &"Bathroom")
	instance.free()
	return found

func randomize(catalog: BuildingLayoutCatalog) -> void:
	# Room count is an explicit authoring decision. Styles keep semantic IDs.
	if layout_scene == null:
		if not layout_choices.is_empty():
			layout_id = layout_choices.pick_random()
		elif kind != Kind.CELLAR and not layout_variants.is_empty():
			layout = layout_variants.pick_random() as Layout
	# Read the room presets without adding an interior level to the world.
	var scene := get_template_scene(catalog)
	if scene == null:
		return
	var instance := scene.instantiate()
	if instance is not BuildingLayout:
		instance.free()
		push_error("Layout must use BuildingLayout: %s" % scene.resource_path)
		return
	var template := instance as BuildingLayout
	for room in template.get_rooms():
		_randomize_room_style(room.room_id, room.style_variants)
	for zone in template.get_floor_zones():
		_randomize_room_style(zone.room_id, zone.style_variants)
	template.free()

func _randomize_room_style(id: StringName, variants: HouseRoomVariants) -> void:
	if variants == null:
		return
	var style := variants.choose_style()
	if style == null:
		return
	if ROOM_PROPERTIES.has(id):
		set(ROOM_PROPERTIES[id], style)
	else:
		additional_rooms[id] = style
		emit_changed()

func to_data() -> Dictionary:
	var data := SaveGraph.get_fields(self, FIELDS)
	if not layout_choices.is_empty():
		data.layout_id = layout_id if not layout_id.is_empty() else layout_choices[0]
	data.layout_scene = layout_scene.resource_path if layout_scene != null else ""
	data.additional_rooms = {}
	for id in additional_rooms:
		if additional_rooms[id] != null:
			data.additional_rooms[str(id)] = additional_rooms[id].to_data()
	for id in ROOM_PROPERTIES.values():
		data[id] = (get(id) as HouseRoomStyle).to_data()
	return data

func apply_data(data: Dictionary) -> void:
	# A previous scene configuration must not add a bathroom to an older save.
	if not data.has("bathroom_enabled"):
		bathroom_enabled = false
	SaveGraph.apply_fields(self, FIELDS, data)
	if data.has("layout_id"):
		layout_id = data.layout_id
	if data.has("layout_scene"):
		var path: String = data.layout_scene
		layout_scene = load(path) as PackedScene if not path.is_empty() else null
	if data.has("additional_rooms"):
		additional_rooms.clear()
		for id: String in data.additional_rooms:
			var style := HouseRoomStyle.new()
			style.apply_data(data.additional_rooms[id])
			additional_rooms[StringName(id)] = style
	for key in ROOM_PROPERTIES.values():
		if data.has(key):
			(get(key) as HouseRoomStyle).apply_data(data[key])
	emit_changed()

static func create_cellar() -> BuildingInteriorSettings:
	var settings := BuildingInteriorSettings.new()
	settings.kind = Kind.CELLAR
	settings.living.wall_style = HouseRoomStyle.Wall.FIELDSTONE
	settings.living.floor_material = HouseRoomStyle.Floor.STONE
	settings.living.wall_color = Color("9c9586")
	settings.living.floor_color = Color("a69c87")
	return settings

static func is_valid_data(data: Variant) -> bool:
	if not SaveGraph.matches(data, {"room_count": Vector2i(2, 4), "layout": Vector2i(0, 2)}):
		return false
	for key in ROOM_PROPERTIES.values():
		if not data.has(key) or not _valid_style(data[key]):
			return false
	if data.has("kind") and not SaveGraph.matches(data.kind, Vector2i(0, 2)):
		return false
	if data.has("balcony") and data.balcony is not bool:
		return false
	if data.has("bathroom_enabled") and data.bathroom_enabled is not bool:
		return false
	if data.has("layout_id") and (data.layout_id is not String or data.layout_id.is_empty()):
		return false
	if data.has("layout_scene"):
		if data.layout_scene is not String:
			return false
		var path: String = data.layout_scene
		if not path.is_empty() and (not path.begins_with("res://scenes/") or not ResourceLoader.exists(path, "PackedScene")):
			return false
	if data.has("additional_rooms"):
		if data.additional_rooms is not Dictionary:
			return false
		for id in data.additional_rooms:
			if id is not String or not _valid_style(data.additional_rooms[id]):
				return false
	return true

static func _valid_style(data: Variant) -> bool:
	return SaveGraph.matches(data, {
		"floor_material": Vector2i(0, HouseRoomStyle.Floor.STONE),
		"wall_style": Vector2i(0, HouseRoomStyle.Wall.LIMESTONE),
		"floor_color": Color(), "wall_color": Color(), "accent_color": Color(),
	})
