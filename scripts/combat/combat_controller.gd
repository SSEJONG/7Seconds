class_name CombatController
extends Node

@export var player_path: NodePath = ^"../Player"
@export var enemy_path: NodePath = ^"../Enemy"

var state: CombatState.Id = CombatState.Id.INIT
var turn_number: int = 0
var action_time_remaining: float = 0.0
var player_hp: int = GameConstants.PLAYER_MAX_HP
var _plan_hand: PackedStringArray = PackedStringArray()

var _player: PlayerController
var _enemy: EnemyPlaceholder
var _resolve_timer: float = 0.0
var _hit_stop_timer: float = 0.0
var _time_scale_before_hit_stop: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_node(player_path) as PlayerController
	_enemy = get_node(enemy_path) as EnemyPlaceholder
	if _enemy:
		_enemy.died.connect(_on_enemy_died)
	EventBus.player_hp_changed.emit(player_hp, GameConstants.PLAYER_MAX_HP)
	_transition_to(CombatState.Id.INIT)


func _process(delta: float) -> void:
	if _hit_stop_timer > 0.0:
		_hit_stop_timer = maxf(0.0, _hit_stop_timer - delta)
		if _hit_stop_timer <= 0.0:
			Engine.time_scale = _time_scale_before_hit_stop
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
	_hit_stop_timer = duration
	Engine.time_scale = 0.0


func start_action_phase_from_plan() -> void:
	if state != CombatState.Id.PLAN_PHASE:
		return
	_begin_action_phase()


func apply_debug_damage_to_enemy(amount: int) -> void:
	if _enemy and _enemy.is_alive():
		_enemy.apply_damage(amount)
		if _player:
			_player.trigger_hit_feedback()
		if _enemy.current_hp <= 0:
			_transition_to(CombatState.Id.VICTORY)


func apply_debug_damage_to_player(amount: int) -> void:
	if state == CombatState.Id.VICTORY or state == CombatState.Id.DEFEAT:
		return
	player_hp = maxi(0, player_hp - amount)
	EventBus.player_hp_changed.emit(player_hp, GameConstants.PLAYER_MAX_HP)
	if _player:
		_player.trigger_hit_feedback()
	if player_hp <= 0:
		_transition_to(CombatState.Id.DEFEAT)


func restart_battle() -> void:
	player_hp = GameConstants.PLAYER_MAX_HP
	if _enemy:
		_enemy.current_hp = _enemy.max_hp
		EventBus.enemy_hp_changed.emit(_enemy.current_hp, _enemy.max_hp)
	EventBus.player_hp_changed.emit(player_hp, GameConstants.PLAYER_MAX_HP)
	_transition_to(CombatState.Id.INIT)


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
	if _hit_stop_timer > 0.0:
		return
	# 계획/정산: 전투 타이머만 멈추고, 입력·UI는 동작 (플레이어 이동은 can_control로 차단)
	if CombatState.is_time_frozen(state):
		Engine.time_scale = 1.0
	elif state == CombatState.Id.ACTION_PHASE:
		Engine.time_scale = 1.0
	else:
		Engine.time_scale = 1.0


func _sync_player_control() -> void:
	if _player == null:
		return
	_player.set_control_enabled(state == CombatState.Id.ACTION_PHASE)


func _enter_init() -> void:
	turn_number = 0
	action_time_remaining = 0.0
	_transition_to(CombatState.Id.PLAN_PHASE)


func _enter_plan_phase() -> void:
	turn_number += 1
	EventBus.turn_started.emit(turn_number)
	_build_placeholder_hand()
	EventBus.plan_hand_updated.emit(_plan_hand)


func _build_placeholder_hand() -> void:
	_plan_hand = PackedStringArray([
		"빠른 베기 x3",
		"찌르기 x2",
		"강타 x1",
		"패링 x2",
		"돌진 x1",
	])
	EventBus.combat_message.emit(
		"턴 %d — 계획 중 (WASD 불가). Enter 또는 [액션 시작] 후 이동" % turn_number
	)


func _begin_action_phase() -> void:
	var old := state
	state = CombatState.Id.ACTION_PHASE
	action_time_remaining = GameConstants.BASE_ACTION_TIME
	_hit_stop_timer = 0.0
	Engine.time_scale = 1.0
	_sync_player_control()
	EventBus.combat_state_changed.emit(old, state)
	EventBus.action_time_changed.emit(action_time_remaining, GameConstants.BASE_ACTION_TIME)
	EventBus.combat_message.emit("액션 페이즈 시작 — 7초")


func _tick_action_phase(delta: float) -> void:
	action_time_remaining = maxf(0.0, action_time_remaining - delta)
	EventBus.action_time_changed.emit(action_time_remaining, GameConstants.BASE_ACTION_TIME)
	if action_time_remaining <= 0.0:
		_transition_to(CombatState.Id.RESOLVE_PHASE)
		return
	if _enemy and not _enemy.is_alive():
		_transition_to(CombatState.Id.VICTORY)


func _enter_resolve_phase() -> void:
	_resolve_timer = GameConstants.RESOLVE_PHASE_DELAY_SEC
	EventBus.combat_message.emit("턴 정산…")


func _tick_resolve_phase(delta: float) -> void:
	_resolve_timer -= delta
	if _resolve_timer > 0.0:
		return
	if player_hp <= 0:
		_transition_to(CombatState.Id.DEFEAT)
	elif _enemy and not _enemy.is_alive():
		_transition_to(CombatState.Id.VICTORY)
	else:
		_transition_to(CombatState.Id.PLAN_PHASE)


func _enter_end_state() -> void:
	action_time_remaining = 0.0
	if _player:
		_player.set_control_enabled(false)
	var msg := "승리!" if state == CombatState.Id.VICTORY else "패배…"
	EventBus.combat_message.emit("%s — R 키로 재시작" % msg)


func _on_enemy_died() -> void:
	if state == CombatState.Id.ACTION_PHASE:
		_transition_to(CombatState.Id.VICTORY)
