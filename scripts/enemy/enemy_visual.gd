@tool
extends Node3D
## Enemy.glb — GLTF 런타임 로드 + 맵·에디터 크기 맞춤 (docs/11)

const _ModelLoader = preload("res://scripts/enemy/enemy_model_loader.gd")

@export var glb_path: String = "res://assets/animation/Enemy.glb"
@export var manual_scale: float = 1.0
@export var y_offset: float = 0.0
@export var auto_fit_height: float = 1.85
@export var ground_align: bool = true
@export var model_yaw_deg: float = 180.0


func _ready() -> void:
	call_deferred("_apply")


func _apply() -> void:
	if get_child_count() == 0 or not _has_animation_player():
		_ModelLoader.spawn_model(self, glb_path)
	var model := get_node_or_null("AnimatedEnemy") as Node3D
	if model and model_yaw_deg != 0.0:
		model.rotation.y = deg_to_rad(model_yaw_deg)
	var s := maxf(0.001, manual_scale)
	scale = Vector3(s, s, s)
	position.y = y_offset
	if auto_fit_height > 0.0:
		var mesh_h := _measure_mesh_height()
		if mesh_h > 0.001:
			var fit := auto_fit_height / mesh_h
			scale *= Vector3(fit, fit, fit)
	if ground_align:
		_align_feet_to_ground()
	_notify_animation_ready()


func _has_animation_player() -> bool:
	return _ModelLoader.find_animation_player(self) != null


func _notify_animation_ready() -> void:
	var enemy := get_parent()
	if enemy == null:
		return
	var anim := enemy.get_node_or_null("EnemyAnimation")
	if anim and anim.has_method("on_visual_ready"):
		anim.on_visual_ready()


func _measure_mesh_height() -> float:
	var min_y := INF
	var max_y := -INF
	for node in _find_mesh_instances(self):
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh == null:
			continue
		var aabb := mesh_inst.get_aabb()
		var xf := global_transform.affine_inverse() * mesh_inst.global_transform
		var corners := _aabb_corners(aabb)
		for c in corners:
			var local := xf * c
			min_y = minf(min_y, local.y)
			max_y = maxf(max_y, local.y)
	if min_y == INF:
		return 0.0
	return max_y - min_y


func _align_feet_to_ground() -> void:
	var min_y := INF
	for node in _find_mesh_instances(self):
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh == null:
			continue
		var aabb := mesh_inst.get_aabb()
		var xf := global_transform.affine_inverse() * mesh_inst.global_transform
		for c in _aabb_corners(aabb):
			min_y = minf(min_y, (xf * c).y)
	if min_y != INF and min_y != 0.0:
		position.y -= min_y


func _find_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			out.append(n as MeshInstance3D)
		for child in n.get_children():
			stack.append(child)
	return out


func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	var p := aabb.position
	var s := aabb.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s,
	]
