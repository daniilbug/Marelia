@tool
class_name UninhabitableHouse
extends HouseFacade

const COMPONENT_FIELDS := ["wall_variant", "roof_variant", "left_window_variant", "right_window_variant", "door_variant"]
const STYLE_COMPONENT_FIELDS := ["wall_variant", "roof_variant", "left_window_variant", "right_window_variant"]
const DAMAGE_FIELDS := ["style", "wall_variant", "roof_variant", "left_window_variant", "right_window_variant", "door_variant", "wall_texture_offset", "roof_texture_offset", "mirror_left_window", "mirror_right_window", "restored"]
const HEALTHY_FIELDS := ["facade_style", "roof_style", "window_style", "door_style", "shutters_closed"]

@export_group("Condition")
@export var restored := false:
	set(value):
		restored = value
		notify_property_list_changed()
		_schedule_refresh()

@export_group("Damage")
@export var designs: Array[UninhabitableHouseDesign] = []:
	set(value):
		designs = value
		notify_property_list_changed()
		_schedule_refresh()
@export var style := 0:
	set(value):
		if style == value:
			return
		style = value
		for field in STYLE_COMPONENT_FIELDS:
			set(field, -1)
		_schedule_refresh()

@export_subgroup("Component overrides")
@export var wall_variant := -1:
	set(value):
		wall_variant = value
		_schedule_refresh()
@export var roof_variant := -1:
	set(value):
		roof_variant = value
		_schedule_refresh()
@export var left_window_variant := -1:
	set(value):
		left_window_variant = value
		_schedule_refresh()
@export var right_window_variant := -1:
	set(value):
		right_window_variant = value
		_schedule_refresh()
@export var door_variant := -1:
	set(value):
		door_variant = value
		_schedule_refresh()

@export_subgroup("Texture placement")
@export var wall_texture_offset := Vector2.ZERO:
	set(value):
		wall_texture_offset = value.round()
		_schedule_refresh()
@export var roof_texture_offset := Vector2.ZERO:
	set(value):
		roof_texture_offset = value.round()
		_schedule_refresh()
@export var mirror_left_window := false:
	set(value):
		mirror_left_window = value
		_schedule_refresh()
@export var mirror_right_window := true:
	set(value):
		mirror_right_window = value
		_schedule_refresh()

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	if property.name == "style" or property.name in COMPONENT_FIELDS:
		var options := PackedStringArray()
		if property.name != "style":
			options.append("Use Door Style:-1" if property.name == "door_variant" else "Use Style:-1")
		for index in designs.size():
			var design := designs[index]
			var label := design.resource_name if design != null else "Missing design"
			label = label.replace(",", " ").replace(":", " ")
			options.append("%s:%d" % [label if not label.is_empty() else "Style %d" % index, index])
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(options)
	if (not restored and property.name in HEALTHY_FIELDS) or (restored and property.name in DAMAGE_FIELDS and property.name != "restored"):
		property.usage &= ~PROPERTY_USAGE_EDITOR

func _get_appearance_fields() -> Array:
	return super._get_appearance_fields() + DAMAGE_FIELDS

func _portal_variant_seed(index: int) -> int:
	return super._portal_variant_seed(index) if restored else -1

func _design(variant: int, default_style := -1) -> UninhabitableHouseDesign:
	if designs.is_empty():
		return null
	var fallback := style if default_style < 0 else default_style
	return designs[clampi(fallback if variant < 0 else variant, 0, designs.size() - 1)]

func _refresh() -> void:
	super._refresh()
	if not is_node_ready():
		return
	var portals: Array[HousePortal] = [$Entrance]
	for balcony in $Balconies.get_children():
		portals.append(balcony.get_node("Door") as HousePortal)
	for portal in portals:
		portal.enabled = restored
	for floor_node in $Visuals/Floors.get_children():
		floor_node.get_node("LeftWindow").flip_h = false
		floor_node.get_node("RightWindow").flip_h = false
	if restored:
		update_configuration_warnings()
		return
	var roof_design := _design(roof_variant)
	if roof_design != null:
		roof_design.apply_part($Visuals/Roof, "roof")
		$Visuals/Roof.region_rect.position = roof_texture_offset
	for floor_node in $Visuals/Floors.get_children():
		var wall_design := _design(wall_variant)
		if wall_design != null:
			wall_design.apply_part(floor_node.get_node("Wall"), "wall")
			floor_node.get_node("Wall").region_rect.position = wall_texture_offset
		for side in 2:
			var window := floor_node.get_node(["LeftWindow", "RightWindow"][side]) as Sprite2D
			var design := _design(left_window_variant if side == 0 else right_window_variant)
			if design != null:
				design.apply_part(window, "window")
			window.position.x = house_width * [-0.28, 0.28][side] - window.texture.get_width() / 2.0
			window.flip_h = mirror_left_window if side == 0 else mirror_right_window
	var door_design := _design(door_variant, door_style)
	if door_design != null:
		for portal in portals:
			door_design.apply_part(portal.get_node("Sprite"), "door")
	update_configuration_warnings()

func _build_connections() -> void:
	if restored:
		super._build_connections()
		return
	for link in $Connections.get_children():
		$Connections.remove_child(link)
		link.queue_free()

func _randomize_doors() -> void:
	super._randomize_doors()
	door_variant = -1

func can_restore_save_data(data: Dictionary) -> bool:
	if not super.can_restore_save_data(data):
		return false
	var appearance: Dictionary = data.appearance
	if appearance.style < 0 or appearance.style >= designs.size():
		return false
	for field in COMPONENT_FIELDS:
		if appearance[field] < -1 or appearance[field] >= designs.size():
			return false
	return true

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if designs.is_empty():
		warnings.append("Assign at least one approved damage design.")
	elif style < 0 or style >= designs.size():
		warnings.append("Select an available damage style.")
	for design in designs:
		if design == null or not design.is_complete():
			warnings.append("Each damage design needs matching albedo and material-mask textures for all four parts.")
	for field in COMPONENT_FIELDS:
		if get(field) < -1 or get(field) >= designs.size():
			warnings.append("Select an available component variant: " + str(field))
	return warnings
