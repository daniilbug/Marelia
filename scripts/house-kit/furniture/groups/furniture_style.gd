@tool
class_name HouseFurnitureStyle
extends Resource

enum Design { RUSTIC, CLASSIC, DECORATIVE }
enum RugDesign { GEOMETRIC, MEDALLION, WOVEN_STRIPES, OVAL_FLORAL }
enum PaintingDesign { COUNTRYSIDE, HARBOR, VINEYARD, LEMONS }

const FIELDS := ["design", "wood_color", "paint_color", "fabric_color", "plaster_color", "stone_color", "roof_color", "rug_style", "painting_style", "pattern_color"]

@export var design: Design = Design.RUSTIC:
	set(value):
		if design == value:
			return
		design = value
		emit_changed()
@export_color_no_alpha var wood_color := Color("ae7d46"):
	set(value):
		if wood_color == value:
			return
		wood_color = value
		emit_changed()
@export_color_no_alpha var paint_color := Color("799080"):
	set(value):
		if paint_color == value:
			return
		paint_color = value
		emit_changed()
@export_color_no_alpha var fabric_color := Color("7d9667"):
	set(value):
		if fabric_color == value:
			return
		fabric_color = value
		emit_changed()
@export_color_no_alpha var plaster_color := Color("ddcdab"):
	set(value):
		if plaster_color == value:
			return
		plaster_color = value
		emit_changed()
@export_color_no_alpha var stone_color := Color("c3b89c"):
	set(value):
		if stone_color == value:
			return
		stone_color = value
		emit_changed()
@export_color_no_alpha var roof_color := Color("b8764e"):
	set(value):
		if roof_color == value:
			return
		roof_color = value
		emit_changed()

@export_group("Decoration")
@export var rug_style: RugDesign = RugDesign.GEOMETRIC:
	set(value):
		if rug_style == value:
			return
		rug_style = value
		emit_changed()
@export var painting_style: PaintingDesign = PaintingDesign.COUNTRYSIDE:
	set(value):
		if painting_style == value:
			return
		painting_style = value
		emit_changed()
@export_color_no_alpha var pattern_color := Color("d2bd97"):
	set(value):
		if pattern_color == value:
			return
		pattern_color = value
		emit_changed()

func _init() -> void:
	resource_local_to_scene = true

func to_data() -> Dictionary:
	return SaveGraph.get_fields(self, FIELDS)

func apply_data(data: Dictionary) -> void:
	SaveGraph.apply_fields(self, FIELDS, data)
