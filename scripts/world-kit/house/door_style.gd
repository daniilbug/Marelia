@tool
class_name HouseDoorStyle
extends Resource

enum Style { PLANK, PANEL, GLAZED }

@export var style: Style = Style.PLANK
@export_color_no_alpha var color := Color("ae7d46")
