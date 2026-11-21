@tool
class_name Surface
extends Polygon2D

enum Style { GRASS, DIRT, COBBLESTONE, LIMESTONE, GRAVEL, SAND }

const GROUP := &"walkable_surfaces"

@export_storage var textures: Array[Texture2D] = []
@export_storage var footstep_sounds: Array[AudioStream] = []
@export_storage var _saved_polygon := PackedVector2Array()

@export_group("Design")
@export var style: Style = Style.LIMESTONE:
	set(value):
		style = value
		_refresh_texture()

@export_group("Audio")
## Overrides the default footstep sound for this surface's style.
@export var footstep_sound: AudioStream

@export_group("Movement")
## Movement speed as a percentage of the player's base speed for each style.
@export var speed_percent_by_style: Dictionary[Style, int] = {}
## Zero uses the default multiplier for the selected style.
@export_range(0.0, 2.0, 0.01, "or_greater") var speed_multiplier_override := 0.0

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

@export_tool_button("Randomize surface") var randomize_action: Callable = randomize

func _ready() -> void:
	_refresh_texture()
	_refresh_geometry()
	add_to_group(GROUP)

func randomize() -> void:
	var choices: Array[Style] = []
	for candidate in Style.values():
		if candidate < textures.size() and textures[candidate] != null:
			choices.append(candidate as Style)
	if not choices.is_empty():
		style = choices.pick_random()

static func find_at(level: Level, world_position: Vector2) -> Surface:
	var top: Surface
	for surface: Surface in level.get_tree().get_nodes_in_group(GROUP):
		if not surface.is_visible_in_tree() or Level.find_level_node(surface) != level:
			continue
		var point := surface.to_local(world_position) - surface.offset
		if Geometry2D.is_point_in_polygon(point, surface.polygon) and (top == null or surface._draws_above(top)):
			top = surface
	return top

func get_footstep_sound() -> AudioStream:
	if footstep_sound != null:
		return footstep_sound
	return footstep_sounds[style] if style >= 0 and style < footstep_sounds.size() else null

func get_speed_multiplier() -> float:
	if speed_multiplier_override > 0.0:
		return speed_multiplier_override
	return maxi(speed_percent_by_style.get(style, 100), 0) / 100.0

func _draws_above(other: Surface) -> bool:
	var z := _effective_z_index()
	var other_z := other._effective_z_index()
	if z != other_z:
		return z > other_z
	var parent := get_parent() as CanvasItem
	if parent != null and parent == other.get_parent() and parent.y_sort_enabled:
		if position.y != other.position.y:
			return position.y > other.position.y
	# The group is enumerated in scene tree order, so this surface draws later.
	return true

func _effective_z_index() -> int:
	var z := z_index
	var item: CanvasItem = self
	while item.z_as_relative:
		item = item.get_parent() as CanvasItem
		if item == null:
			break
		z += item.z_index
	return z

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
