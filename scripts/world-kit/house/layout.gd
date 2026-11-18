@tool
class_name HouseLayout
extends Node2D

## Dimensions of the geometry authored in this scene.
@export var default_size := Vector2(240, 224)
@export var door_variants: HouseDoorVariants
@export var minimum_size := Vector2(208, 184)

var _size := Vector2.ZERO
var _reference: Dictionary = {}

func _ready() -> void:
	_capture_geometry()

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
	resize_to(settings.interior_size)
	for room in get_rooms():
		room.style = settings.get_style(room.room_id)
	for zone in get_floor_zones():
		zone.style = settings.get_style(zone.room_id)
	for wall: HouseWall in $Walls.get_children():
		wall.style = settings.get_style(wall.room_id)
	for door in get_doors():
		door.style = settings.door_style
		door.color = settings.door_color
	var paired := $Exit.connection.get_destination($Exit) as HousePortal if is_instance_valid($Exit.connection) else null
	$Exit.style = paired.style if paired != null else settings.door_style
	$Exit.color = paired.color if paired != null else settings.door_color

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
				group.apply_style_data(choices[style_key])
			else:
				group.choose_style()
				choices[style_key] = group.get_style_data()

func get_door_states() -> Dictionary:
	var states := {}
	for door in get_doors():
		states[str(door.name)] = door.is_open
	return states

func apply_door_states(states: Dictionary) -> void:
	for door in get_doors():
		if states.has(str(door.name)):
			door.is_open = states[str(door.name)]

func _capture_geometry() -> void:
	_size = default_size
	_reference.clear()
	for room in get_rooms():
		_reference[room] = {"position": room.position, "floors": {}}
		for child in room.get_children():
			if child is Polygon2D:
				_reference[room].floors[child] = {"position": child.position, "polygon": child.polygon}
		for group in room.get_placement_groups():
			for point in group.get_points():
				_reference[point] = {"position": point.position}
				for piece in point.find_children("*", "StaticBody2D", true, false):
					if piece is FurniturePiece and piece.get_parent() is not FurniturePiece:
						var parent := piece.get_parent()
						var target: Node2D = parent if parent is HouseFurnitureGroup else piece
						_reference[target] = {"position": to_local(target.global_position)}
	for wall: HouseWall in $Walls.get_children():
		_reference[wall] = {"position": wall.position, "length": wall.length, "openings": wall.openings.duplicate()}
	for door in get_doors():
		_reference[door] = {"position": door.position}
	for marker in _get_markers():
		_reference[marker] = {"position": marker.position}
	for collider in $LevelBounds.get_children():
		if collider is CollisionShape2D:
			_reference[collider] = {"position": collider.position, "size": collider.shape.size}

## Adapts authored geometry without stretching door art or creating geometry.
func resize_to(size: Vector2) -> void:
	if size == Vector2.ZERO:
		size = default_size
	size = size.max(minimum_size)
	if size == _size:
		return
	if _reference.is_empty():
		_capture_geometry()
	var ratio := size / default_size
	var delta := size - default_size
	for room in get_rooms():
		var saved: Dictionary = _reference[room]
		room.position = (saved.position * ratio).round()
		for floor_node: Polygon2D in saved.floors:
			var floor_reference: Dictionary = saved.floors[floor_node]
			var origin: Vector2 = saved.position + floor_reference.position
			floor_node.position = (origin * ratio).round() - room.position
			var polygon := PackedVector2Array()
			for vertex: Vector2 in floor_reference.polygon:
				polygon.append(((origin + vertex) * ratio).round() - room.position - floor_node.position)
			floor_node.polygon = polygon
		for group in room.get_placement_groups():
			for point in group.get_points():
				var origin: Vector2 = saved.position + _reference[point].position
				point.position = (origin * ratio).round() - room.position
	for node in _reference:
		if is_instance_valid(node) and (node is FurniturePiece or node is HouseFurnitureGroup):
			node.global_position = to_global((_reference[node].position * ratio).round())
	for wall: HouseWall in $Walls.get_children():
		var saved: Dictionary = _reference[wall]
		wall.position = (saved.position * ratio).round()
		var axis := 1 if wall.vertical else 0
		var end: Vector2 = saved.position
		end[axis] += saved.length
		var length: float = (end * ratio).round()[axis] - wall.position[axis]
		var openings: Array[float] = []
		for opening: float in saved.openings:
			openings.append(roundf((saved.position[axis] + opening) * ratio[axis]) - wall.position[axis])
		wall.resize_to(length, openings)
	for door in get_doors():
		door.position = (_reference[door].position * ratio).round()
	for marker in _get_markers():
		marker.position = (_reference[marker].position + delta * marker.get_meta("resize_anchor")).round()
	for collider in $LevelBounds.get_children():
		if collider is CollisionShape2D:
			var saved: Dictionary = _reference[collider]
			collider.position = saved.position + delta * collider.get_meta("resize_anchor")
			collider.shape.size = saved.size + delta * collider.get_meta("resize_axis")
	_size = size

func _get_markers() -> Array[Node2D]:
	var markers: Array[Node2D] = [$Exit, $PlayerSpawn, $LevelBounds/BottomLeft, $LevelBounds/TopRight]
	if has_node("Transitions"):
		markers.append($Transitions)
	if has_node("ExitSeal"):
		markers.append($ExitSeal)
	return markers

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
		# Fill the opening with the wall's own material, without an extra sprite.
		var front := $Walls/FrontWall as HouseWall
		var authored: Array[float] = _reference[front].openings
		var openings: Array[float] = []
		if exterior_door:
			for opening in authored:
				openings.append(roundf((_reference[front].position.x + opening) * _size.x / default_size.x) - front.position.x)
		front.openings = openings
