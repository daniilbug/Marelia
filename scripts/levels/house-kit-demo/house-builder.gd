extends Main

func _ready() -> void:
	if multiplayer.is_server():
		for child in spawn_level.get_children():
			if child is HouseFacade:
				child.randomize()
				child.randomize_interior()
	super._ready()
