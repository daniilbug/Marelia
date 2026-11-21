@tool
class_name BuildingLayout
extends Node2D

## Optional fallback catalogue for the room doors in this layout.
@export var door_variants: HouseDoorVariants:
	set(value):
		door_variants = value
		if is_node_ready():
			_apply_door_variants()

func _ready() -> void:
	$Exit.set_opening_wall(get_node_or_null("Walls/FrontWall") as HouseWall)
	_apply_door_variants()

func get_rooms() -> Array[HouseRoom]:
	var rooms: Array[HouseRoom] = []
	for child in $Rooms.get_children():
		if child is HouseRoom:
			rooms.append(child)
	return rooms

func get_doors() -> Array[HouseRoomDoor]:
	var doors: Array[HouseRoomDoor] = []
	for child in $Doors.get_children():
		if child is HouseRoomDoor:
			doors.append(child)
	return doors

func get_floor_zones() -> Array[HouseFloorZone]:
	var zones: Array[HouseFloorZone] = []
	for room in get_rooms():
		for child in room.get_children():
			if child is HouseFloorZone:
				zones.append(child)
	return zones

func apply_configuration(settings: BuildingInteriorSettings) -> void:
	for room in get_rooms():
		room.style = settings.get_style(room.room_id)
	for zone in get_floor_zones():
		zone.style = settings.get_style(zone.room_id)
	for wall: HouseWall in $Walls.get_children():
		wall.style = settings.get_style(wall.room_id)

func _apply_door_variants() -> void:
	for door in get_doors():
		door.set_fallback_variants(door_variants)

func select_placements(choices: Dictionary, shared_styles: Dictionary[DecorationVariants, DecorationStyle] = {}) -> void:
	for room in get_rooms():
		for placement in room.get_placements():
			if not (placement is PlacementGroup or placement is FurniturePiece or placement is DecorationGroup) or not placement.visible:
				continue
			var key := str(room.room_id) + "/" + str(placement.name)
			var style_key := key + "/Style"
			if placement is PlacementGroup:
				if choices.has(key) and placement.has_node(NodePath(choices[key])):
					placement.selected_variant = StringName(choices[key])
				else:
					placement.choose_variant()
					choices[key] = str(placement.selected_variant)
			else:
				# Existing saves can still carry a placement marker for fixed furniture.
				choices.erase(key)
				if not placement.randomize_in_layout:
					choices.erase(style_key)
					continue
			_select_furniture_style(placement, placement.style_variants, style_key, choices, shared_styles)

func _select_furniture_style(placement: Node2D, variants: DecorationVariants, key: String, choices: Dictionary, shared_styles: Dictionary[DecorationVariants, DecorationStyle]) -> void:
	if variants != null and shared_styles.has(variants):
		_apply_furniture_style(placement, shared_styles[variants])
		choices.erase(key)
		return
	if choices.has(key):
		var data: Dictionary = choices[key]
		if not data.is_empty():
			if data != _get_furniture_style_data(placement):
				var saved_style := HouseFurnitureStyle.new()
				saved_style.apply_data(data)
				_apply_furniture_style(placement, saved_style)
			return
		# Older saves could store an empty style for a group containing only furniture pieces.
		if variants is not HouseFurnitureVariants:
			return
	var style := variants.choose_style() if variants != null else null
	if style is HouseFurnitureStyle:
		_apply_furniture_style(placement, style)
		choices[key] = style.to_data()
	elif placement is PlacementGroup:
		_apply_furniture_style(placement, style)
		choices[key] = _get_furniture_style_data(placement)

func _apply_furniture_style(placement: Node2D, style: DecorationStyle) -> void:
	if placement is PlacementGroup:
		placement.apply_style(style)
	elif placement is DecorationGroup:
		placement.apply_placement_style(style)
	elif placement is FurniturePiece:
		style.apply_to(placement)

func _get_furniture_style_data(placement: Node2D) -> Dictionary:
	if placement is DecorationGroup and placement.style is HouseFurnitureStyle:
		return placement.style.to_data()
	if placement is PlacementGroup:
		var point: Marker2D = placement.get_selected_point()
		if point != null:
			for instance in point.get_children():
				if instance is DecorationGroup and instance.style is HouseFurnitureStyle:
					return instance.style.to_data()
	return {}

func get_door_states() -> Dictionary:
	var states := {}
	for door in get_doors():
		states[str(door.name)] = door.is_open
	return states

func apply_door_states(states: Dictionary) -> void:
	for door in get_doors():
		if states.has(str(door.name)):
			door.is_open = states[str(door.name)]

func configure_access(exterior_door: bool, upstairs: bool, downstairs: bool) -> void:
	$Exit.visible = exterior_door
	$Exit.enabled = exterior_door
	$Exit.process_mode = Node.PROCESS_MODE_INHERIT if exterior_door else Node.PROCESS_MODE_DISABLED
	if has_node("Transitions"):
		for child in $Transitions.get_children():
			var active := upstairs if child.name == &"StairsUp" else downstairs
			child.visible = active
			child.enabled = active
			child.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if has_node("ExitSeal"):
		$ExitSeal.process_mode = Node.PROCESS_MODE_DISABLED if exterior_door else Node.PROCESS_MODE_INHERIT
		# Seal the passage visually using the front wall's material.
		$Walls/FrontWall.show_openings = exterior_door
