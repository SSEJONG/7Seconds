extends CombatCharacterAnimation
## docs/11 — Enemy.glb, EventBus.enemy_action_changed (액션 페이즈만)

const ACTION_TO_ANIM: Dictionary = {
	"": "Idle_FoldArms_Loop",
	"APPROACH": "Zombie_Walk_Fwd_Loop",
	"LIGHT_ATTACK": "Sword_Regular_A",
	"SIDE_STEP": "Slide_Loop",
	"DASH_ATTACK": "Sword_Dash_RM",
	"HEAVY_ATTACK": "Sword_Regular_C",
	"GUARD": "Idle_Shield_Loop",
	"RETREAT": "Slide_Exit",
	"STAGGERED": "Hit_Knockback",
	"DEAD": "Hit_Knockback",
}

const LOOP_WHILE_ACTION: Array[String] = [
	"APPROACH",
	"SIDE_STEP",
	"GUARD",
]


func _ready() -> void:
	face_opponent_in_plan = true
	super._ready()


func _connect_action_signals() -> void:
	EventBus.enemy_action_changed.connect(_on_action_signal)


func _on_action_signal(action_id: String, _display_name: String) -> void:
	_on_combat_action(action_id)


func _map_action_to_anim(action_id: String) -> String:
	return str(ACTION_TO_ANIM.get(action_id, "Idle_FoldArms_Loop"))


func _should_hold_loop() -> bool:
	return _current_action in LOOP_WHILE_ACTION
