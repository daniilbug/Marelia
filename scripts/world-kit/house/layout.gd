@tool
class_name HouseLayout
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

func apply_configuration(settings: HouseInteriorSettings) -> void:
	for room in get_rooms():
		room.style = settings.get_style(room.room_id)
	for zone in get_floor_zones():
		zone.style = settings.get_style(zone.room_id)
	for wall: HouseWall in $Walls.get_children():
		wall.style = settings.get_style(wall.room_id)

func _apply_door_variants() -> void:
	for door in get_doors():
		door.set_fallback_variants(door_variants)

func select_placements(choices: Dictionary) -> void:
	for room in get_rooms():
		for group in room.get_placement_groups():
			if not group.visible:
				continue
			var key := str(room.room_id) + "/" + str(group.name)
			if choices.has(key) and group.has_node(NodePath(choices[key])):
				group.selected_variant = StringName(choices[key])
			else:
				group.choose_variant()
				choices[key] = str(group.selected_variant)
			var style_key := key + "/Style"
			if choices.has(style_key):
				var data: Dictionary = choices[style_key]
				if not data.is_empty() and data != _get_furniture_style_data(group):
					var style := HouseFurnitureStyle.new()
					style.apply_data(data)
					group.apply_style(style)
			else:
				group.choose_style()
				choices[style_key] = _get_furniture_style_data(group)

func _get_furniture_style_data(group: PlacementGroup) -> Dictionary:
	var point := group.get_selected_point()
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
