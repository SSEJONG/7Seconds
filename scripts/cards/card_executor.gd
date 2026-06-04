class_name CardExecutor
extends RefCounted
## docs/03, docs/05, docs/07 — 액션 페이즈 카드 1회 사용

static func execute(
	card: CardInstance,
	combat: CombatController,
	player: PlayerController,
	deck: DeckManager,
) -> float:
	if card == null or card.definition == null or card.remaining_uses <= 0:
		return 0.0

	var def := card.definition
	var duration := def.startup_sec + def.active_sec + def.recovery_sec

	match def.card_type:
		CardDefinition.CardType.ATTACK:
			if _try_attack(combat, player, def):
				_try_on_hit_draw(card, def, deck)
		CardDefinition.CardType.MOBILITY:
			player.apply_action_dash(minf(def.range_m * 0.3, 3.0))
			if def.damage > 0:
				_try_attack(combat, player, def)
		CardDefinition.CardType.DEFENSE:
			player.activate_parry_window(def.active_sec)
			EventBus.combat_message.emit(
				"%s — 패링 %.2f초" % [def.display_name, def.active_sec]
			)
		CardDefinition.CardType.TACTIC:
			_execute_tactic(def, combat, deck)
		_:
			EventBus.combat_message.emit("%s" % def.display_name)

	card.remaining_uses -= 1
	EventBus.card_used.emit(def.display_name, card.remaining_uses)
	return maxf(duration, 0.05)


static func _try_attack(
	combat: CombatController,
	player: PlayerController,
	def: CardDefinition,
) -> bool:
	if def.damage <= 0:
		EventBus.combat_message.emit("%s" % def.display_name)
		return false
	return combat.try_apply_card_hit(def.damage, def.stagger_damage, def.range_m, player)


static func _try_on_hit_draw(card: CardInstance, def: CardDefinition, deck: DeckManager) -> void:
	if not def.draw_on_hit or card.on_hit_draw_used:
		return
	card.on_hit_draw_used = true
	deck.draw_to_hand(1)
	EventBus.combat_message.emit("연속 베기 — 적중 시 카드 1장 드로우")


static func _execute_tactic(
	def: CardDefinition,
	combat: CombatController,
	deck: DeckManager,
) -> void:
	if def.action_time_delta != 0.0:
		combat.modify_action_time(def.action_time_delta)
		return
	match def.id:
		"tactical_reload":
			deck.draw_to_hand(1)
			EventBus.combat_message.emit("전술 재장착 — 손패에 카드 1장 추가")
		_:
			EventBus.combat_message.emit("%s" % def.display_name)
