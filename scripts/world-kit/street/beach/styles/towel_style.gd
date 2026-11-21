@tool
class_name BeachTowelStyle
extends DecorationStyle

@export_group("Design")
@export var style: BeachTowel.Style = BeachTowel.Style.STRIPED:
	set(value):
		style = value
		emit_changed()

@export_group("Material colors")
@export_color_no_alpha var fabric_color := Color("b87560"):
	set(value):
		fabric_color = value
		emit_changed()
@export_color_no_alpha var trim_color := Color("e4d2ac"):
	set(value):
		trim_color = value
		emit_changed()

func apply_to(piece: StaticBody2D) -> void:
	if piece is BeachTowel:
		piece.set_appearance(style, fabric_color, trim_color)
