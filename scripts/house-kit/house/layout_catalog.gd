@tool
class_name HouseLayoutCatalog
extends Resource

## Layout references are authored in a resource assigned by the house scene.
@export var scenes: Dictionary[StringName, PackedScene] = {}:
	set(value):
		scenes = value
		emit_changed()
