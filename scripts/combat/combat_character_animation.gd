extends Node
class_name CombatCharacterAnimation
## docs/11 — 계획·정산: Idle 루프 / 액션 페이즈만 전투 모션

const _ModelLoader = preload("res://scripts/enemy/enemy_model_loader.gd")

const IDLE_ANIM_CANDIDATES: PackedStringArray = [
	"Idle_FoldArms_Loop",
	"Idle_No_Loop",
	"Zombie_Idle_Loop",
]

@export var visual_path: NodePath
@export var glb_fallback_path: String = "res://assets/animation/Enemy.glb"
@export var hide_visual_during_action: bool = false
@export var face_opponent_in_plan: bool = false

var _anim_player: AnimationPlayer
var _visual: Node3D
var _idle_anim: String = ""
var _combat_anims_enabled: bool = false
var _current_action: String = ""
var _bound: bool = false


func _ready() -> void:
	EventBus.combat_state_changed.connect(_on_combat_state_changed)
	EventBus.turn_started.connect(_on_turn_started)
	call_deferred("_try_bind")


func on_visual_ready() -> void:
	call_deferred("_try_bind")


func _try_bind() -> void:
	if _bound:
		_apply_plan_stance()
		return
	_visual = get_node_or_null(visual_path) as Node3D
	if _visual == null:
		return
	_anim_player = _ModelLoader.find_animation_player(_visual)
	if _anim_player == null:
		push_warning("%s: AnimationPlayer 없음" % get_script().resource_path.get_file())
		return
	if not _ModelLoader.ensure_animations_on_player(_anim_player, glb_fallback_path):
		push_warning("%s: GLB에서 애니 라이브러리 주입 실패" % get_script().resource_path.get_file())
	_anim_player.active = true
	_anim_player.process_mode = Node.PROCESS_MODE_INHERIT
	if not _anim_player.animation_finished.is_connected(_on_animation_finished):
		_anim_player.animation_finished.connect(_on_animation_finished)
	_idle_anim = _pick_idle_animation()
	if _idle_anim.is_empty():
		push_warning("%s: Idle 클립을 찾지 못함" % get_script().resource_path.get_file())
		return
	_connect_action_signals()
	_bound = true
	_sync_to_current_combat_state()


func _pick_idle_animation() -> String:
	for candidate in IDLE_ANIM_CANDIDATES:
		var resolved := _resolve_animation_name(candidate)
		if not resolved.is_empty():
			return resolved
	for anim_name in _anim_player.get_animation_list():
		var short := _short_anim_name(anim_name)
		var lower := short.to_lower()
		if "idle" in lower and "loop" in lower and "tpose" not in lower:
			return anim_name
	for anim_name in _anim_player.get_animation_list():
		var lower := _short_anim_name(anim_name).to_lower()
		if "idle" in lower and "tpose" not in lower:
			return anim_name
	return ""


func _short_anim_name(full_name: String) -> String:
	var slash := full_name.rfind("/")
	if slash >= 0:
		return full_name.substr(slash + 1)
	return full_name


func _resolve_animation_name(name: String) -> String:
	if _anim_player == null or name.is_empty():
		return ""
	if _anim_player.has_animation(name):
		return name
	for lib_name in _anim_player.get_animation_library_list():
		var full := "%s/%s" % [lib_name, name]
		if _anim_player.has_animation(full):
			return full
		var lib := _anim_player.get_animation_library(lib_name)
		if lib != null and lib.has_animation(name):
			return full
	for existing in _anim_player.get_animation_list():
		if existing == name or existing.ends_with("/%s" % name):
			return existing
		if _short_anim_name(existing) == name:
			return existing
	return ""


func _connect_action_signals() -> void:
	pass


func _on_action_signal(_action_id: String, _display_name: String) -> void:
	pass


func _on_turn_started(_turn_number: int) -> void:
	_apply_plan_stance()


func _on_combat_state_changed(_old_state: int, new_state: int) -> void:
	_combat_anims_enabled = new_state == CombatState.Id.ACTION_PHASE
	if hide_visual_during_action:
		_set_body_visible(new_state != CombatState.Id.ACTION_PHASE)
	if CombatState.is_time_frozen(new_state) or new_state == CombatState.Id.INIT:
		_apply_plan_stance()


func _apply_plan_stance() -> void:
	if not _bound:
		return
	if face_opponent_in_plan:
		_face_opponent()
	_force_idle()


func _sync_to_current_combat_state() -> void:
	var combat := get_tree().get_first_node_in_group("combat_controller") as CombatController
	if combat:
		_on_combat_state_changed(combat.state, combat.state)


func _set_body_visible(visible: bool) -> void:
	if _visual:
		_visual.visible = visible


func _face_opponent() -> void:
	var body := get_parent() as Node3D
	if body == null:
		return
	var target: Node3D = _find_opponent()
	if target == null:
		return
	var look_pos := target.global_position
	look_pos.y = body.global_position.y
	body.look_at(look_pos, Vector3.UP)


func _find_opponent() -> Node3D:
	if get_parent() and get_parent().is_in_group("enemy"):
		return get_tree().get_first_node_in_group("player") as Node3D
	return get_tree().get_first_node_in_group("enemy") as Node3D


func _on_combat_action(action_id: String) -> void:
	if not _combat_anims_enabled or _anim_player == null:
		return
	_play_mapped_action(action_id)


func _play_mapped_action(action_id: String) -> void:
	_current_action = action_id
	var anim_name: String = _map_action_to_anim(action_id)
	anim_name = _resolve_animation_name(anim_name)
	if anim_name.is_empty():
		_force_idle()
		return
	_anim_player.play(anim_name)
	_anim_player.advance(0.0)


func _map_action_to_anim(_action_id: String) -> String:
	return _idle_anim


func _on_animation_finished(anim_name: StringName) -> void:
	if _anim_player == null or not _combat_anims_enabled:
		return
	if _current_action == "DEAD":
		return
	if _should_hold_loop():
		return
	var anim := _anim_player.get_animation(String(anim_name))
	if anim != null and anim.loop_mode != Animation.LOOP_NONE:
		return
	_force_idle()


func _should_hold_loop() -> bool:
	return false


func _force_idle() -> void:
	if _anim_player == null or _idle_anim.is_empty():
		return
	_current_action = ""
	if _anim_player.current_animation != _idle_anim:
		_anim_player.play(_idle_anim)
	_anim_player.advance(0.0)
