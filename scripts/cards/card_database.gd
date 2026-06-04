class_name CardDatabase
extends RefCounted
## docs/06, data/mvp/cards_mvp.json — 카드 정의 로드

var _definitions: Dictionary = {}


func load_from_json(path: String) -> void:
	_definitions.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CardDatabase: cannot open %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("CardDatabase: invalid JSON at %s" % path)
		return
	var cards: Array = parsed.get("cards", [])
	for entry in cards:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var def := _definition_from_dict(entry)
		if def.id.is_empty():
			continue
		_definitions[def.id] = def


func get_definition(card_id: String) -> CardDefinition:
	return _definitions.get(card_id) as CardDefinition


func create_instance(card_id: String) -> CardInstance:
	var def := get_definition(card_id)
	if def == null:
		push_warning("CardDatabase: unknown card id '%s'" % card_id)
		return null
	return CardInstance.new(def)


func has_definition(card_id: String) -> bool:
	return _definitions.has(card_id)


func _definition_from_dict(data: Dictionary) -> CardDefinition:
	var def := CardDefinition.new()
	def.id = str(data.get("id", ""))
	def.display_name = str(data.get("name", def.id))
	def.card_type = CardDefinition.card_type_from_string(str(data.get("type", "ATTACK")))
	def.base_uses = int(data.get("baseUses", 1))
	def.damage = int(data.get("damage", 0))
	def.stagger_damage = int(data.get("staggerDamage", 0))
	def.startup_sec = float(data.get("startup", 0.1))
	def.active_sec = float(data.get("active", 0.15))
	def.recovery_sec = float(data.get("recovery", 0.25))
	def.range_m = float(data.get("range", 2.0))
	def.can_dodge_cancel = bool(data.get("canDodgeCancel", true))
	def.action_time_delta = float(data.get("actionTimeDelta", 0.0))
	def.draw_on_hit = bool(data.get("drawOnHit", false))
	return def
