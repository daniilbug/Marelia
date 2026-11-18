@tool
class_name StreetFence
extends StreetProp

enum Style { WOOD, METAL, STONE }

@export_group("Design")
@export var style: Style = Style.WOOD:
	set(value):
		style = value
		_refresh_appearance()
@export_range(1, 128, 1) var sections := 1:
	set(value):
		sections = clampi(value, 1, 128)
		_refresh_appearance()

func _get_design_index() -> int:
	return style

func _get_section_step() -> int:
	var design := get_current_design() as StreetFenceDesign
	return clampi(design.section_step, 1, design.texture.get_width()) if design != null and design.texture != null else 1

func _refresh_appearance() -> void:
	super._refresh_appearance()
	if not is_node_ready():
		return
	var container := $Segments as Node2D
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	var source := $Sprite as Sprite2D
	if source.texture == null:
		return
	var step := _get_section_step()
	var overlap := source.texture.get_width() - step
	for index in range(1, sections):
		var segment := Sprite2D.new()
		segment.texture = source.texture
		segment.material = source.material
		segment.centered = false
		segment.offset = source.offset
		# Crop the shared post so transparency never blends it twice.
		segment.region_enabled = true
		segment.region_rect = Rect2(overlap, 0, step, source.texture.get_height())
		segment.position = Vector2(index * step + overlap, 0)
		container.add_child(segment)

func _update_geometry() -> void:
	super._update_geometry()
	if not is_node_ready():
		return
	var design := get_current_design()
	if design == null or design.texture == null:
		return
	var extra_width := float((sections - 1) * _get_section_step())
	if footprint_shape == null:
		var collision := $Collision as CollisionShape2D
		var shape := collision.shape as RectangleShape2D
		if shape != null:
			shape.size.x = design.footprint.x + extra_width
			collision.position.x = (design.footprint.x + extra_width) / 2.0 + footprint_offset.x
	if transparency_shape == null:
		var area := $TransparencyArea as TransparencyArea
		var shape := area.shape as RectangleShape2D
		if shape != null:
			shape.size.x = design.occlusion_rect.size.x + extra_width
			area.position.x = design.occlusion_rect.get_center().x + extra_width / 2.0 + transparency_offset.x

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super._get_configuration_warnings()
	for design in designs:
		if not design is StreetFenceDesign:
			warnings.append("Assign a fence design with a section step.")
		elif design.texture != null and (design.section_step < 1 or design.section_step > design.texture.get_width()):
			warnings.append("The section step must fit within the fence texture.")
	return warnings
