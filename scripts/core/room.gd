@tool
class_name Room
extends Node2D

signal layout_changed

@export var room_size: Vector2 = Vector2(80, 60):
	set(v):
		v = v.max(_minimum_room_size())
		if room_size == v:
			return
		room_size = v
		queue_redraw()
		if is_node_ready():
			refresh_layout()

@export var wall_thickness: float = 4.0:
	set(v):
		v = maxf(v, 0.5)
		if is_equal_approx(wall_thickness, v):
			return
		wall_thickness = v
		room_size = room_size.max(_minimum_room_size())
		queue_redraw()
		if is_node_ready():
			refresh_layout()

@onready var navigation_region: NavigationRegion2D = $NavigationRegion
@onready var y_sort: Node2D = $NavigationRegion/YSort

@onready var _wall_top: StaticBody2D = $Walls/Top
@onready var _wall_bottom: StaticBody2D = $Walls/Bottom
@onready var _wall_left: StaticBody2D = $Walls/Left
@onready var _wall_right: StaticBody2D = $Walls/Right

func _ready() -> void:
	refresh_layout()

func refresh_layout() -> void:
	if not is_node_ready():
		return
	var minimum := _minimum_room_size()
	if room_size.x < minimum.x or room_size.y < minimum.y:
		room_size = room_size.max(minimum)
		return
	_update_layout()
	_update_navigation_region()
	layout_changed.emit()

func _minimum_room_size() -> Vector2:
	return Vector2.ONE * (wall_thickness * 2.0 + 1.0)

func get_walls() -> Array[StaticBody2D]:
	var children = $Walls.get_children()
	var bodies = children.filter(func(node): return node is StaticBody2D)
	var walls: Array[StaticBody2D] = []
	walls.assign(bodies)
	return walls

func init_room() -> void:
	pass

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(Vector2.ZERO, room_size), Color(0.3, 0.6, 1.0, 0.07), true)
	draw_rect(Rect2(Vector2.ZERO, room_size), Color(0.3, 0.6, 1.0, 0.8), false)

func _update_layout() -> void:
	var w := room_size.x
	var h := room_size.y
	var t := wall_thickness
	_place_wall(_wall_top, Vector2(w * 0.5, 0.0), Vector2(w, t))
	_place_wall(_wall_bottom, Vector2(w * 0.5, h), Vector2(w, t))
	_place_wall(_wall_left, Vector2(0.0, h * 0.5), Vector2(t, h))
	_place_wall(_wall_right, Vector2(w, h * 0.5), Vector2(t, h))
	
func _update_navigation_region() -> void:
	var bounding_outline := PackedVector2Array([
		Vector2.ZERO,
		Vector2(room_size.x, 0.0),
		room_size,
		Vector2(0.0, room_size.y),
	])

	var polygon: NavigationPolygon
	if navigation_region.navigation_polygon:
		polygon = navigation_region.navigation_polygon.duplicate()
	else:
		polygon = NavigationPolygon.new()
		
	polygon.clear_outlines()
	polygon.clear_polygons()
	var source_data := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(
		polygon,
		source_data,
		self
	)
	source_data.add_traversable_outline(bounding_outline)
	NavigationServer2D.bake_from_source_geometry_data(
		polygon,
		source_data
	)
	navigation_region.navigation_polygon = polygon


	
func _place_wall(body: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	body.position = pos
	var shape := RectangleShape2D.new()
	shape.size = size
	var collisionShape := body.find_child("*Shape") as CollisionShape2D
	collisionShape.shape = shape
