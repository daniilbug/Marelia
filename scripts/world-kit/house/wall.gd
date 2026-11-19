@tool
class_name HouseWall
extends Node2D

@export var room_id: StringName = &"LivingRoom"
@export var length := 288.0:
	set(value):
		length = value
		refresh()
@export var vertical := false:
	set(value):
		vertical = value
		refresh()
@export var openings: Array[float] = []:
	set(value):
		openings = value
		refresh()
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
@export_range(0, 1) var static_alpha := 1.0:
	set(value):
		static_alpha = value
		refresh()

var show_openings := true:
	set(value):
		if show_openings == value:
			return
		show_openings = value
		refresh()

func _ready() -> void:
	if style != null and not style.changed.is_connected(refresh):
		style.changed.connect(refresh)
	refresh()

## Appearance only: colliders and transparency zones belong to the scene.
func refresh() -> void:
	if not is_node_ready() or style == null:
		return
	var sprite := $Sprite as Sprite2D
	var material := HouseArt.apply(sprite, HouseArt.WALLS[style.wall_style], {"plaster_color": style.wall_color}, true)
	sprite.region_enabled = true
	sprite.position = Vector2(-2, -32) if vertical else Vector2(0, -32)
	sprite.region_rect = Rect2(Vector2.ZERO, Vector2(4, length + 32) if vertical else Vector2(length, 32))
	modulate.a = static_alpha
	for index in 3:
		var opening := Vector4(openings[index] - 12, 4, 24, 28) if show_openings and index < openings.size() else Vector4.ZERO
		HouseArt.set_parameter(material, [&"opening_a", &"opening_b", &"opening_c"][index], opening)
