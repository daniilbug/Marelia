@tool
extends HouseFurnitureGroup

func refresh() -> void:
	super.refresh()
	if not is_node_ready() or style == null:
		return
	var painting := style.wall_decoration == HouseFurnitureStyle.WallDecoration.PAINTING
	$Clock.visible = not painting
	$Painting.visible = painting
