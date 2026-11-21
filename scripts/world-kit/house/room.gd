@tool
class_name HouseRoom
extends Node2D

@export var room_id: StringName = &"LivingRoom"
@export var style_variants: HouseRoomVariants
@export var style: HouseRoomStyle = HouseRoomStyle.new():
	set(value):
		if style == value:
			return
		if style != null and style.changed.is_connected(refresh_floor):
			style.changed.disconnect(refresh_floor)
		style = value
		if style != null and not style.changed.is_connected(refresh_floor):
			style.changed.connect(refresh_floor)
		refresh_floor()

func _ready() -> void:
	if style != null and not style.changed.is_connected(refresh_floor):
		style.changed.connect(refresh_floor)
	refresh_floor()

func refresh_floor() -> void:
	if not is_node_ready() or style == null:
		return
	HouseArt.apply($Floor, HouseArt.FLOORS[style.floor_material], HouseArt.floor_colors(style), true)

func get_placements() -> Array[Node]:
	return $Placements.get_children()
