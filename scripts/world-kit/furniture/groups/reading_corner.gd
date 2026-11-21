@tool
extends DecorationGroup

const BOOKCASE = preload("res://scripts/world-kit/furniture/bookcase.gd")
const SIDE_TABLE = preload("res://scripts/world-kit/furniture/bedside_table.gd")

@export_color_no_alpha var lampshade_color := Color("ded1ab"):
	set(value):
		lampshade_color = value
		refresh()

func refresh() -> void:
	super.refresh()
	if not is_node_ready():
		return
	# Reading profiles change the seat; accompanying pieces keep their designs.
	$Bookcase.style = BOOKCASE.Style.WITH_BOOKS
	$SideTable.style = SIDE_TABLE.Style.RUSTIC
	$SideTable/Lamp.fabric_color = lampshade_color
