@tool
class_name HouseFloorZone
extends Polygon2D

@export var room_id: StringName = &"Kitchen"
@export var style_variants: HouseRoomVariants
@export var style: HouseRoomStyle = HouseRoomStyle.new():
	set(value):
		if style == value:
			return
		if style != null and style.changed.is_connected(refresh):
			style.changed.disconnect(refresh)
		style = value
		if style != null and not style.changed.is_connected(refresh):
			style.changed.connect(refresh)
		refresh()

func _ready() -> void:
	if style != null and not style.changed.is_connected(refresh):
		style.changed.connect(refresh)
	refresh()

func refresh() -> void:
	if is_node_ready() and style != null:
		HouseArt.apply(self, HouseArt.FLOORS[style.floor_material], HouseArt.floor_colors(style), true)
