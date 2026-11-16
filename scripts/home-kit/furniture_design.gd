@tool
class_name FurnitureDesign
extends Resource

@export var title := ""
## Down, up, left, right; a single view is used for non-directional objects.
@export var views: Array[FurnitureView] = []

func get_view(direction: int) -> FurnitureView:
	if views.is_empty():
		return null
	return views[clampi(direction, 0, views.size() - 1)]
