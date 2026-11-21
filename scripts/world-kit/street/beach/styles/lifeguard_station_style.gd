@tool
class_name BeachLifeguardStationStyle
extends DecorationStyle

@export_group("Design")
@export var tower_style: BeachLifeguardTower.Style = BeachLifeguardTower.Style.COVERED:
	set(value):
		if tower_style == value:
			return
		tower_style = value
		emit_changed()
@export var stand_style: BeachLifebuoyStand.Style = BeachLifebuoyStand.Style.POST:
	set(value):
		if stand_style == value:
			return
		stand_style = value
		emit_changed()

@export_group("Material colors")
@export_color_no_alpha var tower_color := Color("96aeac"):
	set(value):
		if tower_color == value:
			return
		tower_color = value
		emit_changed()
@export_color_no_alpha var stand_color := Color("89a3a4"):
	set(value):
		if stand_color == value:
			return
		stand_color = value
		emit_changed()
@export_color_no_alpha var lifebuoy_color := Color("bf6355"):
	set(value):
		if lifebuoy_color == value:
			return
		lifebuoy_color = value
		emit_changed()

func apply_to(piece: StaticBody2D) -> void:
	if piece is BeachLifeguardTower:
		piece.set_appearance(tower_style, tower_color, lifebuoy_color)
	elif piece is BeachLifebuoyStand:
		piece.set_appearance(stand_style, stand_color, lifebuoy_color)
