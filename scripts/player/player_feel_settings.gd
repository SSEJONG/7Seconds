class_name PlayerFeelSettings
extends Resource
## 기획자 조정용 — 상세 설명은 docs/09_player_feel_tuning.md

@export_group("이동 (손맛)")
@export_range(1.0, 20.0, 0.1) var move_speed: float = 6.0
@export_range(1.0, 80.0, 0.5) var acceleration: float = 28.0
@export_range(1.0, 80.0, 0.5) var deceleration: float = 32.0
@export_range(0.0, 40.0, 0.5) var air_control: float = 4.0
@export_range(1.0, 40.0, 0.5) var gravity: float = 18.0

@export_group("회피 (손맛)")
@export_range(2.0, 30.0, 0.5) var dodge_speed: float = 12.0
@export_range(0.05, 0.6, 0.01) var dodge_duration: float = 0.22
@export_range(0.1, 3.0, 0.05) var dodge_cooldown: float = 1.0
@export_range(0.05, 0.8, 0.01) var dodge_iframes: float = 0.25
@export_range(0.0, 0.6, 0.01) var dodge_recovery: float = 0.2
@export_range(0.5, 4.0, 0.1) var dodge_distance_multiplier: float = 1.0

@export_group("카메라 (손맛)")
@export_range(0.0005, 0.02, 0.0005) var mouse_sensitivity: float = 0.003
@export_range(10.0, 90.0, 1.0) var camera_pitch_min_deg: float = -50.0
@export_range(10.0, 89.0, 1.0) var camera_pitch_max_deg: float = 60.0
@export_range(2.0, 20.0, 0.5) var camera_height: float = 5.5
@export_range(4.0, 24.0, 0.5) var camera_distance: float = 9.0

@export_group("타격감 (연출)")
@export_range(0.0, 0.25, 0.005) var hit_stop_duration: float = 0.06
@export_range(0.0, 1.0, 0.05) var camera_shake_on_hit: float = 0.15
@export_range(0.0, 1.0, 0.05) var dodge_whoosh_strength: float = 0.35
