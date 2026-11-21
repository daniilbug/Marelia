class_name Player
extends CharacterBody2D

enum Gender { MALE, FEMALE }

static var local_setup: Dictionary = {"name": "Player"}

const SPEED := 350.0
const FPS_WALK := 8.0
const FPS_SWIM := 8.0
const FPS_TREAD_WATER := 4.0
const MOVEMENT_SOUND_GAP := 0.2
const SAVE_SCHEMA := {
	"player_name": "", "level_id": "", "position": Vector2.ZERO,
	"direction": Vector2.ZERO,
	"appearance": {"hair_id": 0, "hair_color_id": 0, "top_id": 0, "top_color_id": 0, "pants_id": 0, "pants_color_id": 0},
}
const SAVE_APPEARANCE: Array[String] = ["hair_id", "hair_color_id", "top_id", "top_color_id", "pants_id", "pants_color_id", "gender", "skin_tone_id"]

const ROW_WALK_S  := 0
const ROW_WALK_N  := 1
const ROW_WALK_W  := 2
const ROW_WALK_E  := 3
const ROW_IDLE    := 4
const ROW_SIT     := 5

@export var is_sitting := false
var seated_seat: Seat = null

signal level_changed

@export var level_id := "sandbox":
	set(value):
		if level_id == value:
			return
		level_id = value
		if is_node_ready():
			_refresh_platform()
			level_changed.emit()

@export var platform_path: NodePath:
	set(value):
		platform_path = value
		if is_node_ready():
			_refresh_platform()
var _platform: WalkablePlatform

# A garment is its existing atlas style ID and fixed fabric color ID.
# These inventories, like appearance, are owned by the server.
@export var owned_tops: Array[Vector2i] = []
@export var owned_bottoms: Array[Vector2i] = []

@export var gender := Gender.MALE:
	set(value):
		gender = value
		_refresh_appearance()

@export var skin_tone_id := CharacterSprite.DEFAULT_SKIN_TONE:
	set(value):
		skin_tone_id = value
		_refresh_appearance()

@export var hair_id: int = 0:
	set(value):
		hair_id = value
		_refresh_appearance()

@export var hair_color_id: int = 2:
	set(value):
		hair_color_id = value
		_refresh_appearance()

@export var top_id: int = 0:
	set(value):
		top_id = value
		_refresh_appearance()

@export var top_color_id: int = 4:
	set(value):
		top_color_id = value
		_refresh_appearance()

@export var pants_id: int = 0:
	set(value):
		pants_id = value
		_refresh_appearance()

@export var pants_color_id: int = 3:
	set(value):
		pants_color_id = value
		_refresh_appearance()

var player_name: String = ""


@export var direction := Vector2.DOWN

@export_storage var is_swimming := false:
	set(value):
		if is_swimming == value:
			return
		is_swimming = value
		if is_node_ready():
			sprite.set_swimming(is_swimming)

@onready var sprite: CharacterSprite = $Sprite
@onready var hands: Node2D = $Hands
@onready var interaction_area: Area2D = $InteractionArea
@onready var camera: Camera2D = get_node_or_null("Camera")
@onready var _movement_audio: AudioStreamPlayer2D = get_node_or_null("MovementAudio")

var _hands_item: Draggable = null
var is_world_input_blocked := false

var _anim_t := 0.0
var _anim_row := ROW_IDLE
var _is_moving := false
var _movement_sound_cooldown := 0.0
var _water_query := PhysicsPointQueryParameters2D.new()
var _idle_tween: Tween

signal appearance_changed

func _enter_tree() -> void:
	set_multiplayer_authority(int(name), true)
	$AppearanceSynchronizer.set_multiplayer_authority(1)

func _ready() -> void:
	_water_query.collision_mask = WaterSurface.SWIM_COLLISION_LAYER
	_water_query.collide_with_areas = true
	_water_query.collide_with_bodies = false
	_refresh_appearance()
	_start_idle_bob()
	if is_swimming:
		sprite.set_swimming(true)
	call_deferred("_setup_authority")
	_refresh_platform()

func get_platform() -> WalkablePlatform:
	return _platform if is_instance_valid(_platform) else null

func _exit_tree() -> void:
	if is_instance_valid(_platform):
		_platform.detach_player(self)

func _get_level() -> Level:
	var world := get_parent() as Main
	return world.get_level(level_id) if world != null else Level.find_level_node(self)

func _refresh_platform() -> void:
	var level := _get_level()
	var next: WalkablePlatform = level.get_node_or_null(platform_path) as WalkablePlatform if level != null and not platform_path.is_empty() else null
	if next == get_platform():
		return
	if is_instance_valid(_platform):
		_platform.detach_player(self)
	_platform = next
	if _platform != null:
		_platform.attach_player(self)

func randomize_appearance(randomize_gender := true) -> void:
	if randomize_gender:
		gender = Gender.MALE if randi_range(0, 1) == 0 else Gender.FEMALE
	hair_id = randi_range(0, CharacterSprite.HAIR_TEXTURES.size() - 1)
	hair_color_id = randi_range(0, CharacterSprite.HAIR_COLORS.size() - 1)
	top_id = randi_range(0, CharacterSprite.TOP_TEXTURES.size() - 1)
	pants_id = randi_range(0, CharacterSprite.PANTS_TEXTURES.size() - 1)
	top_color_id = randi_range(0, CharacterSprite.CLOTHING_COLORS.size() - 1)
	pants_color_id = randi_range(0, CharacterSprite.CLOTHING_COLORS.size() - 1)

func _refresh_appearance() -> void:
	if is_node_ready():
		sprite.set_appearance(hair_id, top_id, pants_id, hair_color_id, top_color_id, pants_color_id, gender == Gender.FEMALE)
		sprite.set_skin_tone(skin_tone_id)
		appearance_changed.emit()

func initialize_wardrobe() -> void:
	for is_top in [true, false]:
		var items := owned_tops if is_top else owned_bottoms
		if not items.is_empty():
			continue
		var current := Vector2i(top_id, top_color_id) if is_top else Vector2i(pants_id, pants_color_id)
		items.append(current)

static func is_valid_wardrobe(data: Variant) -> bool:
	if not SaveGraph.matches(data, {"tops": [], "bottoms": []}):
		return false
	for slot in ["tops", "bottoms"]:
		var count := CharacterSprite.TOP_TEXTURES.size() if slot == "tops" else CharacterSprite.PANTS_TEXTURES.size()
		var items: Array = data[slot]
		if items.is_empty() or items.size() > count * CharacterSprite.CLOTHING_COLORS.size():
			return false
		var seen := {}
		for item in items:
			if item is not Vector2i or item.x < 0 or item.x >= count \
				or item.y < 0 or item.y >= CharacterSprite.CLOTHING_COLORS.size() or seen.has(item):
				return false
			seen[item] = true
	return true

func _setup_authority() -> void:
	if is_multiplayer_authority():
		camera.make_current()

func get_save_data() -> Dictionary:
	var level := _get_level()
	return {
		"player_name": player_name, "level_id": level_id,
		"position": level.to_local(global_position), "direction": direction,
		"platform_path": platform_path,
		"appearance": SaveGraph.get_fields(self, SAVE_APPEARANCE),
		"wardrobe": {"tops": owned_tops.duplicate(), "bottoms": owned_bottoms.duplicate()},
	}

func apply_save_data(data: Dictionary) -> void:
	player_name = data.player_name
	level_id = data.level_id
	platform_path = data.get("platform_path", NodePath())
	direction = data.get("direction", Vector2.DOWN)
	apply_appearance(data.get("appearance", {}))
	if data.has("wardrobe"):
		owned_tops.assign(data.wardrobe.tops)
		owned_bottoms.assign(data.wardrobe.bottoms)

func apply_appearance(appearance: Dictionary) -> void:
	SaveGraph.apply_fields(self, SAVE_APPEARANCE, appearance)

func _start_idle_bob() -> void:
	if _idle_tween != null:
		_idle_tween.kill()
	_anim_row = _dir_to_idle_row(direction)
	sprite.frame = _anim_row * 4
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(sprite, "scale:y", 0.95, 0.45).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(sprite, "scale:y", 1.0, 0.45).set_trans(Tween.TRANS_SINE)

func _physics_process(delta: float) -> void:
	_movement_sound_cooldown = maxf(0.0, _movement_sound_cooldown - delta)
	if not is_multiplayer_authority():
		return
	var input_blocked := is_world_input_blocked
	var dir := Vector2.ZERO if input_blocked else Input.get_vector("left", "right", "up", "down")
	if is_sitting:
		velocity = Vector2.ZERO
		if dir != Vector2.ZERO:
			_stand_up()
		return

	velocity = dir * SPEED
	if not input_blocked:
		move_and_slide()
	var water := _get_water_surface()
	_update_swimming_state(water != null)
	var moved := not input_blocked and get_position_delta().dot(dir) > 0.01
	var can_play_sound := moved and _movement_sound_cooldown == 0.0
	if water != null:
		var stroked := _animate_swimming(delta, dir)
		if stroked and can_play_sound:
			_play_movement_sound(water.swim_stroke_sound)
	else:
		var stepped := _animate_movement(delta, dir)
		if stepped and can_play_sound:
			_play_footstep()

func _play_footstep() -> void:
	var level := _get_level()
	if level == null or get_platform() != null:
		return
	var surface := Surface.find_at(level, global_position)
	if _play_surface_footstep(surface) and not multiplayer.get_peers().is_empty():
		_receive_footstep.rpc(level.level_id, level.get_path_to(surface))

@rpc("authority", "call_remote", "reliable")
func _receive_footstep(step_level_id: String, surface_path: NodePath) -> void:
	if _movement_sound_cooldown > 0.0:
		return
	var level := _get_level()
	if level == null or level.level_id != step_level_id or level.local_player == null:
		return
	var surface := level.get_node_or_null(surface_path) as Surface
	if surface != null and surface.is_visible_in_tree() and Level.find_level_node(surface) == level:
		_play_surface_footstep(surface)

func _play_surface_footstep(surface: Surface) -> bool:
	return surface != null and _play_movement_sound(surface.get_footstep_sound())

func _play_movement_sound(sound: AudioStream) -> bool:
	if _movement_audio == null or sound == null:
		return false
	_movement_audio.stream = sound
	_movement_audio.play()
	_movement_sound_cooldown = sound.get_length() + MOVEMENT_SOUND_GAP
	return true

func _update_swimming_state(in_water: bool) -> void:
	if is_swimming == in_water:
		return

	is_swimming = in_water
	_is_moving = false
	_anim_t = 0.0
	if is_swimming:
		_idle_tween.pause()
	else:
		_start_idle_bob()

func _get_water_surface() -> WaterSurface:
	var level := _get_level()
	if level == null or get_platform() != null:
		return null
	# The player origin is at the feet, so overlap with the body does not trigger swimming.
	_water_query.position = global_position
	for hit in get_world_2d().direct_space_state.intersect_point(_water_query):
		var water := hit.collider as WaterSurface
		if water != null and Level.find_level_node(water) == level:
			return water
	return null

func _animate_swimming(delta: float, dir: Vector2) -> bool:
	var moving := dir != Vector2.ZERO
	if moving != _is_moving:
		_is_moving = moving
		_anim_t = 0.0
	if moving:
		direction = dir
	var fps := FPS_SWIM if moving else FPS_TREAD_WATER
	var previous_phase := int(_anim_t * fps)
	_anim_t = fposmod(_anim_t + delta, CharacterSprite.SWIM_PHASE_COUNT / fps)
	var phase := int(_anim_t * fps)
	sprite.set_swim_frame(_dir_to_idle_row(direction), moving, phase)
	# In phase 2 the arms sweep through the water.
	return moving and phase == 2 and phase != previous_phase

func _animate_movement(delta: float, dir: Vector2) -> bool:
	var walking := dir != Vector2.ZERO
	if walking != _is_moving:
		_is_moving = walking
		if walking:
			_idle_tween.pause()
			sprite.scale.y = 1.0
			_anim_t = 0.0
		else:
			_idle_tween.play()
			_anim_row = _dir_to_idle_row(direction)
			sprite.frame = _anim_row * 4
	if not walking:
		return false

	var previous_frame := int(_anim_t * FPS_WALK)
	direction = dir
	_anim_t += delta
	if not is_zero_approx(dir.x):
		_anim_row = ROW_WALK_E if dir.x > 0 else ROW_WALK_W
	elif not is_zero_approx(dir.y):
		_anim_row = ROW_WALK_S if dir.y > 0 else ROW_WALK_N
	var frame := int(_anim_t * FPS_WALK)
	sprite.frame = _anim_row * 4 + (frame % 4)
	# The alternating planted feet are in columns 1 and 3 of the walk cycle.
	return frame != previous_frame and frame % 2 == 1

func _dir_to_idle_row(d: Vector2) -> int:
	if absf(d.x) >= absf(d.y):
		return ROW_WALK_E if d.x > 0 else ROW_WALK_W
	return ROW_WALK_S if d.y > 0 else ROW_WALK_N

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if is_world_input_blocked:
		if event.is_action_pressed("ui_cancel"):
			var level := _get_level()
			if level == null:
				return
			for child in level.get_children():
				if child is NPC and child.conversation.peer_id == int(name):
					child.conversation.close()
					get_viewport().set_input_as_handled()
					break
		return
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("take"):
		_try_take_drop()

func _try_interact() -> void:
	if is_sitting and seated_seat != null and seated_seat.stand_on_interact:
		_stand_up()
		return
	var areas := interaction_area.get_overlapping_areas()
	var nearest_seat: Seat = null
	var nearest_distance := INF
	if not is_sitting:
		for area in areas:
			var candidate := area.get_parent() as Seat
			if candidate != null and not candidate.is_occupied and candidate.is_player_in_reach(self):
				var distance := global_position.distance_squared_to(candidate.global_position)
				if distance < nearest_distance:
					nearest_seat = candidate
					nearest_distance = distance
	if nearest_seat != null:
		_sit_in(nearest_seat)
		return
	var conversation := NPCConversation.nearest(self, areas)
	if conversation != null:
		conversation.interact(self)
		return
	var nearest: Node2D
	for area in areas:
		var candidate := area.get_parent() as Node2D
		if candidate is not Interactable:
			continue
		if nearest == null or global_position.distance_squared_to(candidate.global_position) < global_position.distance_squared_to(nearest.global_position):
			nearest = candidate
	if nearest is Interactable:
		nearest.interact(self)

func _try_take_drop() -> void:
	var areas := interaction_area.get_overlapping_areas()
	var nearest: Node2D
	for area in areas:
		var candidate := area.get_parent() as Node2D
		if _hands_item != null:
			if candidate is not DropPlace or not candidate.can_accept(_hands_item):
				continue
		elif candidate is not Draggable or not candidate.can_pickup(self):
			continue
		if nearest == null or global_position.distance_squared_to(area.global_position) < global_position.distance_squared_to(nearest.global_position):
			nearest = candidate
	if _hands_item != null and nearest is DropPlace:
		_hands_item.drop(self, nearest)
	elif nearest is Draggable:
		nearest.pickup(self)

func take_spawned_item(item: Draggable) -> void:
	if _hands_item != null:
		return
	_hands_item = item
	item.tree_exiting.connect(func():
		if _hands_item == item:
			_hands_item = null
	, CONNECT_ONE_SHOT)

func _sit_in(seat: Seat) -> void:
	if is_sitting or not seat.occupy(self):
		return
	seated_seat = seat
	is_sitting = true
	is_swimming = false
	_is_moving = false
	global_position = seat.get_seat_position()
	_idle_tween.pause()
	sprite.frame = (ROW_WALK_N if seat.facing_north else ROW_SIT) * 4

func _stand_up() -> void:
	if seated_seat:
		seated_seat.vacate(self)
		if seated_seat.stand_position_offset != Vector2.ZERO:
			global_position = seated_seat.to_global(seated_seat.stand_position_offset)
		seated_seat = null
	is_sitting = false
	_start_idle_bob()

@rpc("any_peer", "call_local", "reliable")
func rpc_apply_player_setup(setup: Dictionary) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return
	if setup.has("name"):
		player_name = setup["name"]
