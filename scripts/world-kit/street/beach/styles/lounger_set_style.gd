@tool
class_name BeachLoungerSetStyle
extends DecorationStyle

@export_group("Design")
@export var lounger_style: BeachLounger.Style = BeachLounger.Style.STRIPED:
	set(value):
		if lounger_style == value:
			return
		lounger_style = value
		emit_changed()
@export var umbrella_style: BeachUmbrella.Style = BeachUmbrella.Style.STRIPED:
	set(value):
		if umbrella_style == value:
			return
		umbrella_style = value
		emit_changed()

@export_group("Material colors")
@export_color_no_alpha var fabric_color := Color("4c7483"):
	set(value):
		if fabric_color == value:
			return
		fabric_color = value
		emit_changed()
@export_color_no_alpha var trim_color := Color("ddd0ac"):
	set(value):
		if trim_color == value:
			return
		trim_color = value
		emit_changed()
@export_color_no_alpha var lounger_frame_color := Color("a77c4f"):
	set(value):
		if lounger_frame_color == value:
			return
		lounger_frame_color = value
		emit_changed()

func apply_to(piece: StaticBody2D) -> void:
	if piece is BeachLounger:
		piece.set_appearance(lounger_style, fabric_color, lounger_frame_color)
	elif piece is BeachUmbrella:
		piece.set_appearance(umbrella_style, fabric_color, trim_color)
