@tool
class_name BeachTowelStyle
extends BeachDecorationStyle

@export_group("Design")
@export var style: BeachTowel.Style = BeachTowel.Style.STRIPED

@export_group("Material colors")
@export_color_no_alpha var fabric_color := Color("b87560")
@export_color_no_alpha var trim_color := Color("e4d2ac")
