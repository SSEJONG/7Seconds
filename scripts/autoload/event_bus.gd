extends Node
## 전역 이벤트 허브 (Autoload).
## emit: combat_controller, enemy_placeholder 등 / connect: combat_debug_ui 등
## 이 파일 안에서는 시그널을 쓰지 않으므로 UNUSED_SIGNAL 경고가 납니다 — 의도된 설계입니다.
@warning_ignore("unused_signal")

signal combat_state_changed(old_state: int, new_state: int)
signal turn_started(turn_number: int)
signal action_time_changed(remaining: float, total: float)
signal player_hp_changed(current: int, max_hp: int)
signal enemy_hp_changed(current: int, max_hp: int)
signal plan_hand_updated(card_labels: PackedStringArray)
signal combat_message(message: String)
