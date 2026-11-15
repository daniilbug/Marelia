class_name DropPlace
extends Node2D

@onready var shape: CollisionShape2D = $Area/Shape

func can_accept(item: Draggable) -> bool:
	var level := Level.find_level_node(self)
	for child in level.get_children():
		if child is Draggable and child != item and child.holder_peer_id == 0 and child.dock_path == level.get_path_to(self):
			return false
	return true
