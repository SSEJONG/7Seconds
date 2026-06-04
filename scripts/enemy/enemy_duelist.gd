class_name EnemyDuelist
extends CharacterBody3D
## docs/04, docs/05 — 검투병 코어 시퀀스·공격·방어·경직

signal died

@export var data_json_path: String = "res://data/mvp/enemy_duelist.json"
@export var combat_controller_path: NodePath = ^"../../CombatController"

@export_group("비주얼 (assets/animation/Enemy.glb)")
## Visual 노드의 enemy_visual.gd에서 맞춤 — 여기 값은 레거시(미사용)
@export var model_scale: float = 1.0
@export var model_y_offset: float = 0.0

var max_hp: int = GameConstants.ENEMY_MAX_HP
var current_hp: int = max_hp
var stagger_meter: int = 0

var _data: EnemyDuelistData
var _combat: CombatController
var _player: PlayerController

var _sequence_active: bool = false
var _elapsed_action_time: float = 0.0
var _action_time_total: float = GameConstants.BASE_ACTION_TIME
var _fired_core: Array = []
var _fired_extension: Array = []

var _current_action_id: String = ""
var _action_phase: String = ""
var _action_timer: float = 0.0
var _hit_applied_this_active: bool = false

var _guard_timer: float = 0.0
var _stagger_timer: float = 0.0
var _move_timer: float = 0.0
var _strafe_sign: float = 1.0


func _ensure_data() -> EnemyDuelistData:
	if _data == null:
		_data = EnemyDuelistData.load_from_json(data_json_path)
		max_hp = _data.max_hp
	return _data


func _ready() -> void:
	_ensure_data()
	current_hp = max_hp
	_combat = get_node_or_null(combat_controller_path) as CombatController
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	_face_spawn_toward_player()
	EventBus.enemy_hp_changed.emit(current_hp, max_hp)
	_emit_intent_preview(false)


func _face_spawn_toward_player() -> void:
	if _player == null:
		return
	var target := _player.global_position
	target.y = global_position.y
	look_at(target, Vector3.UP)


func reset_for_battle() -> void:
	_ensure_data()
	current_hp = max_hp
	stagger_meter = 0
	_end_sequence()
	EventBus.enemy_hp_changed.emit(current_hp, max_hp)
	_emit_intent_preview(false)


func is_alive() -> bool:
	return current_hp > 0


func apply_damage(amount: int) -> void:
	if current_hp <= 0:
		return
	var final := amount
	if _guard_timer > 0.0 and _player and _is_frontal_hit_from(_player.global_position):
		final = int(round(float(amount) * _ensure_data().guard_damage_multiplier))
		EventBus.combat_message.emit("방어 — 피해 %d" % final)
	current_hp = maxi(0, current_hp - final)
	EventBus.enemy_hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		_die()


func apply_stagger(amount: int) -> void:
	if not is_alive() or _stagger_timer > 0.0:
		return
	stagger_meter += amount
	if stagger_meter >= _ensure_data().stagger_threshold:
		stagger_meter = 0
		_enter_stagger(1.5)
		EventBus.combat_message.emit("적 경직!")


func begin_action_phase(action_time_total: float) -> void:
	_action_time_total = action_time_total
	_elapsed_action_time = 0.0
	_sequence_active = true
	_fired_core.clear()
	_fired_extension.clear()
	_current_action_id = ""
	_guard_timer = 0.0
	_stagger_timer = 0.0
	velocity = Vector3.ZERO
	_emit_intent_preview(action_time_total > GameConstants.BASE_ACTION_TIME + 0.01)
	EventBus.enemy_action_changed.emit("", "대기")


func end_action_phase() -> void:
	_end_sequence()


func refresh_plan_preview() -> void:
	_emit_intent_preview(false)


func on_action_time_extended(new_total: float) -> void:
	_action_time_total = new_total
	_emit_intent_preview(true)
	EventBus.combat_message.emit("액션 시간 연장 — 적 확장 시퀀스 예고")


func tick_action_phase(elapsed: float, delta: float) -> void:
	if not _sequence_active or not is_alive():
		return
	_elapsed_action_time = elapsed
	if _guard_timer > 0.0:
		_guard_timer = maxf(0.0, _guard_timer - delta)
	if _stagger_timer > 0.0:
		_stagger_timer = maxf(0.0, _stagger_timer - delta)
		velocity = Vector3.ZERO
		move_and_slide()
		return

	_tick_sequence_events()
	_tick_current_action(delta)
	move_and_slide()


func get_intent_summary(include_extension: bool) -> String:
	var data := _ensure_data()
	if include_extension and not data.extension_intent_summary.is_empty():
		return data.extension_intent_summary
	return data.intent_summary


func _end_sequence() -> void:
	_sequence_active = false
	_current_action_id = ""
	_action_phase = ""
	velocity = Vector3.ZERO
	EventBus.enemy_action_changed.emit("", "—")


func _die() -> void:
	_end_sequence()
	EventBus.enemy_action_changed.emit("DEAD", "처치됨")
	died.emit()


func _emit_intent_preview(include_extension: bool) -> void:
	var data := _ensure_data()
	var summary := get_intent_summary(include_extension)
	EventBus.enemy_intent_updated.emit(summary, data.display_name)


func _tick_sequence_events() -> void:
	var data := _ensure_data()
	_try_fire_sequence(data.core_sequence, _fired_core)
	if _elapsed_action_time > GameConstants.BASE_ACTION_TIME - 0.01:
		_try_fire_sequence(data.extension_sequence, _fired_extension)


func _try_fire_sequence(sequence: Array, fired_flags: Array) -> void:
	for i in sequence.size():
		if i < fired_flags.size() and fired_flags[i]:
			continue
		var entry: Dictionary = sequence[i]
		var at := float(entry.get("time", 0.0))
		if _elapsed_action_time < at:
			continue
		if _elapsed_action_time > _action_time_total:
			continue
		if not _current_action_id.is_empty() and _action_phase != "done":
			continue
		var action_id := str(entry.get("action", ""))
		_start_action(action_id)
		while fired_flags.size() <= i:
			fired_flags.append(false)
		fired_flags[i] = true


func _start_action(action_id: String) -> void:
	var data := _ensure_data()
	_current_action_id = action_id
	_action_timer = 0.0
	_hit_applied_this_active = false
	var act := data.get_action(action_id)
	EventBus.enemy_action_changed.emit(action_id, data.get_action_display_name(action_id))

	if action_id == "GUARD":
		_action_phase = "guard"
		_guard_timer = float(act.get("duration", 1.2))
		_action_phase = "done"
		return

	if bool(act.get("move", false)):
		_action_phase = "move"
		_move_timer = float(act.get("duration", 1.0))
		return
	if bool(act.get("strafe", false)):
		_action_phase = "strafe"
		_move_timer = float(act.get("duration", 0.5))
		_strafe_sign = 1.0 if randf() > 0.5 else -1.0
		return
	if bool(act.get("retreat", false)):
		_action_phase = "retreat"
		_move_timer = float(act.get("duration", 0.6))
		return

	_action_phase = "startup"
	if action_id == "DASH_ATTACK":
		_begin_dash_toward_player(float(act.get("dashSpeed", 10.0)))


func _tick_current_action(delta: float) -> void:
	match _action_phase:
		"move":
			_tick_move_toward(delta)
		"strafe":
			_tick_strafe(delta)
		"retreat":
			_tick_retreat(delta)
		"startup", "active", "recovery":
			_tick_attack_phases(delta)
		"done", "":
			velocity = velocity.lerp(Vector3.ZERO, delta * 8.0)


func _tick_move_toward(delta: float) -> void:
	if _player == null:
		return
	var data := _ensure_data()
	_face_player()
	var to_player := _flat_to(_player.global_position)
	if to_player.length() > 1.2:
		velocity = to_player.normalized() * data.move_speed
	else:
		velocity = Vector3.ZERO
	_move_timer -= delta
	if _move_timer <= 0.0:
		_action_phase = "done"
		_current_action_id = ""


func _tick_strafe(delta: float) -> void:
	if _player == null:
		return
	var data := _ensure_data()
	_face_player()
	var right := global_transform.basis.x * _strafe_sign
	velocity = right * data.move_speed * 0.85
	_move_timer -= delta
	if _move_timer <= 0.0:
		_action_phase = "done"
		_current_action_id = ""


func _tick_retreat(delta: float) -> void:
	if _player == null:
		return
	var data := _ensure_data()
	_face_player()
	var away := -_flat_to(_player.global_position)
	if away.length() > 0.01:
		velocity = away.normalized() * data.move_speed * 0.9
	_move_timer -= delta
	if _move_timer <= 0.0:
		_action_phase = "done"
		_current_action_id = ""


func _tick_attack_phases(delta: float) -> void:
	var act := _ensure_data().get_action(_current_action_id)
	var startup := float(act.get("startup", 0.2))
	var active := float(act.get("active", 0.2))
	var recovery := float(act.get("recovery", 0.3))
	_action_timer += delta

	if _action_phase == "startup":
		velocity = Vector3.ZERO
		if _action_timer >= startup:
			_action_phase = "active"
			_action_timer = 0.0
			_hit_applied_this_active = false
	elif _action_phase == "active":
		if not _hit_applied_this_active:
			_try_hit_player(act)
			_hit_applied_this_active = true
		if _action_timer >= active:
			_action_phase = "recovery"
			_action_timer = 0.0
	elif _action_phase == "recovery":
		velocity = velocity.lerp(Vector3.ZERO, delta * 10.0)
		if _action_timer >= recovery:
			_action_phase = "done"
			_current_action_id = ""


func _try_hit_player(act: Dictionary) -> void:
	if _player == null or _combat == null:
		return
	var range_m := float(act.get("range", 2.0))
	if global_position.distance_to(_player.global_position) > range_m:
		return
	if _player.is_invincible():
		EventBus.combat_message.emit("회피 성공!")
		return
	if _player.is_parry_active():
		apply_stagger(_ensure_data().parry_stagger)
		EventBus.combat_message.emit("패링 성공!")
		return
	var damage := int(act.get("damage", 0))
	if damage > 0:
		_combat.apply_damage_to_player(damage)


func _begin_dash_toward_player(speed: float) -> void:
	if _player == null:
		return
	var dir := _flat_to(_player.global_position)
	if dir.length() > 0.01:
		velocity = dir.normalized() * speed


func _enter_stagger(duration: float) -> void:
	_stagger_timer = duration
	_current_action_id = ""
	_action_phase = ""
	velocity = Vector3.ZERO
	EventBus.enemy_action_changed.emit("STAGGERED", "경직")


func _face_player() -> void:
	if _player == null:
		return
	var target := _player.global_position
	target.y = global_position.y
	look_at(target, Vector3.UP)


func _flat_to(target: Vector3) -> Vector3:
	var d := target - global_position
	d.y = 0.0
	return d


func _is_frontal_hit_from(attacker_pos: Vector3) -> bool:
	var to_attacker := (attacker_pos - global_position).normalized()
	var forward := -global_transform.basis.z.normalized()
	return forward.dot(to_attacker) > 0.25
