@tool
class_name HouseRoomStyle
extends Resource

enum Floor { WOOD, TERRACOTTA, ORNAMENT, WOOD_NARROW, WOOD_CHEVRON, WOOD_BASKET, TILE_CHECKER, TILE_OCTAGON, TILE_MAIOLICA, STONE }
enum Wall { PLASTER, STRIPED, BOTANICAL, FIELDSTONE, LIMESTONE }
const FIELDS := ["floor_material", "floor_color", "wall_style", "wall_color", "accent_color"]
const FLOOR_COLORS := [Color("ae7d46"), Color("b8764e"), Color("b4aa8a"), Color("af8657"), Color("af8657"), Color("af8657"), Color("d3c5a7"), Color("d3c5a7"), Color("d3c5a7"), Color("a69c87")]

@export var floor_material: Floor = Floor.WOOD:
	set(value):
		if floor_material == value:
			return
		if floor_color.is_equal_approx(FLOOR_COLORS[floor_material]):
			floor_color = FLOOR_COLORS[value]
		floor_material = value
		emit_changed()
@export_color_no_alpha var floor_color := Color("ae7d46"):
	set(value):
		if floor_color == value:
			return
		floor_color = value
		emit_changed()
@export var wall_style: Wall = Wall.STRIPED:
	set(value):
		if wall_style == value:
			return
		wall_style = value
		emit_changed()
@export_color_no_alpha var wall_color := Color("ddcdab"):
	set(value):
		if wall_color == value:
			return
		wall_color = value
		emit_changed()
@export_color_no_alpha var accent_color := Color("7d9667"):
	set(value):
		if accent_color == value:
			return
		accent_color = value
		emit_changed()

func _init() -> void:
	resource_local_to_scene = true

func to_data() -> Dictionary:
	return SaveGraph.get_fields(self, FIELDS)

func apply_data(data: Dictionary) -> void:
	SaveGraph.apply_fields(self, FIELDS, data)
