class_name EnemyDuelistData
extends RefCounted
## docs/06 — enemy_duelist.json 로드

var id: String = "duelist"
var display_name: String = "검투병"
var max_hp: int = 120
var move_speed: float = 4.8
var stagger_threshold: int = 30
var guard_damage_multiplier: float = 0.3
var parry_stagger: int = 15
var intent_summary: String = ""
var extension_intent_summary: String = ""
var actions: Dictionary = {}
var core_sequence: Array = []
var extension_sequence: Array = []


static func load_from_json(path: String) -> EnemyDuelistData:
	var data := EnemyDuelistData.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("EnemyDuelistData: cannot open %s" % path)
		return data
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return data
	data.id = str(parsed.get("id", "duelist"))
	data.display_name = str(parsed.get("name", "검투병"))
	data.max_hp = int(parsed.get("maxHP", 120))
	data.move_speed = float(parsed.get("moveSpeed", 4.8))
	data.stagger_threshold = int(parsed.get("staggerThreshold", 30))
	data.guard_damage_multiplier = float(parsed.get("guardDamageMultiplier", 0.3))
	data.parry_stagger = int(parsed.get("parryStagger", 15))
	data.intent_summary = str(parsed.get("intentSummary", ""))
	data.extension_intent_summary = str(parsed.get("extensionIntentSummary", ""))
	data.actions = parsed.get("actions", {})
	data.core_sequence = parsed.get("coreSequence", [])
	data.extension_sequence = parsed.get("extensionSequence", [])
	return data


func get_action(action_id: String) -> Dictionary:
	if actions.has(action_id):
		return actions[action_id] as Dictionary
	return {}


func get_action_display_name(action_id: String) -> String:
	var act := get_action(action_id)
	return str(act.get("displayName", action_id))
