@tool
extends DecorationGroup

func _get_piece_visibility(piece: StaticBody2D, fallback: bool) -> bool:
	var profile := style as HouseFurnitureStyle
	if profile == null:
		return fallback
	var painting := profile.wall_decoration == HouseFurnitureStyle.WallDecoration.PAINTING
	if piece == $Clock:
		return not painting
	if piece == $Painting:
		return painting
	return fallback
