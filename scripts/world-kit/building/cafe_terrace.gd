@tool
extends Node2D

func set_appearance_seed(seed_value: int) -> void:
	var left := $LeftPlant as FurniturePiece
	var right := $RightPlant as FurniturePiece
	if left.style_variants == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var profile := left.style_variants.choose_style(rng)
	if profile != null:
		profile.apply_to(left)
		profile.apply_to(right)
