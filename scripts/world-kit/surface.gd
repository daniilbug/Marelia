@tool
class_name Surface
extends Polygon2D

enum Style { GRASS, DIRT, COBBLESTONE, LIMESTONE, GRAVEL, SAND }

@export_storage var textures: Array[Texture2D] = []
@export_storage var _saved_polygon := PackedVector2Array()

@export_group("Design")
@export var style: Style = Style.LIMESTONE:
	set(value):
		style = value
		_refresh_texture()

@export_group("Geometry")
## Use the native Polygon2D contour instead of building a rectangle from Size.
@export var use_polygon := false:
	set(value):
		if use_polygon == value:
			return
		if use_polygon and is_node_ready():
			_saved_polygon = polygon
		use_polygon = value
		_refresh_geometry()
@export var size := Vector2(128, 96):
	set(value):
		size = value.round().max(Vector2.ONE)
		_refresh_geometry()

func _ready() -> void:
	_refresh_texture()
	_refresh_geometry()

func _refresh_texture() -> void:
	if not is_node_ready():
		return
	texture = textures[clampi(style, 0, textures.size() - 1)] if not textures.is_empty() else null

func _refresh_geometry() -> void:
	if not is_node_ready():
		return
	if not use_polygon:
		polygon = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	elif not _saved_polygon.is_empty():
		polygon = _saved_polygon
		_saved_polygon = PackedVector2Array()
