@tool
class_name StreetSurface
extends Sprite2D

enum Style { GRASS, DIRT, COBBLESTONE, LIMESTONE, GRAVEL }

@export_storage var textures: Array[Texture2D] = []

@export_group("Design")
@export var style: Style = Style.LIMESTONE:
	set(value):
		style = value
		_refresh_surface()
@export var size := Vector2(128, 96):
	set(value):
		size = value.round().max(Vector2.ONE)
		_refresh_surface()

func _ready() -> void:
	_refresh_surface()

func _refresh_surface() -> void:
	if not is_node_ready():
		return
	texture = textures[clampi(style, 0, textures.size() - 1)] if not textures.is_empty() else null
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	centered = false
	region_enabled = true
	region_rect = Rect2(Vector2.ZERO, size)
