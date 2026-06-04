class_name CardInstance
extends RefCounted
## docs/06 CardInstance — 전투 중 카드 1장

var definition: CardDefinition
var remaining_uses: int = 0
var on_hit_draw_used: bool = false


func _init(def: CardDefinition) -> void:
	definition = def
	remaining_uses = def.base_uses if def else 0


func get_label() -> String:
	if definition == null:
		return "?"
	return "%s x%d" % [definition.display_name, remaining_uses]


func get_definition_id() -> String:
	return definition.id if definition else ""


func is_usable() -> bool:
	return remaining_uses > 0
