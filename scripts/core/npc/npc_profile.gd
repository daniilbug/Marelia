class_name NPCProfile
extends Resource

const APPEARANCE_CATALOGS := {
	"hair_id": CharacterSprite.HAIR_TEXTURES, "top_id": CharacterSprite.TOP_TEXTURES,
	"pants_id": CharacterSprite.PANTS_TEXTURES, "hair_color_id": CharacterSprite.HAIR_COLORS,
	"top_color_id": CharacterSprite.CLOTHING_COLORS, "pants_color_id": CharacterSprite.CLOTHING_COLORS,
}

var appearance: Dictionary = {}
var active := false

static func create(npc: NPC) -> NPCProfile:
	var profile := NPCProfile.new()
	npc.randomize_appearance(false)
	profile.appearance = SaveGraph.get_fields(npc, APPEARANCE_CATALOGS.keys())
	return profile

func apply_appearance(npc: NPC) -> void:
	SaveGraph.apply_fields(npc, APPEARANCE_CATALOGS.keys(), appearance)

func get_save_data() -> Dictionary:
	return {"appearance": appearance.duplicate()}

static func from_save(data: Dictionary) -> NPCProfile:
	var profile := NPCProfile.new()
	profile.appearance = data.appearance.duplicate()
	return profile

static func is_valid_save(data: Variant) -> bool:
	if not SaveGraph.matches(data, {"appearance": {}}):
		return false
	for field in APPEARANCE_CATALOGS:
		var limit: int = APPEARANCE_CATALOGS[field].size()
		if not data.appearance.has(field) or not SaveGraph.matches(data.appearance[field], Vector2i(0, limit - 1)):
			return false
	return true
