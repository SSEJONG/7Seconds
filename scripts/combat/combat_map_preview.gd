extends Node
## 계획 단계에서 맵上的 적 확인용 — B 키로 프리뷰 카메라

@export var preview_camera_path: NodePath = ^"../MapPreviewCamera"
@export var player_path: NodePath = ^"../Player"

var _preview_cam: Camera3D
var _player_cam: Camera3D
var _combat: CombatController


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_preview_cam = get_node_or_null(preview_camera_path) as Camera3D
	_combat = get_tree().get_first_node_in_group("combat_controller") as CombatController
	var player := get_node_or_null(player_path) as PlayerController
	if player:
		_player_cam = player.get_node_or_null("Head/Camera3D") as Camera3D
	_set_preview_active(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map_preview"):
		_toggle_preview()


func _toggle_preview() -> void:
	if _preview_cam == null or _combat == null:
		return
	if _combat.state != CombatState.Id.PLAN_PHASE:
		EventBus.combat_message.emit("맵 프리뷰는 계획 단계에서만 (B)")
		return
	var on := not _preview_cam.current
	_set_preview_active(on)
	EventBus.combat_message.emit("맵 프리뷰: %s (B로 복귀)" % ("켜짐" if on else "꺼짐"))


func _set_preview_active(on: bool) -> void:
	if _preview_cam == null:
		return
	_preview_cam.current = on
	if _player_cam:
		_player_cam.current = not on
	if on:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
