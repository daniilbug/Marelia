@tool
class_name HouseFacadeStyle
extends Resource

enum Facade { PLASTER, FIELDSTONE }
enum Roof { TILES, COPPI }
enum WindowStyle { LOUVERED, PANELLED, ARCHED }

const FIELDS := ["facade_style", "roof_style", "window_style", "shutters_closed", "facade_color", "roof_color", "shutter_color", "frame_color", "plinth_color"]

@export var facade_style: Facade = Facade.PLASTER
@export var roof_style: Roof = Roof.TILES
@export var window_style: WindowStyle = WindowStyle.LOUVERED
@export var shutters_closed := false
@export_color_no_alpha var facade_color := Color("dec59a")
@export_color_no_alpha var roof_color := Color("b8764e")
@export_color_no_alpha var shutter_color := Color("647f60")
@export_color_no_alpha var frame_color := Color("ae7d46")
@export_color_no_alpha var plinth_color := Color("b4aa8a")

func to_data() -> Dictionary:
	return SaveGraph.get_fields(self, FIELDS)
