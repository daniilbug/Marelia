@tool
class_name FurniturePiece
extends StaticBody2D

const PALETTE_SHADER = preload("res://assets/world-kit/furniture/shaders/furniture_palette.gdshader")
const MATERIAL_COLORS := {"wood_color": 1, "paint_color": 2, "fabric_color": 3, "plaster_color": 4, "stone_color": 5, "roof_color": 6}

@export_storage var designs: Array[FurnitureDesign] = []
@export_storage var paintable_materials := 0
@export_storage var supports_transparency := false

@export_group("Material colors")
@export_color_no_alpha var wood_color := Color("ae7d46"):
	set(value):
		wood_color = value
		_update_palette()
@export_color_no_alpha var paint_color := Color("7d9667"):
	set(value):
		paint_color = value
		_update_palette()
@export_color_no_alpha var fabric_color := Color("a16a74"):
	set(value):
		fabric_color = value
		_update_palette()
@export_color_no_alpha var plaster_color := Color("ddcdab"):
	set(value):
		plaster_color = value
		_update_palette()
@export_color_no_alpha var stone_color := Color("b4aa8a"):
	set(value):
		stone_color = value
		_update_palette()
@export_color_no_alpha var roof_color := Color("b8764e"):
	set(value):
		roof_color = value
		_update_palette()

@export_group("Geometry")
## Additional offset from the approved ground anchor; never moves the collider.
@export var visual_offset := Vector2.ZERO:
	set(value):
		visual_offset = value
		_refresh_appearance()
@export var blocks_movement := true:
	set(value):
		blocks_movement = value
		_update_geometry()
## Empty uses the selected view's footprint. A custom shape is never resized.
@export var footprint_shape: Shape2D:
	set(value):
		if is_node_ready() and value == null and $Collision.shape == footprint_shape:
			$Collision.shape = null
		footprint_shape = value
		if footprint_shape != null:
			footprint_shape.resource_local_to_scene = true
		_update_geometry()
## Adjustment to the default footprint center, or the center of a custom shape.
@export var footprint_offset := Vector2.ZERO:
	set(value):
		footprint_offset = value
		_update_geometry()

@export_group("Transparency")
@export var transparency_enabled := true:
	set(value):
		transparency_enabled = value
		_update_geometry()
## Empty uses a zone behind the selected view. A custom shape stays unchanged.
@export var transparency_shape: Shape2D:
	set(value):
		var area := get_node_or_null("TransparencyArea") as TransparencyArea
		if is_node_ready() and value == null and area != null and area.shape == transparency_shape:
			area.shape = null
		transparency_shape = value
		if transparency_shape != null:
			transparency_shape.resource_local_to_scene = true
		_update_geometry()
## Adjustment to the default zone center, or the center of a custom shape.
@export var transparency_offset := Vector2.ZERO:
	set(value):
		transparency_offset = value
		_update_geometry()
@export_range(0.0, 1.0, 0.05) var inside_alpha := 0.2:
	set(value):
		inside_alpha = clampf(value, 0.0, 1.0)
		_update_geometry()
@export_range(0.0, 5.0, 0.05) var fade_duration := 0.2:
	set(value):
		fade_duration = maxf(0.0, value)
		_update_geometry()

var _view: FurnitureView
var _palette: ShaderMaterial
var _syncing_geometry := false

func _ready() -> void:
	# A fresh material per node prevents color changes leaking to other instances.
	_palette = ShaderMaterial.new()
	_palette.shader = PALETTE_SHADER
	$Sprite.material = _palette
	_refresh_appearance()
	notify_property_list_changed()

func _validate_property(property: Dictionary) -> void:
	if property.name in MATERIAL_COLORS and not (paintable_materials & (1 << MATERIAL_COLORS[property.name])):
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["transparency_enabled", "transparency_shape", "transparency_offset", "inside_alpha", "fade_duration"] and not supports_transparency:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _get_design_index() -> int:
	return 0

func apply_group_style(group_style: HouseFurnitureStyle) -> void:
	if designs.size() > 1 and get("style") is int:
		var design := mini(group_style.design, designs.size() - 1)
		if get("style") != design:
			set("style", design)
	for field in MATERIAL_COLORS:
		if (paintable_materials & (1 << MATERIAL_COLORS[field])) != 0 and get(field) != group_style.get(field):
			set(field, group_style.get(field))

func _get_direction_index() -> int:
	return 0

func get_current_view() -> FurnitureView:
	return _view

func _refresh_appearance() -> void:
	if not is_node_ready():
		return
	var sprite := $Sprite as Sprite2D
	var next_view: FurnitureView
	if not designs.is_empty():
		next_view = designs[clampi(_get_design_index(), 0, designs.size() - 1)].get_view(_get_direction_index())
	if _view != next_view:
		sprite.frame = 0
	_view = next_view
	sprite.texture = _view.albedo if _view else null
	sprite.hframes = _view.frames if _view else 1
	sprite.position = (_view.origin if _view else Vector2.ZERO) + visual_offset
	_update_palette()
	_update_geometry()

func _update_palette() -> void:
	if _palette == null:
		return
	_palette.set_shader_parameter("wood_color", wood_color)
	_palette.set_shader_parameter("paint_color", paint_color)
	_palette.set_shader_parameter("fabric_color", fabric_color)
	_palette.set_shader_parameter("plaster_color", plaster_color)
	_palette.set_shader_parameter("stone_color", stone_color)
	_palette.set_shader_parameter("roof_color", roof_color)
	_palette.set_shader_parameter("material_mask", _view.material_mask if _view else null)

func _update_geometry() -> void:
	if not is_node_ready() or _view == null or _syncing_geometry:
		return
	_syncing_geometry = true
	var collision := $Collision as CollisionShape2D
	var size := _view.footprint
	if footprint_shape != null:
		collision.shape = footprint_shape
		collision.position = footprint_offset
	elif _is_default_shape(collision.shape, collision.position):
		collision.position = Vector2(0, -size.y / 2.0) + footprint_offset
		collision.shape = _default_rectangle(size.max(Vector2.ONE), collision.position)
	else:
		# Promote direct child edits to serialized root overrides as well.
		footprint_offset = collision.position
		footprint_shape = collision.shape
	var has_footprint := footprint_shape != null or (size.x > 0 and size.y > 0)
	collision.set_deferred("disabled", not blocks_movement or not has_footprint)
	var area := get_node_or_null("TransparencyArea") as TransparencyArea
	if area == null:
		_syncing_geometry = false
		return
	# Only the inner Shape moves. The component's authored transform is untouched.
	if transparency_shape != null:
		area.shape = transparency_shape
		area.get_node("Shape").position = transparency_offset
	elif _is_default_shape(area.shape, area.get_node("Shape").position):
		var height := maxf(2.0, -_view.origin.y - size.y)
		area.get_node("Shape").position = Vector2(0, _view.origin.y + height / 2.0) + transparency_offset
		area.shape = _default_rectangle(Vector2(minf(size.x, _view.get_frame_size().x), height), area.get_node("Shape").position)
	else:
		transparency_offset = area.get_node("Shape").position
		transparency_shape = area.shape
	area.enabled = transparency_enabled
	area.inside_alpha = inside_alpha
	area.transition_duration = fade_duration
	_syncing_geometry = false

func _is_default_shape(shape: Shape2D, offset: Vector2) -> bool:
	if shape == null:
		return true
	# Metadata survives scene serialization. Direct edits on the component or its
	# shape turn an automatic default into an authored override, including reloads.
	return shape is RectangleShape2D \
		and shape.has_meta("_furniture_default_size") \
		and shape.has_meta("_furniture_default_offset") \
		and shape.get_meta("_furniture_default_size") == shape.size \
		and shape.get_meta("_furniture_default_offset") == offset

func _default_rectangle(size: Vector2, offset: Vector2) -> RectangleShape2D:
	var rectangle := RectangleShape2D.new()
	rectangle.resource_local_to_scene = true
	rectangle.size = size
	rectangle.set_meta("_furniture_default_size", size)
	rectangle.set_meta("_furniture_default_offset", offset)
	return rectangle
