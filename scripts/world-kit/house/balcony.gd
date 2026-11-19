@tool
class_name HouseBalcony
extends WalkablePlatform

func _ready() -> void:
	configure(Color("b4aa8a"))

func configure(stone: Color) -> HousePortal:
	HouseArt.apply($Floor, "plinth_stone", {"stone_color": stone}, true)
	HouseArt.apply($Rail, "balcony_rail", {"paint_color": Color("4d514b"), "stone_color": stone})
	return $Door as HousePortal
