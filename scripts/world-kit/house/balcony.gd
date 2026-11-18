@tool
class_name HouseBalcony
extends WalkablePlatform

func _ready() -> void:
	configure(HouseDoorStyle.Style.PLANK, Color("ae7d46"), Color("b4aa8a"))

func configure(style: HouseDoorStyle.Style, wood: Color, stone: Color) -> void:
	if not is_node_ready():
		return
	HouseArt.apply($Floor, "plinth_stone", {"stone_color": stone}, true)
	HouseArt.apply($Rail, "balcony_rail", {"paint_color": Color("4d514b"), "stone_color": stone})
	$Door.style = style
	$Door.color = wood
