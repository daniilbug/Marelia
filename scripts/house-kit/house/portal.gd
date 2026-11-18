@tool
class_name HousePortal
extends LevelTransition

@export var style: HouseDoorStyle.Style = HouseDoorStyle.Style.PLANK:
	set(value):
		if style == value:
			return
		style = value
		_refresh_art()
@export_color_no_alpha var color := Color("ae7d46"):
	set(value):
		if color == value:
			return
		color = value
		_refresh_art()

func _ready() -> void:
	_refresh_art()

func _refresh_art() -> void:
	if is_node_ready():
		HouseArt.apply($Sprite, HouseArt.DOORS[style] + "_closed", {"wood_color": color, "paint_color": color})
