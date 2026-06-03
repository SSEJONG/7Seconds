extends Control

@onready var _state_label: Label = %StateLabel
@onready var _turn_label: Label = %TurnLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _player_hp_label: Label = %PlayerHpLabel
@onready var _enemy_hp_label: Label = %EnemyHpLabel
@onready var _hand_label: Label = %HandLabel
@onready var _message_label: Label = %MessageLabel
@onready var _feel_hint_label: Label = %FeelHintLabel

var _combat: CombatController


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_combat = get_tree().get_first_node_in_group("combat_controller") as CombatController
	EventBus.combat_state_changed.connect(_on_combat_state_changed)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.action_time_changed.connect(_on_action_time_changed)
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.enemy_hp_changed.connect(_on_enemy_hp_changed)
	EventBus.plan_hand_updated.connect(_on_plan_hand_updated)
	EventBus.combat_message.connect(_on_combat_message)
	_refresh_all()


func _on_combat_state_changed(_old: int, new_state: int) -> void:
	_state_label.text = "상태: %s" % CombatState.to_string_id(new_state)
	var frozen := CombatState.is_time_frozen(new_state)
	_timer_label.text = "시간: %s" % ("정지" if frozen and new_state != CombatState.Id.VICTORY and new_state != CombatState.Id.DEFEAT else "%.1f초" % _combat.action_time_remaining if _combat else "-")


func _on_turn_started(turn_number: int) -> void:
	_turn_label.text = "턴: %d" % turn_number


func _on_action_time_changed(remaining: float, total: float) -> void:
	if _combat and _combat.state == CombatState.Id.ACTION_PHASE:
		_timer_label.text = "액션 시간: %.1f / %.1f초" % [remaining, total]
	else:
		_timer_label.text = "액션 시간: —"


func _on_player_hp_changed(current: int, max_hp: int) -> void:
	_player_hp_label.text = "플레이어 HP: %d / %d" % [current, max_hp]


func _on_enemy_hp_changed(current: int, max_hp: int) -> void:
	_enemy_hp_label.text = "적 HP: %d / %d" % [current, max_hp]


func _on_plan_hand_updated(card_labels: PackedStringArray) -> void:
	_hand_label.text = "손패(임시): " + ", ".join(card_labels)


func _on_combat_message(message: String) -> void:
	_message_label.text = message


func _refresh_all() -> void:
	if _combat == null:
		return
	_on_combat_state_changed(_combat.state, _combat.state)
	_on_turn_started(_combat.turn_number)
	_on_player_hp_changed(_combat.player_hp, GameConstants.PLAYER_MAX_HP)
	var enemy := get_tree().get_first_node_in_group("enemy") as EnemyPlaceholder
	if enemy:
		_on_enemy_hp_changed(enemy.current_hp, enemy.max_hp)
	_feel_hint_label.text = "손맛: default_player_feel.tres · 가이드 docs/09_player_feel_tuning.md"


func _on_start_action_pressed() -> void:
	if _combat:
		_combat.start_action_phase_from_plan()


func _on_restart_pressed() -> void:
	if _combat:
		_combat.restart_battle()


func _on_damage_enemy_pressed() -> void:
	if _combat:
		_combat.apply_debug_damage_to_enemy(30)


func _on_damage_player_pressed() -> void:
	if _combat:
		_combat.apply_debug_damage_to_player(25)
