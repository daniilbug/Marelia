@tool
extends Level

@export_tool_button("Randomize decorations") var randomize_action: Callable = randomize_decorations

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		randomize_decorations()
	super._ready()

func randomize_decorations() -> void:
	for placement in $Placements.get_children():
		if placement is PlacementGroup:
			placement.choose_variant()
			placement.choose_style()
