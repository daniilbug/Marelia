extends Main

@export var randomize_facades := true

func _ready() -> void:
	if multiplayer.is_server() and spawn_level != null:
		for child in spawn_level.get_children():
			if child is Building:
				if randomize_facades:
					child.randomize()
				child.randomize_interior()
	super._ready()
