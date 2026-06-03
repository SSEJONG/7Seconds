extends Node

@export var combat_controller_path: NodePath = ^".."

var _combat: CombatController


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_combat = get_node(combat_controller_path) as CombatController


func _unhandled_input(event: InputEvent) -> void:
	if _combat == null:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("start_action"):
		if _combat.state == CombatState.Id.PLAN_PHASE:
			_combat.start_action_phase_from_plan()
	elif event.is_action_pressed("restart_combat"):
		_combat.restart_battle()
	elif event.is_action_pressed("debug_damage_enemy"):
		_combat.apply_debug_damage_to_enemy(30)
	elif event.is_action_pressed("debug_damage_player"):
		_combat.apply_debug_damage_to_player(25)
	elif event.is_action_pressed("toggle_mouse_capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
