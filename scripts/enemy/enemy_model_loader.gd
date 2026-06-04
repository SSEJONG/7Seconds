extends RefCounted
## Enemy.glb — GLTFDocument로 스켈레탈·AnimationPlayer 확보 (docs/11)

const DEFAULT_GLB: String = "res://assets/animation/Enemy.glb"


static func spawn_model(parent: Node3D, glb_path: String = DEFAULT_GLB) -> Node3D:
	for child in parent.get_children():
		child.queue_free()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(glb_path, state) != OK:
		push_error("EnemyModelLoader: GLB 로드 실패 — %s" % glb_path)
		return null
	var model: Node3D = doc.generate_scene(state) as Node3D
	if model == null:
		push_error("EnemyModelLoader: generate_scene 실패 — %s" % glb_path)
		return null
	model.name = "AnimatedEnemy"
	parent.add_child(model)
	return model


static func find_animation_player(root: Node) -> AnimationPlayer:
	var best: AnimationPlayer = null
	var best_count := -1
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is AnimationPlayer:
			var ap := n as AnimationPlayer
			var count := ap.get_animation_list().size()
			if count > best_count:
				best_count = count
				best = ap
		for child in n.get_children():
			stack.append(child)
	return best


static func copy_animation_libraries(from_ap: AnimationPlayer, to_ap: AnimationPlayer) -> void:
	if from_ap == null or to_ap == null:
		return
	for lib_name in from_ap.get_animation_library_list():
		var lib := from_ap.get_animation_library(lib_name)
		if lib == null:
			continue
		var target_lib_name: String = str(lib_name)
		if target_lib_name.is_empty():
			target_lib_name = "default"
		if to_ap.has_animation_library(target_lib_name):
			to_ap.remove_animation_library(target_lib_name)
		to_ap.add_animation_library(target_lib_name, lib.duplicate(true))


static func ensure_animations_on_player(anim_player: AnimationPlayer, glb_path: String = DEFAULT_GLB) -> bool:
	if anim_player == null:
		return false
	if not anim_player.get_animation_list().is_empty():
		return true
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(glb_path, state) != OK:
		return false
	var temp: Node = doc.generate_scene(state)
	if temp == null:
		return false
	var src_ap := find_animation_player(temp)
	if src_ap == null:
		temp.queue_free()
		return false
	copy_animation_libraries(src_ap, anim_player)
	temp.queue_free()
	return not anim_player.get_animation_list().is_empty()
