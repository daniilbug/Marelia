@tool
class_name HouseStairs
extends LevelTransition

## Selects the artwork; passage geometry is authored in the scene's children.
@export var descending := false
@export_color_no_alpha var wood_color := Color("ae7d46"):
	set(value):
		wood_color = value
		_refresh_art()

func _ready() -> void:
	_refresh_art()

func _on_body_entered(body: Node2D) -> void:
	if body is Player and multiplayer.is_server():
		# Create the destination after physics has finished reporting overlaps.
		_activate.call_deferred(body)

func _refresh_art() -> void:
	if not is_node_ready():
		return
	var stem := "stairs_down" if descending else "stairs_up"
	HouseArt.apply($Sprite, stem, {"wood_color": wood_color})
