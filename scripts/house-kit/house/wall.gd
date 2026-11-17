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

var _reference: Dictionary = {}

func _ready() -> void:
	if style != null and not style.changed.is_connected(refresh):
		style.changed.connect(refresh)
	_capture_geometry()
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
		var opening := Vector4(openings[index] - 12, 4, 24, 28) if index < openings.size() else Vector4.ZERO
		HouseArt.set_parameter(material, [&"opening_a", &"opening_b", &"opening_c"][index], opening)

func _capture_geometry() -> void:
	_reference = {"length": length, "openings": openings.duplicate(), "colliders": {}}
	for collider: CollisionShape2D in $Collisions.get_children():
		_reference.colliders[collider] = Rect2(collider.position - collider.shape.size / 2.0, collider.shape.size)
	var area := $TransparencyArea as TransparencyArea
	_reference.zone_position = area.position
	_reference.zone_size = (area.shape as RectangleShape2D).size

## Resize existing authored segments; passages keep their original 24px width.
## No nodes or collision shapes are generated here.
func resize_to(new_length: float, new_openings: Array[float]) -> void:
	if _reference.is_empty():
		_capture_geometry()
	var axis := 1 if vertical else 0
	for collider: CollisionShape2D in _reference.colliders:
		var rectangle: Rect2 = _reference.colliders[collider]
		var start := _map_coordinate(rectangle.position[axis], new_length, new_openings)
		var end := _map_coordinate(rectangle.end[axis], new_length, new_openings)
		var size := rectangle.size
		size[axis] = end - start
		collider.shape.size = size
		var center := rectangle.get_center()
		center[axis] = (start + end) / 2.0
		collider.position = center
	var area := $TransparencyArea as TransparencyArea
	var zone_position: Vector2 = _reference.zone_position
	var zone_size: Vector2 = _reference.zone_size
	var ratio: float = new_length / _reference.length
	zone_position[axis] *= ratio
	zone_size[axis] *= ratio
	area.position = zone_position
	area.shape.size = zone_size
	length = new_length
	openings = new_openings

func _map_coordinate(value: float, new_length: float, new_openings: Array[float]) -> float:
	var old_knots: Array[float] = [0.0]
	var new_knots: Array[float] = [0.0]
	for index in _reference.openings.size():
		old_knots.append_array([_reference.openings[index] - 12, _reference.openings[index] + 12])
		new_knots.append_array([new_openings[index] - 12, new_openings[index] + 12])
	old_knots.append(_reference.length)
	new_knots.append(new_length)
	for index in range(1, old_knots.size()):
		if value <= old_knots[index] or index == old_knots.size() - 1:
			return remap(value, old_knots[index - 1], old_knots[index], new_knots[index - 1], new_knots[index])
	return value
