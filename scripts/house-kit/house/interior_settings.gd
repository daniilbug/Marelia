@tool
class_name HouseInteriorSettings
extends Resource

enum RoomCount { TWO = 2, THREE = 3, FOUR = 4 }
enum Layout { A, B, C }

const ROOM_PROPERTIES := {
	&"LivingRoom": "living", &"Kitchen": "kitchen",
	&"Bedroom": "bedroom", &"SecondBedroom": "second_bedroom",
}
const FIELDS := ["room_count", "layout", "interior_size", "door_style", "door_color"]

@export var room_count: RoomCount = RoomCount.THREE:
	set(value):
		if room_count == value:
			return
		room_count = value
		emit_changed()
@export var layout: Layout = Layout.A:
	set(value):
		if layout == value:
			return
		layout = value
		emit_changed()
@export var layout_variants: Array[Layout] = [Layout.A, Layout.B, Layout.C]
@export var interior_size := Vector2(288, 256):
	set(value):
		value = value.clamp(Vector2(240, 224), Vector2(1024, 1024)).snapped(Vector2(8, 8))
		if interior_size == value:
			return
		interior_size = value
		emit_changed()
@export var door_style: HouseDoorStyle.Style = HouseDoorStyle.Style.PLANK:
	set(value):
		if door_style == value:
			return
		door_style = value
		emit_changed()
@export_color_no_alpha var door_color := Color("ae7d46"):
	set(value):
		if door_color == value:
			return
		door_color = value
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

func get_style(room_id: StringName) -> HouseRoomStyle:
	return get(ROOM_PROPERTIES.get(room_id, "living")) as HouseRoomStyle

func get_template_path() -> String:
	return "res://scenes/house-kit/house/layouts/%d_%s.tscn" % [room_count, ["a", "b", "c"][layout]]

func randomize() -> void:
	# Room count is an explicit authoring decision. Styles keep semantic IDs.
	if not layout_variants.is_empty():
		layout = layout_variants.pick_random() as Layout
	# Read the room presets without adding an interior level to the world.
	var template := (load(get_template_path()) as PackedScene).instantiate() as HouseLayout
	if template.door_variants != null:
		var selected := template.door_variants.choose_style()
		if selected != null:
			door_style = selected.style
			door_color = selected.color
	for room in template.get_rooms():
		if room.style_variants == null:
			continue
		var style := room.style_variants.choose_style()
		if style != null:
			set(ROOM_PROPERTIES[room.room_id], style)
	for zone in template.get_floor_zones():
		if zone.style_variants == null:
			continue
		var style := zone.style_variants.choose_style()
		if style != null:
			set(ROOM_PROPERTIES[zone.room_id], style)
	template.free()

func to_data() -> Dictionary:
	var data := SaveGraph.get_fields(self, FIELDS)
	for id in ROOM_PROPERTIES.values():
		data[id] = (get(id) as HouseRoomStyle).to_data()
	return data

func apply_data(data: Dictionary) -> void:
	SaveGraph.apply_fields(self, FIELDS, data)
	for key in ROOM_PROPERTIES.values():
		if data.has(key):
			(get(key) as HouseRoomStyle).apply_data(data[key])
