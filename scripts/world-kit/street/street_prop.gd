@tool
class_name StreetProp
extends StaticBody2D

const PALETTE_SHADER = preload("res://assets/world-kit/street/shaders/street_palette.gdshader")
const MATERIAL_COLORS := {"body_color": 1, "support_color": 2}

@export_storage var designs: Array[StreetPropDesign] = []
@export_storage var paintable_materials := 6
@export_storage var supports_transparency := false

@export_group("Material colors")
@export_color_no_alpha var body_color := Color("687d53"):
	set(value):
		body_color = value
		_update_palette()
@export_color_no_alpha var support_color := Color("414a3c"):
	set(value):
		support_color = value
		_update_palette()

@export_group("Geometry")
@export var footprint_shape: Shape2D:
	set(value):
		footprint_shape = value
		_update_geometry()
@export var footprint_offset := Vector2.ZERO:
	set(value):
		footprint_offset = value
		_update_geometry()
@export_range(-180.0, 180.0, 0.1, "radians_as_degrees") var footprint_rotation := 0.0:
	set(value):
		footprint_rotation = value
		_update_geometry()

@export_group("Transparency")
@export var transparency_enabled := true:
	set(value):
		transparency_enabled = value
		_update_geometry()
@export var transparency_shape: Shape2D:
	set(value):
		transparency_shape = value
		_update_geometry()
@export var transparency_offset := Vector2.ZERO:
	set(value):
		transparency_offset = value
		_update_geometry()

var _design: StreetPropDesign
var _palette: ShaderMaterial

func _ready() -> void:
	# Every instance owns its palette; changing a style never resets its colors.
	if paintable_materials != 0:
		_palette = ShaderMaterial.new()
		_palette.shader = PALETTE_SHADER
	$Sprite.material = _palette
	_refresh_appearance()
	notify_property_list_changed()

func _validate_property(property: Dictionary) -> void:
	if property.name in MATERIAL_COLORS and not (paintable_materials & (1 << MATERIAL_COLORS[property.name])):
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["transparency_enabled", "transparency_shape", "transparency_offset"] and not supports_transparency:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _get_design_index() -> int:
	return 0

func get_current_design() -> StreetPropDesign:
	return _design

func _refresh_appearance() -> void:
	if not is_node_ready():
		return
	_design = designs[clampi(_get_design_index(), 0, designs.size() - 1)] if not designs.is_empty() else null
	$Sprite.texture = _design.texture if _design != null else null
	$Sprite.offset = _design.origin if _design != null else Vector2.ZERO
	_update_palette()
	_update_geometry()
	update_configuration_warnings()

func _update_palette() -> void:
	if _palette == null:
		return
	_palette.set_shader_parameter("body_color", body_color)
	_palette.set_shader_parameter("support_color", support_color)
	_palette.set_shader_parameter("material_mask", _design.material_mask if _design != null else null)
	if _design != null:
		_palette.set_shader_parameter("source_body_color", _design.source_body_color)
		_palette.set_shader_parameter("source_support_color", _design.source_support_color)

func _update_geometry() -> void:
	if not is_node_ready():
		return
	var collision := $Collision as CollisionShape2D
	var area := get_node_or_null("TransparencyArea") as TransparencyArea
	if _design == null:
		collision.set_deferred("disabled", true)
		if area != null:
			area.enabled = false
		return
	if footprint_shape != null:
		collision.shape = footprint_shape
		collision.position = footprint_offset
		collision.rotation = footprint_rotation
	else:
		if _design.footprint_shape != null:
			# Shape edits on one instance must not modify the shared style resource.
			collision.shape = _design.footprint_shape.duplicate()
		else:
			var shape := RectangleShape2D.new()
			shape.size = _design.footprint.max(Vector2.ONE)
			collision.shape = shape
		collision.position = Vector2(0, -_design.footprint.y / 2.0) + footprint_offset
		collision.rotation = _design.footprint_rotation
	collision.set_deferred("disabled", _design.footprint == Vector2.ZERO and footprint_shape == null and _design.footprint_shape == null)
	if area == null:
		return
	if transparency_shape != null:
		area.shape = transparency_shape
		area.position = transparency_offset
	else:
		var shape := RectangleShape2D.new()
		shape.size = _design.occlusion_rect.size.max(Vector2.ONE)
		area.shape = shape
		area.position = _design.occlusion_rect.get_center() + transparency_offset
	area.enabled = supports_transparency and transparency_enabled and (_design.occlusion_rect.has_area() or transparency_shape != null)

func _get_configuration_warnings() -> PackedStringArray:
	if designs.is_empty():
		return PackedStringArray(["Assign at least one street prop design."])
	for design in designs:
		if design == null or design.texture == null:
			return PackedStringArray(["Assign a texture to each design."])
		if paintable_materials != 0 and design.material_mask == null:
			return PackedStringArray(["Assign a material mask to each paintable design."])
	return PackedStringArray()
