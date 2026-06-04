extends Control

@onready var _state_label: Label = %StateLabel
@onready var _turn_label: Label = %TurnLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _player_hp_label: Label = %PlayerHpLabel
@onready var _enemy_hp_label: Label = %EnemyHpLabel
@onready var _enemy_intent_label: Label = %EnemyIntentLabel
@onready var _enemy_action_label: Label = %EnemyActionLabel
@onready var _pile_label: Label = %PileLabel
@onready var _reroll_label: Label = %RerollLabel
@onready var _hand_container: HBoxContainer = %HandContainer
@onready var _selected_card_label: Label = %SelectedCardLabel
@onready var _message_label: Label = %MessageLabel
@onready var _feel_hint_label: Label = %FeelHintLabel
@onready var _confirm_reroll_button: Button = %ConfirmRerollButton

var _combat: CombatController
var _selected_hand_indices: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_combat = get_tree().get_first_node_in_group("combat_controller") as CombatController
	EventBus.combat_state_changed.connect(_on_combat_state_changed)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.action_time_changed.connect(_on_action_time_changed)
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.enemy_hp_changed.connect(_on_enemy_hp_changed)
	EventBus.enemy_intent_updated.connect(_on_enemy_intent_updated)
	EventBus.enemy_action_changed.connect(_on_enemy_action_changed)
	EventBus.plan_hand_updated.connect(_on_plan_hand_updated)
	EventBus.combat_hand_changed.connect(_on_combat_hand_changed)
	EventBus.deck_piles_changed.connect(_on_deck_piles_changed)
	EventBus.reroll_status_changed.connect(_on_reroll_status_changed)
	EventBus.combat_message.connect(_on_combat_message)
	_refresh_all()


func _on_combat_state_changed(_old: int, new_state: int) -> void:
	_state_label.text = "상태: %s" % CombatState.to_string_id(new_state)
	var frozen := CombatState.is_time_frozen(new_state)
	_timer_label.text = "시간: %s" % (
		"정지"
		if frozen and new_state != CombatState.Id.VICTORY and new_state != CombatState.Id.DEFEAT
		else "%.1f초" % _combat.action_time_remaining if _combat else "-"
	)
	_update_reroll_controls(new_state)


func _on_turn_started(turn_number: int) -> void:
	_turn_label.text = "턴: %d" % turn_number


func _on_action_time_changed(remaining: float, total: float) -> void:
	if _combat and _combat.state == CombatState.Id.ACTION_PHASE:
		var ext := " (연장)" if total > GameConstants.BASE_ACTION_TIME + 0.01 else ""
		_timer_label.text = "액션 시간: %.1f / %.1f초%s" % [remaining, total, ext]
	else:
		_timer_label.text = "액션 시간: —"


func _on_player_hp_changed(current: int, max_hp: int) -> void:
	_player_hp_label.text = "플레이어 HP: %d / %d" % [current, max_hp]


func _on_enemy_hp_changed(current: int, max_hp: int) -> void:
	_enemy_hp_label.text = "적 HP: %d / %d" % [current, max_hp]


func _on_enemy_intent_updated(summary: String, enemy_name: String) -> void:
	_enemy_intent_label.text = "적 예고(%s): %s" % [enemy_name, summary]


func _on_enemy_action_changed(_action_id: String, display_name: String) -> void:
	_enemy_action_label.text = "적 행동: %s" % display_name


func _on_plan_hand_updated(card_labels: PackedStringArray) -> void:
	if _combat and _combat.state == CombatState.Id.ACTION_PHASE:
		return
	_selected_hand_indices.clear()
	_rebuild_plan_hand_buttons(card_labels)
	_update_reroll_controls(_combat.state if _combat else CombatState.Id.INIT)
	_selected_card_label.text = "선택: — (액션: 휠·좌클릭)"


func _on_combat_hand_changed(
	card_labels: PackedStringArray,
	selected_index: int,
	in_action_phase: bool,
) -> void:
	if not in_action_phase:
		return
	_rebuild_action_hand_labels(card_labels, selected_index)
	_selected_card_label.text = (
		"선택: %s · 휠 변경 · 좌클릭 사용" % card_labels[selected_index]
		if selected_index >= 0 and selected_index < card_labels.size()
		else "선택: —"
	)


func _on_deck_piles_changed(draw_count: int, discard_count: int) -> void:
	_pile_label.text = "드로우 pile: %d · 버림 pile: %d" % [draw_count, discard_count]


func _on_reroll_status_changed(remaining_rerolls: int, can_reroll: bool) -> void:
	_reroll_label.text = "교체 남음: %d회" % remaining_rerolls
	if _confirm_reroll_button:
		_confirm_reroll_button.disabled = not can_reroll or _selected_hand_indices.is_empty()


func _on_combat_message(message: String) -> void:
	_message_label.text = message


func _rebuild_plan_hand_buttons(card_labels: PackedStringArray) -> void:
	for child in _hand_container.get_children():
		child.queue_free()
	for i in card_labels.size():
		var btn := Button.new()
		btn.text = card_labels[i]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(100, 36)
		var idx := i
		btn.toggled.connect(func(pressed: bool) -> void: _on_hand_card_toggled(idx, pressed))
		_hand_container.add_child(btn)


func _rebuild_action_hand_labels(card_labels: PackedStringArray, selected_index: int) -> void:
	for child in _hand_container.get_children():
		child.queue_free()
	for i in card_labels.size():
		var lbl := Label.new()
		lbl.text = card_labels[i]
		lbl.custom_minimum_size = Vector2(108, 36)
		if i == selected_index:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
		elif card_labels[i].contains("(소진)"):
			lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		_hand_container.add_child(lbl)


func _on_hand_card_toggled(index: int, pressed: bool) -> void:
	if pressed:
		_selected_hand_indices[index] = true
	else:
		_selected_hand_indices.erase(index)
	var deck := _combat.get_deck_manager() if _combat else null
	var can_reroll := deck != null and deck.rerolls_remaining > 0
	if _confirm_reroll_button:
		_confirm_reroll_button.disabled = not can_reroll or _selected_hand_indices.is_empty()


func _update_reroll_controls(combat_state: int) -> void:
	var in_plan := combat_state == CombatState.Id.PLAN_PHASE
	if _confirm_reroll_button:
		_confirm_reroll_button.visible = in_plan
		if not in_plan:
			_confirm_reroll_button.disabled = true
	if not in_plan:
		return
	for child in _hand_container.get_children():
		if child is Button:
			(child as Button).disabled = false


func _refresh_all() -> void:
	if _combat == null:
		return
	_on_combat_state_changed(_combat.state, _combat.state)
	_on_turn_started(_combat.turn_number)
	_on_player_hp_changed(_combat.player_hp, GameConstants.PLAYER_MAX_HP)
	var deck := _combat.get_deck_manager()
	if deck:
		_on_deck_piles_changed(deck.draw_pile.size(), deck.discard_pile.size())
		_on_plan_hand_updated(deck.get_hand_labels())
		_on_reroll_status_changed(deck.rerolls_remaining, deck.rerolls_remaining > 0)
	var enemy := get_tree().get_first_node_in_group("enemy") as EnemyDuelist
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


func _on_confirm_reroll_pressed() -> void:
	if _combat == null:
		return
	var indices: Array[int] = []
	for key in _selected_hand_indices.keys():
		indices.append(int(key))
	if _combat.request_hand_reroll(indices):
		_selected_hand_indices.clear()
