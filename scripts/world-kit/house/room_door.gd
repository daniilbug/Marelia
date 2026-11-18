@tool
class_name HouseRoomDoor
extends "res://scripts/core/door.gd"

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
	state_changed.connect(_show_state)
	_refresh_art()
	super._ready()
	# Initial state travels with the lazy level. Only later changes use RPCs,
	# so a late peer never receives a synchronizer path before the level exists.
	if not Engine.is_editor_hint():
		state_changed.connect(_broadcast_state)

func _refresh_art() -> void:
	if not is_node_ready():
		return
	var colors := {"wood_color": color, "paint_color": color}
	HouseArt.apply($Closed, HouseArt.DOORS[style] + "_closed", colors)
	HouseArt.apply($Open, HouseArt.DOORS[style] + "_open", colors)

func _broadcast_state(open: bool) -> void:
	if multiplayer.is_server():
		_receive_state.rpc(open)

@rpc("authority", "reliable")
func _receive_state(open: bool) -> void:
	is_open = open

func _show_state(open: bool) -> void:
	$Closed.visible = not open
	$Open.visible = open
	$TransparencyArea/Shape.set_deferred("disabled", open)
	$TransparencyArea/LeftLeaf.set_deferred("disabled", not open)
	$TransparencyArea/RightLeaf.set_deferred("disabled", not open)
