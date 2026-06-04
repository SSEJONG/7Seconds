class_name CombatController
extends Node

@export var player_path: NodePath = ^"../Player"
@export var enemy_path: NodePath = ^"../Enemy"
@export var deck_manager_path: NodePath = ^"../DeckManager"

var state: CombatState.Id = CombatState.Id.INIT
var turn_number: int = 0
var action_time_remaining: float = 0.0
var action_time_total: float = GameConstants.BASE_ACTION_TIME
var player_hp: int = GameConstants.PLAYER_MAX_HP

var _player: PlayerController
var _enemy: EnemyDuelist
var _deck: DeckManager
var _resolve_timer: float = 0.0
var _hit_stop_end_usec: int = 0
var _time_scale_before_hit_stop: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_node(player_path) as PlayerController
	_enemy = get_node(enemy_path) as EnemyDuelist
	_deck = get_node(deck_manager_path) as DeckManager
	if _enemy:
		_enemy.died.connect(_on_enemy_died)
	EventBus.player_hp_changed.emit(player_hp, GameConstants.PLAYER_MAX_HP)
	_transition_to(CombatState.Id.INIT)


func _process(delta: float) -> void:
	if _tick_hit_stop():
		return

	match state:
		CombatState.Id.ACTION_PHASE:
			_tick_action_phase(delta)
		CombatState.Id.RESOLVE_PHASE:
			_tick_resolve_phase(delta)


func request_hit_stop(duration: float) -> void:
	if duration <= 0.0 or state != CombatState.Id.ACTION_PHASE:
		return
	_time_scale_before_hit_stop = Engine.time_scale
	_hit_stop_end_usec = Time.get_ticks_usec() + int(duration * 1_000_000.0)
	Engine.time_scale = 0.0


func _tick_hit_stop() -> bool:
	if _hit_stop_end_usec <= 0:
		return false
	if Time.get_ticks_usec() >= _hit_stop_end_usec:
		_hit_stop_end_usec = 0
		Engine.time_scale = _time_scale_before_hit_stop
		return false
	return true


func start_action_phase_from_plan() -> void:
	if state != CombatState.Id.PLAN_PHASE:
		return
	_begin_action_phase()


func apply_damage_to_enemy(amount: int, stagger_amount: int = 0) -> void:
	if _enemy and _enemy.is_alive():
		if stagger_amount > 0:
			_enemy.apply_stagger(stagger_amount)
		_enemy.apply_damage(amount)
		if _player:
			_player.trigger_hit_feedback()
		if _enemy.current_hp <= 0:
			_transition_to(CombatState.Id.VICTORY)


func apply_debug_damage_to_enemy(amount: int) -> void:
	apply_damage_to_enemy(amount)


func apply_damage_to_player(amount: int) -> void:
	if state == CombatState.Id.VICTORY or state == CombatState.Id.DEFEAT:
		return
	if state != CombatState.Id.ACTION_PHASE:
		return
	player_hp = maxi(0, player_hp - amount)
	EventBus.player_hp_changed.emit(player_hp, GameConstants.PLAYER_MAX_HP)
	if _player:
		_player.trigger_hit_feedback()
	EventBus.combat_message.emit("적 공격! -%d HP" % amount)
	if player_hp <= 0:
		_transition_to(CombatState.Id.DEFEAT)


func apply_debug_damage_to_player(amount: int) -> void:
	if state == CombatState.Id.VICTORY or state == CombatState.Id.DEFEAT:
		return
	player_hp = maxi(0, player_hp - amount)
	EventBus.player_hp_changed.emit(player_hp, GameConstants.PLAYER_MAX_HP)
	if _player:
		_player.trigger_hit_feedback()
	if player_hp <= 0:
		_transition_to(CombatState.Id.DEFEAT)


func get_action_elapsed() -> float:
	return maxf(0.0, action_time_total - action_time_remaining)


func modify_action_time(delta_sec: float) -> void:
	if state != CombatState.Id.ACTION_PHASE or delta_sec == 0.0:
		return
	var capped := delta_sec
	if capped > 0.0:
		capped = minf(capped, GameConstants.ACTION_TIME_GAIN_CAP_PER_USE)
	else:
		capped = maxf(capped, -GameConstants.ACTION_TIME_GAIN_CAP_PER_USE)

	var was_short := action_time_total <= GameConstants.BASE_ACTION_TIME + 0.01
	action_time_remaining += capped
	action_time_remaining = clampf(action_time_remaining, 0.0, GameConstants.MAX_ACTION_TIME)
	action_time_total = clampf(
		maxf(action_time_total, action_time_remaining),
		GameConstants.BASE_ACTION_TIME,
		GameConstants.MAX_ACTION_TIME,
	)

	if capped > 0.0:
		EventBus.combat_message.emit("액션 시간 +%.1f초 (남음 %.1f초)" % [capped, action_time_remaining])
		if was_short and action_time_total > GameConstants.BASE_ACTION_TIME + 0.01 and _enemy:
			_enemy.on_action_time_extended(action_time_total)
	elif capped < 0.0:
		EventBus.combat_message.emit("액션 시간 %.1f초" % capped)

	_emit_action_time()


func try_apply_card_hit(
	damage: int,
	stagger: int,
	range_m: float,
	player: PlayerController,
) -> bool:
	if _enemy == null or not _enemy.is_alive() or player == null:
		return false
	var dist := player.global_position.distance_to(_enemy.global_position)
	if dist > range_m:
		EventBus.combat_message.emit("사거리 밖 (%.1fm / %.1fm)" % [dist, range_m])
		return false
	apply_damage_to_enemy(damage, stagger)
	return true


func _emit_action_time() -> void:
	EventBus.action_time_changed.emit(action_time_remaining, action_time_total)


func restart_battle() -> void:
	player_hp = GameConstants.PLAYER_MAX_HP
	if _enemy:
		_enemy.reset_for_battle()
	EventBus.player_hp_changed.emit(player_hp, GameConstants.PLAYER_MAX_HP)
	_transition_to(CombatState.Id.INIT)


func get_deck_manager() -> DeckManager:
	return _deck


func request_hand_reroll(selected_hand_indices: Array[int]) -> bool:
	if state != CombatState.Id.PLAN_PHASE or _deck == null:
		return false
	return _deck.try_reroll(selected_hand_indices)


func cycle_card_selection(direction: int) -> void:
	if state != CombatState.Id.ACTION_PHASE or _deck == null:
		return
	_deck.cycle_hand_selection(direction)


func try_use_selected_card() -> void:
	if state != CombatState.Id.ACTION_PHASE or _deck == null or _player == null:
		return
	_deck.try_use_selected_card(self, _player)


func _transition_to(next: CombatState.Id) -> void:
	var old := state
	state = next
	_apply_time_scale()
	_sync_player_control()
	match next:
		CombatState.Id.INIT:
			_enter_init()
		CombatState.Id.PLAN_PHASE:
			_enter_plan_phase()
		CombatState.Id.ACTION_PHASE:
			pass
		CombatState.Id.RESOLVE_PHASE:
			_enter_resolve_phase()
		CombatState.Id.VICTORY, CombatState.Id.DEFEAT:
			_enter_end_state()
	EventBus.combat_state_changed.emit(old, next)
	EventBus.combat_message.emit("상태: %s" % CombatState.to_string_id(next))


func _apply_time_scale() -> void:
	if _hit_stop_end_usec > 0:
		return
	# 계획/정산: 전투 타이머만 멈추고, 입력·UI는 동작 (플레이어 이동은 can_control로 차단)
	if CombatState.is_time_frozen(state):
		Engine.time_scale = 1.0
	elif state == CombatState.Id.ACTION_PHASE:
		Engine.time_scale = 1.0
	else:
		Engine.time_scale = 1.0


func _sync_player_control() -> void:
	if _player:
		_player.set_control_enabled(state == CombatState.Id.ACTION_PHASE)
	_sync_mouse_mode()


func _sync_mouse_mode() -> void:
	# docs/03 — 계획·정산·승패 UI 클릭용; 액션 페이즈만 시점 조작(캡처)
	if state == CombatState.Id.ACTION_PHASE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _enter_init() -> void:
	turn_number = 0
	action_time_remaining = 0.0
	if _deck:
		_deck.setup_battle()
	_transition_to(CombatState.Id.PLAN_PHASE)


func _enter_plan_phase() -> void:
	turn_number += 1
	EventBus.turn_started.emit(turn_number)
	if _deck:
		_deck.start_turn()
	if _enemy:
		_enemy.refresh_plan_preview()
	EventBus.combat_message.emit(
		"턴 %d — 계획 중 (WASD 불가). Enter 또는 [액션 시작] 후 이동" % turn_number
	)


func _begin_action_phase() -> void:
	var old := state
	state = CombatState.Id.ACTION_PHASE
	action_time_total = GameConstants.BASE_ACTION_TIME
	action_time_remaining = action_time_total
	_hit_stop_end_usec = 0
	Engine.time_scale = 1.0
	if _deck:
		_deck.begin_action_phase()
	if _enemy:
		_enemy.begin_action_phase(action_time_total)
	_sync_player_control()
	EventBus.combat_state_changed.emit(old, state)
	_emit_action_time()
	EventBus.combat_message.emit("액션 페이즈 시작 — %.0f초" % action_time_total)


func _tick_action_phase(delta: float) -> void:
	action_time_remaining = maxf(0.0, action_time_remaining - delta)
	_emit_action_time()
	if _enemy and _enemy.is_alive():
		_enemy.tick_action_phase(get_action_elapsed(), delta)
	if action_time_remaining <= 0.0:
		_transition_to(CombatState.Id.RESOLVE_PHASE)
		return
	if _enemy and not _enemy.is_alive():
		_transition_to(CombatState.Id.VICTORY)


func _enter_resolve_phase() -> void:
	_resolve_timer = GameConstants.RESOLVE_PHASE_DELAY_SEC
	if _enemy:
		_enemy.end_action_phase()
	if _deck:
		_deck.discard_hand_at_turn_end()
	EventBus.combat_message.emit("턴 정산…")


func _tick_resolve_phase(delta: float) -> void:
	_resolve_timer -= delta
	if _resolve_timer > 0.0:
		return
	# docs/05 — 동시 사망 시 승리 우선
	if _enemy and not _enemy.is_alive():
		_transition_to(CombatState.Id.VICTORY)
	elif player_hp <= 0:
		_transition_to(CombatState.Id.DEFEAT)
	else:
		_transition_to(CombatState.Id.PLAN_PHASE)


func _enter_end_state() -> void:
	action_time_remaining = 0.0
	var msg := "승리!" if state == CombatState.Id.VICTORY else "패배…"
	EventBus.combat_message.emit("%s — R 키로 재시작" % msg)


func _on_enemy_died() -> void:
	if state == CombatState.Id.ACTION_PHASE:
		_transition_to(CombatState.Id.VICTORY)
