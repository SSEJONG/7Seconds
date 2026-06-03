class_name EnemyPlaceholder
extends CharacterBody3D

signal died

@export var max_hp: int = GameConstants.ENEMY_MAX_HP

var current_hp: int = max_hp


func _ready() -> void:
	current_hp = max_hp
	EventBus.enemy_hp_changed.emit(current_hp, max_hp)


func apply_damage(amount: int) -> void:
	if current_hp <= 0:
		return
	current_hp = maxi(0, current_hp - amount)
	EventBus.enemy_hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		died.emit()


func is_alive() -> bool:
	return current_hp > 0
