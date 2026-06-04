class_name PlayerController
extends CharacterBody3D
## docs/02 — 1인칭 이동·시점·회피

@export var feel: PlayerFeelSettings
@export var combat_controller_path: NodePath = ^"../../CombatController"

var can_control: bool = false

var _combat: Node = null
var _head: Node3D
var _camera: Camera3D
var _pitch_rad: float = 0.0

var _dodge_cooldown_left: float = 0.0
var _dodge_time_left: float = 0.0
var _dodge_iframes_left: float = 0.0
var _dodge_recovery_left: float = 0.0
var _dodge_direction: Vector3 = Vector3.FORWARD
var _is_dodging: bool = false

var _shake_strength: float = 0.0
var _shake_decay: float = 10.0
var _camera_rest_local: Vector3 = Vector3.ZERO
var _last_shake_tick_usec: int = 0
var _parry_end_usec: int = 0


func _ready() -> void:
	if feel == null:
		feel = load("res://resources/combat/default_player_feel.tres") as PlayerFeelSettings
	_combat = get_node_or_null(combat_controller_path)
	_head = $Head
	_camera = $Head/Camera3D
	_apply_first_person_rig()
	_last_shake_tick_usec = Time.get_ticks_usec()
	var body_mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if body_mesh:
		body_mesh.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not can_control:
		return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		rotate_y(-motion.relative.x * feel.mouse_sensitivity)
		_pitch_rad = clampf(
			_pitch_rad - motion.relative.y * feel.mouse_sensitivity,
			deg_to_rad(feel.camera_pitch_min_deg),
			deg_to_rad(feel.camera_pitch_max_deg)
		)
		_head.rotation.x = _pitch_rad


func _physics_process(delta: float) -> void:
	_tick_dodge_timers(delta)
	if not can_control:
		_apply_gravity(delta)
		move_and_slide()
	else:
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var wish_dir := _get_flat_move_direction(input_dir)

		if _is_dodging:
			_process_dodge(delta)
		elif _dodge_recovery_left > 0.0:
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, feel.deceleration * delta)
			velocity.z = move_toward(velocity.z, 0.0, feel.deceleration * delta)
		else:
			_process_movement(wish_dir, delta)

		move_and_slide()
	_update_camera_shake(delta)


func set_control_enabled(enabled: bool) -> void:
	can_control = enabled
	if not enabled:
		velocity = Vector3.ZERO
		_is_dodging = false


func is_invincible() -> bool:
	return _dodge_iframes_left > 0.0


func activate_parry_window(duration_sec: float) -> void:
	if duration_sec <= 0.0:
		return
	_parry_end_usec = Time.get_ticks_usec() + int(duration_sec * 1_000_000.0)


func is_parry_active() -> bool:
	return _parry_end_usec > 0 and Time.get_ticks_usec() < _parry_end_usec


func trigger_hit_feedback() -> void:
	_shake_strength = maxf(_shake_strength, feel.camera_shake_on_hit)
	if feel.hit_stop_duration > 0.0 and _combat != null and _combat.has_method("request_hit_stop"):
		_combat.request_hit_stop(feel.hit_stop_duration)


func apply_action_dash(distance_m: float) -> void:
	if not can_control:
		return
	var dir := _get_flat_forward()
	velocity = dir * distance_m * 4.0
	velocity.y = 0.0


func get_aim_origin() -> Vector3:
	return _camera.global_position


func get_aim_direction() -> Vector3:
	return -_camera.global_transform.basis.z.normalized()


func _get_flat_move_direction(input_dir: Vector2) -> Vector3:
	if input_dir.is_zero_approx():
		return Vector3.ZERO
	var yaw_basis := Basis.from_euler(Vector3(0.0, rotation.y, 0.0))
	return (yaw_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()


func _get_flat_forward() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	return forward.normalized()


func _process_movement(wish_dir: Vector3, delta: float) -> void:
	_apply_gravity(delta)
	if wish_dir.is_zero_approx():
		velocity.x = move_toward(velocity.x, 0.0, feel.deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, feel.deceleration * delta)
	else:
		var target := wish_dir * feel.move_speed
		var accel := feel.air_control if not is_on_floor() else feel.acceleration
		velocity.x = move_toward(velocity.x, target.x, accel * delta)
		velocity.z = move_toward(velocity.z, target.z, accel * delta)

	if Input.is_action_just_pressed("dodge") and _dodge_cooldown_left <= 0.0 and _dodge_recovery_left <= 0.0:
		_start_dodge(wish_dir)


func _start_dodge(wish_dir: Vector3) -> void:
	_dodge_direction = wish_dir if not wish_dir.is_zero_approx() else _get_flat_forward()
	_is_dodging = true
	_dodge_time_left = feel.dodge_duration
	_dodge_iframes_left = feel.dodge_iframes
	_dodge_cooldown_left = feel.dodge_cooldown
	_shake_strength = maxf(_shake_strength, feel.dodge_whoosh_strength * 0.5)
	velocity = _dodge_direction * feel.dodge_speed * feel.dodge_distance_multiplier
	velocity.y = 0.0


func _process_dodge(delta: float) -> void:
	_dodge_time_left -= delta
	velocity = _dodge_direction * feel.dodge_speed * feel.dodge_distance_multiplier
	velocity.y = 0.0
	if _dodge_time_left <= 0.0:
		_is_dodging = false
		_dodge_recovery_left = feel.dodge_recovery
		velocity *= 0.35


func _tick_dodge_timers(delta: float) -> void:
	if _dodge_cooldown_left > 0.0:
		_dodge_cooldown_left = maxf(0.0, _dodge_cooldown_left - delta)
	if _dodge_iframes_left > 0.0:
		_dodge_iframes_left = maxf(0.0, _dodge_iframes_left - delta)
	if _dodge_recovery_left > 0.0:
		_dodge_recovery_left = maxf(0.0, _dodge_recovery_left - delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= feel.gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0


func _apply_first_person_rig() -> void:
	_head.position = Vector3(0.0, feel.eye_height_m, 0.0)
	_camera.position = Vector3.ZERO
	_camera.rotation = Vector3.ZERO
	_camera.fov = feel.camera_fov_deg
	_camera_rest_local = Vector3.ZERO
	_pitch_rad = 0.0
	_head.rotation.x = 0.0


func _update_camera_shake(scaled_delta: float) -> void:
	if _shake_strength <= 0.0:
		_camera.position = _camera_rest_local
		_shake_strength = 0.0
		_last_shake_tick_usec = 0
		return
	var offset := Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		0.0
	) * _shake_strength
	_camera.position = _camera_rest_local + offset
	# Godot 4.6에는 Engine.get_real_delta_time() 없음 — 히트스톱 시에만 시계로 감쇠
	var dt: float = scaled_delta
	if dt <= 0.000001:
		var now_usec: int = Time.get_ticks_usec()
		if _last_shake_tick_usec > 0:
			dt = float(now_usec - _last_shake_tick_usec) / 1_000_000.0
		_last_shake_tick_usec = now_usec
	_shake_strength = maxf(0.0, _shake_strength - _shake_decay * dt)
