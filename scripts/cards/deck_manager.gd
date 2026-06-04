class_name DeckManager
extends Node
## docs/03 — 드로우·버림·손패 / 액션: 휠 선택·좌클릭 1장 사용

@export var cards_json_path: String = "res://data/mvp/cards_mvp.json"
@export var starting_deck_json_path: String = "res://data/mvp/starting_deck.json"

var draw_pile: Array[String] = []
var discard_pile: Array[String] = []
var hand: Array[CardInstance] = []
var rerolls_remaining: int = 0
var selected_hand_index: int = 0
var in_action_phase: bool = false

var _database: CardDatabase = CardDatabase.new()
var _card_use_busy: bool = false


func _ready() -> void:
	_database.load_from_json(cards_json_path)


func setup_battle() -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	rerolls_remaining = 0
	selected_hand_index = 0
	in_action_phase = false
	_card_use_busy = false
	_load_starting_deck_into_draw_pile()
	_shuffle_draw_pile()
	_emit_deck_state()


func start_turn() -> void:
	in_action_phase = false
	_card_use_busy = false
	rerolls_remaining = GameConstants.REROLL_COUNT_PER_TURN
	draw_to_hand(GameConstants.STARTING_HAND_SIZE)
	EventBus.combat_message.emit(
		"손패 %d장 — 교체 %d회 남음 (카드 클릭 후 [교체 확정])" % [hand.size(), rerolls_remaining]
	)
	_emit_deck_state()


func begin_action_phase() -> void:
	in_action_phase = true
	_card_use_busy = false
	selected_hand_index = _first_usable_index()
	_emit_deck_state()
	var selected := get_selected_card()
	if selected:
		EventBus.combat_message.emit(
			"액션 — 휠: 카드 변경 · 좌클릭: %s 사용" % selected.definition.display_name
		)
	else:
		EventBus.combat_message.emit("액션 — 사용 가능한 카드 없음")


func end_action_phase() -> void:
	in_action_phase = false
	_card_use_busy = false


func discard_hand_at_turn_end() -> void:
	end_action_phase()
	for card in hand:
		if card:
			discard_pile.append(card.get_definition_id())
	hand.clear()
	_emit_deck_state()


func draw_to_hand(count: int) -> void:
	for _i in count:
		var drawn := draw_one()
		if drawn == null:
			break
		hand.append(drawn)
	if in_action_phase and count > 0:
		_advance_selection_after_deplete()
		_emit_deck_state()


func notify_hand_changed() -> void:
	_emit_deck_state()


func draw_one() -> CardInstance:
	if draw_pile.is_empty():
		_reshuffle_discard_into_draw()
	if draw_pile.is_empty():
		return null
	var card_id: String = draw_pile.pop_back()
	return _database.create_instance(card_id)


func try_reroll(selected_hand_indices: Array[int]) -> bool:
	if in_action_phase or rerolls_remaining <= 0 or selected_hand_indices.is_empty():
		return false
	if not _indices_valid(selected_hand_indices):
		return false

	var sorted := selected_hand_indices.duplicate()
	sorted.sort()
	sorted.reverse()

	var discard_count := 0
	for idx in sorted:
		var card := hand[idx]
		discard_pile.append(card.get_definition_id())
		hand.remove_at(idx)
		discard_count += 1

	rerolls_remaining -= 1
	draw_to_hand(discard_count)
	selected_hand_index = clampi(selected_hand_index, 0, maxi(hand.size() - 1, 0))

	EventBus.combat_message.emit(
		"카드 %d장 교체 — 교체 %d회 남음" % [discard_count, rerolls_remaining]
	)
	_emit_deck_state()
	return true


func cycle_hand_selection(direction: int) -> void:
	if not in_action_phase or hand.is_empty() or _card_use_busy:
		return
	if direction == 0:
		return

	var step := 1 if direction > 0 else -1
	var idx := selected_hand_index
	var tries := hand.size()
	while tries > 0:
		idx = (idx + step + hand.size()) % hand.size()
		if hand[idx].is_usable():
			selected_hand_index = idx
			_emit_deck_state()
			return
		tries -= 1


func try_use_selected_card(combat: CombatController, player: PlayerController) -> bool:
	if not in_action_phase or _card_use_busy:
		return false
	var card := get_selected_card()
	if card == null or not card.is_usable():
		EventBus.combat_message.emit("사용할 수 없는 카드입니다")
		return false

	_card_use_busy = true
	var lock_sec := CardExecutor.execute(card, combat, player, self)
	if card.remaining_uses <= 0:
		_advance_selection_after_deplete()
	_emit_deck_state()
	_start_card_use_unlock(lock_sec)
	return true


func get_selected_card() -> CardInstance:
	if selected_hand_index < 0 or selected_hand_index >= hand.size():
		return null
	return hand[selected_hand_index]


func get_hand_labels() -> PackedStringArray:
	return get_hand_display_labels(false)


func get_hand_display_labels(for_action: bool) -> PackedStringArray:
	var labels := PackedStringArray()
	for i in hand.size():
		var card := hand[i]
		var text := card.get_label()
		if card.remaining_uses <= 0:
			text += " (소진)"
		if for_action and i == selected_hand_index and card.is_usable():
			text = "▶ " + text
		labels.append(text)
	return labels


func _start_card_use_unlock(seconds: float) -> void:
	var timer := get_tree().create_timer(seconds)
	timer.timeout.connect(_on_card_use_unlock)


func _on_card_use_unlock() -> void:
	_card_use_busy = false


func _advance_selection_after_deplete() -> void:
	var next := _first_usable_index()
	selected_hand_index = next if next >= 0 else 0


func _first_usable_index() -> int:
	for i in hand.size():
		if hand[i].is_usable():
			return i
	return -1


func _load_starting_deck_into_draw_pile() -> void:
	var file := FileAccess.open(starting_deck_json_path, FileAccess.READ)
	if file == null:
		push_error("DeckManager: cannot open %s" % starting_deck_json_path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for entry in parsed.get("entries", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var card_id := str(entry.get("id", ""))
		var count := int(entry.get("count", 0))
		if not _database.has_definition(card_id):
			push_warning("DeckManager: skipping unknown card '%s'" % card_id)
			continue
		for _i in count:
			draw_pile.append(card_id)


func _reshuffle_discard_into_draw() -> void:
	if discard_pile.is_empty():
		return
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	_shuffle_draw_pile()
	EventBus.combat_message.emit("버림 더미를 섞어 드로우 pile에 넣었습니다")


func _shuffle_draw_pile() -> void:
	draw_pile.shuffle()


func _indices_valid(indices: Array[int]) -> bool:
	var seen: Dictionary = {}
	for idx in indices:
		if idx < 0 or idx >= hand.size():
			return false
		if seen.has(idx):
			return false
		seen[idx] = true
	return true


func _emit_deck_state() -> void:
	var labels := get_hand_display_labels(in_action_phase)
	EventBus.combat_hand_changed.emit(labels, selected_hand_index, in_action_phase)
	EventBus.plan_hand_updated.emit(labels)
	EventBus.deck_piles_changed.emit(draw_pile.size(), discard_pile.size())
	EventBus.reroll_status_changed.emit(rerolls_remaining, rerolls_remaining > 0 and not in_action_phase)
