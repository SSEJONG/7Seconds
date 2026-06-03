class_name CombatState
extends RefCounted

enum Id {
	INIT,
	PLAN_PHASE,
	ACTION_PHASE,
	RESOLVE_PHASE,
	VICTORY,
	DEFEAT,
}


static func to_string_id(state: Id) -> String:
	match state:
		Id.INIT:
			return "INIT"
		Id.PLAN_PHASE:
			return "PLAN_PHASE"
		Id.ACTION_PHASE:
			return "ACTION_PHASE"
		Id.RESOLVE_PHASE:
			return "RESOLVE_PHASE"
		Id.VICTORY:
			return "VICTORY"
		Id.DEFEAT:
			return "DEFEAT"
		_:
			return "UNKNOWN"


static func is_time_frozen(state: Id) -> bool:
	return state == Id.PLAN_PHASE or state == Id.RESOLVE_PHASE or state == Id.VICTORY or state == Id.DEFEAT
